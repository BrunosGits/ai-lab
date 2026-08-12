# Project Conception Log

Timeline of decisions behind the AI Lab VPS project. Every idea considered, chosen or
rejected, and why. This complements the private session log (what was done, kept local) and `journal.md`
(how it felt). Updated whenever a decision is made.

---

## 2026-08-11 - OpenSearch issue 6323 reproduction

**Decision: reproduce issue 6323 on the VPS with two OpenSearch versions before writing any fix.**
- Why: the reporter and the maintainers asked for a minimal reproduction first, and the issue is two years old with no repro on record
- Chosen: two single-node OpenSearch containers from the official image, 2.3.0 (the reported version) and 2.19.6 (current), running side by side on the VPS
- Status: done, both clusters came up green and the environment stays up for a follow-up

**Decision: publish the negative result and ask for the original script, rather than guess a fix.**
- Considered: keep digging indefinitely, or post the finding and pivot to another issue right away
- Chosen: an exhaustive sweep first (storage, local reindex, ingest pipeline, special characters, multibyte around the 2000 byte mark, remote reindex, plus a code scan for truncation limits), then a public comment with the evidence and a request for the reporter's exact script
- Why: the truncation does not reproduce anywhere, and the reported error message only fires when a long string is used as a field name, which points at the reporter's pipeline rather than at the server
- Status: comment posted on issue 6323, awaiting the reporter's script

---

## 2026-08-11 - First contribution target: CorsixTH

**Decision: the next open-source contribution is a bugfix PR to CorsixTH, the open-source Theme Hospital reimplementation.**
- Why: the game logic is mostly Lua with a C++ engine, the project has an open "Good First Issue" list, and the game data requirement is satisfiable with the free, legal Theme Hospital demo, so no game purchase is needed
- Chosen setup: two machines with split jobs. The Mac owns playing, reproducing visual/gameplay bugs and verifying fixes. The VPS owns the developer loop: clone, build, tests, static analysis, git operations, CI-like testing
- Demo: the official demo at `https://th.corsix.org/Demo.zip`, hosted by the CorsixTH project (freely distributed demo of the 1997 Bullfrog game, not abandonware piracy)
- Planned path: demo on Mac -> CorsixTH installed (Homebrew) -> game running with demo data -> fork CorsixTH -> pick a small open bug -> reproduce with the demo -> investigate the Lua/C++ code -> write fix -> build and test on the VPS -> verify in game on the Mac -> open PR
- Status: in progress, first target is getting the demo running on the Mac

---

## 2026-08-10 - The fork rebrands to expandir

**Decision: the fork drops the name espanso+ and becomes expandir.**
- Why: espanso+ sounded like an official premium or paid edition of espanso, and it is neither. GPL grants no trademark rights, so the borrowed brand had to go.
- Chosen: GitHub repo renamed `espanso-plus` to `expandir`, binary renamed, config path moved to a new folder, docs and references updated everywhere. Rust crate names stay `espanso-*` so upstream merges stay easy.
- Status: applied. All matches and triggers carried over intact. A release workflow now publishes binaries from tags, the first tag went out as `v0.1.0-espanso-plus` before the rename, a fresh `v0.1.0-expandir` tag followed.

**Decision: this repo's expandir references follow the rename.**
- Chosen: the Trello project label and list migrate from `[espanso-plus]` to `[expandir]` on the next sync, the achievements note and conception log text updated, and the VPS build box stays in service under the new name with the `~/espanso-plus` folder keeping its old path.

---

## 2026-08-10 — Docker in, UFW out, git over SSH

**Decision: host firewall moves from ufw to pure iptables.**
- Why: installing `netfilter-persistent` (needed to persist the DOCKER-USER chain) silently removed ufw
- Chosen: rebuilt the host rules by hand in iptables, same policy as before (INPUT DROP + 22/80/443 only, IPv4 + IPv6), persisted to `/etc/iptables/rules.v4|v6`
- Status: verified after a reboot, both host rules and DOCKER-USER survived

**Decision: git push switches from PAT-in-URL to a dedicated SSH key.**
- Considered: reusing the existing server key, or `gh` alone
- Chosen: separate key `~/.ssh/id_ed25519_github`, added to GitHub as an authentication key, `~/.ssh/config` host block for github.com, remote switched to `git@github.com:...`
- Why: no token in the git path at all, and a GitHub-side revoke never touches server access
- Status: DONE, `git push` verified over SSH

---

## 2026-08-07 - Search feature tested for real

**Decision: test the search feature on real systems, CI green is not a substitute for use.**
- Considered: treating the all-green fork CI as proof the feature works
- Chosen: a real Linux test on the VPS with a virtual display (xdotool moves the cursor, xwininfo reads the window position back) plus a manual test on a Windows machine, before declaring the feature done
- Why: CI compiles the feature on all four platforms but never opens the search window, so the cursor positioning logic had still never run on Linux or Windows
- Status: roadmap updated with both test items, Linux test planned for the next session

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
- Status: DONE — removed 2026-08-07 (see below).

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
- Privacy: emails scrubbed from all past commits (replaced with `[redacted-email]`), repo rewritten and force-pushed.

