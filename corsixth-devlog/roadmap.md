# 🎮 CorsixTH Contributions

*First contribution merged · learning a large open source game project* · Started 2026-08-11

This document is the master plan for contributing to [CorsixTH](https://github.com/CorsixTH/CorsixTH), the open source reimplementation of the 1997 Bullfrog game Theme Hospital. The goal is to learn how a game with Lua game logic on a C++ engine actually works by doing the work: read the code, reproduce a real issue, fix it, open a PR, respond to maintainer review. Every change ships through a fork, a PR and maintainer review, and each contribution lands a journal entry and a roadmap update.

---

## 🖥️ Environment & Setup

- [x] Fork `BrunosGits/CorsixTH-1` (upstream-linked, holds all fix commits)
- [x] VPS dev box: Debian 13, CMake + Ninja
- [x] SDL3 3.4.14 + SDL3_mixer 3.2.4 built from source into `/opt/SDL3`
  - Debian 13 ships an SDL2-era mixer, master moved to SDL3
- [x] Game compiles clean from master
- [x] Lua unit tests (busted) green
- [x] Lint (luacheck) clean
- [x] Theme Hospital demo data copied to the VPS
- [x] Dev build boots headless with the demo data

### Commands learned — Setup

**Build (SDL3 from source)**
- `cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/SDL3` — configure SDL3 for `/opt/SDL3`
- `cmake --build build -j` — build
- `cmake --install build` — install to prefix
- `cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/SDL3` — point the game build at the local SDL3
- `cmake --build build` — incremental game build

**Tests & lint**
- `busted` — run the Lua unit test suite (CorsixTH style)
- `luacheck CorsixTH/Lua` — static analysis, 297 files clean
- `python3 scripts/check_whitespace.py` — CI whitespace gate (a stray trailing space fails the PR)

**Headless smoke**
- `SDL_VIDEODRIVER=offscreen ./build/CorsixTH` — render-less video driver
- `xvfb-run -a ./build/CorsixTH` — virtual display when SDL needs a device
- `smoketest.lua` env vars: `SMOKE_HEARTBEAT` (JSONL progress telemetry), `SMOKE_LOAD_ONLY` (skip gameplay, probe load)
- `TheApp.moviePlayer:stop()` — the intro movie blocks `World:onTick`; stop it in tests

---

## 🐛 Issue Tracks

### #1793 — Broken Lua docs links on GitHub Pages ✅
- [x] Root cause: LDocGen generated class and index pages only, never a page per source file, while file-tree links pointed at pages that never existed
- [x] First theory (GitHub Pages swallowing files) tested and dropped
- [x] Fix: LDocGen writes one page per file, listing classes and functions, with directory entries as plain text
- [x] Verified: 503 pages, 20465 local links, zero broken
- [x] PR #3494 merged by the maintainers — closes #1793

### #1467 — Entities table modified inside an `ipairs` loop 🔄
- [x] Root cause: `destroyEntity` mid-loop shifts the table, skipping whoever lands in the already-visited slot
- [x] Fix: defer destruction until after the loop (`to_destroy` + `_flushDestroyedEntities`, `current_tick_entity` marker)
- [x] Old-savegame compat: `entities_to_destroy` created lazily (deserialiser never re-runs constructors)
- [x] Plant branch hole: end-of-day loop never set the iterating marker for plants
- [x] Headless repro: three dummies, the middle destroys the first mid-tick; fails if the third is skipped
- [x] Negative control: fix disabled → `SMOKE FAIL: dummy C was skipped (the #1467 bug)`
- [x] Full game data matrix: offscreen 3/3 · xvfb 3/3 · demo control 2/2
- [x] 86/86 unit tests green, luacheck clean
- [x] CI green: LuaJIT, Lua 5.1, Lua 5.5, Windows
- [x] smoketest hardened (heartbeat, intro-movie stop, auto-difficulty, load-only)
- [ ] PR #3501 maintainer review
- [ ] Appveyor check — may need to pin the owner if it stays stuck

### #3372 — Properly destroy entities on pickup again 🚧
- [x] Root cause: #3304 stopped destroying on pickup (object made invisible + kept in `world.entities`), which leaked duplicates → save corruption #3376, patched by band-aid #3370 (`table_contains` guards)
- [x] Approach selected: snapshot-and-destroy with tile reservation
  - Capture move snapshot (`object_type`, `tile_x`, `tile_y`, `direction`, `room_ref`, slave, machine/plant state) at pickup, then `destroyEntity` (safe via #1467 deferred machinery)
  - Reserve source footprint tiles during the place window; release on place/cancel/sell/close
  - Recreate from snapshot on place or Esc-cancel; refund on sell
  - Unify corridor + room-edit paths (room-edit already destroys today)
  - Remove both `table_contains` band-aids after confirming no other dependency
- [ ] Implement commit 1: object move snapshot/restore helpers
- [ ] Implement commit 2: destroy on pickup with tile reservation
- [ ] Implement commit 3: unify corridor and room-edit pickup paths
- [ ] Implement commit 4: remove `table_contains` duplicate band-aids
- [ ] Implement commit 5: pickup/place/cancel/sell/save tests + negative control
- [ ] Verification matrix green (place · Esc-cancel · sell · save-mid-window · negative control)
- [ ] PR + CI green

### #2469 — Right mouse panning causes object placement glitches ⏭️
- [ ] Reproduce headless
- [ ] Root-cause the pan/placement interaction
- [ ] Fix + tests + PR

### #1738 — Handymen do not water plants in the middle of benches (backlog) 🕳️
- [ ] Claim after #3372 lands

---

## 🧪 Testing & Validation

| Check | Result |
|---|---|
| Unit tests (busted) | 86/86 green |
| Lint (luacheck) | 297 files, 0 warnings |
| Demo smoke | 3/3 green |
| Offscreen (SDL_VIDEODRIVER) | 3/3 green |
| xvfb | 3/3 green |
| Demo control | 2/2 green |
| Negative control (guard disabled) | RED with exact bug message |
| Headless (no video device) | RED — SDL requires a video device, expected |

**Lesson:** a timeout with no output is usually pipe buffering, not a hang. Add heartbeats, and always check the tick loop is actually running — intro movies, paused states and menu loops silently skip it.

---

## 🔄 Contribution Loop (the habit)

```
Fork → Reproduce → Root-cause → Fix → Test (+ negative control) → PR → CI green → Journal → Update ROADMAP
```

Each issue ends with a published PR, a journal entry and a roadmap update. Old issues are worth claiming fast; the ones left are the deep ones.

---

## 🕐 Sessions

| Date | Start | End | Hours | Work |
|---|---|---|---|---|
| 2026-08-11 | 22:03 | 22:26 | 0.38 | VPS setup, fork, build chain |
| 2026-08-11 | 22:26 | 23:14 | 0.80 | Build SDL3, headless boot, tests |
| 2026-08-12 | 20:53 | 22:52 | 1.98 | #1793 docs fix + PR #3494, #1467 fix + tests |
| 2026-08-13 | 20:37 | 23:30 | 2.89 | #1467 negative control, smoke tests, full-data move |
| 2026-08-16 | 10:00 | 12:00 | 2.00 | Full-data matrix, CI fix, green run |

**Total:** 5 sessions · 8h 03m

---

## 📈 Skills to build along the way

- Reading Lua game logic and the Lua/C++ boundary
- Writing Lua unit tests in the busted style used by CorsixTH
- Running a CI-like loop on a headless server (heartbeat + negative control)
- Shipping a real open source contribution through maintainer review

---

## 💻 Project Facts

| | |
|---|---|
| **Project** | CorsixTH — open source reimplementation of Theme Hospital (1997 Bullfrog) |
| **Game logic** | Lua on a C++ engine (SDL3) |
| **Started** | 2026-08-11 |
| **Fork** | `BrunosGits/CorsixTH-1` |
| **PRs** | #3494 merged · #3501 open |
| **Dev box** | VPS (Debian 13) — shared with AI Lab |
| **Demo data** | Legal Theme Hospital demo, on the VPS only |
