# Journal

Personal diary of the AI Lab project: memories, feelings, stories. One entry per day,
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

**Story:** I'd been planning this project for so long that the plan became a way to avoid
starting. Always one more spreadsheet, one more consideration, never an actual server.
Then tonight, sometime after midnight, I just did it. Grabbed the card, typed the number,
and about fourteen seconds later I had a machine in Canada East that was entirely mine.
I remember the small panic when the root password email came in, because I was sure the
whole thing would fall apart before I even SSH'd in. It didn't. That first `apt update`
made it official. The plan PDF is real now too: a printable four-phase roadmap instead of
vague intentions. I'm tired but wired. I think this is what starting feels like.

**What I learned:** Planning only got me so far. Making it real took actually spending
money on it, which no notebook ever did. And it took fourteen seconds. That's all it took
to change what I'll be doing for the next year.

**Feelings / notes:** A little embarrassed that an impulsive credit card purchase is what
finally got me started. Also weirdly proud. Later today I begin Phase 1: the foundation,
the hardening, the first of the boring but important work.

---

## 2026-08-05 — The day it started feeling real

**Mood:** excited, a little proud

**Did:** wrapped up Phase 1.5 (PostgreSQL, systemd FastAPI), ran a security audit, and
built the rescue-mode runbook.

**Story:** Today I went through OVH rescue mode end to end. Booted the VPS into rescue,
mounted the data disk read-only, chroot'd back into the system to prove I could recover
even with zero login access. I keep coming back to the moment the marker file showed up on
the mounted disk. That was the first time the whole "this is a real machine, I'm the admin"
thing stopped being abstract. Then there are the fail2ban numbers: 3,882 failed SSH
passwords in 24 hours, and the server just shrugs them off. It's quietly defending itself
while I sleep.

**What I learned:** A safe procedure is still worth doing once on purpose. Rescue mode was
a lot less scary after I'd run it for real. And since the printed plan is the source of
truth, every fix becomes a commit, and the repo is quietly recording the project's history
on its own.

**Feelings / notes:** Started a proper journal so I don't lose the why behind the commands.
Noticed I enjoy the security and hardening part more than I expected. Tomorrow: the rescue
drill itself, then Docker.
