# Swing door left — thob 52 — vanilla-parity deep note

See also: Door-object-deep.md (thob 3 base door — queue/setTile/early_list/afterLoad mechanics live there, not repeated here). Pair: Swing-door-right-object-deep.md (thob 53 master).

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/doors/swing_door_left.lua:22`: `id="swing_door_left"`, `:23` `thob=52`, `:26` `class="SwingDoor"`, `:27` `ticks=false`.
- `:28-31` `idle_animations` north=1996, west=1998. No south/east — mirror via `entities/object.lua:29-34,64-75`.
- No `supports_creation_for_map` — not a map object (room door). Ends `:33` `return object`. Data-only; behavior in right-door file.
- Class `SwingDoor` in `swing_door_right.lua:33` (`class "SwingDoor" (Door)` — inherits `Door`, unlike EntranceDoor).
- `:38-46` ctor: `is_master=object_type==object` (false here/slave), `Door()` init, `paired=false`, `pairDoors`, saves `old_anim/old_flags` (`:43-44`).
- `:63-71` slave pairing: `getObject(x+1,y)` or `(x,y+1)` for `swing_door_right`; links `master.slave=self`.
- `:78-90` `checkPaired`: asserts mutual link or asserts no neighbor exists (`:80-88`).
- `:93-99` `onClick`, `:102-108` `updateDynamicInfo`, `:111-113` `getDynamicInfo` — all delegate slave→master. `game_ui.lua:523-527` special-cases `swing_door_left` to `master.room`.
- `:120-127` `swingSlave`: anim 2034 (out) / 2032 (in), flags 1 if east/west else 0 (`:121`).
- `:171-174` `getWalkableTiles`: `if not is_master return {}` — slave contributes zero tiles.
- `:190-207` `afterLoad`: `<184` re-pairs if unlinked (`:191-196`), else sets `paired=true` both sides (`:198-203`); then `Door.afterLoad` (`:206`, covers `<57` buildable flags per `door.lua:192-205`).
- Placement: `dialogs/edit_room.lua:498-500` creates `swing_door_right` + `swing_door_left` pair; rooms with `swing_doors=true`: `rooms/dna_fixer.lua:38`, `rooms/ward.lua:45`, `rooms/operating_theatre.lua:43`; blueprint checks `:1340-1371`.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:272`: thob 52 `StartCost=0, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `52 Double Door Part #1`.
- `original_strings.lua:176`: `swing_door1=S[2][53]`; `:1822` `S[40][53], -- no description`.
- EXE not disassembled; SAM sets present; LUT/`original_cells` unused for this object yet. Screenshot/save pending.

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob 52 | `swing_door_left.lua:23` | `base_config.lua:272` | match (proxy; EXE pending) |
| cost 0 / strength 10 / avail | `base_config.lua:272` | same | match (proxy) |
| idle north 1996 / west 1998 | `swing_door_left.lua:28-31` | no anim decode | unverified |
| slave walkable {} | `swing_door_right.lua:171-174` | no EXE mask/overlay | unverified |
| slave→master delegate | `swing_door_right.lua:93-113` + `game_ui.lua:523-527` | unknown | unverified |
| swing anims 2032/2034 | `swing_door_right.lua:120-127` | no anim decode | unverified |
| re-pair `<184` | `swing_door_right.lua:190-207` | save-compat invention | Inference (compat, not vanilla) |

Inherits base-door queue/flags/early_list via `Door` — see Door-object-deep.md for `door.lua:40-50,56-92,94-156,192-208`.

## 4. Footprint-compare [Inference]
- No `orientations`; `Door:getWalkableTiles` (`door.lua:138-146`) overridden. Slave empty set means only master tiles block — pair footprint = master 6-tile block (`swing_door_right.lua:182-187`), not 2+2.
- Mirror rule still applies to idle anims; walkable override branches only on `west` vs else (so east/south/north share one mask).

## 5. Fact vs Inference vs Hypothesis
- Fact: thob/cost/anims/empty-slave/delegation/pairing/asserts as cited.
- Inference: slave-empty design prevents double-blocking; `<184` re-pair is compat shim.
- Hypothesis: 6-tile master mask equals vanilla double-door mask (needs overlay + disasm).

## 6. Strict / minimal + next + pass/fail
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: overlay TH swing-door rooms (ward/OT/dna); `original_cells` dump vs SAM; disassemble thob-52/53; 5000-tick soak + save/load + `busted`/`luacheck`.
