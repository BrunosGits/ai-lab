# Hair Restorer Object Deep — thob 25

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/hair_restorer.lua:22-23`: `id="hair_restorer"`, `thob=25`; `:24-25` cure, fallback 10.
- `:28-33`: ticks false, preview 5074, `default_strength=8`, crashed 5116, smoke 3460.
- `:34-40`: idle 2070 north, south copied; `:42-58` usage begin 2074/2078, in_use 2082/568, finish 2086.
- `:62-68` north: use `{0,1}`, handyman `{0,-1}`, offset `{0,2}`, finish `{0,1}`, 3-vertical footprint, `use_animate_from_use_position`, smoke `{0,0}`.
- `:71-75` east: use `{1,0}`, handyman `{-1,0}`, offset `{2,0}`, finish `{1,0}`, 3-horizontal footprint.
- `:81-83`: patient marker `{-1.0,-1.1}`; staff marker Handyman 568 at `{61,-36,px}`.
- Room `CorsixTH/Lua/rooms/hair_restoration.lua:22-24,30`: `id=hair_restoration`, level 19, needs `{hair_restorer=1,console=1}`; `:31-40` preview 5074, min 4, blue/17, Doctor=1.
- Disease `baldness` → `hair_restoration`: `CorsixTH/Lua/diseases/baldness.lua:55-56`.

## 2. Original TH data
- TH table `base_config.lua:245`: `-- 25 Hair restorer`, Cost 1000, Avail 0, Strength 8. Documented fact.
- TH room `base_config.lua:299`: `[19] Cost 500 HAIR_RESTORER`. Documented fact.
- No footprint table; EXE owns placement. Documented fact (absence).

## 3. Comparison verdict
- thob 25 / room 19 / cost-strength 1000-8 / preview 5074: match. Documented fact.
- 1-wide bar, solid centre, passable ends, opposed use/handyman: unverified; strict==minimal (no contested side column). Hypothesis.
- 2070-2086 anim block + shared Handyman 568: coherent original block. Inference.

## 4. Next
- Original hair-restoration screenshot grid overlay; verify Handyman 568 shared range; TH.map dump of thob 25 save.
