# Lecture chair — thob 36 (NOT 57) — vanilla-parity deep note

> Label correction: the wave brief said `lecture_chair (thob 57)` but repo + base_config prove `lecture_chair=36` and `video_game=57`. `objects/lecture_chair.lua:23` `thob=36`; `base_config.lua:256` `36 Lecture Chair StartCost=50`; `objects/video_game.lua:23` `thob=57`; `base_config.lua:277` `57 Video Game StartCost=200`. Full-repo thob scan shows one 36, one 57 (only dup is thob 28 shield+b). No runtime collision. Fix docs, keep thobs.

Scope: lecture_chair (thob 36). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

- `id="lecture_chair"` :22, `thob=36` :23; `ticks=false` :26; preview `5084` :27; town-map true :28
- `copy_north_to_south`; idle north `2626`, south aliased; usage north-only + copy: `begin_use Doctor 2632`, `in_use 2622`, `finish_use 2636`
- Staff markers with keyframes :44-48
- `orientations` north+east only: north `{0,0 complete},{1,0 only_passable}`, `use="passable"`, animate-from-use, `early_list=true`; east `{0,0 complete},{0,1 only_passable}`
- Room `rooms/training.lua:23-31`: id training, level 22, `objects_needed={lecture_chair=1,projector=1}`, preview 5086, facilities 4; `:49-60` counts loos→maximum_staff; `:222-233` `findFreeObjectNearToUse(lecture_chair)` with `not_enough_lecture_chairs` advice

THOB + cost: `base_config.lua:256`: `{StartCost=50, StartAvail=1, StartStrength=10}, -- 36 Lecture Chair`. Room cost `[22] Cost=1850` TRAINING.

## 2. Original TH data

- Base row match (proxy). Room cost match (proxy). Strings `original_strings.lua:160,1806`.
- Training values `base_config.lua:129-132` (projector/skeleton/bookcase factors, not chair).
- No thob-36 disassembly; no overlay.

## 3. Footprint-compare

- N `{0,0},{1,0p}`, E `{0,0},{0,1p}`; `use="passable"` → first passable; nearest solid d=1 → single-dir; no recenter.
- Only N+E defined; S via copy (anims), W/E-S via `orient_mirror` + flip fallback; east idle missing → mirrored north+flip.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Doctor-only begin/in/finish; `use_animate_from_use_position`. No secondary/finish/slave/smoke/crash. `early_list` north only.
- Room flow: student→chair reserve, consultant→projector; count → maximum_staff.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 36 (brief 57 wrong) | match (proxy) | `lecture_chair.lua:23` vs `base_config.lua:256` |
| cost 50 / avail 1 | match (proxy) | `base_config.lua:256` |
| 2-tile N/E, early_list N | unverified | `:52,58` |
| idle/usage/markers | unverified | `:33-48` |
| training binding | match (proxy) | `training.lua:30-31,222-233` |
| thob 57 = video_game | confirmed separate | `video_game.lua:23`, `base_config.lua:277` |

## 6. Fact vs Inference vs Hypothesis

- Fact: thob/cost/room/anims/footprints + 57-mislabel proof.
- Inference: mirror/flip for missing dirs, no-shift.
- Hypothesis: 2-tile side-passable matches vanilla wall-chair row.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: correct brief/catalog 57-dup line; overlay; `original_cells` vs SAM; disassemble thob-36; training soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
