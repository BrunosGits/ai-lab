# Journal

Personal diary of the AI Lab projects: memories, feelings, stories.
One entry per day, newest first. This is not the session log (that's the private
session log, kept local, for times/commands/verdicts).

<p align="right"><b>Total time on all projects: 28h 02m</b></p>

---

## Time Tracker Summary

| Project | Sessions | Total Hours |
|---------|----------|-------------|
| AI Lab | 12 | 13.33h |
| CorsixTH | 6 | 9.04h |
| OpenSearch | 4 | 5.66h |
| **Total** | **22** | **28.03h** |

---

## Journal Entries

---

### [CorsixTH] 2026-08-17: Clean fork, clean PR, CI green

**Mood:** clean, satisfied the mess is gone

**Story:** Deleted the polluted fork (BrunosGits/CorsixTH-1) that had 18 commits mixed with personal devlog files. Created a fresh fork BrunosGits/CorsixTH with only the 3 clean commits: core fix (world.lua + 23 unit tests), smoketest improvements, whitespace fix. PR #3504 opened with CI passing (LuaJIT, Windows, vcpkg Lua 5.5, Lua 5.1 pending). The old PR #3501 closed automatically when the fork vanished. Also cleaned up the opensearch-fork that was just a mirror with no changes.

**What I learned:** A PR tied to a personal fork dies with the fork. The clean approach is: fix on a clean branch, push to a fresh fork, open PR. The maintainers see only the relevant diff. Also: deleting unused forks removes noise.

**Feelings / notes:** Satisfying to watch the old PR close and the new one open clean. The whitespace CI gate caught the trailing space — good gate.

**Did:** deleted BrunosGits/CorsixTH-1 and opensearch-fork, created BrunosGits/CorsixTH fork, pushed fix-1467-clean branch (3 commits), opened PR #3504, verified CI green, updated ai-lab docs.

---

### [AI Lab] 2026-08-16: Phase 3 shipped, and the firewall was mine all along

**Mood:** relieved, then quietly proud of the tiny stack

**Story:** Today Phase 3 went live. The slim stack came up as three containers, caddy owning the only published port, hello behind it, postgres on an internal network with the secrets injected by infisical run so no .env file exists on the server. Then the external test failed and everything pointed at OVH. The dashboard showed 80 and 443 already permitted, and the API agreed, but curl from my computer kept timing out. It turned out the blocker was my own DOCKER-USER chain. Published ports travel the FORWARD path, not INPUT, so my old rules never matched inbound SYN packets and the default drop ate them. One accept rule for tcp 80 and 443, a netfilter-persistent save, and http://<vps-ip>.sslip.io answered with hello from docker compose. Postgres stayed closed, ssh stayed up, and the whole phase got committed and pushed.

**What I learned:** Published container ports cross the FORWARD chain, so host INPUT rules never see them. A rule that works from inside the box proves nothing about the outside. The OVH firewall was right all along, I was the firewall.

**Feelings / notes:** Forty five minutes of confusion traced back to a chain I wrote myself. Slightly embarrassing, but now it is documented in the roadmap commands so it will not bite twice.

**Did:** built the compose stack (caddy 2.11.4, hello, postgres 17.11), pinned tags, internal backend network, moved the FastAPI app into a container, dropped the apt cluster and the systemd unit, injected secrets via infisical run, fixed DOCKER-USER to accept inbound 80 and 443, persisted the rules, verified external access, committed and pushed the phase.

---

### [CorsixTH] 2026-08-16: The fix that held, and the movie that blocked the test

**Mood:** quiet satisfaction, with a side of of course it was the intro movie

**Story:** The deferred-destruction fix for #1467 was solid, negative control failed exactly as expected when the guard was disabled, but the full-game smoke test timed out at 500s with zero output. Pipe buffering hid all progress. The real culprit: full game data autoplays the intro movie (moviePlayer.playing=true), which blocks World:onTick entirely. A one-line TheApp.moviePlayer:stop() in the smoketest unblocked everything.

