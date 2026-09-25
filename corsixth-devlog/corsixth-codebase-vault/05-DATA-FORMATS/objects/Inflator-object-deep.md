# Inflator Object Deep — thob 9

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/inflator.lua:22-23`: `id="inflator"`, `thob=9`; `:24-25` cure, fallback 2.
- `:28-33`: ticks false, preview 908, `default_strength=10`, crashed 3362, smoke 3424.
- `:38-54`: idle 572; multi Standard Male Patient-Doctor 464/478/482/496/576; Handyman 3480.
- `:58-66` north: handyman `{1,-1}`, use `{0,1}`, secondary `{-1,1}`, finish `{1,0}`/`{1,-1}`, 3x3 footprint (4 solid-ish + 5 passable), smoke `{0,0}`.
- `:69-76` east: handyman `{-1,1}`, use `{1,0}`, secondary `{1,-1}`, finish `{0,1}`/`{-1,1}`, 3x3 footprint.
- `:81-88`: patient markers + idle `{-0.9,-1.0}`; staff markers Handyman north+south `{59,-3,px}`.
- Room `CorsixTH/Lua/rooms/inflation.lua:22-24,30`: `id=inflation`, level 17, needs `{inflator=1}`; `:31-40` preview 908, min 4, blue/17, Doctor=1.
- Disease `bloaty_head` → `inflation`: `CorsixTH/Lua/diseases/bloaty_head.lua:52-53`.

## 2. Original TH data
- TH table `base_config.lua:229`: `-- 9 Inflator Machine`, Cost 2500, Avail 0, Strength 8. Documented fact.
- TH room `base_config.lua:297`: `[17] Cost 1500 INFLATOR`. Documented fact.
- Strength 10 vs 8: functional match (runtime from `research_department.lua:59`). Documented fact.
- No footprint/use table; EXE owns placement. Documented fact (absence).

## 3. Comparison verdict
- thob 9 / room 17 / cost 2500 / preview 908: match. Documented fact.
- 3x3 with 5 passable, dual use/finish: unverified; permissive ring — strict 1:1 might solidify `{1,-1}`/`{1,0}` as with thob 22 east column. Hypothesis.
- `need_north_side` north vs `need_west_side` east correctly rotated: good sign. Inference.
- Anim cluster 464-576 contiguous: original block. Inference.

## 4. Next
- Overlay original inflation screenshot; test if `{1,0}` should be solid; find save with inflator; confirm `finish_use_position_secondary` vs EXE.
