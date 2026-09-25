# Operating Table Object Deep — master (thob 30) + slave (thob 12)

Legend: [D]=Documented fact (read), [I]=Inference (code-derived), [H]=Hypothesis (needs vanilla proof). Method: VANILLA_METHOD.

## 1. Identity
- [D] Master `Lua/objects/machines/operating_table.lua:22-25`: id=`operating_table`, slave_id=`operating_table_b`, class=`OperatingTable`, thob=30.
- [D] Slave `Lua/objects/machines/operating_table_b.lua:22-24`: id=`operating_table_b`, class=`OperatingTable`, thob=12.
- [D] Master `:26-27` cure, fallback=19 (kidney beans: `diseases/kidney_beans.lua:23,62-64`).
- [D] Both `ticks=false`; both `show_in_town_map=true`.
- [D] Master `default_strength=8` (`:32`), crashed 3392 (`:33`), smoke 3472 (`:35`). Slave crashed=0 (no smoke/strength).
- [D] `base_config.lua:250` thob30 `Cost 5000 Avail 0 Strength 12`; `:232` thob12 `Cost 5` = "Build Room Trestle Table". [I] thob12 row is a build-room trestle, not a surgical slave — vanilla meaning unproven.
- [D] `HOSPITAL.EXE` present but not disassembled; no screenshot/save for this pair (W2 [T+C] only).

## 2. Footprints (pre-shift, as written)
- [D] Master north (`:98-103`): passable `{-2,-1}`, `{-1,-2}`, `{1,-1}`; solid `{-1,-1}`, `{0,-1}`, `{0,-2}`, `{1,0}`, `{1,-2}` (8 entries, 5 solid).
- [D] Master east (`:111-115`): passable `{-1,-2}`, `{-2,-1}`, `{-1,1}`; solid `{-1,-1}`, `{-1,0}`, `{-2,0}`, `{0,1}`, `{-2,1}`, `{0,0}` bare (9 entries, 6 solid).
- [D] South=north via `copy_north_to_south`; east/west via mirror.
- [D] Slave (`operating_table_b.lua:55-64`): north + east `footprint={}`, `use_position={0,0}` — occupies no tiles.
- [I] Post-shift (computed): north use `{-1,-2}`→`{0,-1}`, slave `{1,-1}`→`{2,0}`; east use `{-2,-1}`→`{-1,0}`, slave `{-1,1}`→`{0,2}`.
- [H] East `{0,0}` bare-solid has no north counterpart — intentional vs drift. Do not "fix" before vanilla overlay.

## 3. Use / repair / smoke
- [D] North use `{-1,-2}`, secondary `{-2,-1}`; east swapped. All `only_passable` tiles in own footprint.
- [D] Repair tile = use tile (post-shift north `{0,-1}`, east `{-1,0}`) via `object.lua:956-958` + `machine.lua:564-586,290-293` [I].
- [D] Smoke `{0,0}` both orients → post-shift `{1,1}` [I].
- [D] Slave `use {0,0}` = own tile; room walks surgeon2 to it (`rooms/operating_theatre.lua:293,334`).

## 4. Master-slave mechanics
- [D] decl: `slave_id` + per-orient `slave_position` north `{1,-1}` (`:105`), east `{-1,1}` (`:117`).
- [D] mixin: `OperatingTable(Machine)` → `Machine.slaveMixinClass` → `Object.slaveMixinClass`.
- [D] create: ctor offsets by `slave_position`, `newObject(slave_id)` + `slave.master=self` (`object.lua:118-131`).
- [D] move: `setTile` override re-tiles slave (`object.lua:167-183`).
- [D] destroy: `onDestroy` destroys slave first (`object.lua:161-166`); `Machine:onDestroy` clears repair/smoke.
- [D] orient-sync: `master_to_slave initOrientation` + `finalize`, `setCrashedAnimation`; slave anim 2310 / mirror fallback.
- [D] event-redirect: slave→master click/info/repair; master→slave above; slave hidden from lists (`world.lua:2455`, `machine_dialog.lua:145`).
- [D] wear guard: `OperatingTable:machineUsed` only if `not self.master` — prevents double-count/explosion from slave [I].
- [D] 4 dirs covered by 2 defs + copy + mirror [I].

## 5. Room + costs
- [D] `rooms/operating_theatre.lua:30-35` needs `operating_table=1`; level_id=10 matches `base_config.lua:290` Cost 2250; min 6; 2×Surgeon; preview 5080 = master `:31`.
- [D] Two-surgeon sync: action1 on master, action2 on slave; patient via `getSecondaryUsageTile`.
- [D] Cost mismatch: base Strength 12 vs Lua `default_strength` 8 [H — needs EXE + research check].

## 6. Verdict + next
- FAIL(strict): no overlay, east `{0,0}` asymmetry unresolved, soak/tests pending. Minimal: not filed. W2 pending [T+C].
- Next: decode EXE thob 30/12; SAM overlay; resolve asymmetry + strength 8/12; in-game place/walk/rotate/destroy/crash/save-load; 5000-tick soak + `busted` + `luacheck`.
