# Bin Object Deep — thob 50

## 1. CorsixTH definition — Documented fact
- `Lua/objects/bin.lua:22`: `id="bin"`, `:23` `thob=50`; `:27` `ticks=false`; `:28` `corridor_object=6`; `:29` `class="SideObject"`; `:30` `build_preview_animation=5096`.
- `:32-35` `idle_animations` north=1752, south=1752 (copied); no east/west — mirror fallback.
- `:37-44` orientations: north footprint `{0,0 only_side=true}`; east footprint `{0,0 only_side=true}`. South/west not defined — mirror fallback (`object.lua:29-34`).
- `class="SideObject"` — treated as wall-adjacent decoration, no `use_position`, no `handyman_position`, no `use_position_secondary`, no `early_list`, no slave, no crashed/smoke.
- `corridor_object=6` allows placement in corridors.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:271`: thob 50 row: `StartCost=300, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `50 Bin`.
- `corridor_object=6` allows corridor placement.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 50 | `bin.lua:23` | `base_config.lua:271` | match (proxy; EXE pending) |
| cost 300 / strength 10 | `base_config.lua:271` | `base_config.lua:271` | match (proxy) |
| footprint 1 tile `only_side` | `bin.lua:41-44` | no EXE mask / overlay | unverified |
| `only_side=true` semantics | `object.lua:386-392` (paired passable) | unknown | unverified |
| north+south idle only | `bin.lua:34-35` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:271` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- Single tile with `only_side=true` — per `object.lua:386-392` this creates a paired passable flag: east orientation makes west passable, north makes south passable, etc.
- North/south idle copied; east/west via `orient_mirror` (`north<->west`, `east<->south`).
- No `use_position`, `handyman_position`, `early_list`, slave, crashed/smoke.
- `SideObject` class suggests wall-adjacent placement only.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay corridor/wall both orients; `original_cells` dump vs SAM; disassemble thob-50; runtime footprint dump; 5000-tick soak + save/load + `busted`/`luacheck`.