Full matrix: offscreen (3/3), xvfb (3/3), demo control (2/2) all green. luacheck clean (297 files). 86/86 unit tests pass. The fix is complete and validated on full game data.

**What I learned:** A timeout with no output is usually pipe buffering, not a hang. Add heartbeats. And always check whether the game is actually running its tick loop — intro movies, paused states, and menu loops will silently skip it.

**Feelings:** The negative control failing on cue (dummy C was skipped) is still the best confirmation a fix works.

**Did:** validated the #1467 deferred-destruction fix on full game data (offscreen, xvfb, demo), fixed smoketest intro-movie blocker, added JSONL heartbeat telemetry, full matrix pass, luacheck + 86 unit tests green, negative control confirmed.

---

### [OpenSearch] 2026-08-13 (session 1)

**Mood:** Productive. Good rhythm between investigation and collaboration.

**Story:** Worked on the opensearch contribution project. First, investigated PR #22701 (read block auto-release) — found it's a duplicate of already-merged #22610, posted a comment explaining this, and closed that path.

Then moved to PR #22654 (monitor mode workload group rejections). The PR fixes a bug where MONITOR mode workload groups were incorrectly rejecting requests with 429. The fix was correct but codecov/patch failed at 60% (target 80%).

Investigated deeply with subagents: confirmed the coverage gap (one missing branch isPresent() == false in rejectIfNeeded), designed a minimal test to cover it, ran 83 WLM tests on the VPS (all pass), generated a jacoco report proving the test flips line 274 to fully covered (80%, clearing the 71.43% auto target), and posted a humanized comment with the exact test code for the author.

Also discovered a bypass: local scroll requests skip both the transport interceptor and the listener, so MONITOR guard isn't hit there. And WLM has zero user-facing docs (two confusing monitor concepts). Filed those as follow-ups.

Waited for author response on the test fix.

**What I learned:** Codecov patch target is auto-derived from project baseline (71.43% here), not a fixed 80%. Jacoco pc (partially covered) on a line with || means operand short-circuit, not a real bug. The WLM monitor terminology is overloaded: WlmMode.MONITOR_ONLY (cluster default) vs ResiliencyMode.MONITOR (group setting) — users can't discover this without docs. Subagent parallel investigation is powerful for covering multiple angles fast.

**Feelings / notes:** Good session. The investigation-to-action loop worked: find gap, design fix, verify locally, comment with exact code. The author (SaiManas2106) has been responsive on their other PRs, so likely they'll apply the test and get green.

**Did:** Analyzed PR #22701, confirmed duplicate of #22610, posted comment. Analyzed PR #22654, root-caused codecov 60% gap. Ran 83 WLM unit tests on VPS (all pass). Generated jacoco coverage report, verified 4/5 lines = 80%. Drafted and posted humanized PR comment with exact test fix. Investigated integration test gaps, interceptor bypass, cancellation consistency, doc gaps, related issues. Restored VPS checkout to clean state.

---

### [OpenSearch] 2026-08-13 (session 2): Issue updates and fixes committed

**Mood:** focused, satisfied with the double progress

**Story:** Today two tracked issues moved forward. For #6323 I posted a minimal reproduction using the reporter's exact string: the 138-char dotted key fails identically via direct PUT and painless reindex promotion, and short keys like .start and a..b fail the same way — confirming the error is structural (dot expansion), not value truncation at ~2000 chars. For #17561 I committed the fix to the fork and built a distribution node that now lists the full accepted codec set (lucene_default + all registered Lucene codecs + built-ins) instead of the old hardcoded [default, lz4, best_compression, zlib]. The end-to-end test confirmed not_a_codec returns the full list and best_compression still succeeds. Both issues have comment threads on GitHub.

On the planning side I mapped the code paths and competitive landscape for #22494 (cache compiled regex automatons). The author ZiwenWan has a production-tested PoC with strong latency numbers and is happy to contribute a PR, so the approach is to monitor and coordinate rather than duplicate effort. The code analysis showed the exact call sites (RegexpQuery, AutomatonQuery, KeywordFieldMapper) and the cache infrastructure API to use.

