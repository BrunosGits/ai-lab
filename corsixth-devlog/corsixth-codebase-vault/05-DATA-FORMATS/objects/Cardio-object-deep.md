# Cardiogram Object Deep — thob 13

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/cardio.lua:22-23`: `id="cardio"`, `thob=13`; `:24-25` `research_fallback=38`, `research_category="diagnosis"`.
- `:28-33`: `ticks=false`, `build_preview=918`, `default_strength=12`, `crashed=3308`, `show_in_town_map=true`, `smoke=3432`.
- `:34-40`: `idle north=648`, south copy; `:41-63` Handyman `in_use 890`, `finish 894` + 7-keyframe staff markers; `:65-138` 6-variant multi-use sharing numbers; `:160` patient marker `{-0.9,-0.9}`.
- `:140-148` north: 5-tile footprint (`{-1,-1 complete}`, `{-1,0 complete}`, `{1,-1 only_passable}`, `{0,-1 need_north}`, `{0,0 only_passable}`), `render_attach {-1,0}`, `use {1,-1}`, `secondary {0,0}`, `handyman_offset {1,-1}`, `smoke {0,0}`.
- `:149-157` east: 5-tile footprint, `render_attach {0,-1}`, `use {-1,1}`, `secondary {0,0}`, `handyman_offset {-1,1}`, `smoke {0,0}`.
- south = north; no west key → north/south/east placeable.
- Room `CorsixTH/Lua/rooms/cardiogram.lua:22,24,30`: `id=cardiogram`, `level_config_id=12`, `objects_needed={cardio=1,screen=1}`; `:32-37` diagnosis 3, min 4, yellow/19; `:38-41` Doctor=1.

## 2. Original TH data
- thob 13 = Cardiogram: `th_map.h:60`, same-values comment. Documented fact.
- `base_config.lua:233`: `StartCost 1000, StartAvail 0, StartStrength 13`. Documented fact.
- Room cost `base_config.lua:292`: `[12] Cost 470 CARDIO`. Documented fact.
- Anim hard-coding `th_gfx.cpp:209-210`; M-anims 5186. All used ids < 5186 — Inference (exist).
- No thob-13 screenshot/save oracle. Documented fact (absence).

## 3. Comparison verdict
- thob id 13 / cost 1000 / room 470: match. Documented fact.
- anim existence: match (existence). Inference.
- footprint 5 tiles / only_passable / use positions: unknown — minimal surface vs thob 22. Hypothesis.
- `default_strength` 12 vs Start 13: match (distinct fields). Documented fact.

## 4. Next
- Thob-13 EXE routine; original Cardiogram screenshot measurement; confirm `render_attach` split vs single.
