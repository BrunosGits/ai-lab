# Electrolyser Object Deep — thob 46

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/electrolyser.lua:22-23`: `id="electrolyser"`, `thob=46`; `:24-25` cure, fallback 3.
- `:28-33`: ticks false, preview 930, `default_strength=10`, crashed 3300, smoke 3456, town_map true.
- `:34-40`: idle north 1262, south copied; `:41-67` usage begin 1266/3546, in_use 1274/3550, finish variants; `:89-90` patient marker `{-1.3,-1.2}`.
- `:70-78` north: 10-tile footprint + `render_attach {-1,-1}`; `:76-77` use `passable`, smoke `{0,0}`.
- `:79-87` east: 10-tile footprint + `render_attach {-1,-1}`; `:85-86` use `passable`, smoke `{0,0}`.
- Room `CorsixTH/Lua/rooms/electrolysis.lua:22-24,30`: `id=electrolysis`, level 23, needs `{electrolyser=1,console=1}`; `:31-40` preview 930, min 5, blue/17, Doctor=1.
- Disease `hairyitis` → `electrolysis`: `CorsixTH/Lua/diseases/hairyitis.lua:53-54`.

## 2. Original TH data
- TH table `base_config.lua:266`: `-- 46 Electrolysis Machine`, StartCost 3500, StartAvail 0, StartStrength 8. Documented fact.
- TH room `base_config.lua:303`: `[23] Cost 500 ELECTRO`. Documented fact.
- `default_strength` 10 vs Start 8: apparent mismatch, functional match — runtime strength from `research_department.lua:59` + `machine.lua:33-36`. Documented fact.
- No footprint/use table in `DATA/`; EXE owns placement. Documented fact (absence).

## 3. Comparison verdict
- thob 46 / room 23 / cost 3500 / preview 930: match. Documented fact.
- idle/usage anim block: unverified (no TH anim table).
- north/east 3x3+1 footprints + `passable` use: unverified; reads as strict (side columns solid, one entry tile). Hypothesis.
- Strict == minimal here (only one passable already). Hypothesis.

## 4. Next
- Grid overlay from original electrolysis screenshot; disassemble EXE thob 46; dump original save with electrolyser.
