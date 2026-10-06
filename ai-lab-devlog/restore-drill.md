# Monthly Restore Drill — Runbook

**Goal:** prove the backups in `scripts/backup.sh` can actually bring the stack back
**before** a real disaster. Every drill restores into throwaway names first — **the live
volumes and database are never touched** until the explicit full-rebuild step, which this
drill does NOT perform.

- Server: `<user>@<vps-ip>` (OVH VPS-1 2027, Debian 13) · project dir `~/ai-lab`
  (VERIFIED 2026-10-06, read-only: `ls ~/ai-lab` shows `compose.yaml`, `Caddyfile`, `backups/`, `scripts/`)
- Source: age-encrypted sets in Backblaze B2 bucket `ai-lab-backups`
  (VERIFIED 2026-10-06, read-only: `rclone lsl b2:ai-lab-backups/` lists sets up to 2026-09-17)
- When: once a month, plus one full-rebuild drill per the roadmap. Budget ~30–45 min.
- Risk: LOW (decrypt + restore to temp names only; read-only against live data)

What each backup set contains (per `scripts/backup.sh`):

| File | Contents | How it was made |
|---|---|---|
| `ai-lab-db-<ts>.dump.age` | PostgreSQL custom-format dump | `pg_dump -Fc` via `docker exec ai-lab-postgres` |
| `ai-lab-volumes-<ts>.tar.gz.age` | `pgdata`, `caddy_data`, `caddy_config` volumes | `alpine tar -C /data` over read-only mounts |
| `ai-lab-config-<ts>.tar.gz.age` | `compose.yaml`, `Caddyfile`, `scripts/`, misc | `tar -C ~/ai-lab` |

> Known gaps (verified from repo reads, 2026-10-06): `compose.yaml` also defines a
> `redis_data` volume that `backup.sh` does **not** archive — decide whether Redis
> persistence needs backup before relying on this drill. The config tar lists
> `rescue-drill.md` at the project root, but the file lives at
> `ai-lab-devlog/rescue-drill.md` — that entry archives nothing (`|| true` either way).
> Nightly timer unit is `ai-lab-backup.timer` (user unit, VERIFIED below).

> Health warning from the 2026-10-06 read-only check: the nightly backup is
> currently FAILING (service exits 1 at "Fetching secrets from Infisical", every
> night Oct 4–6; last good triple is 2026-09-17; 0-byte `.dump` residue files
> linger in `~/ai-lab/backups/`). Suspected cause: the hardcoded
> `INFISICAL_TOKEN` in `scripts/backup.sh` expired mid-September. Fix that first —
> otherwise this drill tests a stale September set. Also: the Docker daemon was
> `inactive`/`disabled` at check time, so Steps 4–5 need a running daemon.

---

## Step 0 — Before you start (on your computer)

You need three things. If any is missing, stop — the drill fails closed:

1. **Age identity** (the private key matching `AGE_PUBLIC_KEY` in `scripts/backup.sh`).
   The public key alone cannot decrypt. Know where the private key lives before you start.
   (Location UNVERIFIED — never executed a decrypt in the read-only check.)
2. **B2 access** — `rclone` configured with a remote that can read `b2:ai-lab-backups`
   (VERIFIED 2026-10-06: remote `b2:` exists on the VPS and lists the bucket.)
3. **Infisical access** — needed only for the paper walk-through of Step 5
   (machine identity `mac-cli`, scope `prod:/**` per `roadmap.md`).

Record the live state so the drill has something to compare against (read-only):

```sh
ssh <user>@<vps-ip> 'docker compose --project-directory ~/ai-lab ps; \
echo "--- volumes"; docker volume ls | grep ai-lab; \
echo "--- latest set"; ls -l ~/ai-lab/backups/ | tail -5; \
echo "--- timer"; systemctl --user status ai-lab-backup.timer 2>&1 | head -5' > /tmp/pre-restore-state.txt
```

