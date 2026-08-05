# Journal

Personal diary of the AI Lab project — memories, feelings, stories. One entry per day,
appended. This is not the session log (that's `session-log.md`, for times/commands/verdicts).

---

## Template

```md
## YYYY-MM-DD — Short title
**Mood:** ...
**Did:** ...
**Story:** ...
**What I learned:** ...
**Feelings / notes:** ...
```

---

## 2026-08-05 — The day it started feeling real

**Mood:** excited, a little proud

**Did:** wrapped up Phase 1.5 (PostgreSQL, systemd FastAPI), ran a security audit, and
built the rescue-mode runbook.

**Story:** We went deep on OVH rescue mode today — booted the VPS into rescue, mounted
the data disk read-only, and chroot'd back into the system to prove we could recover even
with zero login access. I keep coming back to that moment the marker file showed up on the
mounted disk. It's the first time the whole "this is a real machine, I'm the admin" thing
stopped being abstract. The fail2ban numbers too — 3882 failed SSH passwords in 24h, and the
server just... shrugs them off. It's quietly defending itself while I sleep.

**What I learned:** even a "safe" procedure is a story — rescue mode is less scary when
you've done it once on purpose. And that the printed plan is the source of truth, which
means every fix gets a commit, which means the repo is starting to tell the project's story
by itself.

**Feelings / notes:** Started a proper journal so I don't lose the *why* behind the
commands. Noticed I enjoy the security/hardening part more than I expected. Tomorrow:
the rescue drill itself, then Docker.
