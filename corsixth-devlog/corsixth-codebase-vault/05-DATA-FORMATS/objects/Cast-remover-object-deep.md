# Cast Remover Object Deep — thob 24

## 1. Identity — Documented fact
- `Lua/objects/machines/cast_remover.lua:22-23`: `id="cast_remover"`, `thob=24`; `:24-25` cure, fallback 9 (fractured_bones expertise 9).
- `:28-33`: ticks false, preview 5072, `default_strength=10`, crashed 3388, town_map true, smoke 3468.
- Room `Lua/rooms/fracture_clinic.lua:22,24-25`: fracture_clinic, level 21, FractureRoom; `:29-30` extinguisher/radiator/plant/bin + `cast_remover=1`; `:35-41` min 4, blue/17, Nurse=1.
- `base_config.lua:244`: thob 24 `StartCost=2000, StartAvail=0, StartStrength=11`; `:301` room `[21] Cost=500 FRACTURE`. Lua strength 10 vs base 11 — mismatch of 1.
- `diseases/fractured_bones.lua:29` cure_price 450.

## 2. Footprint (pre-shift, as written) — Documented fact
- North (`:122-133`): use `{0,0}`; footprint `{-1,-1 complete}`, `{0,-1 pass}`, `{1,-1 pass}`, `{-1,0 complete}`, `{0,0 pass+complete}`, `{-1,1 pass need_west_side}`, `{-1,-2 pass invisible optional}`, `{-2,-1 pass invisible optional}`; render_attach `{-1,1}`; smoke `{0,0}`.
- East (`:136-147`): use `{0,0}`; footprint `{-1,-1}`, `{0,-1 complete}`, `{1,-1 pass need_north_side}`, `{-1,0 pass}`, `{0,0 pass+complete}`, `{-1,1 pass}`, `{-2,-1},{-1,-2} pass invisible optional`; `early_list=true`; smoke `{0,0}`.
- South=north (`copy_north_to_south`); west/south via mirror. Never compare literally.

## 3. Normalized (post `processTypeDefinition`) — Inference
- North: nearest solid to `{0,0}` is `{-1,0}` (d=1). Post-shift use→`{1,0}`, secondary→`{1,-1}`, finish→`{2,-1}`, smoke→`{1,0}`, render→`{0,1}`.
- East: nearest solid `{0,-1}` (d=1). Post-shift use→`{0,1}`, secondary→`{-1,1}`, finish→`{-1,2}`, smoke→`{0,1}`.
- `walk_in_tile` NOT shifted — world tile moves with new origin. `walk_in_to_use=true` applies to repair (`use_object`) only, not multi-use.

## 4. Table-form `handyman_position` (focus) — Documented fact
- North `:123`: `{{0,-2},{-1,-1}}`; east `:137`: `{{-1,-1},{-2,0}}`. Only object in `Lua/` with `{{` table form.
- Resolver `object.lua:297-314` names `cast_remover` explicitly; `Machine:getRepairTile` assumes single `{x,y}` but `setHandymanRepairPosition` (`machine.lua:564-588`) picks first candidate with pathfinder distance + same room, else leaves unset.
- Inference: handyman lists match POST-shift optional tiles exactly, while footprint is PRE-shift — author wrote handyman in post-shift space.
- Hypothesis: if neither candidate is in-room/reachable, `handyman_position` stays nil and repair errors. Needs fault-injection test.

## 5. Multi-use flow — Documented fact
- `fracture_clinic.lua:56-62`: patient tile via `findObjectNear`, staff via `getSecondaryUsageTile`; staff faces west/north; patient `walkTo`.
- Anims male + female blocks; after-use clears patient layers 2,3,4 (casts), meander/finish + `dealtWithPatient`.

## 6. Verdict + next
- STRICT: NOT PASS — no overlay, masks not filed. MINIMAL: NOT YET. Strength mismatch (10 vs 11) is the only concrete parity delta.
- Next: `original_cells` dump + grid overlay; 4-tile room walk test both orients; handyman-candidate fault test; 5000-tick soak + save/load; resolve strength 10-vs-11; `busted` + `luacheck`.
