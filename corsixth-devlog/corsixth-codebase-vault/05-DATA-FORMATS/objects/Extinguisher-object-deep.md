# Fire Extinguisher Object Deep — thob 43

## 1. CorsixTH definition — Documented fact
- `Lua/objects/fire_extinguisher.lua:22`: `id="extinguisher"`, `:23` `thob=43`; `:27` `class="SideObject"`; `:28` `corridor_object=4`; `:29` `build_preview_animation=912`.
- `:30-33` `idle_animations` north=178, east=468, south=470 (no west — mirror fallback).
- `:35-50` orientations: all 4 explicit — footprint `{0,0 only_side=true}` each. `only_side=true` per orientation.
- `class="SideObject"`, `corridor_object=4`, `build_preview_animation=912`.
- No `use_position`, `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke, `usage_animations`, `idle_animations` only north/east/south (west mirror).

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:263`: thob 43 row: `StartCost=25, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `43 Fire Extinguisher`.
- `corridor_object=4` allows corridor placement.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 43 | `fire_extinguisher.lua:23` | `base_config.lua:263` | match (proxy; EXE pending) |
| cost 25 / strength 10 | `base_config.lua:263` | `base_config.lua:263` | match (proxy) |
| footprint `only_side` all 4 | `fire_extinguisher.lua:35-50` | no EXE mask / overlay | unverified |
| idle 3 orientations defined | `fire_extinguisher.lua:30-33` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:263` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- Single tile `only_side` each orient; paired passable logic per `object.lua:386-392`.
- North/east/south idle defined; west via mirror.
- No `use_position` — purely decorative/wall-mounted `SideObject`.
- `corridor_object=4` allows corridor placement.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay corridor/wall all 4 orients; `original_cells` dump vs SAM; disassemble thob-43; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.