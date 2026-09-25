# Screen Object Deep — thob 16

## 1. CorsixTH definition — Documented fact
- `Lua/objects/screen.lua:22`: `id="screen"`, `:23` `thob=16`; `:27` `ticks=false`; `:28` `build_preview_animation=926`; `:30` `show_in_town_map=true`.
- `:32-33` `idle_animations` north=1022 (single, no east/south/west — mirror).
- `:35-57` `usage_animations` (non-theatre): Elvis `946` (transformation); Standard M `undress=1048, dress=1052`; Standard F `undress=2848, dress=2844`. No north/east/south/west — single north block, mirror for other orients.
- `:59-76` patient markers on idle (1022, 1204) + usage anims (kf1/kf2/kf3).
- `:78-90` orientations: north only — footprint 4 tiles `{-1,-1 only_passable},{-1,0},{0,-1},{0,0}`, `render_attach_position={-1,0}`, `use_position="passable"`. East/south/west not defined — mirror fallback via `object.lua:29-34`.
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:236`: thob 16 row: `StartCost=250, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `16 Screen`.
- `scanner_room.lua:30`: `objects_needed={scanner=1,console=1,screen=1}` — required in scanner.
- `x_ray_room.lua` does not require screen (uses x_ray_viewer instead).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 16 | `screen.lua:23` | `base_config.lua:236` | match (proxy; EXE pending) |
| cost 250 / strength 10 | `base_config.lua:236` | `base_config.lua:236` | match (proxy) |
| footprint 4 tiles (north only) | `screen.lua:78-90` | no EXE mask / overlay | unverified |
| Anim variants (Elvis transform, M/F undress/dress) | `screen.lua:35-57` | DAT/ANI not decoded | unverified |
| Required in scanner | `scanner_room.lua:30` | no TH room table extracted | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:236` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- North-only 4-tile (1 passable + 3 complete); `use_position="passable"` → the `only_passable` tile.
- East/south/west via `orient_mirror` (`north<->west`, `east<->south`).
- No `copy_north_to_south` for orientations — north only defined.
- No `need_*_side`, `early_list`, slave, crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay scanner room all 4 orients; `original_cells` dump vs SAM; disassemble thob-16; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.