**What I learned:** Two issues can advance in parallel when one is a field-name theory and the other a setting-derivation fix. And a working PoC from a third party changes the calculus on a fallback issue — the plan shifts from implement independently to monitor and coordinate.

**Feelings / notes:** Good to close out the session with concrete progress on the two main tracks and a clear path on the third.

**Did:** closed the time tracker, posted the #6323 minimal-reproduction comment, posted the #17561 update comment, committed and pushed the #17561 fix to BrunosGits/opensearch-fork, mapped the #22494 code paths and competitive landscape, and planned the next session.

---

### [OpenSearch] 2026-08-11: The fix that ran green

**Mood:** methodical, then proud of the first green run

**Story:** Morning, the #6323 reproduction. Two OpenSearch versions, 2.3.0 and 2.19.6, everything I could throw at the reindex API, strings from 1980 to 20000 chars, pipelines, remote reindex. Every value came back identical. The error the reporter saw comes from field-name validation, I reproduced it verbatim by putting a long string where a field name goes, the dots get read as object separators. The cutoff does not exist in vanilla OpenSearch.

Evening, the #17561 fix. The codec error message now comes from the same list the validation accepts, the five built-ins, every registered Lucene codec and the CodecAliases aliases, deduped and sorted. Two tests cover it. I ran EngineConfigTests on the VPS with JDK 21, six tests, zero failures, and posted the results asking for the green light.

Then a cleanup. The Mac's git identity was set to PublishProject, so three commits here and one on the expandir fork were attributed to that account. I rewrote the authorship to BrunosGits with git-filter-repo, force-pushed both and fixed the Mac identity.

**What I learned:** A negative result, written up carefully, is still progress. A fix only earns its place once it runs against the real codebase. A stale global git identity can misattribute commits for weeks.

**Feelings / notes:** The first green run on the real code was worth the ten minutes the 2-core build took. I have now made an OpenSearch change that compiles and passes.

**Did:** swept 2.3.0 and 2.19.6 for the #6323 cutoff, found nothing, pinned the error to field-name validation and posted the evidence. Implemented the #17561 fix with two tests, ran them green on the VPS and posted the results. Rewrote the PublishProject commits on this repo and the expandir fork, force-pushed both, fixed the Mac git identity.

---

### [OpenSearch] 2026-08-07: The project begins

**Mood:** eager, ready, humbled

**Story:** First day of a new project, this one about contributing to OpenSearch. The goal is to
learn how a large open source project actually works by doing the work: reading the code, finding
a real issue, sending a real patch.

The day had three parts. First the hunt for an issue. Almost everything I liked already had a PR
or a volunteer, which was the first lesson. I commented on #21323, the Lucene warning logs at
startup, thinking it was open, but a PR was already on it, stalled in review. Wasted words there.
Then I found #6323, a bug from 2023 where long strings get cut at 2000 characters, still broken,
no one working on it. The maintainer had been asking for a minimal reproduction for months. I
claimed it and promised the repro first.

Second, the environment. To reproduce #6323 I need to run OpenSearch, and the plan is Docker on
the VPS, installed later on demand. The VPS details stay out of this repo.

Third, since one issue is a single point of failure, I claimed a second one, #17561, a small bug
where the error message lists the wrong codec values. I also kept a third in my pocket, #22494,
cached regex automaton compilation, without commenting on it, in case both fall through.

**What I learned:** Small issues in OpenSearch get claimed within days. The ones left are deep,
like #6323, or untriaged with no one caring. To have a real chance I need to claim fast and be
ready to reproduce fast. I also learned to check for an existing PR before commenting, the
expensive way.

**Feelings / notes:** The humbling part is how fast things get taken. The good part is that two
maintainers have answered, which is more attention than I expected on the first day.

**Did:** set up the project scaffold for OpenSearch contributions, modeled on the AI Lab project.
Commented on #21323, later found redundant. Claimed #6323 and #17561 with coordination comments.
Recorded #22494 as plan B without commenting. Added check-issues for tracking.

