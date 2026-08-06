# Project Conception Log

Timeline of decisions behind the AI Lab VPS project. Every idea considered, chosen or
rejected, and why. This complements `session-log.md` (what was done) and `journal.md`
(how it felt). Updated whenever a decision is made.

---

## 2026-08-04 — Day one

**Decision: buy the VPS now, stop planning.**
- Considered: planning longer, waiting for a "better moment"
- Chosen: impulsive credit card purchase (OVH VPS-1 2027, 2 vCPU, 4 GB RAM, 40 GB disk, Debian 13)
- Why: momentum beats planning when planning stops producing decisions. Committing money made the project real.

**Decision: keep a printable master plan (PDF).**
- Considered: a purely digital plan
- Chosen: `ai-lab-summary.md` + `ai-lab-summary.pdf` (printed copy is the source of truth)
- Rejected later: regenerating the PDF when the md changes. The printed copy stays canonical.

**Decision: time tracking from day one.**
- Chosen: `time-tracker.json` + `scripts/time-tracker.py` + `session-log.md`
- Why: target ~9–11 h/week until Dec 15, 2026.

---

## 2026-08-05 — Infrastructure decisions

**Decision: harden SSH aggressively.**
- Chosen: key-only auth, root password disabled, `passwd -l root`, Fail2Ban, UFW 22/80/443.
- Gotcha learned: OpenSSH is first-value-wins. A `60-hardening.conf` drop-in does not override `50-cloud-init.conf`, the earlier file had to be edited directly.

**Decision: Fail2Ban bantime raised 10m → 1h.**
- Why: after hardening, the server still absorbed thousands of failed logins per day. 10 minutes was too weak.

**Decision: xrdp bound to loopback (127.0.0.1:3389).**
- Considered: keeping it on all interfaces for easy GUI access
- Chosen: loopback only, after security audit flagged `*:3389` as a public exposure. Access via SSH tunnel.

**Decision: desktop GUI stays for now, removed before Docker.**
- Chosen: Xfce + xrdp + Chrome + OpenCode Desktop stay during Phase 1.5 for learning, then get removed first in Phase 2.
- Why: a GUI idles at ~2.5–4.5 GB RAM on a 4 GB VPS. It must go before Docker needs the memory.
- Status: scheduled, not yet done.

**Decision: systemd-first (Phase 1.5) before Docker.**
- Chosen: PostgreSQL via apt + FastAPI behind a systemd unit + gunicorn first.
- Why: learn Linux before containers. Docker is Phase 2, and the systemd unit stays as a rollback path.

**Decision: PostgreSQL 17, single instance, as a container in Phase 3.**
- Considered: keeping the apt cluster (PG 17) and adding a PG 16 container (original plan)
- Chosen: containerize `postgres:17` (matching the apt version), drop the apt cluster. No duplication, one postgres.
- Why: architecture review flagged the duplicate-postgres problem as the top finding.

**Decision: backup target = Backblaze B2 primary.**
- Considered: rclone → B2 or OVH Object Storage (was open)
- Chosen: B2 primary (10 GB free tier, off-provider redundancy), OVH Object Storage kept as documented alternative.

**Decision: backups on a systemd timer, not cron.**
- Why: systemd-first philosophy. Timer units are the systemd-native way.

**Decision: backup encryption with age, not gpg.**
- Why: age is simpler and modern. Reviewer-backed.

**Decision: Month 3 = OpenCode Zen (not OpenRouter).**
- Renamed after architecture review (M1). Multi-model access via Zen + HF instead.

**Decision: DNS plan added.**
- Considered: none (no plan at all)
- Chosen: sslip.io/nip.io for tests → custom ~$10/yr domain before going public.

**Decision: rescue mode gets a real drill.**
- Chosen: `rescue-drill.md` runbook written (mount read-only, verify marker, chroot recovery, reboot).
- Status: runbook done, drill NOT yet run. Scheduled as the first task of Phase 2.

**Decision: UFW separated from DOCKER-USER.**
- UFW 22/80/443 marked complete. DOCKER-USER default-drop (conntrack-ACCEPT-then-DROP via netfilter-persistent) kept as a Phase 2 task so it survives reboot.

**Decision: Docker daemon hardening plan set.**
- Chosen: log rotation (10m × 3), `live-restore: true`, builder GC.

---

## 2026-08-05 — Journaling & tooling

**Decision: keep a personal journal.**
- Considered: Day One, Notion, Bear, a git commit-message diary
- Chosen: `journal.md` in the repo (markdown, free, private, exportable forever, git history as timeline).
- Noted: when the repo goes public, the journal goes with it. Revisit at that point (keep, git rm, or skip-worktree).

**Decision: Obsidian NOT added now.**
- Considered: Obsidian for journaling + backlinks + graph + Dataview + mobile capture
- Rejected: the wins are future value (needs ~30+ notes to matter), plus costs: another app, GUI, git-conflict risk with the commit flow.
- Revisit when: corpus reaches ~30+ notes, or when phone capture is wanted. Zero migration since it reads raw markdown.

**Decision: commit identity = GitHub-verified gmail.**
- Considered: keeping the proton.me email
- Chosen: switched repo git email to the GitHub-verified address so commits count on the contribution graph. Past commits keep the old email (not rewritten).

**Decision: `.md` files open in VS Code by default.**
- Chosen: `duti -s com.microsoft.VSCode md all` (was Notion). Installed duti via Homebrew to make it stick.

---

## Standing decisions (apply always)

- **Publish everything**: code → GitHub, demos → Hugging Face, config → Infisical, data → encrypted backups (B2).
- **Secrets only in Infisical**: no `.env` on the server, never committed. Runtime injection via `infisical run -- docker compose up -d`.
- **Printed plan is the source of truth**: only tick existing checkboxes, keep original wording/structure. Plan edits are recorded in commits.
- **PDF is final**: never regenerate `ai-lab-summary.pdf`.
- **Slim stack**: only what's being studied now. Only ports 80/443 published.
- **Security first**: key-only SSH, root locked, UFW + edge firewall allowlist, Fail2Ban, no secrets in git history.
