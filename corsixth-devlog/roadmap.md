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

### #3545 — Run length encoder implementation is very expensive 🔬
- [x] Root cause: `are_ranges_equal` does 2 divisions per integer compare, 52k calls per save (~25ms)
- [x] Fix held locally: memcmp compares, 128 power of 2 buffer with mask, division free write, self compare skip (1 file, no format change, decoder untouched)
- [x] Verified: harness 23.4ms to 2.7ms, real save 280ms to 227ms, 36 level maps + developed hospital round trip clean, old saves load
- [x] Posted findings on the issue (2026-09-19), disclosed ±4% size noise by layout
- [x] Matrix green 2026-09-19: sweep winner 128, 36 fresh maps plus developed hospital, findings posted on the issue
- [x] Draft PR 3554 opened (no RLE for new saves, map v5 to v6, decoder kept)
- [x] Review: lewri plus TheCycoONE say no SAVEGAME_VERSION bump without Lua afterload, bump reverted, PR is th_map.cpp only. No api bump unless asked
- [x] TheCycoONE holding further comments, invited to post them. Staying in draft per ARGAMX process note
- [x] Held comment landed: strip the 11 read guards in the v6 raw branch (no error propagation, old code did not handle early end either)
- [x] Dual model analysis plus devil check: facts confirmed, sticky end of input error verified in persist_lua.cpp, truncated loads fail either way. UB catch: stripped version needs uint32_t v as 0 plus anchoring comment
- [x] Softened reply posted, awaiting direction on shape
- [ ] Address held comments when they land, then undraft
- [ ] Maintainer call: drop RLE for new saves post #3534 (RLE expands random data ~2%)

---
### #3441 — Ultrascan footprint does not match original game (P4 Low) ✅ Merged PR #3526

- [x] Research: save 907K zip / 2.7M sav, map 128x128, strict vs minimal masks, 16-object-placement/VANILLA_FOOTPRINT_MATRIX.md + TH_ORIGINAL_ULTRASCAN.md, TH_ORIGINAL_TILES.md, Ultrascan-room-deep.md, Ultrascan-diagnosis-flow.md
- [x] PR #3526 merged Sep 14 2026 by ARGAMX → master (commit 06b70cd, branch fix/3441-ultrascan-footprint) — closes #3441 — Reviewed tobylane, Approved TheCycoONE + ARGAMX, 5/6 checks passed
- [x] Fix: ultrascanner.lua blocked north {-1,1},{0,1} and east {1,-1},{1,0} (south copies north, west mirrors east), kept use_position {0,-1} passable to avoid shifted draw, removed 265 preserve (app.lua:31 + object.lua:920 did nothing, old saves keep old footprint via normal save data)
- [x] Vault: PR tracking 06-PR-TRACKING/PR-3441-vanilla-ultrascan.md updated to merged, KANBAN Done, spec/entities/ultrascanner_3441_spec.lua 65/65 busted + luacheck 0/297
- [x] Post-merge: east side shifted image fixed by moving block to south edge, second image red crosses guided final east {1,-1},{1,0} placement

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

### #3331 — Humanoids can walk through walls (studying, not claimed) 🔬
- [x] Study: read #3331 + #3340 (merged placement ban) + #3382 (recalc trigger) + #3404 (avoid flag initiative)
- [x] Found most of the fix already in master: unconditional refuse 218a9006, avoid_tile flag plus cost, #3340 ban, edit_room flag restore
- [x] Headless matrix on current master: bench VIP escapes covered tile with no wall punch, blueprint nurses stand on covered tiles, toilet save pre setup, control clean
- [x] Adjacent latent find: VIP without door animations routed through fracture_clinic door errors at walk.lua:347 near tick 550 (needs clean repro before claiming)
- [x] Open hole: walk.lua recalc only fires when current tile is passable, so wall ahead while standing covered walks the stale path
- [x] Proposed solution: 4 line Lua change (not_passable drops the here passable requirement, always repath on obstacle), stuck case covered by existing idle plus finish in action_walk_start
- [x] Implemented on branch fix/3331-walk-gate (walk.lua plus 12 minus 12), probe proved the branch fires, baseline walks on, matrix green
- [x] Maintainer reply: ARGAMX points at open PR #3489 (connectivity check, stalled waiting on #3465 C++ helper) as already in progress
- [x] Analysis: #3489 keeps the covered stance gate, so the bench case stays open. Ours is the complementary half, cheaper at runtime (no per step distance check)
- [x] Draft PR #3556 opened, reply posted on #3331 offering rebase onto #3489 or standalone, awaiting direction
### #2469 — Right mouse panning causes object placement glitches ⏭️
- [ ] Reproduce headless
- [ ] Root-cause the pan/placement interaction
- [ ] Fix + tests + PR

### #1793 — Broken Lua docs links on GitHub Pages ✅
- [x] Root cause: LDocGen generated class and index pages only, never a page per source file, while file-tree links pointed at pages that never existed
- [x] First theory (GitHub Pages swallowing files) tested and dropped
- [x] Fix: LDocGen writes one page per file, listing classes and functions, with directory entries as plain text
- [x] Verified: 503 pages, 20465 local links, zero broken
- [x] PR #3494 merged by the maintainers — closes #1793

### #1738 — Handymen do not water plants in the middle of benches (backlog) 🕳️
- [ ] Claim after #3372 lands

### #1467 — Entities table modified inside an `ipairs` loop ✅
- [x] Root cause: `destroyEntity` mid-loop shifts the table, skipping whoever lands in the already-visited slot
- [x] Fix: defer destruction until after the loop (`to_destroy` + `_flushDestroyedEntities`, `current_tick_entity` marker)
- [x] Old-savegame compat: `entities_to_destroy` initialized in `afterLoad` for `old < 265`
- [x] Plant branch hole: end-of-day loop never set the iterating marker for plants
- [x] Headless repro: three dummies, the middle destroys the first mid-tick; fails if the third is skipped
- [x] Negative control: fix disabled → `SMOKE FAIL: dummy C was skipped (the #1467 bug)`
- [x] Full game data matrix: offscreen 3/3 · xvfb 3/3 · demo control 2/2
- [x] 84/84 unit tests green, luacheck clean
- [x] CI green: LuaJIT, Lua 5.1, Lua 5.5, Windows
- [x] Clean pattern: queue invariant via constructor + afterLoad (v265)
- [x] PR #3504 merged 2026-09-06 (d98fbe80) — closes #1467


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

## 📈 Skills to build along the way

- Reading Lua game logic and the Lua/C++ boundary
- Writing Lua unit tests in the busted style used by CorsixTH
- Running a CI-like loop on a headless server (heartbeat + negative control)
- Shipping a real open source contribution through maintainer review
