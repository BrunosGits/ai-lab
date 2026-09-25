# Vanilla-Parity Validation Method (objects)

> Precedent: thob 22 ultrascanner (#3441).

## 1. TH data sources (per object)

1. `thob` mask (primary): `HOSPITAL.EXE` is ground truth (not yet
   disassembled). Proxies, in order: (a) repo Lua `object.thob`;
   (b) `base_config.lua:221+` `StartCost/StartAvail/StartStrength`
   table (covers thob 1-61; thob 63/heli and no-thob trio absent).
2. Block LUT (tiles, NOT footprints): `th_map.cpp:316`
   `gs_iTHMapBlockLUT[256]` + `fixOutdoorTiles` allow-list.
   Footprint flags are derived from object footprints, not the LUT.
3. `original_cells`: `th_map.cpp:294-302,369-507,938,1544+` — preserved
   TH tiles at load. Use `original_cells` dump vs `LEVELS/*.SAM`
   overlay to separate wall/tile mismatches from footprint mismatches.
4. Screenshot + save (ultrascanner precedent only):
   issue-3441 shot `7f209963` vs CorsixTH shot, save `3441.sav`.
   All other 61 objects: screenshot/save = pending.

## 2. Footprint-compare procedure (repeatable)

1. Extract current: read repo `Lua/objects/<id>.lua` (or
   `machines/<id>.lua`) `orientations.{north,east}` footprints.
   Note derivations: `copy_north_to_south` (south=north) and
   `orient_mirror` (`object.lua:29`: north<->west, east<->south).
   Never compare south/west literally — compare north/east, derive rest.
2. Normalize for `processTypeDefinition` (`object.lua:926-1010`):
   footprint is re-centered on nearest solid tile to `use_position`;
   all of `use_position_secondary/finish_*/smoke_position/slave_position`
   shift with it. Record pre- and post-shift coords.
3. Build two vanilla masks (ultrascanner precedent):
   `strict` = 1:1 wall-adjacent vanilla; `minimal` = smallest diff
   that closes the walk-through gap. File both in per-object
   `TH_ORIGINAL_<ID>.md`, matrix in `16-object-placement/`.
4. Compare via `occupyTilesByObjectFootprintAt` semantics
   (`object.lua:462-555`): solid = no `only_passable`;
   `complete_cell`/`need_*_side` drive directional `buildable*` flags.
5. Grid-overlay the TH screenshot before claiming strict. Stale vault
   matrices are not truth: Sprint-6 matrix had east `{0,-1},{1,-1}`
   blocked; merged fix is north `{-1,1},{0,1}` + east `{1,-1},{1,0}`
   blocked, east `{0,-1}` (use_position) kept passable
   (see `PR-3441-vanilla-ultrascan.md`, repo `ultrascanner.lua`
   east footprint). Always re-read the repo file.

## 3. Behavior checklist (per orientation)

- `use_position` (+`secondary`, `finish_*`): check `"passable"`-keyword
  resolution (`object.lua:945-954`) and `pathfind_allowed_dirs`.
- `orientations`: all 4 dirs or documented mirror/copy;
  `idle_animations` per dir, `early_list`, `render_attach_position`,
  patient/staff markers.
- Master-slave: `slave_id` + per-orient `slave_position`
  (see `operating_table.lua:23,96-117` + `slaveMixinClass()`),
  create/move/destroy/orient-sync/event-redirect. N/A for most.
- Crash/repair: `crashed_animation`, `smoke_animation`,
  `smoke_position`, `default_strength`, `handyman_position`
  reachability after block.
- Soak: 5000-tick headless load + save/load cycle; note save-compat
  gate decision (3441 final: no version preserve — old saves keep old
  footprint via save data).

## 4. Pass / fail

- PASS(strict): all north + east tiles match vanilla overlay,
  behavior checklist green, soak + `busted` + `luacheck` clean.
- PASS(minimal): contested gap closed, no regressions
  (use/handyman/slave reachable, no old-save crash), strict rows filed
  as backlog.
- FAIL: any walk-through solid, unreachable use/handyman/slave,
  shifted-draw regression, or save-load crash.
- Record: `08-QUERIES/vanilla-coverage.md` status + per-object
  deep note + test-results note.

## 5. Wave plan (T=Lua thob, C=base_config row, V=screenshot/save)

- W0 DONE (1): ultrascanner 22 [T+C+V]
- W1 diagnosis (5): scanner 14, x_ray 27, blood_machine 42, cardio 13, analyser 41 [T+C]
- W2 cure heavy, multi-tile/slave (10): inflator 9, hair_restorer 25, slicer 26, dna_fixer 23, cast_remover 24, electrolyser 46, jelly_moulder 47, shower 54, operating_table 30 + operating_table_b 12 [T+C]
- W3 research/OT support (10): autopsy 55, computer 40, console 15, pharmacy_cabinet 39, projector 37, op_sink1 33, op_sink2 34, surgeon_screen 35, x_ray_viewer 29, radiation_shield 28 [T+C]
- W4 furniture (20): desk 1, cabinet 2, chair 6, bench 4, bed 8, screen 16, couch 18, crash_trolley 20, loo 51, sink 32, bookcase 56, lecture_chair 57, comfortable_chair 61, pool_table 10, sofa 19, tv 21, video_game 57-dup, skeleton 60, reception_desk 11, drinks_machine 7 [T+C]
- W5 corridor/side/doors (11): bin 50, plant 45, radiator 44, extinguisher 43, door 3, entrance_left 58, entrance_right 59, swing_left 52, swing_right 53 [T+C]; litter, rathole [no thob]
- W6 special/no-parity (3): helicopter 63 [T only], gates_to_hell 48 [T+C cost 0], radiation_shield_b [no thob]
- COUNT GAP: CATALOG header says 43+15+4=62 but tables enumerate 41+15+4=60 named rows; TH-only base_config thobs (5 Table, 12 Trestle, 17 Jukebox, 31 Lamp, 38/49 Bed Screens) have no Lua object — confirm and mark out-of-scope.
