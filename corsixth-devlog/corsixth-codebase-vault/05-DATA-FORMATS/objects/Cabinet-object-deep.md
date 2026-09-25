# Cabinet Object Deep — thob 2

## 1. CorsixTH definition — Documented fact
- `Lua/objects/cabinet.lua:22`: `id="cabinet"`, `:23` `thob=2`; `:27` `ticks=false`; `:28` `build_preview_animation=5054`.
- `:30-33` `idle_animations` north=80, east=82 (no south/west — mirror fallback).
- `:35-46` `usage_animations`: Doctor only; north `in_use=88`, east `in_use=90`; south/west not defined (mirror).
- `:48-49` staff markers on east/north `in_use` at `{0,0}`.
- `:51-77` orientations: north footprint `{0,0 complete},{0,1 only_passable}`, `use_position="passable"`, `use_animate_from_use_position=true`; east footprint `{0,0 complete},{-1,0 only_passable}`, `use_position="passable"`; south footprint `{0,0 complete},{0,-1 only_passable}`, `use_position="passable"`; west footprint `{0,0 complete},{1,0 only_passable}`, `use_position="passable"`, `use_animate_from_use_position=true`. All 4 orients explicit (no copy).
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object not Machine.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:222`: thob 2 row: `StartCost=100, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `2 Cabinet`.
- `research.lua:38`: `objects_needed={desk=1,cabinet=1,autopsy=1}` — required in research.
- `research.lua:65`: `staff_usage_objects` includes `cabinet=true` — staff cycles cabinet (100 research pts).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 2 | `cabinet.lua:23` | `base_config.lua:222` | match (proxy; EXE pending) |
| cost 100 / strength 10 | `base_config.lua:222` | `base_config.lua:222` | match (proxy) |
| footprint 2 tiles (all 4 orients) | `cabinet.lua:51-77` | no EXE mask / overlay | unverified |
| `use_animate_from_use_position` | true (north/west) | unknown | unverified |
| Doctor-only anims 80/82/88/90 | `cabinet.lua:30-49` | DAT/ANI not decoded | unverified |
| required in research | `research.lua:38` | no TH room table extracted | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:222` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- All 4 orients explicit 2-tile (1 complete + 1 passable); `use_position="passable"` resolves to the passable tile (`object.lua:945-954`).
- `use_animate_from_use_position=true` on north/west means patient animates at use tile.
- No `copy_north_to_south` — all 4 hand-written; south/west not mirror of north/east (they are distinct 2-tile definitions).
- No `need_*_side`, no `early_list`, no slave, no crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay research room all 4 orients; `original_cells` dump vs `LEVELS/*.SAM`; disassemble thob-2; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.