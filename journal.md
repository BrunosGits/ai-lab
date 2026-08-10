# Journal

Personal diary of the AI Lab project: memories, feelings, stories. One entry per day,
appended. This is not the session log (that's the private session log, kept local, for times/commands/verdicts).

<p align="right"><b>Total time on the project: 10h 22m</b></p>

---

## 2026-08-07: Docker questions, then the great GUI purge

**Mood:** curious, then decisive, a little ruthless, then generous, then thorough

**Story:** Before running any `apt install docker`, I wanted to understand what I was about to run. We walked through the fundamentals: a container is not a mini-VM, it's an ordinary process that sees its own isolated view of the filesystem, network and users. An image is a read-only stack of layers with a writable layer on top, and a Dockerfile is just the recipe for building those layers. Then the industry picture: Docker and OCI containers killed the "works on my machine" problem, and the same image registry pattern now sits under almost every cloud-native stack. The plan treats Docker as the backbone from here on, because that's how software ships in 2026.

Then the machine refused to boot from its own disk, still spinning in rescue mode from yesterday's drill. A small panic, a fix to the OVH API script, and a stop → netboot→local → start later it was back. With the GUI off (multi-user target), the RAM reading dropped from ~2.8 GB used to 457 MB. Then the RDP session kept dropping me mid-work, and I made the call: no more band-aids. If I'm going to run Docker on 4 GB, the desktop is dead weight. I purged every package that paints pixels on that box and didn't look back. The final `dpkg` check was clean enough, aside from a few orphaned Xfce libraries left to sweep.

Later the same box changed jobs. The espanso+ fork needed a real Linux build machine, and this
server turned out to be exactly that. I installed the full toolchain the CI job uses, doubled
the swap so the final link step could not run out of memory, and cloned the fork read-only.
  The first release build came back green in 5 minutes and 36 seconds. After all those libraries
  went in, I checked the boot target. Still multi-user, still no display manager. The purge held.

Then I went back to the espanso+ search feature to see what still stood between it and done.
The code turned out to be fully wired: the config option parses with a default of false, the
daemon hands it to the search window, and the Linux positioning logic lives in search.cpp.
The fork's CI came back green on all four platforms, and I almost called it finished. Then I
asked what that green actually proves. It proves the feature compiles everywhere, not that it
ever opened. The cursor positioning had never run on Linux or Windows. So I updated the
roadmap: a real test on the VPS with a virtual display, moving the cursor and reading the
window position back, plus a manual pass on a Windows machine. The README still claims Linux
and Windows are untested, and the option is missing from the config template, so both get
fixed before the feature counts as done.

**What I learned:** Containers are processes, not machines. Images and containers are different, and images are layered, which makes them shareable. The industry adopted containers for reproducible delivery, isolation and fast startup. My rule going in: understand the why before you install the thing. And some decisions are easier to make a second time. The plan already said "remove the GUI first in Phase 2." I was just executing it early, when the memory pressure was in my face instead of a checkbox. Going headless forces me to treat the server like a server: every interaction is SSH, every app is a service, nothing sits on it that doesn't earn its RAM. Pixels live on my own machine now.

A build machine is not a GUI machine. Installing every library a compile needs does not
install a desktop, the boot target is the real gatekeeper. And I finally built the closing
habit I had been putting off: the journal header now carries the total time, the tracker
  refreshes it, and one command closes the day by writing the journal, the decisions and the
  achievements.

Green CI means a feature compiles on every platform, not that it works on any of them. The
search window passed all four jobs and had never been drawn on two of them. A headless server
can still test a GUI, it just paints it on a virtual display instead of a real screen.

**Feelings / notes:** The morning's Q&A and the night's GUI purge feel like two halves of the same move. Both were about clearing the box to make room for the thing it's actually for. The server finally feels like a proper machine. A bit sad the cozy desktop experiment is over, but it was always a learning scaffold, not the goal. Next: Docker, with real breathing room.

Giving this box a second job felt right. It went from a burden I nearly fought to a tool that
serves two projects. And my first GitHub achievement landed today, Quickdraw, for a pull
request opened five minutes after the commit that resolved it. A small badge, but the first
  one. It feels like the start of a habit.

Almost ticked the feature as done on green builds alone. Catching the gap between compiles and
works before calling it finished felt right. Two more test items on the list that belong there.

**Did:** spent the morning session on a Docker Q&A about what containers actually are, why they exist, and how the industry uses them, before installing a single package. Then brought the VPS back from a stuck rescue boot, enabled headless boot, and removed the desktop GUI entirely: Xfce, the login manager, xrdp, Chrome, even OpenCode Desktop. That freed about a gig and a half of disk and most of the RAM. Then I set up the VPS as the
espanso+ Linux build box: 4G swap, toolchain installed, first release build green in 5m 36s,
box still headless. Added the total project time to the journal header, refreshed
automatically by the tracker. Built the end-session command and the achievements log, and
  logged today's Quickdraw.

In the evening I audited the search feature end to end, confirmed the fork CI green on all four
platforms, ticked that roadmap item, and added real Linux and Windows tests because CI only
compiles the feature. Logged the decision to test it for real before calling it finished.

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
