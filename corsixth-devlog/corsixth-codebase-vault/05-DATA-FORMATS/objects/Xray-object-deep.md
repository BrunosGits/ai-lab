# X-Ray Object Deep — thob 27

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/x_ray.lua:22-23`: `id="x_ray"`, `thob=27`.
- `x_ray.lua:24-25`: `research_category="diagnosis"`, `research_fallback=39`.
- `x_ray.lua:28-33`: `ticks=false`, `build_preview=5076`, `default_strength=12`, `crashed=3384`, `show_in_town_map=true`, `smoke=3440`.
- `x_ray.lua:34-37`: `copy_north_to_south`; `x_ray.lua:39-41`: `idle north=1988`.
- `x_ray.lua:78-86` north: `use {1,-1}`, `render {-1,-1}`, 9-tile footprint `{(-2,-2),(-1,-2),(-2,-1),(-1,-1),(0,-1),(1,-1 only_passable),(-2,0),(-1,0),(0,0)}`, `smoke {0,0}`.
- `x_ray.lua:87-95` east: `use {-1,1}`, `render {-1,-1}`, 9-tile footprint `{(-2,-2),(-1,-2),(0,-2),(-2,-1),(-1,-1),(0,-1),(-1,0),(0,0),(-1,1 only_passable)}`, `smoke {0,0}`.
- `x_ray.lua:98`: `patient marker -2,-2`; `x_ray.lua:100-119`: staff kf path for 3558 + `3562 at kf14`.
- `x_ray.lua:71,73`: Chewbacca `5136 or 5138?` comment + Handyman 3562 missing-sprite TODO — open fidelity gap, admitted in code.
- Room `CorsixTH/Lua/rooms/x_ray_room.lua:22`: `id=x_ray`; `:24` `level_config_id=16`; `:30` `objects_needed={x_ray=1,radiation_shield=1}`; `:32-34` `diagnosis=7`; `:35` `minimum_size=6`; `:38-40` `Doctor=1`.
- Cost table `CorsixTH/Lua/base_config.lua:247`: `4000, StartAvail 0, Strength 12` for thob 27 X-Ray; `:248` shield 2000.
- Companion `CorsixTH/Lua/objects/radiation_shield.lua:26-29`: `id=radiation_shield thob=28`.

## 2. Original TH data
- THOB 27 X-Ray — Documented fact: cost 4000 / strength 12 via `base_config.lua:247`.
- Binary `~/game_data/HOSP/HOSPITAL.EXE` holds thob 27 routine — Hypothesis: not yet disassembled.
- Footprint 9+1 passable — Inference: L-block + entry extension matches gantry + approach tile.

## 3. Comparison verdict
- thob id 27: match. Documented fact.
- cost 4000 / strength 12: match. Documented fact.
- footprint 9 tiles + 1 passable: presumed match vs EXE pending. Inference.
- use `{1,-1}` N / `{-1,1}` E: presumed match; equals `only_passable` tile in each footprint. Inference.
- south=north, west=mirror: presumed match. Inference.
- Chewbacca `5136 vs 5138` + missing 3562 sprite: open gap, documented in code. Documented fact.

## 4. Masks / compat / next
- Strict 1:1 (Hypothesis): keep 9-tile L; no change unless EXE shows wall-adjacency block.
- Minimal (Hypothesis): no change. Preserve saves.
- Next: disassemble EXE thob 27; overlay original X-Ray screenshot; verify `5136 vs 5138` and missing 3562 sprite.
