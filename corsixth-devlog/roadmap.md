# CorsixTH contributions

*First contribution merged · learning a large open source game project* · Started 2026-08-11

Master plan for contributing to [CorsixTH](https://github.com/CorsixTH/CorsixTH).
The goal is to land real fixes through the issue-first, fork-based workflow and learn how a
game with Lua game logic on a C++ engine actually works. Every change ships through a fork,
a PR and maintainer review.

---

## Current track

- [x] Set up the fork and the headless dev box
  - Built SDL3 3.4.14 + SDL3_mixer 3.2.4 from source into `/opt/SDL3` (Debian 13 ships an SDL2-era mixer)
  - Game compiles clean, boots headless with the Theme Hospital demo data
- [x] Fix #1793 (broken Lua docs links)
  - Root cause: LDocGen never generated a page per source file, only class and index pages
  - Extended LDocGen to write one page per file; rebuilt docs: 503 pages, 20465 local links, zero broken
  - PR #3494 merged by the maintainers, closes #1793
- [x] Fix #1467 (entities table modified inside an `ipairs` loop)
  - Root cause: `destroyEntity` mid-loop shifts the table, skipping whatever lands in the visited slot
  - Fix defers destruction until after the loop (`_flushDestroyedEntities`)
  - Headless repro with three dummies; negative control confirms the guard catches the bug
  - Old-savegame compat (lazy `entities_to_destroy`) and plant end-of-day branch holes fixed
  - Validated on full game data: offscreen 3/3, xvfb 3/3, demo control 2/2
  - 86/86 unit tests green, luacheck clean (297 files)
  - CI green on LuaJIT, Lua 5.1, Lua 5.5 and Windows
  - PR #3501 open, waiting for maintainer review
- [ ] #2469 — right mouse panning causes object placement glitches
- [ ] #1738 — handymen do not water plants in the middle of benches (backlog)

---

## Completed

- [x] Fork `BrunosGits/CorsixTH-1` and devlog scaffold
- [x] VPS dev box: SDL3 built from source, CMake + Ninja build
- [x] Lua unit tests (busted) and lint (luacheck) green
- [x] Headless boot with the demo data
- [x] #1793 root-caused, fixed, PR #3494 merged
- [x] #1467 root-caused, fixed and validated on full game data
- [x] smoketest hardened (heartbeat telemetry, intro-movie stop, auto-difficulty, load-only mode)
- [x] #1467 CI green across all GitHub jobs

---

## On hold / watching

- PR #3501 (#1467) — maintainer review
- Appveyor check on PR #3501 — may need to pin the owner if it stays stuck
- #2469 — next candidate once #1467 lands
- #1738 — backlog
