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
- V1-CORRECTION (2026-10-07): the row EXISTS — `base_config.lua:265`: `{StartCost=5, StartAvail=1, WhenAvail=0, StartStrength=10, AvailableForLevel=1}, -- 45 Plant1`. The earlier "missing" claim was a scan error (comment says Plant1). Cost 5, avail 1, strength 10. No gap.
- `corridor_object=7` allows corridor placement.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 45 | `plant.lua:23` | `base_config.lua:265` | match (proxy) |
| cost 5 / avail 1 / strength 10 | `base_config.lua:265` | same row | match (proxy) |
| footprint 1 tile complete | `plant.lua:55-76` | no EXE mask / overlay | unverified |
| watering lifecycle (5 states) | `plant.lua:89-200` | unknown — TH had plants | Inference (likely faithful) |
| Handyman watering + pathfinding | `plant.lua:130-180` | unknown | unverified |
| VIP pleasing factor | `plant.lua:260-263` | TH had plant rating | Inference |
| purchaseable (StartAvail=1) | `base_config.lua:265` | same row | match (proxy) |

## 4. Footprint-compare [Inference]
- 1-tile complete_cell all 4 orients; `use_animate_from_use_position=true` means anim at tile center.
- No `use_position` keyword — handyman uses `getBestUsageTileXY` pathfinding to adjacent tile.
- Plant health states (5 frames) animate via `setNextState` timer; TH used ~50 days between states (CorsixTH `days_between_states=64`).
- `vomitInducing` check for VIP rating matches `vip.lua:326-338` plant scoring.

## 5. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- V1 closed the base_config question (row exists, cost 5 / strength 10). Remaining: overlay + soak.
- Next: TH screenshot grid-overlay; `original_cells` dump vs SAM; disassemble thob-45; 5000-tick soak + save/load + `busted`/`luacheck`.