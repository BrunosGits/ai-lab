# X-Ray Viewer Object Deep — thob 29

## 1. CorsixTH definition — Documented fact
- `Lua/objects/x_ray_viewer.lua:22`: `id="x_ray_viewer"`, `:23` `thob=29`; no research fields.
- `:27` `ticks=false`; `:28` `build_preview_animation=5078`; `:30` `show_in_town_map=true`.
- `:31-36` `locked_to_wall`: north→east, west→north (permittable wall → orientation).
- `:38-43` `idle_animations` north=2390, south copied.
- `:45-56` orientations: north footprint 1 tile `{0,0 need_west_side=true}`, `early_list=false` (implicit); east footprint 1 tile `{0,0 need_north_side=true}`, `early_list=true`. No `use_position`, `render_attach`, `handyman_position` defined.
- No `copy_north_to_south` for orientations (explicit); south copied for idle via `copy_north_to_south`.
- No `use_position` at all — viewer is wall-mounted, not walked to.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:249`: thob 29 row: `StartCost=500, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `29 X-Ray Viewer`.
- `operating_theatre.lua:30-35`: `objects_needed={x_ray_viewer=1}` — required.
- `operating_theatre.lua:roomFinished`: finds x_ray_viewer near entrance (`fx,fy` from `getEntranceXY`) and caches it.
- Paired with x_ray machine (thob 27) + radiation_shield (thob 28) in same room.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 29 | `x_ray_viewer.lua:23` | `base_config.lua:249` | match (proxy; EXE pending) |
| cost 500 / strength 10 | `base_config.lua:249` | `base_config.lua:249` | match (proxy) |
| footprint 1 tile + need_*_side | `x_ray_viewer.lua:47-56` | no EXE mask / overlay | unverified |
| `locked_to_wall` | north→east, west→north | unknown | unverified |
| `early_list=true` east | explicit east only | unknown | unverified |
| No use_position | wall-mounted, not walked to | likely correct | Inference |
| idle anim 2390 | `x_ray_viewer.lua:40-43` | DAT/ANI not decoded | unverified |

## 4. Footprint-compare [Inference]
- Single tile with directional `need_*_side` flag: north needs west side clear; east needs north side clear.
- `early_list=true` east affects build-order per `object.lua:513-528`.
- `locked_to_wall` forces orientation per wall side; south/west via mirror.
- No `use_position` — viewer not walked to; doctor uses from console (x_ray machine).

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay theatre wall-mounted both sides; `original_cells` dump vs SAM; verify `locked_to_wall` vs vanilla; 5000-tick soak + save/load + `busted`/`luacheck`.