# Blood Machine Object Deep — thob 42

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/machines/blood_machine.lua:22-23`: `id="blood_machine"`, `thob=42`; `:24-25` `research_fallback=37`, `research_category="diagnosis"`.
- `:28-33`: `ticks=false`, `build_preview=5094`, `default_strength=12`, `crashed=3372`, `show_in_town_map=true`, `smoke=3460`.
- `:34-40`: `idle north=2228`, south copies north; `:41-42` comment "staff is the primary user, not the patient".
- `:43-89`: `multi_usage_animations` three doctor variants; `:90-92` Handyman `in_use 3498/3484`; `:119` patient marker `{-1.5,-0.8}`.
- `:95-105` north: `handyman {0,-1}`, `secondary {1,0}`, `use {0,-1}`, 7-tile footprint (`{-1,-1 only_passable need_east+west}`, `{0,-1 only_passable need_north}`, `{-2,0 need_south+north}`, `{-1,0}`, `{0,0 complete}`, `{1,0 only_passable}`, `{-1,1 need_east+west}`), `smoke {0,0}`.
- `:106-116` east: `handyman {-1,0}`, `secondary {0,1}`, `use {-1,0}`, 7-tile footprint, `smoke {0,0}`.
- south = north (`:34-37`); no west key → north/south/east placeable (`dialogs/place_objects.lua:483-486`).
- Room `CorsixTH/Lua/rooms/blood_machine_room.lua:22,24,30`: `id=blood_machine`, `level_config_id=15`, `objects_needed={blood_machine=1}`; `:32-37` diagnosis 6, min 4, yellow wall, floor 19; `:38-41` Doctor=1.

## 2. Original TH data
- thob 42 = Blood Machine: `CorsixTH/Src/th_map.h:89` (`blood_machine = 42`), "same values as original TH". Documented fact.
- Cost/strength/avail `CorsixTH/Lua/base_config.lua:262`: `StartCost 3000, StartAvail 0, StartStrength 10`. Documented fact.
- Room cost `base_config.lua:295`: `[15] Cost 3000 BLOOD_MACHINE`. Documented fact.
- Anims hard-coded original indices: `th_gfx.cpp:209-210`; M-anims 5186 (`th_gfx.cpp:147` + `~/game_data/HOSP/DATAM/MSTART-1.ANI` 20744 B). Idle 2228, preview 5094, crashed 3372, smoke 3460, usage 3498/3484 all < 5186 — Inference (exist).
- Runtime strength comes from `StartStrength`, not `default_strength`: `research_department.lua:59` + `machine.lua:36`. Documented fact.
- No screenshot/save oracle for thob 42. Documented fact (absence).

## 3. Comparison verdict
- thob id 42: match. Documented fact.
- object cost 3000 / room cost 3000: match. Documented fact.
- anim existence: match (existence). Inference.
- footprint 7 tiles: unknown — needs EXE disassembly. Hypothesis.
- only_passable / use positions: unknown — strict/minimal open. Hypothesis.
- `default_strength` 12 vs Start 10: match (distinct fields, runtime = StartStrength). Documented fact.

## 4. Next
- Disassemble thob-42 footprint; grid-overlay original Blood Machine screenshot; check save compat if strict blocks old saves.