(Timer unit name VERIFIED 2026-10-06: `ai-lab-backup.timer`, user unit at
`~/.config/systemd/user/ai-lab-backup.timer`, `OnCalendar=daily` with
`RandomizedDelaySec=1800`. If `docker compose ps` errors, the daemon may be down —
see `pause-resume.md` to bring the stack up first.)

---

## Step 1 — Fetch the latest backup set (to your computer or the VPS `/tmp`)

Pick one restore host. Prefer the VPS `/tmp` (bandwidth is free there); use your
computer only if you want to prove the set is retrievable off-site.

```sh
# list what B2 actually has (proves the nightly upload works)
rclone lsl b2:ai-lab-backups/ | sort | tail -5

# fetch the newest triple (replace <ts> with the real timestamp)
export TS=<ts>
rclone copy b2:ai-lab-backups/ai-lab-db-$TS.dump.age \
            b2:ai-lab-backups/ai-lab-volumes-$TS.tar.gz.age \
            b2:ai-lab-backups/ai-lab-config-$TS.tar.gz.age /tmp/restore-drill/
ls -l /tmp/restore-drill/
```

Expected result: all three `.age` files present, non-empty, timestamps from last night.
(If the newest triple is weeks old, the nightly job is broken — check
`systemctl --user status ai-lab-backup.service` before trusting the set.)

---

## Step 2 — Decrypt (age)

```sh
cd /tmp/restore-drill/
for f in *.age; do age -d -i ~/.age/ai-lab-identity.txt -o "${f%.age}" "$f"; done
ls -l   # expect: .dump + two .tar.gz, no .age left unprocessed
```

If `age` asks for a passphrase / fails on the identity file, the drill stops here —
that means the private key is lost and **backups are unrecoverable**. Re-keying
(`age-keygen`, new public key in `scripts/backup.sh`, fresh full backup) becomes the
priority action.

---

## Step 3 — Verify integrity (no restore yet)

```sh
# 1. DB dump table of contents (proves pg_dump -Fc output is intact)
pg_restore --list ai-lab-db-$TS.dump | head -20
pg_restore --list ai-lab-db-$TS.dump | wc -l   # expect > 0

# 2. Volume + config archives list cleanly (proves tar is intact)
tar -tzf ai-lab-volumes-$TS.tar.gz | head -20
tar -tzf ai-lab-config-$TS.tar.gz
```

Expected result: no `unexpected EOF` / checksum errors from any archive.

---

## Step 4 — Drill restore into throwaway names (never the live volumes)

Spin up a scratch Postgres container and restore **there**, and unpack volumes to
`/tmp` — the live `ai-lab-postgres` container and `ai-lab_*` volumes stay running
untouched:

```sh
# scratch postgres ( throwaway volume + throwaway container name )
docker volume create restore-drill-pgdata
docker run -d --name restore-drill-postgres \
  -e POSTGRES_USER=drill -e POSTGRES_PASSWORD=drill -e POSTGRES_DB=drill \
  -v restore-drill-pgdata:/var/lib/postgresql/data postgres:17.11
sleep 8
docker exec restore-drill-postgres pg_isready -U drill -d drill   # expect: accepting connections

# restore the dump into the scratch container (role/db created fresh)
docker exec -i restore-drill-postgres psql -U drill -d drill -c \
  "SELECT 1;"   # sanity: scratch db answers
cat ai-lab-db-$TS.dump | docker exec -i restore-drill-postgres \
  pg_restore -U drill -d drill --no-owner --role=drill 2>&1 | tail -5

# unpack volumes to /tmp (list only — proves paths, writes nothing to docker volumes)
mkdir -p /tmp/restore-drill/volumes && tar -xzf ai-lab-volumes-$TS.tar.gz -C /tmp/restore-drill/volumes/
ls /tmp/restore-drill/volumes/   # expect: pgdata/ caddy_data/ caddy_config/
```

Expected result: `pg_restore` exits 0 (warnings about `OWNER` are fine given
`--no-owner`), scratch DB answers queries, volume tree lists.

---

## Step 5 — Acceptance criteria (the drill passes iff ALL hold)

