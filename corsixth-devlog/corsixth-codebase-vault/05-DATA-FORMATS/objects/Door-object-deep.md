# Door Object Deep — thob 3

## 1. CorsixTH definition — Documented fact
- `Lua/objects/door.lua:22`: `id="door"`, `:23` `thob=3`; `:26` `class="Door"`; `:27` `ticks=false`.
- `:29-51` `Door` class: `queue` with same-room priority; `setupDoor` (room edit preserves queue); `updateDynamicInfo` (room name + queue size); `onClick` opens `UIQueue`; `door_flag_name` per direction (north→`doorNorth`/`tallNorth`, west→`doorWest`/`tallWest`); `setTile` manages map flags (`buildableNorth/South` or `East/West`, `doNotIdle`), shadows; `getWalkableTiles` returns 2 tiles; `setAnimation` adds `early_list` flag for north; `closeDoor` clears queue; `getDrawingLayer` = `Door`; `checkForDeadlock` (reroutes if reserved not at front); `afterLoad` compat (<57 sets buildable flags).
- `:30-32` `idle_animations` north=104, west=106 (no south/east — mirror fallback).
- No orientations table — `Door` class handles tile flags directly via `setTile`; `early_list` added for north via `setAnimation` override.
- `corridor_object` absent — doors only in rooms (room edit creates door).
- No `use_position`, `handyman_position`, `early_list` (added dynamically for north), slave, crashed/smoke, `usage_animations`.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:223`: thob 3 row: `StartCost=40, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `3 Door`.
- Room edit creates doors; doors not directly purchasable (but cost exists).
- `Door` class manages room queue, buildable flags, dynamic info (room name + queue size).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob id 3 | `door.lua:23` | `base_config.lua:223` | match (proxy; EXE pending) |
| cost 40 / strength 10 | `base_config.lua:223` | `base_config.lua:223` | match (proxy) |
| Footprint (2 tiles per `getWalkableTiles`) | `door.lua:159-164` | no EXE mask / overlay | unverified |
| Map flags (`doorNorth` etc.) | `door.lua:130-148` | TH had door flags | Inference (likely faithful) |
| Queue logic + dynamic info | `door.lua:53-80` | TH had room queues | Inference |
| `early_list` for north | `door.lua:166-169` | unknown | unverified |
| purchaseable (StartAvail=1) | `base_config.lua:223` | base_config same | match (proxy) |

## 4. Footprint-compare [Inference]
- Door occupies 2 tiles (`getWalkableTiles`): tile + adjacent (west: x-1; north: y-1).
- `setTile` manages `buildable*`, `doNotIdle` flags on both tiles; `afterLoad` compat for old saves.
- `early_list` added for north doors only (affects draw order).
- No standard footprint table — `Door` class is special-cased.

## 4. strict/minimal + next
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: TH screenshot grid-overlay room doors both orients; `original_cells` dump vs SAM; verify `doorNorth`/`tallNorth` flags; disassemble thob-3; 5000-tick soak + save/load + `busted`/`luacheck`.