# Chair Object Deep — thob 6

## 1. CorsixTH definition — Documented fact
- `Lua/objects/chair.lua:22`: `id="chair"`, `:23` `thob=6`; `:27` `ticks=false`; `:28` `build_preview_animation=5056`; `:30` `walk_in_to_use=true`.
- `:32-35` `idle_animations` north=686, east=688 (no south/west — mirror).
- `:37-135` `usage_animations`: 12 patient types × north/east × `begin_use`/`in_use`/`finish_use`; `in_use` east uses `make_list` helper (16 not-talking + 3 nodding + 1 talking per variant). South/west not defined — mirror fallback.
- `:137-149` `walk_in_to_use=true` (class `Chair` overrides `removeUser`/`resetUsageAndReservation`/`afterLoad` for bench-like behavior).
- `:151-177` orientations: all 4 explicit (north/east/south/west) — footprint 2 tiles: north `{0,0 complete},{0,-1 only_passable+invisible+shareable}`, `use_position="passable"`; east `{0,0 complete},{1,0 only_passable+invisible+shareable}`; south `{0,0 complete},{0,1 only_passable+invisible+shareable}`; west `{0,0 complete},{-1,0 only_passable+invisible+shareable}`. All `use_position="passable"`.
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object.
- Class `Chair` with `afterLoad` compatibility for old saves (<119).

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:226`: thob 6 row: `StartCost=60, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `6 Chair`.
- No specific room requires chair — general furniture.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 6 | `chair.lua:23` | `base_config.lua:226` | match (proxy; EXE pending) |
| cost 60 / strength 10 | `base_config.lua:226` | `base_config.lua:226` | match (proxy) |
| footprint 2 tiles (all 4 orients) | `chair.lua:151-177` | no EXE mask / overlay | unverified |
| `invisible+shareable` passable tile | `chair.lua:151-177` | unknown | unverified |
| 12 patient variants | `chair.lua:37-135` | DAT/ANI not decoded | unverified |
| `walk_in_to_use=true` | `chair.lua:30` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:226` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- All 4 orients explicit 2-tile (complete + passable with `invisible+shareable` flags). `use_position="passable"` resolves to passable tile.
- `shareable=true` on passable tile allows multiple entities per `object.lua:386-392`.
- No `copy_north_to_south` — all 4 explicit.
- No `need_*_side`, `early_list`, slave, crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay all 4 orients; `original_cells` dump vs SAM; disassemble thob-6; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.