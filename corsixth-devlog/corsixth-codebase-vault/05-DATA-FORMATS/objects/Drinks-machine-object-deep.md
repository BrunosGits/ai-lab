# Drinks machine — thob 7 — vanilla-parity deep note

Scope: drinks_machine (thob 7). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition

Lua `~/CorsixTH/CorsixTH/Lua/objects/drinks_machine.lua`:
- `id="drinks_machine"` :22, `thob=7` :23; `ticks=false` :26; `corridor_object=3` :27; preview `906` :28; `multiple_users_allowed=true` :29; `dynamic_info=true` :30
- `idle_animations` all 4 explicit: south 170, west 172, north 174, east 176
- `usage_animations` south/east/west only, NO north: 12 patient types each; comment `:47` on anim 426
- `orientations` all 4 explicit, 2 tiles each: north `{0,0 complete},{0,-1 only_passable}` + `use="passable"` + north-only `added_animation_offset_while_in_use`; east `{0,0},{1,0}` + animate-from-use; south/west analogous
- Corridor-placeable (`object.lua:772,777`); excluded from `count_category` (`:931-933`)
- Economy: `hospital.lua:1433-1436` `sellSodaToPatient` reads `level_config.gbv.SodaPrice`; `patient.lua:817-826` thirst drain + toilet gain; `patient.lua:863-895` seeks machine within 8 when room-less/queueing; `humanoid_actions/queue.lua:324-350` get-soda action; `objects/litter.lua:37` soda_can drops; `map.lua:960` default `SodaPrice=20`

THOB + cost: `base_config.lua:227`: `{StartCost=500, StartAvail=1, StartStrength=10}, -- 7 Drinks`. SodaPrice 20 (`base_config.lua:148-149`).

## 2. Original TH data

- Base row + price match (proxy). Strings `original_strings.lua:131,1777`.
- Game data present (`DATA/VBLK`, `VELE/VFRA/VLIST/VSPR/VSTA`, `LEVELS/*.SAM`); no decoded thob-7 mask; EXE not disassembled.

## 3. Footprint-compare

- All 4 explicit 2-tile; `use="passable"` → first `only_passable`. Nearest solid d=1 → single-dir, pre==post. No mirror derivation needed.
- Strict/minimal unfiled.

## 4. Behavior checklist

- Passable-use all dirs, multi-user, soda economy + litter drop wired. No secondary/finish/slave/smoke; no `default_strength` → no repair.
- Idle per-dir distinct; **usage north missing** — north-facing use fallback unknown, needs runtime test.
- Soak pending.

## 5. Verdict per attribute

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 7 / cost 500 / price 20 | match (proxy) | `base_config.lua:227,148-149` |
| 2-tile ×4 footprint | unverified | `drinks_machine.lua:89,94,99,104` |
| idle/usage anims | unverified | `drinks_machine.lua:31-86` |
| missing north usage | unverified (parity or bug?) | absent `:37-86` |
| economy wiring | match-internal | `hospital.lua:1433`, `patient.lua:817-895` |
| overlay/soak | pending | none exists |

## 6. Fact vs Inference vs Hypothesis

- Fact: Lua shape, economy chain, base row, strings.
- Inference: no-shift, single-dir, corridor freedom.
- Hypothesis: 2-tile matches vanilla; north-usage gap may be vanilla-accurate. Needs proof.

## 7. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: overlay 4 dirs; `original_cells` vs SAM; disassemble thob-7; north-usage runtime test; soak + save/load + `busted`/`luacheck`.
- Result: FAIL (pending).
