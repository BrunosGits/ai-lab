# Parity Rig (V0) — footprint verification harness

Established 2026-10-07. Verifies hand-derived post-shift footprints against the REAL engine code (`Object.processTypeDefinition` + `occupyTilesByObjectFootprintAt`), replacing "computed, needs runtime dump" inference with executed proof.

## Rig

- Spec: `08-QUERIES/parity_footprint_spec.lua` (copy of the busted spec; runs in `CorsixTH/CorsixTH/Luatest` as `spec/parity_footprint_spec.lua`).
- Method: load real object definition via `loadfile`, run real `Object.processTypeDefinition`, assert post-shift tables; instantiate real `Object` with recording stub map, assert per-tile flags.
- Stubs (environment only, never the logic under test): `package.preload["TH"]` noop-animation mock (busted env has no C++ TH), auto-vivifying `_S`, `TheApp.animation_manager` noops, stub world/hospital/map with `setCellFlags` recorder.
- Non-pollution: snapshot/restore clobbered globals in `teardown` (preload TH, TheApp, _S, Hospital + mock action globals). Verified: 175/175 green across the file set with and without this spec in the run.

## V0 findings (slicer thob 26 + operating_table thob 30, 7/7 green)

1. `handyman_position` is NOT shifted by `processTypeDefinition` (`object.lua:999-1012` shift list covers secondary/finish/smoke/use/slave/render only). Slicer handyman stays `{1,-1}`/`{-1,1}` — deep-note values corrected. Open question refined: is the unshifted tile reachable in-game (was: "far offset suspect")?
2. Operating-table east `{0,0}` bare-solid asymmetry CONFIRMED present in post-shift table (not a note error). Do-not-fix standing.
3. OccupyTiles flag semantics confirmed: `buildable=false` on all footprint tiles, `passable=true` exactly on `only_passable` tiles.
4. `pairs()` iteration order matched list order in all V0 cases (tie-breaks resolved as predicted), but this is Lua-implementation-dependent — flag any future mismatch as engine-behavior evidence, not test bug, on first occurrence.

## Next

- Extend spec per object in V1/V2 order (mechanical: load type, shift asserts, occupy asserts).
- Soak + overlay + SAM phases remain manual (headless driver + screenshot rig still to build).
