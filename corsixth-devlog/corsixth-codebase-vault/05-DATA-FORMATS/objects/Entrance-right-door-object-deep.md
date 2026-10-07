# Entrance right door — thob 59 — vanilla-parity deep note

See also: Door-object-deep.md (thob 3 base door). Pair: Entrance-left-door-object-deep.md (thob 58 slave).

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/doors/entrance_right_door.lua:22`: `id="entrance_right_door"`, `:23` `thob=59`, `:26` `class="EntranceDoor"`, `:27` `ticks=false`.
- `:28-31` `idle_animations` north=308, west=312. No south/east — mirror via `entities/object.lua:29-34,64-75`.
- `:32` `supports_creation_for_map=true`.
- `:34` `class "EntranceDoor" (Object)` — base is `Object`, not `Door`. Applies to both entrance halves.
- `:39-43` ctor: `is_master=object_type==object` (true here), `occupant_count=0`, `is_open=false`.
- `:45-51` master pairing: `getObject(x-1,y)` or `(x,y-1)` for `entrance_left_door`; sets `slave.master=self`.
- `:60-70` anim frame list built from `idle_animations[direction]`; `:148-158` `tick` steps toward open/closed.
- `:73-84` `onOccupantChange`: `occupant_count+=delta`, `eledoor2.wav` (`:77`), `ticks=true`, propagates to slave (`:81-83`). Only master notifies occupants.
- `:95-102` master walkable: north `{{0,-1},{1,0},{1,-1}}`, west `{{-1,0},{0,1},{-1,1}}` (4 tiles incl self).
- `:104-136` `setTile`: `tallNorth/tallWest` (`:107`), `buildable=false,doNotIdle=true` (`:130-132`); master registers `notifyObjectOfOccupants` on self + 1 slave offset (`:124-128`); `updateShadows` (`:135`).
- `:138-146` `getWalkableTiles`: self + master offsets.
- No `orientations`, no `use_position`, no `handyman_position`, no `early_list`, no `slave_position` table, no crashed/smoke, no `corridor_object`.
- Map pair creation `map_editor.lua:1194-1199`; lookup `map_editor.lua:1224-1225,1255,1266,1283-1284`; `world.lua:135-137` thob→id map, `:583-585` map-object gate.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:279`: thob 59 `StartCost=0, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `59 Entrance Right Door`.
- `original_strings.lua:183`: `entrance_right=S[2][60]`; `:1829` `S[40][60], -- no description`.
- EXE ground truth not disassembled; SAM sets present; LUT/`original_cells` unused for this object yet.
- Screenshot/save pending (only thob 22 has V).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob 59 | `entrance_right_door.lua:23` | `base_config.lua:279` | match (proxy; EXE pending) |
| cost 0 / strength 10 / avail | `base_config.lua:279` | same | match (proxy) |
| idle north 308 / west 312 | `entrance_right_door.lua:28-31` | no anim decode | unverified |
| master walkable 4 tiles | `entrance_right_door.lua:95-102,138-146` | no EXE mask/overlay | unverified |
| tall-only + notify | `entrance_right_door.lua:107,124-132` | unknown | unverified |
| master→slave link | `entrance_right_door.lua:45-51` | TH had paired entrance | Inference |
| occupancy open/sound | `entrance_right_door.lua:73-84` | unknown | unverified |

Base-door delta: base `Door` (`door.lua:35,40-50,56-92,94-97,150-156`) queues/early-lists/door-flags; Entrance-right does occupancy counting + tall flags + 4-tile master mask. See Door-object-deep.md.

## 4. Footprint-compare [Inference]
- No `orientations` → no `processTypeDefinition` shift. North/west walkable lists are the footprint.
- Master 4-tile L-shape (self + N/E-adjacent) vs slave 2-tile strip implies 2-wide doorway. Passability driven by `buildable/doNotIdle`, not `only_passable`.
- South/east derived only via `orient_mirror` + map-flag parity (`entities/object.lua:42-49`); never compare literally.

## 5. Fact vs Inference vs Hypothesis
- Fact: thob/cost/anims/master mask/notify/sound/pairing as cited.
- Inference: right=master/left=slave split; map-only placement; mirror covers missing dirs.
- Hypothesis: master 4-tile mask equals vanilla (needs overlay + disasm).

## 6. Strict / minimal + next + pass/fail
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A.
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: same as left + verify master/slave adjacency (`x-1` vs `y-1`) against TH maps; disassemble thob-59; soak + save/load + `busted`/`luacheck`.
