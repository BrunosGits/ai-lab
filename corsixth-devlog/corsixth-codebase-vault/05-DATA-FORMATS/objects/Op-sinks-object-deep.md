# Op Sinks Object Deep — op_sink1 (thob 33) + op_sink2 (thob 34)

Legend: [D]=Documented fact, [I]=Inference, [H]=Hypothesis. Master-slave pair.

## 1. Identity
- [D] `op_sink1.lua:22`: `id="op_sink1"`, slave_id=`op_sink2`, class=`OperatingSink`, thob=33.
- [D] `op_sink1.lua:27-28`: `ticks=false`, `walk_in_to_use=true`, `show_in_town_map=true`.
- [D] `op_sink1.lua:29-34`: `locked_to_wall`: north→east, west→north (permittable wall → orientation).
- [D] `op_sink2.lua:22`: `id="op_sink2"`, class=`OperatingSink`, thob=34; no slave_id.
- [D] `op_sink1.lua:55-57`: `OperatingSink:slaveMixinClass()` (same pattern as operating_table).
- [D] `base_config.lua:253`: thob 33 `StartCost=50, StartAvail=1, StartStrength=10` comment `33 Op Sink 1`.
- [D] `base_config.lua:254`: thob 34 `StartCost=50, StartAvail=1, StartStrength=10` comment `34 Op Sink 2`.
- [D] `operating_theatre.lua:30-35`: `objects_needed={operating_table=1, surgeon_screen=1, op_sink1=1, x_ray_viewer=1}` — master only.

## 2. Footprints & orientations — Documented fact
- op_sink1 north (`:37-46`): footprint `{0,0 complete},{0,-1 complete},{1,0 only_passable+invisible}`, `use_position={1,0}`, `slave_position={0,-1}`.
- op_sink1 east (`:48-54`): footprint `{0,0 complete},{-1,0 complete},{0,1 only_passable+invisible}`, `use_position={0,1}`, `slave_position={-1,0}`.
- op_sink2 north+east (`op_sink2.lua:46-52`): `footprint={}` (empty) — occupies no tiles.
- South not defined; `copy_north_to_south` + mirror for orientations.
- [D] `locked_to_wall` forces orientation: north wall → east, west wall → north.

## 3. Animations — Documented fact
- op_sink1 `idle` north=2354 (south copied); `usage` north Surgeon `in_use=2362` (south copied).
- op_sink2 `idle` north=2358 (south copied); no usage anims (slave).
- Both `ticks=false`, no crashed/smoke — Objects, not Machines.

## 4. Master-slave mechanics — Documented fact
- [D] decl: `op_sink1.slave_id="op_sink2"`; per-orient `slave_position` north `{0,-1}`, east `{-1,0}`.
- [D] mixin: `OperatingSink:slaveMixinClass()` → `Object.slaveMixinClass` (same as operating_table).
- [D] create: ctor offsets by `slave_position`, `newObject(slave_id)` + `slave.master=self` (`object.lua:118-131`).
- [D] move: `setTile` override re-tiles slave (`object.lua:167-183`).
- [D] destroy: `onDestroy` destroys slave first (`object.lua:161-166`).
- [D] orient-sync: `initOrientation` + `finalize`; slave `idle` anim 2358 / mirror fallback.
- [D] event-redirect: slave→master click/info; slave hidden from lists (`world.lua:2455`).
- [D] `walk_in_to_use=true` (master only) — repair path.

## 5. Room + costs
- [D] `operating_theatre.lua:30-35`: needs `op_sink1=1`; level_id=10 Cost 2250; min 6; 2×Surgeon; preview 5080.
- [D] Cost 50 each (`base_config.lua:253-254`); purchasable (StartAvail=1).
- [I] Sinks auto-placed via `locked_to_wall`; orientation tied to wall side.

## 6. Verdict + next
- FAIL(strict): no overlay, no soak. Minimal: not filed.
- Next: TH screenshot grid-overlay theatre north/east both orients; `original_cells` dump vs SAM; verify `locked_to_wall` logic vs vanilla; 5000-tick soak + save/load + `busted`/`luacheck`.