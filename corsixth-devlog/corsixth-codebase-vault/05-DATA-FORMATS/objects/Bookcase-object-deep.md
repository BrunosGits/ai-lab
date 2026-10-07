# Bookcase — thob 56 — vanilla-parity deep note

Scope: bookcase (thob 56). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

Lua object `~/CorsixTH/CorsixTH/Lua/objects/bookcase.lua` (54 lines total):
- `object.id = "bookcase"` :23, `object.thob = 56` :23
- `object.ticks = false` :26, `build_preview_animation = 5104` :27, `show_in_town_map = true` :28
- `copy_north_to_south` :29-32; `idle_animations` :33-35 north `2406`
- `usage_animations` :36-40 north `in_use = {Doctor = 2414}` :38
- `orientations` :41-52: north footprint `{0,0 complete},{1,0 only_passable}`, `use_position="passable"`, `use_animate_from_use_position=true`; east `{0,0 complete},{0,1 only_passable}`, same use flags
- Absent (verified full file): no `research_category`, no slave, no `default_strength/crashed/smoke`, no `render_attach`, no `handyman_position`, no `early_list`.

Rooms:
- `rooms/psych.lua:29` additional includes bookcase; `objects_needed = {screen=1, couch=1, comfortable_chair=1}` (optional)
- `rooms/psych.lua:63` staff idle via `findFreeObjectNearToUse(staff,"bookcase","near")`; `:89-92,123-125` reuse loop with `UseObjectAction` every ~10 ticks at 50%
- `rooms/training.lua:30` additional includes bookcase; `objects_needed = {lecture_chair=1, projector=1}`; `:77` counts `{projector, skeleton, bookcase}`; `:117` bookcase uses `training_value[2]`
- Training values `base_config.lua:129-133`: `[0]=10 projector, [1]=15 skeleton, [2]=20 bookcase`

THOB + cost: Lua thob 56 aligns with `base_config.lua:276`: `{StartCost=350, StartAvail=1, StartStrength=10, AvailableForLevel=1}, -- 56 Bookcase`.

## 2. Original TH data

- `base_config.lua:276` — cost 350, avail 1, strength 10.
- Strings `original_strings.lua:180` (`bookcase = S[2][57]`); tooltip `:1826` (`S[40][57]`, has description).
- Game data `~/game_data/HOSP`: `HOSPITAL.EXE` (1655539 bytes, 1997-05-13), `LEVELS/` (55x `*.SAM`), `DATA/`, `DATAM/`. Ground truth not disassembled.
- Tile LUT `th_map.cpp:316-338` maps SAM bytes to tiles only — NOT footprints.
- `original_cells` preserved (`th_map.cpp:294-295,369,418,677-689,938,1542-1550`); no dump/overlay for thob 56.

## 3. Footprint-compare

- north: solid `(0,0)`, passable `(1,0)`; east: solid `(0,0)`, passable `(0,1)`; south=north; west/south via `orient_mirror` (`object.lua:29-34`). Compare N/E only.
- `use="passable"` → first `only_passable` (`object.lua:945-952`). Nearest solid distance 1 → restricted `pathfind_allowed_dirs`, recenter `(0,0)`, pre==post.
- Strict/minimal masks unfiled — no overlay.

## 4. Behavior checklist

- N/E defined, S copied, W mirrored; idle mirrored; no `early_list`. Use reachable in principle (adjacent solid).
- No secondary/finish/slave/smoke; crash/repair N/A. Blocked use would silently idle — silent regression risk.
- Soak 5000-tick + save/load, `busted`/`luacheck`: not run.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| id / thob 56 | match (proxy) | `bookcase.lua:22-23` vs `base_config.lua:276` |
| cost 350 / avail 1 / strength 10 | match (proxy) | `base_config.lua:276` |
| psych + training wiring | match | `psych.lua:29,63`, `training.lua:30,77,117` |
| footprint N/E shape | unverified | `bookcase.lua:43,48` |
| idle 2406 / Doctor 2414 | unverified | `bookcase.lua:34,38` |
| overlay/save/soak | pending | none exists |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua lines, room wirings, base row, strings, LUT-limits, `original_cells` mechanism, mirror/copy rules.
- Inference: pre==post shift, restricted dirs, silent-failure claim.
- Hypothesis: 1-solid+1-passable equals vanilla adjacency. Needs EXE/screenshot proof.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: (1) screenshot+SAM overlay; (2) pre/post-shift record; (3) soak + save/load; (4) `busted`/`luacheck`.
- Result: FAIL (pending).
