# DNA Fixer Object Deep — thob 23

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/dna_fixer.lua:22-23`: `id="dna_fixer"`, `thob=23`; `:24-25` `research_fallback=8`, `research_category="cure"`.
- `:28-33`: `ticks=false`, `build_preview=5070`, `default_strength=7`, `crashed=3376 -- TODO correct?`, `show_in_town_map=true`, `smoke=3444`.
- `:34-44`: `idle north=3840`, south copy; comments list unmapped `2350`, sparks `3848/3850/3852`, "No repair animation??".
- `:45-60`: `usage_animations` north-only, east uses `mirror/mirror_morph`; begin `3614`, morph `3594→1150/3618`, finish `1154/3622` mirrored.
- `:63-71` north: 7-tile footprint (`{-2,-1 complete}`, `{-1,-1 complete}`, `{0,-1}`, `{-2,0 complete}`, `{-1,0}`, `{0,0 need_south}`, `{-1,1 only_passable}`), `use_position = "passable"` (→ `{-1,1}` via `object.lua:945-954`), `early_list = true`, `smoke {0,0}`.
- `:72-79` east: 7-tile footprint, `use = "passable"` (→ `{1,-1}`), `smoke {0,0}`.
- south = north; no west key → north/south/east placeable.
- Room `CorsixTH/Lua/rooms/dna_fixer.lua:22,24,30`: `id=dna_fixer`, `level_config_id=23`, `objects_needed={dna_fixer=1,console=1}`; `:32-38` clinics 6, min 5, blue/17, swing doors; `:39-42` Researcher=1.

## 2. Original TH data
- thob 23 = DNA: `th_map.h:70`. Documented fact.
- `base_config.lua:243`: `StartCost 10000, StartAvail 0, StartStrength 7`. Documented fact.
- Room cost `base_config.lua:298`: `[18] Cost 7000 ALIEN`. Documented fact.
- Anim hard-coding `th_gfx.cpp:209-210`; all used ids < 5186 — Inference (exist).
- No thob-23 oracle. Documented fact (absence).

## 3. Comparison verdict
- thob id 23 / cost 10000 / strength 7 / room 7000: match. Documented fact.
- anim existence: match (existence); crashed 3376 flagged TODO in source. Documented fact.
- footprint 7 tiles / single passable per orient: unknown; smallest surface of the group. Hypothesis.
- `use="passable"` resolution: match (engine rule); original intent unknown.

## 4. Next
- Verify 3376 vs original; map repair-anim gap (3848/3850/3852 sparks?); disassemble thob-23; overlay original DNA room.
