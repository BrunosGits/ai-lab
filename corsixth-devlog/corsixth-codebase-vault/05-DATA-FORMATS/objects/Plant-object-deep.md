# Plant Object Deep — thob 45

## 1. CorsixTH definition — Documented fact
- `Lua/objects/plant.lua:22`: `id="plant"`, `:23` `thob=45`; `:24` `class="Plant"`; `:27` `ticks=false`; `:28` `corridor_object=7`; `:29` `build_preview_animation=934`.
- `:31-38` `idle_animations` north/south/east/west=1950 (explicit all 4).
- `:40-53` `usage_animations`: Handyman `begin_use` (north 1972, east 1974, `object_visible=true`), `in_use` (north 1980, east 1982, `object_visible=true`). South/west not defined — mirror fallback.
- `:55-76` orientations: all 4 explicit — footprint `{0,0 complete_cell}`, `use_animate_from_use_position=true`. No `use_position` (keyword not used), `use_animate_from_use_position=true` means patient/handyman animates at tile.
- `:78-87` staff markers on watering anims (kf1/kf2/kf3/kf4).
- `:89-200` class `Plant` with full lifecycle: 5 health states (healthy→drooping1→drooping2→dying→dead), `days_between_states=64`, watering calls via dispatcher, handyman pathfinding to best access tile, `tickDay` health decay (temp-adjusted), unreachable handling, `isPleasingFactor` for VIP rating, `vomitInducing` for litter, cleaning task integration, `afterLoad` compatibility.
- No `early_list`, slave, crashed/smoke — `SideObject` with custom tick logic.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:266` (comment line 46): thob 45 not listed in base_config objects table (scanned 220-278). **Gap**: Plant missing from base_config StartCost/Avail/Strength table — may be hardcoded in TH or derived.
- `corridor_object=7` allows corridor placement.
- No base_config row found for thob 45 — CorsixTH may have invented cost/strength or loaded from different source.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 45 | `plant.lua:23` | no base_config row | **divergence** — base_config missing |
| cost/strength | not in base_config | unknown | **unverified — major gap** |
| footprint 1 tile complete | `plant.lua:55-76` | no EXE mask / overlay | unverified |
| watering lifecycle (5 states) | `plant.lua:89-200` | unknown — TH had plants | Inference (likely faithful) |
| Handyman watering + pathfinding | `plant.lua:130-180` | unknown | unverified |
| VIP pleasing factor | `plant.lua:260-263` | TH had plant rating | Inference |
| purchaseable | no base_config row | unknown | unverified |

## 4. Footprint-compare [Inference]
- 1-tile complete_cell all 4 orients; `use_animate_from_use_position=true` means anim at tile center.
- No `use_position` keyword — handyman uses `getBestUsageTileXY` pathfinding to adjacent tile.
- Plant health states (5 frames) animate via `setNextState` timer; TH used ~50 days between states (CorsixTH `days_between_states=64`).
- `vomitInducing` check for VIP rating matches `vip.lua:326-338` plant scoring.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no base_config row, no soak. PASS(minimal): N/A.
- **Critical gap**: thob 45 missing from base_config — need to find original TH cost/strength/availability.
- Next: search TH data for plant cost (maybe in different table); TH screenshot grid-overlay; `original_cells` dump vs SAM; disassemble thob-45; 5000-tick soak + save/load + `busted`/`luacheck`.