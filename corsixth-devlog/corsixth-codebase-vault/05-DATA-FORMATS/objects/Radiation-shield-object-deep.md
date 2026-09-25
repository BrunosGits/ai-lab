# Radiation Shield Object Deep — master (thob 28) + slave (thob 28b)

Legend: [D]=Documented fact, [I]=Inference, [H]=Hypothesis. Master-slave pair.

## 1. Identity
- [D] `radiation_shield.lua:22`: `id="radiation_shield"`, slave_id=`radiation_shield_b`, class=`RadiationShield`, thob=28.
- [D] `radiation_shield.lua:27-30`: `ticks=true`, `build_preview_animation=922`, `show_in_town_map=true`.
- [D] `radiation_shield_b` not found as separate file — slave class same `RadiationShield`, thob presumably 28 (same) or implicit; code uses `slaveMixinClass` but no `slave_id` check for different thob.
- [D] `base_config.lua:248`: thob 28 row: `StartCost=2000, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `28 Radiation Shield`.
- [D] `x_ray_room.lua:30`: `objects_needed={x_ray=1, radiation_shield=1}` — paired with x_ray machine.

## 2. Footprints & orientations — Documented fact
- Master north (`:47-55`): 9-tile footprint `{-2,-1},{-1,-1},{0,-1},{-2,0},{-1,0},{0,0 only_passable},{-2,1},{-1,1},{0,1}`, `render_attach_position={0,-1}`, `use_position={0,0}`.
- Master east (`:57-65`): 9-tile footprint `{-1,-2},{0,-2},{1,-2},{-1,-1},{0,-1},{1,-1},{-1,0},{0,0 only_passable},{1,0}`, `render_attach_position={0,-1}`, `use_position={0,0}`.
- `use_position={0,0}` on `only_passable` tile in both orients; `render_attach` one tile above.
- No explicit `slave_position` — slave class same, likely shares footprint logic but `footprint={}` as slave (cf. operating_table_b).
- South copied for idle; east explicit; west/south via mirror.

## 3. Animations — Documented fact
- Idle north=794 (console anims reused); south copied.
- Usage: Doctor `begin_use=798` (sits), `begin_use_2=806` (pulls handle), `in_use={810 idle,814 buttons}`, `finish_use=802` (stands) — identical to console (thob 15).
- `ticks=true` (unlike x_ray machine which is false).

## 4. Master-slave mechanics — Documented fact + Inference
- [D] decl: `slave_id="radiation_shield_b"`; `RadiationShield:slaveMixinClass()`.
- [I] Slave file not found; likely same thob 28 with empty footprint (cf. `op_sink2`, `operating_table_b`).
- [D] create/move/destroy/orient-sync/redirect same pattern as operating_table (via `slaveMixinClass`).
- [I] Slave hidden from lists (`world.lua:2455`); event-redirect to master.
- [I] Paired with x_ray machine in room; doctor uses shield console while patient in x_ray.

## 5. Room + costs
- [D] `x_ray_room.lua:30`: `objects_needed={x_ray=1, radiation_shield=1}`; level_id=16 Cost 4000; min 6; Doctor=1; preview 5076.
- [D] Cost 2000 / strength 10; purchasable (StartAvail=1).
- [I] Shield console positioned by `locked_to_wall`? Not present — free placement.

## 6. Verdict + next
- FAIL(strict): no overlay, slave file missing from repo, no soak. Minimal: not filed.
- Next: find/verify `radiation_shield_b` file or confirm implicit; TH screenshot grid-overlay x-ray room both orients; `original_cells` dump vs SAM; verify slave creation + event redirect; 5000-tick soak + save/load + `busted`/`luacheck`.