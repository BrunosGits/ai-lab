# Journal

Personal diary of the AI Lab project: memories, feelings, stories. One entry per day,
appended. This is not the session log (that's the private session log, kept local, for times/commands/verdicts).

<p align="right"><b>Total time on the project: 11h 06m</b></p>

---

## 2026-08-07: Docker questions, then the great GUI purge

**Mood:** curious, decisive, a little ruthless, then generous, then thorough

**Story:** Before running any `apt install docker`, I wanted to understand what I was about to run. We walked through the fundamentals: a container is not a mini-VM, it's an ordinary process that sees its own isolated view of the filesystem, network and users. An image is a read-only stack of layers with a writable layer on top, and a Dockerfile is just the recipe for building those layers. That's how software ships in 2026.

Then the machine refused to boot from its own disk, still spinning in rescue mode from yesterday's drill. A fix to the OVH API script, a stop, a netboot→local, a start, and it was back. The RDP session kept dropping me mid-work, and I made the call: no more band-aids. If I'm going to run Docker on 4 GB, the desktop is dead weight. I purged every package that paints pixels and didn't look back. RAM dropped to 457 MB.

The same box changed jobs that evening. The espanso+ fork needed a real Linux build machine, so I installed the CI toolchain, doubled the swap, cloned the fork, and the first release build came back green in 5m 36s. Still headless. Then I audited the search feature and nearly called it finished. CI was green on all four platforms, but green only means it compiles everywhere, not that it ever opened. The cursor positioning had never run on Linux or Windows, so I added real tests instead of ticking it done.

**What I learned:** Containers are processes, not machines. My rule going in: understand the why before you install the thing. And the GUI removal was easier the second time, the plan already said it, I was just executing it early. Headless means every interaction is SSH and every app is a service. A build machine is not a GUI machine, the boot target is the real gatekeeper.

Green CI means a feature compiles on every platform, not that it works on any of them. The search window passed all four jobs and had never been drawn on two of them.

**Feelings / notes:** The morning's Q&A and the night's GUI purge feel like two halves of the same move, clearing the box for the thing it's actually for. A bit sad the cozy desktop experiment is over, but it was always a learning scaffold, not the goal. The server finally feels like a proper machine.

Giving this box a second job felt right. And my first GitHub achievement landed today, Quickdraw, for a pull request opened five minutes after the commit that resolved it. A small badge, but the first one.

**Did:** spent the morning on a Docker Q&A, brought the VPS back from a stuck rescue boot, and removed the desktop GUI entirely to free RAM for Docker. Set up the VPS as the espanso+ build box, first release build green in 5m 36s. Audited the search feature and added real Linux and Windows tests because CI only compiles it. Built the end-session command and the achievements log, and logged today's Quickdraw.

---

## 2026-08-06: The day the rescue test finally passed

**Mood:** relieved, proud, productive

**Story:** The dashboard kept throwing a cryptic "invalid or empty URL" error whenever I
tried to flip the rescue toggle, so I had to find another way. The OVH docs were not clear
about it and a couple of links 404'd, but after some poking around I found the panel that
generates an API key for remote control, built a small script around it, and got the
machine to reboot into rescue. Not one, not two, but three attempts before the boot took.
I'm glad I tested this before I actually needed it, because the process was far from
simple to set up. The moment the SSH host key changed, I knew the rescue environment was
really there. That's the whole point of the drill: prove we can get back in before we ever
have to.

**What I learned:** The "obvious" path in the dashboard can be a dead end, and the docs
won't always cover what you hit. When the UI fails, the API is still there, and the API
has a task system that tells you exactly what's happening under the hood. Also worth
remembering, the order matters: set the boot mode while the machine is stopped, then start
it. I only found that by failing forward.

**Feelings / notes:** A quiet confidence, like the first piece of the foundation is sealed.
Rescue mode went from a wall of unknown to something I've actually done. Now Phase 2 and
that first public push. What a productive morning.

**Did:** ran the rescue-mode drill end to end, but through the OVH API instead of the
dashboard, and closed out the infrastructure foundation. Next up is Phase 2 and the first
public push to GitHub.

---

## 2026-08-05: The day it started feeling real

**Mood:** excited, a little proud

**Story:** I wrote the rescue-mode runbook today, step by step: boot into rescue from the
OVH dashboard, mount the disk read-only, verify the marker file, chroot back in, then
reboot from disk. I haven't run it yet, but just writing it made me feel safer. Rescue mode
was a wall of unknown before, now it's a checklist. Even the moment I'm dreading, the one
where the machine goes dark in the dashboard and I wait for the email with the rescue IP,
has its own step. Then there are the fail2ban numbers: 3,882 failed SSH passwords in 24
hours, and the server just shrugs them off. It's quietly defending itself while I sleep.

**What I learned:** A safe procedure is still worth doing once on purpose. Rescue mode was
a wall of unknown until I wrote down every step. Actually running it is still ahead of me.
And since the printed plan is the source of truth, every fix becomes a commit, and the repo
is quietly recording the project's history on its own.

**Feelings / notes:** Started a proper journal so I don't lose the why behind the commands.
Noticed I enjoy the security and hardening part more than I expected. Tomorrow: the rescue
drill itself, then Docker.

**Did:** wrapped up Phase 1.5 (PostgreSQL, systemd FastAPI), ran a security audit, and
built the rescue-mode runbook.

---

## 2026-08-04: The night I stopped planning and bought the server

**Mood:** impulsive, then giddy, then afraid it would break

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

**Did:** signed up for the OVH VPS (VPS-1 2027, Debian 13), paid with my credit card,
set the root password, created the project plan and its PDF, installed the Infisical CLI,
created my machine identity and the time tracker.
