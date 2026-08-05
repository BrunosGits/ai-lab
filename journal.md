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

## 2026-08-04 — The night I stopped planning and bought the server

**Mood:** impulsive, then giddy, then afraid it would break

**Did:** signed up for the OVH VPS (VPS-1 2027, Debian 13), paid with my credit card,
set the root password, created the project plan and its PDF, installed the Infisical CLI,
created my machine identity and the time tracker.

**Story:** I'd been planning this project for so long the plan had become the excuse —
always one more spreadsheet, one more consideration, never a server. And then tonight,
sometime after midnight, I just did it. Grabbed the card, typed the number, and boom —
fourteen seconds of OVH processing later I had a machine in Canada East that was entirely
mine. I remember the small panic when the root password email came in and I thought the
whole thing would fall apart before I even SSH'd in. It didn't. The first `apt update`
run felt like signing a lease on my own future. The plan PDF exists now too — a real,
printable, four-phase roadmap, not just vague intentions. I'm tired but wired. I think
this is what "starting" feels like.

**What I learned:** momentum beats planning when planning stops producing decisions.
Committing money made the project real in a way no notebook ever could. And that
fourteen seconds is all it takes to change what you're going to be doing for the next
year.

**Feelings / notes:** A little embarrassed it took impulsive spending to start something
I wanted for so long. Also weirdly proud. Tomorrow (well, later today) I begin Phase 1:
the foundation, the hardening, the first of the boring-but-important work.

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
