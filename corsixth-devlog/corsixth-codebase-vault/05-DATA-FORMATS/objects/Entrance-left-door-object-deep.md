# Entrance left door — thob 58 — vanilla-parity deep note

See also: Door-object-deep.md (thob 3 base door — queue/early_list/door-flags live there, not repeated here). Pair: Entrance-right-door-object-deep.md (thob 59 master).

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/doors/entrance_left_door.lua:22`: `id="entrance_left_door"`, `:23` `thob=58`, `:26` `class="EntranceDoor"`, `:27` `ticks=false`.
- `:28-31` `idle_animations` north=316, west=318. No south/east — mirror fallback via `entities/object.lua:29-34` + `:64-75` (`orient_mirror`, FlipHorizontal).
- `:32` `supports_creation_for_map=true`. Data-only file — class code lives in right-door file. Ends `:34` `return object`.
- Class `EntranceDoor` defined in `entrance_right_door.lua:34` (`class "EntranceDoor" (Object)` — NOT `Door`).
- `:39-41` ctor: `is_master = object_type == object` (so left=false/slave), `Object()` init, `occupant_count=0`, `is_open=false`.
- `:52-59` slave pairing: checks `(x+1,y)` then `(x,y+1)` for `entrance_right_door`; links `master.slave=self`.
- `:60-70` anim frames via `anims:getFirstFrame/getNextFrame`, `frame_index=1`.
- `:86-93` slave walkable: north `{{0,-1}}`, west `{{-1,0}}`. No `orientations` table anywhere.
- `:104-136` `setTile`: flag `tallNorth`/`tallWest` (`:107`), `buildable=false,doNotIdle=true` on self+offsets (`:130-132`); clears on move (`:117-119`); `th:updateShadows()` (`:135`). Only master calls `notifyObjectOfOccupants` (`:110-115,:124-128`).
- `:138-146` `getWalkableTiles`: self + slave offsets (2 tiles total for left).
- `:73-84` `onOccupantChange`: count delta, `eledoor2.wav` (`:77`), `ticks=true`; forwards to slave only (`:81-83`) — left never forwards.
- `:148-158` `tick`: steps `frame_index` toward open/closed target, `th:setFrame`.
- Map creation: `world.lua:583-585` gates on `supports_creation_for_map`; `entities/object.lua:42-49` maps even flag→north, odd→west; `dialogs/resizables/map_editor.lua:1194-1199` creates right+left pair.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:278`: thob 58 `StartCost=0, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `58 Entrance Left Door`.
- `languages/original_strings.lua:182`: `entrance_left=S[2][59]`; `:1828` `entrance_left=S[40][59], -- no description`.
- `~/game_data/HOSP/HOSPITAL.EXE` present (1.6M, 1997) — ground truth, not disassembled. No thob-58 mask extracted.
- `~/game_data/HOSP/LEVELS/*.SAM` present — no `original_cells` dump vs SAM done for entrances.
- `th_map.cpp:316` LUT + `:294-302,369-507,938,1542+` `original_cells` — not yet used for this object (tiles, not footprints, per method).
- Screenshot/save: pending (only thob 22 has V).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob 58 | `entrance_left_door.lua:23` | `base_config.lua:278` | match (proxy; EXE pending) |
| cost 0 / strength 10 / avail | `base_config.lua:278` | same | match (proxy) |
| idle north 316 / west 318 | `entrance_left_door.lua:28-31` | no anim decode | unverified |
| slave walkable 2 tiles | `entrance_right_door.lua:86-93,138-146` | no EXE mask/overlay | unverified |
| tall-only flags (no `doorNorth`) | `entrance_right_door.lua:107,117,130` | unknown | unverified |
| map-only (`supports_creation_for_map`) | `entrance_left_door.lua:32` + `world.lua:583` | TH entrances map-placed | Inference |
| occupancy sound/open | `entrance_right_door.lua:73-84` | unknown | unverified |
| south/east mirror | `entities/object.lua:29-34,64-75` | unknown | unverified |

Base-door delta (thob 3): base `Door` has queue, `doorNorth/tallNorth`, 2-tile `getWalkableTiles` (`door.lua:94-97,138-146`), `early_list` north (`door.lua:150-156`). Entrance-left has none of that — `Object` base, tall-only, occupancy ticks. See Door-object-deep.md.

## 4. Footprint-compare [Inference]
- No `orientations` table → `processTypeDefinition` re-center does not apply. Compare `getWalkableTiles` directly, north/west only.
- Slave footprint is 2 tiles; pair total (with master) is 2 origins + up to 4 offsets. No `only_passable`/`complete_cell` semantics — `setTile` drives `buildable/doNotIdle` directly.
- `occupyTilesByObjectFootprintAt` (`entities/object.lua:462-555`) not used — custom `setTile` path.

## 5. Fact vs Inference vs Hypothesis
- Fact: ids/thobs/costs/anims/flags/pairing/sound as cited above.
- Inference: map-only role; mirror fallback covers south/east; tall-only flags faithful.
- Hypothesis: 2-tile slave mask equals vanilla mask (needs overlay + EXE disasm).

## 6. Strict / minimal + next + pass/fail
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A (no gap identified without overlay).
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: overlay TH entrance screenshot; `original_cells` dump vs SAM; disassemble thob-58; 5000-tick soak + save/load + `busted`/`luacheck`.
