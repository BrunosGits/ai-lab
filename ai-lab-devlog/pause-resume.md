# Pause / Resume — Runbook

**Goal:** stop the whole stack cleanly (pause) and bring it back in minutes
(resume), with no lost data and no secret re-entry. **Pause never deletes volumes.**

- Server: `<user>@<vps-ip>` (OVH VPS-1 2027, Debian 13) · project dir `~/ai-lab`
  (VERIFIED 2026-10-06, read-only: `compose.yaml`, `Caddyfile`, `backups/`, `scripts/` present)
- When: before host maintenance, to free RAM/CPU, or to cut churn while away.
  Budget ~10 min each way.
- Risk: LOW (compose `stop`/`down` without `-v` keeps all volumes; secrets stay in Infisical)

---

## What runs where

| Piece | Where | Unit / name (VERIFIED 2026-10-06 unless noted) |
|---|---|---|
| Docker stack | `~/ai-lab/compose.yaml` | `ai-lab-caddy`, `ai-lab-hello`, `ai-lab-redis`, `ai-lab-postgres` (UNVERIFIED live — daemon was down at check time) |
| Nightly backup | user systemd | `ai-lab-backup.timer` (`OnCalendar=daily`, `RandomizedDelaySec=1800`) → `ai-lab-backup.service` (`ExecStart=~/ai-lab/scripts/backup.sh`) |
| Docker daemon | system systemd | `docker.service` (was `inactive`/`disabled` at check time — resume must start it) |
| Secrets | Infisical Cloud | injected via `infisical run -- docker compose …` — no `.env` on disk, nothing to back up by hand |

---

## Step 0 — Record the running state (read-only, both before pause and after resume)

```sh
ssh <user>@<vps-ip> 'echo "--- compose"; docker compose --project-directory ~/ai-lab ps; \
echo "--- daemon"; systemctl is-active docker; \
echo "--- timer"; systemctl --user is-active ai-lab-backup.timer; \
echo "--- next run"; systemctl --user list-timers ai-lab-backup.timer --no-pager' > /tmp/pre-pause-state.txt
```

---

## Step 1 — Pause: stop the backup timer first (so it can't fire mid-pause)

```sh
ssh <user>@<vps-ip> 'systemctl --user stop ai-lab-backup.timer; \
systemctl --user is-active ai-lab-backup.timer || echo "timer stopped"'
```

Stopping (not disabling) keeps the schedule for resume. Use `disable` instead only if
the pause will last weeks.

---

## Step 2 — Pause: stop the stack (volumes kept)

```sh
# from ~/ai-lab on the VPS; secrets inject at runtime, no .env needed
ssh <user>@<vps-ip> 'infisical run --projectId <id> --env prod --path /caddy --path /postgres -- \
  docker compose --project-directory ~/ai-lab stop'
```

Prefer `stop` over `down`: containers stay defined, `up` is one command, networks
and volume attachments are untouched. Use `down` only if you also want the
one-off network cleanup.

Verify: `docker compose --project-directory ~/ai-lab ps` shows all `exited`,
and external `curl http://<vps-ip>.sslip.io/` no longer answers (expected).

---

## Step 3 — Pause (optional): stop the Docker daemon

Only if pausing to free maximum RAM or for host work:

```sh
ssh <user>@<vps-ip> 'sudo systemctl stop docker; systemctl is-active docker || echo "docker stopped"'
```

> `daemon.json` has `live-restore: true`, so a daemon *restart* would keep
> containers up — but we already stopped them, so this step just reclaims memory.

---

## Step 4 — Resume: start the daemon, then the stack

```sh
# 1. daemon (needed — it was found disabled/inactive on 2026-10-06)
ssh <user>@<vps-ip> 'sudo systemctl start docker; systemctl is-active docker'

# 2. stack, same secrets pattern as always
ssh <user>@<vps-ip> 'infisical run --projectId <id> --env prod --path /caddy --path /postgres -- \
  docker compose --project-directory ~/ai-lab up -d'
```

---

## Step 5 — Resume: re-arm the backup timer, verify health

```sh
ssh <user>@<vps-ip> 'systemctl --user start ai-lab-backup.timer; \
systemctl --user is-active ai-lab-backup.timer; \
docker compose --project-directory ~/ai-lab ps; \
docker exec ai-lab-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
curl -s http://<vps-ip>.sslip.io/   # expect: {"message":"hello from docker compose"}
```

Acceptance (resume passes iff ALL hold):

- [ ] `docker compose ps` shows all four containers `Up` (`postgres` `healthy`)
- [ ] `pg_isready` answers `accepting connections`
- [ ] external curl returns the hello JSON; port 5432 stays closed externally
- [ ] `ai-lab-backup.timer` is `active (waiting)` with a future trigger
- [ ] output matches `/tmp/pre-pause-state.txt` from Step 0

---

## Step 6 — Close out

- [ ] Compare post-resume state against `/tmp/pre-pause-state.txt` (containers, timer)
- [ ] Record pause/resume in `journal.md` (date, reason, duration, surprises)
- [ ] If the pause was for host maintenance, confirm `netfilter-persistent` rules
      reloaded (`sudo iptables -S INPUT` shows 22/80/443 ACCEPT + DROP policy)

---

## Notes & gotchas

- **Never `docker compose down -v`.** The `-v` flag deletes named volumes
  (`pgdata`, `caddy_data`, …) — that turns a pause into data loss. `stop` can't hurt you.
- **Secrets are not files.** If `infisical run` fails on resume (bad token/scope —
  scope must be `prod:/**` per `roadmap.md`), the stack won't start. That is a
  secrets problem, not a data problem; volumes are still intact.
- **Timer + daemon interplay:** the backup service runs `After=network.target
  docker.service`, so resuming the stack before re-arming the timer is the safe order.
- **If the backup was already failing before the pause** (it was, nightly since
  2026-09-18 per the 2026-10-06 check — suspected expired `INFISICAL_TOKEN` in
  `scripts/backup.sh`), resume won't fix it. See `restore-drill.md` before trusting
  any backup set.
