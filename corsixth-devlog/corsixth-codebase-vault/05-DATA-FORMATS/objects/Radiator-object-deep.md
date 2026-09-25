# Radiator Object Deep — thob 44

## 1. CorsixTH definition — Documented fact
- `Lua/objects/radiator.lua:22`: `id="radiator"`, `:23` `thob=44`; `:27` `class="SideObject"`; `:28` `corridor_object=5`; `:29` `build_preview_animation=914`.
- `:30-33` `idle_animations` north=750, east=752 (no south/west — mirror fallback).
- `:35-50` orientations: all 4 explicit — footprint `{0,0 only_side=true}` each. `only_side=true` per orientation (paired passable logic).
- `class="SideObject"`, `corridor_object=5`, `build_preview_animation=914`.
- No `use_position`, `handyman_position`, `use_position_secondary`, `early_list`, slave, crashed/smoke, `usage_animations`, `idle_animations` only north/east (south/west mirror).

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:264`: thob 44 row: `StartCost=20, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `44 Radiator`.
- `corridor_object=5` allows corridor placement.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 44 | `radiator.lua:23` | `base_config.lua:264` | match (proxy; EXE pending) |
| cost 20 / strength 10 | `base_config.lua:264` | `base_config.lua:264` | match (proxy) |
| footprint `only_side` all 4 | `radiator.lua:35-50` | no EXE mask / overlay | unverified |
| `only_side` paired passable | `object.lua:386-392` | unknown | unverified |
| idle north/east only | `radiator.lua:30-33` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:264` | base_config same | match (proxy) |

## 3. Footprint-compare [Inference]
- Single tile `only_side` each orient; `only_side=true` creates paired passable flag per `object.lua:386-392` (north→south passable, east→west passable, etc.).
- North/east idle defined; south/west via `orient_mirror`.
- No `use_position` — purely decorative/wall-mounted; `SideObject` class.
- `corridor_object=5` allows corridor placement.

## 4. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay corridor/wall all 4 orients; `original_cells` dump vs SAM; disassemble thob-44; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.