Run these against the **scratch** restore, then record pass/fail:

- [ ] All three `.age` files fetched from B2, decrypted with the stored age identity
- [ ] `pg_restore --list` on the dump succeeds (no corruption)
- [ ] Scratch restore exits 0; row/table spot-check answers, e.g.
      `docker exec restore-drill-postgres psql -U drill -d drill -c '\dt'`
      shows the expected tables (compare with live: `SELECT count(*) FROM <key-table>`)
- [ ] Volume tar extracts with `pgdata/`, `caddy_data/`, `caddy_config/` present
- [ ] Config tar contains a `compose.yaml` identical to git HEAD
      (`diff <(tar -xzOf ai-lab-config-$TS.tar.gz compose.yaml) compose.yaml`)
- [ ] Live stack untouched: `docker compose ps` output matches `/tmp/pre-restore-state.txt`

Then tear down the scratch restore:

```sh
docker rm -f restore-drill-postgres
docker volume rm restore-drill-pgdata
rm -rf /tmp/restore-drill
```

---

## Step 6 — Full-rebuild path (paper walk-through, NOT executed in the monthly drill)

Once, per the roadmap, do this for real (fresh VPS or wiped project dir). Monthly,
just re-read it and note anything that rotted:

1. Fresh Debian → clone repo, install Docker + Compose plugin, `infisical` + `rclone` + `age`.
2. `infisical run -- ... -- docker compose up -d postgres` (secrets from Infisical —
   no `.env` to restore, by design).
3. Fetch + decrypt latest set (Steps 1–2), then restore **for real**:
   ```sh
   cat ai-lab-db-$TS.dump | docker exec -i ai-lab-postgres \
     pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --no-owner
   docker compose down
   # volumes: stop stack first, then unpack over fresh volumes, then up
   docker run --rm -v ai-lab_pgdata:/data/pgdata -v /tmp/restore-drill:/backup \
     alpine tar -xzf /backup/ai-lab-volumes-$TS.tar.gz -C /data
   infisical run -- ... -- docker compose up -d
   ```
4. Acceptance: external `curl http://<vps-ip>.sslip.io/` → hello JSON,
   `pg_isready` healthy, port 5432 closed externally, SSH intact.

(OVH-mount variant per roadmap: boot rescue, mount `/dev/sda1`, copy the B2 set
in from there — UNVERIFIED, never exercised.)

---

## Step 7 — Close out

- [ ] Scratch containers/volumes removed, `/tmp/restore-drill` deleted (no dump residue)
- [ ] Record the drill in `journal.md` (date, backup timestamp tested, pass/fail per criterion, surprises)
- [ ] If anything failed: file the fix (re-key age, fix `backup.sh` paths, add `redis_data`) before next month
- [ ] Confirm the next monthly drill date (systemd calendar or local reminder)

---

## Notes & gotchas

- **Age private key is the single point of failure.** Public key in git is useless
  without it. Store the identity offline in ≥2 places; the drill is the proof it exists.
- **Never `pg_restore` into the live container during a monthly drill.** Step 4 uses
  `restore-drill-postgres` precisely so a corrupt dump can't take down production data.
- **B2 lifecycle vs local retention:** `backup.sh` deletes local `.age` files after 30
  days but never prunes B2 — check bucket growth monthly (`rclone size b2:ai-lab-backups/`).
- **`latest` symlinks** in `~/ai-lab/backups/` (`ai-lab-db.dump.age`,
  `ai-lab-volumes.tar.gz.age`, `ai-lab-config.tar.gz.age` → newest dated set,
  VERIFIED 2026-10-06) are handy for Step 1 — but confirm they point at a fresh
  set before relying on them.
- **OVH Automated Backup (1 rotation, daily)** is a whole-disk safety net, not a
  substitute: file-level restore from B2 is what this drill practices.
- If anything looks wrong after a *full rebuild*: `docker compose logs -f`,
  `systemctl --user status`, and B2 still holds every prior set — nothing is destructive
  until you `docker volume rm` the live volumes.
