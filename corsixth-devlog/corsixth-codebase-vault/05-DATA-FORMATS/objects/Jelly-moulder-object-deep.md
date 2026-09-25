# Jelly Moulder Object Deep — thob 47

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/jelly_moulder.lua:22-23`: `id="jelly_moulder"`, `thob=47`; `:24-25` cure, fallback 12.
- `:28-33`: ticks false, preview 928, `default_strength=7`, crashed 3312, smoke 3440.
- `:38-40`: idle 1302; `:42-60` anim order comment 1302-1382 + female 3958-3982; `:62` `walk_in_to_use=true`; `:63-67` Handyman 3502; `:71-102` multi Doctor-Patient male + female blocks.
- `:106-117` north: handyman `{2,-1}`, walk_in `{1,-1}`, use `{-1,1}`, secondary `{1,-1}`, finish `{-1,1}`/`{1,0}`, 7-tile footprint with complete centre, `render_attach {0,-1}`, smoke `{0,0}`.
- `:120-130` east: handyman `{-1,2}`, walk_in `{-1,1}`, use `{1,-1}`, secondary `{-1,1}`, finish `{1,-1}`/`{0,1}`, 7-tile footprint, `render_attach {-1,0}`.
- Room `CorsixTH/Lua/rooms/jelly_vat.lua:22-24,30`: `id=jelly_vat`, level 24, needs `{jelly_moulder=1}`; `:31-40` preview 928, min 4, blue/17, Doctor=1.
- Disease `jellyitis` → `jelly_vat`: `CorsixTH/Lua/diseases/jellyitis.lua:64-65`.

## 2. Original TH data
- TH table `base_config.lua:267`: `-- 47 Jellyitus Moulding Machine`, Cost 6500, Strength 7. Documented fact.
- TH room `base_config.lua:304`: `[24] Cost 4500 JELLY_VAT`. Documented fact.
- No footprint/use table; EXE owns placement. Documented fact (absence).

## 3. Comparison verdict
- thob 47 / room 24 / cost-strength 6500-7 / preview 928: match. Documented fact.
- 7-tile asymmetric shape with complete centre: unverified; looks strict. Hypothesis.
- Handyman outside footprint both orients: outlier, keep pending screenshot (save-compat risk if tightened). Documented fact + Hypothesis.
- 1302-1382 chain + female 3958-3982: mirrors original sequence. Inference.

## 4. Next
- Screenshot grid for jelly vat door swing; verify walk_in tiles vs EXE pathing; TH.map dump of thob 47 save; check `{2,-1}` repair reachability.
