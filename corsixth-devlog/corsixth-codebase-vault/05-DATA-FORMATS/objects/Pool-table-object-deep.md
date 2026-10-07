# Pool table — thob 10 (Snooker) — vanilla-parity deep note

Scope: pool_table (thob 10, alias Snooker). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="pool_table"` :22, `thob=10` :23; `ticks=false` :26; preview `5058` :27
- idle north `2130`, south aliased; usage north + south-duplicate: 5 phases (begin/begin_2/begin_3/in/finish), Doctor+Handyman only (nurses dislike pool per comment)
- `orientations` N+E only, 9 tiles each: north 3×3 with center-use, `need_north_side`, dual `complete`; east transposed; explicit `use={0,0}` (passable+complete tile); per-orient `render_attach`
- Room `rooms/staff_room.lua:22-38`: id staff_room, level 25, additional incl pool_table, `objects_needed={sofa=1}` (optional); use: `use_staffroom.lua:47-48` 20% pool (not twice in row); `:66-67` use time 2-5; `:74-77` relaxation 0.05; `staff.lua:95-103` happiness 0.074

THOB + cost: `base_config.lua:230`: `{StartCost=150, StartAvail=1, StartStrength=10}, -- 10 Snooker Table`. Room `[25] Cost=1350`.

## 2. Original TH data

- Base + room rows match (proxy). Strings `original_strings.lua:134,1780`.
- No thob-10 disassembly; no overlay. Block LUT tiles-only.

## 3. Footprint-compare

- Explicit `use={0,0}` on a passable+complete tile (vs passable-keyword elsewhere). Nearest solid d=1 → single-dir + recenter (N subtract `{0,-1}` → use `{0,1}`; E subtract `{-1,0}` → use `{1,0}`). Post-shift differs — record both when filing.
- N `need_north_side` vs E dual-complete: directional `buildable*` differ. Only N+E defined; S anims duplicate N; W/S via mirror + flip.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Explicit center-use → post-shift corner-use; distinct `render_attach` per orient. No secondary/finish/slave/smoke/`early_list`.
- Doctor+Handyman only; Nurse excluded. No `default_strength` → no repair.
- Staffroom loop: sofa default, pool 20%, 2-5 ticks, relax 0.05. Soak pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 10 (Snooker=pool) | match (proxy) | `pool_table.lua:23` vs `base_config.lua:230` |
| cost 150 / avail 1 | match (proxy) | `base_config.lua:230` |
| 9-tile N/E, explicit center-use | unverified | `:94-106` |
| 5-phase anims, Doctor/Handyman | unverified | `:28-90` |
| staff-room binding + relax values | unverified parity | `staff_room.lua:29`, `use_staffroom.lua:76`, `staff.lua:97` |

## 6. Fact vs Inference vs Hypothesis

- Fact: thob/cost/room/anims/footprints/relax values as cited.
- Inference: recenter shift, mirror fallback, block semantics.
- Hypothesis: 3×3 center-use matches vanilla clearance; dual-complete east encodes wall-adjacency.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: overlay; `original_cells` vs SAM; masks; disassemble thob-10; staffroom soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
