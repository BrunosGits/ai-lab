# Surgeon Screen Object Deep — thob 35

## 1. CorsixTH definition — Documented fact
- `Lua/objects/surgeon_screen.lua:22`: `id="surgeon_screen"`, `:23` class=`SurgeonScreen`, `:24` `thob=35`.
- `:27` `ticks=false`; `:28` `build_preview_animation=926`; `:30` `show_in_town_map=true`.
- `:32-35` `idle_animations` north=2772 (single, no south copy — no `copy_north_to_south`).
- `:37-43` orientations: north footprint 4 tiles `{-1,-1 only_passable},{-1,0},{0,-1},{0,0}`, `render_attach_position={-1,0}`, `use_position="passable"`. East not defined — no `east` key; south not copied; west/east via mirror (`object.lua:29-34`).
- `:45-77` `usage_animations` (operating theatre only): Surgeon `scrubs_on_t1..t3` (2780/2/4), `scrubs_off_t1..t4` (2790/2/4/6); Standard M/F Patient `gown_on/off`; idle anims marked with kf1/kf2/kf3 markers for patient/staff positions.
- `:79-124` Extensive staff/patient markers on scrubs/gown anims (kf1/kf2/kf3 keyframes).
- `:126-130` class `SurgeonScreen` extends `Object`; ctor sets `num_green_outfits=2`, `num_white_outfits=0`.
- No east/south footprint defined; south not copied; mirror handles.
- No `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke — Object not Machine.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:255`: thob 35 row: `StartCost=200, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `35 Surgeon Screen`.
- `operating_theatre.lua:30-35`: `objects_needed={operating_table=1, surgeon_screen=1, op_sink1=1, x_ray_viewer=1}` — required.
- `operating_theatre.lua:288-334`: two-surgeon sync — action1 on `operating_table`, action2 on `surgeon_screen`; patient via `getSecondaryUsageTile`.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 35 | `surgeon_screen.lua:24` | `base_config.lua:255` | match (proxy; EXE pending) |
| cost 200 / strength 10 | `base_config.lua:255` | `base_config.lua:255` | match (proxy) |
| footprint 4 tiles (north only) | `surgeon_screen.lua:38-43` | no EXE mask / overlay | unverified |
| `use_position="passable"` | keyword on `only_passable` | unknown | unverified |
| Anim numbers + markers | `surgeon_screen.lua:45-124` | DAT/ANI not decoded | unverified |
| Required in theatre | `operating_theatre.lua:33` | no TH room table extracted | unverified |
| East/south orientations | missing in file; mirror fallback | unknown | unverified |

## 4. Footprint-compare [Inference]
- North-only 4-tile with `only_passable` at `{-1,-1}`; `use_position="passable"` → that tile.
- East/south via `orient_mirror` (`north<->west`, `east<->south`); `early_list` absent.
- No `need_*_side`, no `early_list`, no slave, no crash/smoke.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak, east/south unverified. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay theatre north+east; `original_cells` dump vs SAM; disassemble thob-35; runtime footprint dump for all 4 orients; 5000-tick soak + save/load + `busted`/`luacheck`.