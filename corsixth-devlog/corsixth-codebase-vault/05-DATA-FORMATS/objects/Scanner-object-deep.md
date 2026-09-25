# Scanner Object Deep — thob 14

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/scanner.lua:22-23`: `id="scanner"`, `thob=14`.
- `scanner.lua:24-25`: `research_category="diagnosis"`, `research_fallback=36`.
- `scanner.lua:28-33`: `ticks=false`, `build_preview_animation=920`, `default_strength=12`, `crashed_animation=3316`, `show_in_town_map=true`, `smoke_animation=3428`.
- `scanner.lua:34-37`: `copy_north_to_south`; `scanner.lua:39-41`: `idle north=1398`.
- `scanner.lua:210-216` north: `use {0,0}`, `footprint {(-2,-1),(-1,-1),(0,-1),(-2,0),(-1,0 need_south_side),(0,0 complete_cell only_passable)}`, `render {0,-1}`, `smoke {0,0}`.
- `scanner.lua:217-222` east: `use {0,0}`, `footprint {(-1,-2),(0,-2),(-1,-1),(0,-1 need_east_side),(-1,0),(0,0 complete_cell only_passable)}`, `render {-1,0}`, `smoke {0,0}`.
- `scanner.lua:224-227`: `patient marker -1.1,-1.1`; `staff marker Handyman 564 at -3,-3 px`.
- Room `CorsixTH/Lua/rooms/scanner_room.lua:22`: `id=scanner`; `:24` `level_config_id=13`; `:30` `objects_needed={scanner=1,console=1,screen=1}`; `:32-34` `diagnosis=4`; `:35` `minimum_size=5`; `:38-40` `Doctor=1`.
- Cost table `CorsixTH/Lua/base_config.lua:234`: `5000, StartAvail 0, Strength 12` for thob 14 Scanner.
- Companion `CorsixTH/Lua/objects/console.lua:22-23`: `id=console thob=15`.

## 2. Original TH data
- THOB 14 Scanner — Documented fact: cost 5000 / strength 12 via `base_config.lua:234` (transcribed TH table).
- Binary `~/game_data/HOSP/HOSPITAL.EXE` holds thob 14 placement routine — Hypothesis: not yet disassembled.
- Footprint shape 6-tile north/east — Inference: no contested-gap report as for thob 22; assumed inherited from original.

## 3. Comparison verdict
- thob id 14: match — `scanner.lua:23` vs `base_config.lua:234`. Documented fact.
- cost 5000 / strength 12: match — `scanner.lua:30` + `base_config.lua:234`. Documented fact.
- footprint tile count 6+6: presumed match — `scanner.lua:213,219` vs EXE pending. Inference.
- `need_south_side` north / `need_east_side` east: unverified. Hypothesis.
- `only_passable+complete_cell` on use `{0,0}`: presumed match. Inference.
- south=north, west=mirror: presumed match — `scanner.lua:34-37` + `entities/object.lua:29-34,64-74`. Inference.
- markers `-1.1,-1.1` / Handyman `-3,-3px`: CorsixTH-only tuning. Hypothesis.
- room `scanner+console+screen`, min 5, diagnosis 4: match (CorsixTH); original room def — Inference.

## 4. Masks / compat / next
- Strict 1:1 (Hypothesis): keep 6-tile shape; no change unless EXE shows wall-adjacency block.
- Minimal (Hypothesis): no change. No doctor-through-wall observed; preserve saves.
- Next: disassemble HOSPITAL.EXE thob 14 placement; grid-overlay original Scanner screenshot.
