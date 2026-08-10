# Journal

Personal diary of the AI Lab project: memories, feelings, stories. One entry per day,
appended. This is not the session log (that's the private session log, kept local, for times/commands/verdicts).

<p align="right"><b>Total time on the project: 11h 06m</b></p>

---

## 2026-08-10: Docker is finally in

**Mood:** accomplished, then humbled by a package conflict

**Story:** Phase 2 had waited on the checklist long enough, so today I added the official Docker repo, installed the engine with the Compose plugin, added myself to the docker group, hardened the daemon, and wired a DOCKER-USER chain that drops anything a container tries to reach unless it is another container. Then I rebooted and watched it all come back on its own. The rules persisted. But installing netfilter-persistent silently removed ufw, and I found the host wide open only by reading the rules myself. I rebuilt the firewall by hand in iptables, same policy as before, drop everything and allow only 22, 80 and 443 on both address families. Pushing git also finally dropped the token from the URL, a dedicated SSH key just for GitHub now.

**What I learned:** Tools remove their rivals quietly, nothing in the install output said ufw was going. A reboot is the only honest test of persistence, and separate keys per service mean a revoke on one never touches the other.

**Feelings / notes:** Docker was the reason the GUI had to go, so today closed a loop that started with the big purge. The ufw surprise was a good reminder that nothing on this box is set and forgotten.

**Did:** installed Docker CE 29.7.2 + Compose, hardened the daemon, set up DOCKER-USER default-drop, rebooted to verify. Rebuilt the firewall as pure iptables after ufw vanished. Switched GitHub to a dedicated SSH key. Updated the docs and the tracker.

---

## 2026-08-07: Docker questions, then the great GUI purge

**Mood:** curious, then decisive, then generous, then thorough

**Story:** Before installing anything I wanted to understand what I was about to run. We walked through the fundamentals: a container is not a mini-VM, it's an ordinary process with its own isolated view of the filesystem, network and users, and an image is a read-only stack of layers. Then the machine refused to boot from its own disk, still stuck in yesterday's rescue mode. A fix to the OVH API script, a stop, a netboot, a start, and it was back. The RDP session kept dropping me mid-work, and I made the call: no more band-aids. If Docker needs the RAM, the desktop is dead weight, so I purged every package that paints pixels. RAM dropped to 457 MB.

**What I learned:** Containers are processes, not machines. Understand the why before you install the thing. The GUI removal was easier the second time, the plan already said it, I was just executing it early.

**Feelings / notes:** The Q&A and the purge are two halves of the same move, clearing the box for what it's actually for. A bit sad the cozy desktop experiment is over, but it was always a scaffold.

**Did:** Docker Q&A, fixed the stuck rescue boot, purged the desktop GUI.

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