**Decision: `.md` files open in VS Code by default.**
- Chosen: `duti -s com.microsoft.VSCode md all` (was Notion). Installed duti via Homebrew to make it stick.

---

## 2026-08-06 — Going public

**Decision: repo published to GitHub.**
- Chosen: keep `journal.md` public as-is (honest, human, part of the story).
- Scrub before publish: VPS public IP and SSH usernames replaced with `<vps-ip>` / `<user>` placeholders in `ai-lab-summary.md`, `rescue-drill.md`, `session-log.md`. Privacy over convenience.
- Verified: no IP/usernames/secrets/emails in any tracked file; `.infisical.json` stays gitignored; PDF predates the IP so it is already clean.

**Decision: introduce Rust into the project.**
- Chosen: rewrite the time tracker in Rust as a cargo binary (`scripts/time-tracker/`), keep the Python version as reference, then later rewrite the hello service in Rust (axum) once comfortable.
- Why: learning Rust needs a real, used tool — small scope (CLI, JSON, file I/O, error handling), zero server risk, and the existing `time-tracker.json` format is reused unchanged so history is untouched.
- Verify: `status`/`summary` output byte-identical to Python; `start`/`close` round-trip tested against a backup of the real JSON.

**Decision: session data kept private (tool stays public).**
- Chosen: `time-tracker.json` and `session-log.md` removed from the repo and scrubbed from git history (`git filter-repo --invert-paths`), force-pushed. Files live on locally only, hidden via `.git/info/exclude`. The Rust tracker keeps writing to `time-tracker.json` as before.
- Why: the tool is a portfolio piece; the session log and raw timings are personal.

---

## 2026-08-07 - The box gains a second job

**Decision: the VPS doubles as the expandir Linux build box.**
- Considered: keeping expandir builds on GitHub CI only
- Chosen: full linux-x11 toolchain on the server, swap doubled to 4G, read-only clone at `~/espanso-plus` (the folder kept the old name after the fork rebranded from espanso-plus to expandir)
- Why: a real Debian 13 box matching the CI job, heavy builds and tests run there for free, and the fork gains a second copy of its code
- Status: first release build green in 5m 36s. The box stayed headless, no display manager came back with the libraries

**Decision: track GitHub achievements in this repo.**
- Chosen: `achievements.md` plus `scripts/check-achievements.sh`, run by `/end-session`
- Why: the first achievement (Quickdraw) landed today, a running record keeps the habit honest
- Status: Quickdraw logged under 2026-08-07

**Decision: one command ends the working day.**
- Chosen: `/end-session` closes the tracker, writes or merges the journal, logs decisions and achievements, refreshes the total time line, then commits
- Considered: keeping each closing step manual
- Why: the journal now shows total project time at the top and the tracker refreshes it automatically, the closing habit needed a single entry point

---

## 2026-08-07 — GUI removed, VPS goes permanently headless

**Decision: remove the desktop GUI entirely, not just disable it.**
- Chosen: purge everything — `lightdm`, `lightdm-gtk-greeter`, `light-locker`, `xrdp`, `xorgxrdp`, `xfce4`, `xfce4-goodies`, `google-chrome-stable`, `opencode` (OpenCode Desktop) — plus `apt autoremove --purge` (343 orphaned packages). Only harmless library leftovers remain.
- Why: the plan already called for removing the GUI first in Phase 2 to free RAM for Docker; a live RDP session kept disconnecting, and the user chose to go all-in now rather than keep a half-working GUI. RAM dropped to ~457 MB used, ~1.5 GB freed.
- Decided against: keeping Xfce "just in case" or re-adding RDP. Any future GUI task happens on the computer.

**Decision: RDP is obsolete.**
- The loopback xrdp + SSH tunnel + Windows App setup was deliberately destroyed with the purge. Do not re-propose it. Remote GUI work, if ever needed, runs on the computer (VS Code remote, opencode TUI/web).

---

## Standing decisions (apply always)

- **Publish everything**: code → GitHub, demos → Hugging Face, config → Infisical, data → encrypted backups (B2).
- **Secrets only in Infisical**: no `.env` on the server, never committed. Runtime injection via `infisical run -- docker compose up -d`.
- **Printed plan is the source of truth**: only tick existing checkboxes, keep original wording/structure. Plan edits are recorded in commits.
- **PDF is final**: never regenerate `ai-lab-summary.pdf`.
- **Slim stack**: only what's being studied now. Only ports 80/443 published.
- **Security first**: key-only SSH, root locked, UFW + edge firewall allowlist, Fail2Ban, no secrets in git history.
- **Privacy**: never write emails or other personal information in docs or commits. If one leaks in, scrub it from past history and force-push.