---

### [CorsixTH] 2026-08-12: Squeezing the entity-loop bug until it squeaked

**Mood:** first fix merged, then surprised by the old-savegame crash

**Story:** The biggest news came first: the maintainers merged my docs fix, closing #1793. Issue #1467: world.entities is walked with ipairs while some handlers destroy other entities, shifting the table and skipping whoever lands in the visited slot. The fix defers removal to after the loop.

A headless smoke test reproduced the skip deterministically (three dummies, the middle destroying the first mid-tick; the test fails if the third gets skipped), and a GUI variant rendered every frame. I hacked the fix back out and both failed with exactly the message they should catch.

Two hidden holes surfaced. An old savegame crashed on the first tick because the deserialiser never re-runs constructors, leaving the new queue missing. And the end-of-day loop never set the iterating marker for plants. Both fixed, both tested.

The day ended with a move to the full game data for reliable tests.

**What I learned:** A regression test's job is to fail when the bug comes back; the negative control tells you it can. The tests that catch you are about old savegames and the code path nobody remembers.

**Feelings:** The skip-repro failing on cue is the closest thing a headless server has to a high five.

**Did:** merged the docs fix into CorsixTH (#1793), implemented the deferred-destruction fix (#1467), 86 unit tests green, headless and GUI smoke tests plus a negative control, fixed the old-savegame crash and the plant branch hole, moved to the full game data.

---

### [AI Lab] 2026-08-11: Everything moves to the VPS

**Mood:** relieved and tidy

**Story:** After the 6323 investigation I moved the whole working environment to the VPS. The three repos, the time trackers and their private logs, the agent skills, the opencode config and the Trello credentials all went over and were verified one by one. The time tracker builds and reports the same totals, the Trello sync runs, GitHub accepts the keys. Two surprises came out of the move, a decision-log entry about a new contribution target that was never committed and a stale clone of the espanso fork already sitting on the server. Both are safe now, the entry lives on the VPS as pending work and the stale clone is set aside. The local copies were deleted only after the server copies were confirmed intact.

**What I learned:** A move like this only feels safe in stages. Verify the tracker totals and the journal totals match, then delete. Also that the key which lets this machine reach the VPS is the one thing I keep, since it is the only door left.

**Feelings / notes:** The delete step was oddly satisfying, the local machine got visibly lighter. The session data stays behind until the very end, so the conversation can be carried over to the server.

**Did:** moved three repos to the VPS, restored the private tracker and session files, set up opencode and the skills, copied the keys and the git identity, verified the tracker, the Trello sync and GitHub access, synced an uncommitted decision-log entry, deleted the local copies and left only the session data and the access key behind.

---

### [CorsixTH] 2026-08-11: A working dev box and a first pull request

**Mood:** focused, quietly pleased when the game first booted headless, and then very pleased when the first issue became a real fix

**Story:** The plan was to do all the real work on the VPS over SSH, so the project became a fork of CorsixTH with a devlog folder inside it. The build chain was a small saga: master moved to SDL3, Debian 13 ships one too old for the mixer, so I built SDL3 3.4.14 and SDL3_mixer 3.2.4 from source into /opt/SDL3. The game compiled clean, 63 unit tests green, luacheck clean, and the welcome screen printed headless using the demo data.

Then came the first issue, #1793: dead links in the generated Lua docs. My first theory, that GitHub Pages was swallowing files, was wrong. The truth was simpler: LDocGen never generated a page per source file, only class pages and index pages, while the file tree links were built from path-based ids pointing at pages that never existed. So I made LDocGen write one page per file, listing the classes and functions there, with directory entries as plain text. Rebuilt the docs and checked every link: 503 pages, 20465 local links, zero broken. I opened the pull request and learned the labels are the maintainers to add.

**What I learned:** A headless dev box turns a docs bug into a checkable claim: rebuild, script over every link, done. A wrong theory is still useful if you test it and drop it.

**Feelings / notes:** The first headless boot felt like a small victory, and opening the first pull request felt like the devlog setup paying for itself. The MIDI music still will not load with no synth on the box, but that is a cosmetic gap. Now it is a waiting game for the maintainers.

**Did:** set up the fork, built SDL3 and SDL3_mixer into /opt/SDL3, compiled the game, ran the Lua tests and lint, confirmed the headless boot, root-caused issue #1793, extended LDocGen to generate per-file pages, verified 20465 links, and opened pull request #3494.

---

### [AI Lab] 2026-08-11: The fork got a name

**Mood:** settled, quietly proud

**Story:** For three days my fork was called espanso+, a name I borrowed without thinking.
Today I released the first build under that name, and only then stopped to ask what the plus
meant. It read like an official premium edition, a thing the espanso team might be selling.
I wanted none of that, so the fork became expandir, the Portuguese verb for to expand, a
name that says what the tool does and belongs to no one else's brand. The rename went all
the way through: the repo, the binary, the config folder, the docs, and every reference to
the fork in this project. A release workflow went out first under the old name, then a
fresh tag carried the new one. The best part was watching all my triggers load into the
renamed app without losing a single one.

**What I learned:** GPL gives you the code, but never the name, and borrowing a brand makes
a side project read like a product. Renaming a running tool is survivable when the data and
the code move together and the docs follow in the same pass.

**Feelings / notes:** It stopped being a fork in the abstract and became a thing I maintain.
There is a small joy in watching my own list load into a program that carries a name I
chose. Two entries share today, the Docker one and this one, and both feel like progress.

**Did:** renamed the fork from espanso+ to expandir across the repo, binary, config folder and
docs, published a release workflow with a first tag under the old name followed by a fresh
expandir tag, kept every match and trigger intact, updated this project's build box
references and the achievements note, and closed the tracker with the extra minutes.

---

### [AI Lab] 2026-08-10: Docker is finally in

**Mood:** accomplished, then humbled by a package conflict

**Story:** Phase 2 had waited on the checklist long enough, so today I added the official Docker repo, installed the engine with the Compose plugin, hardened the daemon, and wired a DOCKER-USER chain that drops anything a container tries to reach unless it is another container. Then I rebooted and watched it all come back on its own. But installing netfilter-persistent silently removed ufw, and I found the host wide open only by reading the rules myself, so I rebuilt the firewall by hand in iptables, drop everything and allow only 22, 80 and 443 on both address families. Pushing git also finally dropped the token from the URL, a dedicated SSH key just for GitHub now.

**What I learned:** Tools remove their rivals quietly, nothing in the install output said ufw was going. A reboot is the only honest test of persistence, and separate keys per service mean a revoke on one never touches the other.

**Feelings / notes:** Docker was the reason the GUI had to go, so today closed a loop that started with the big purge. The ufw surprise was a good reminder that nothing on this box is set and forgotten.

**Did:** installed Docker CE 29.7.2 + Compose, hardened the daemon, set up DOCKER-USER default-drop, rebooted to verify. Rebuilt the firewall as pure iptables after ufw vanished. Switched GitHub to a dedicated SSH key. Updated the docs and the tracker.

---

### [AI Lab] 2026-08-10: The fork got a name

**Mood:** settled, quietly proud

**Story:** For three days my fork was called espanso+, a name I borrowed without thinking.
Today I released the first build under that name, and only then stopped to ask what the plus
meant. It read like an official premium edition, a thing the espanso team might be selling.
I wanted none of that, so the fork became expandir, the Portuguese verb for to expand, a
name that says what the tool does and belongs to no one else's brand. The rename went all
the way through: the repo, the binary, the config folder, the docs, and every reference to
the fork in this project. A release workflow went out first under the old name, then a
fresh tag carried the new one. The best part was watching all my triggers load into the
renamed app without losing a single one.

**What I learned:** GPL gives you the code, but never the name, and borrowing a brand makes
a side project read like a product. Renaming a running tool is survivable when the data and
the code move together and the docs follow in the same pass.

**Feelings / notes:** It stopped being a fork in the abstract and became a thing I maintain.
There is a small joy in watching my own list load into a program that carries a name I
chose. Two entries share today, the Docker one and this one, and both feel like progress.

**Did:** renamed the fork from espanso+ to expandir across the repo, binary, config folder and
docs, published a release workflow with a first tag under the old name followed by a fresh
expandir tag, kept every match and trigger intact, updated this project's build box
references and the achievements note, and closed the tracker with the extra minutes.

---

### [AI Lab] 2026-08-07: Docker questions, then the great GUI purge

**Mood:** curious, then decisive, then generous, then thorough

**Story:** Before installing anything I wanted to understand what I was about to run. We walked through the fundamentals: a container is not a mini-VM, it's an ordinary process with its own isolated view of the filesystem, network and users, and an image is a read-only stack of layers. Then the machine refused to boot from its own disk, still stuck in yesterday's rescue mode. A fix to the OVH API script, a stop, a netboot, a start, and it was back. The RDP session kept dropping me mid-work, and I made the call: no more band-aids. If Docker needs the RAM, the desktop is dead weight, so I purged every package that paints pixels. RAM dropped to 457 MB.

**What I learned:** Containers are processes, not machines. Understand the why before you install the thing. The GUI removal was easier the second time, the plan already said it, I was just executing it early.

**Feelings / notes:** The Q&A and the purge are two halves of the same move, clearing the box for what it's actually for. A bit sad the cozy desktop experiment is over, but it was always a scaffold.

**Did:** Docker Q&A, fixed the stuck rescue boot, purged the desktop GUI.

---

### [AI Lab] 2026-08-06: The day the rescue test finally passed

**Mood:** relieved, proud, productive

**Story:** The dashboard kept throwing a cryptic "invalid or empty URL" error whenever I
tried to flip the rescue toggle, so I had to find another way. The OVH docs were not clear
about it and a couple of links 404'd, but after some poking around I found the panel that
generates an API key for remote control, built a small script around it, and got the
machine to reboot into rescue. Not one, not two, but three attempts before the boot took.
The moment the SSH host key changed, I knew the rescue environment was really there. That's
the whole point of the drill: prove we can get back in before we ever have to.

**What I learned:** The "obvious" path in the dashboard can be a dead end, and the docs
won't always cover what you hit. When the UI fails, the API is still there. Also worth
remembering, the order matters: set the boot mode while the machine is stopped, then start
it. I only found that by failing forward.

**Feelings / notes:** A quiet confidence, like the first piece of the foundation is sealed.
Rescue mode went from a wall of unknown to something I've actually done. Now Phase 2 and
that first public push. What a productive morning.

**Did:** ran the rescue-mode drill end to end, but through the OVH API instead of the
dashboard, and closed out the infrastructure foundation. Next up is Phase 2 and
that first public push to GitHub.

---

### [AI Lab] 2026-08-05: The day it started feeling real

**Mood:** excited, a little proud

**Story:** I wrote the rescue-mode runbook today, step by step: boot into rescue from the
OVH dashboard, mount the disk read-only, verify the marker file, chroot back in, then
reboot from disk. I haven't run it yet, but just writing it made me feel safer. Rescue mode
was a wall of unknown before, now it's a checklist. Even the moment I'm dreading, the one
where the machine goes dark in the dashboard and I wait for the email with the rescue IP,
has its own step. Then there are the fail2ban numbers: 3,882 failed SSH passwords in 24
hours, and the server just shrugs them off.

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

### [AI Lab] 2026-08-04: The night I stopped planning and bought the server

**Mood:** impulsive, then giddy, then afraid it would break

**Story:** I'd been planning this project for so long that the plan became a way to avoid
starting. Always one more spreadsheet, one more consideration, never an actual server.
Then tonight, sometime after midnight, I just did it. Grabbed the card, typed the number,
and about fourteen seconds later I had a machine in Canada East that was entirely mine.
I remember the small panic when the root password email came in, because I was sure the
whole thing would fall apart before I even SSH'd in. It didn't. That first 
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

---
