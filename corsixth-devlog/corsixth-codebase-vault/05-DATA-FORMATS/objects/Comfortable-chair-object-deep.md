# Comfortable chair — thob 61 — vanilla-parity deep note

Scope: comfortable_chair (thob 61). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

Lua `~/CorsixTH/CorsixTH/Lua/objects/comfortable_chair.lua` (68 lines):
- `id="comfortable_chair"` :22, `thob=61` :23; `ticks=false` :26; preview `5110` :27; town-map true :28
- `copy_north_to_south` :29-32; idle north `2524` :33-35
- `usage_animations` :36-43 north: `begin_use Doctor 2516`, `begin_use_2 2512`, `in_use 2544`, `finish_use 2520`
- Staff markers :45-53 with pixel keyframes
- `orientations` :55-66: north footprint `{0,0 complete},{0,1 only_passable}`, `use="passable"`, animate-from-use; east `{0,0 complete},{1,0 only_passable}`, same
- Absent: no `research_category`, slave, crash/strength/smoke, `render_attach`, `handyman_position`, `early_list`.

Rooms:
- `rooms/psych.lua:30` — `objects_needed` includes `comfortable_chair=1` (required, with screen+couch)
- `rooms/psych.lua:131-133` — `findObjectNear` + `UseObjectAction` with loop callback; psychiatrist's seat, no nil-guard (loud failure if missing)

THOB + cost: `base_config.lua:281`: `{StartCost=100, StartAvail=1, StartStrength=10, AvailableForLevel=1}, -- 61 Comfy Chair`.

## 2. Original TH data

- `base_config.lua:281` — cost 100, avail 1, strength 10.
- Strings `original_strings.lua:185` (`S[2][62]`); tooltip `:1831` (`S[40][62] -- no description`).
- Game data as bookcase note; thob-61 mask not disassembled; no overlay.

## 3. Footprint-compare

- north: solid `(0,0)`, passable `(0,1)` (+y); east: solid `(0,0)`, passable `(1,0)` (+x). Axes swapped vs bookcase (bookcase north passable is +x) — verified by direct read.
- south=north; west/east via `orient_mirror`. `use="passable"` → first passable. Nearest solid d=1 → restricted dirs, pre==post.
- Strict/minimal unfiled.

## 4. Behavior checklist

- 4-stage Doctor sequence + staff markers; `use_animate_from_use_position` both orients. No secondary/finish/slave/smoke; crash/repair N/A.
- Psych-required with nil-unguarded use — placement regression would be loud.
- Soak + save/load, `busted`/`luacheck`: not run.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| id / thob 61 | match (proxy) | `comfortable_chair.lua:22-23` vs `base_config.lua:281` |
| cost 100 / avail 1 / strength 10 | match (proxy) | `base_config.lua:281` |
| required in psych | match | `psych.lua:30,131-133` |
| footprint N/E (axis-swapped vs bookcase) | unverified vs vanilla | `comfortable_chair.lua:57,62` |
| idle/usage/markers | unverified | `comfortable_chair.lua:34,38-41,48-53` |
| overlay/save/soak | pending | none exists |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua lines, psych wiring, base row, strings, mirror/copy rules.
- Inference: pre==post, restricted dirs, loud-failure claim.
- Hypothesis: axis-swapped passables reproduce vanilla. Needs proof.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: (1) psych screenshot+SAM overlay; (2) axis-swap vanilla check; (3) marker trace; (4) soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
