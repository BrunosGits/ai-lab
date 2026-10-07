# Swing door right — thob 53 — vanilla-parity deep note

See also: Door-object-deep.md (thob 3 base door). Pair: Swing-door-left-object-deep.md (thob 52 slave).

## 1. CorsixTH definition — Documented fact
- `CorsixTH/Lua/objects/doors/swing_door_right.lua:22`: `id="swing_door_right"`, `:23` `thob=53`, `:26` `class="SwingDoor"`, `:27` `ticks=false`.
- `:28-31` `idle_animations` north=2006, west commented out (`--west=2050,--1998`). West falls back to north+FlipHorizontal via `entities/object.lua:64-75`.
- `:33` `class "SwingDoor" (Door)`; `:36` local ref.
- `:38-46` ctor: `is_master=true`, `Door()` init, `paired=false`, `pairDoors(x,y)`, stash `old_anim/old_flags` (`:43-44`), persistable stub `:45` (savegame 181).
- `:52-62` master pairing: `getObject(x-1,y)` or `(x,y-1)` for `swing_door_left`; sets `slave.master=self`, `paired=true` both.
- `:78-90` `checkPaired` asserts (`:80-88`).
- `:93-113` master handles `onClick/updateDynamicInfo/getDynamicInfo` (slave delegates).
- `:120-149` swing: `swingSlave` 2032/2034; `swingDoors` triggers slave then timed master 2048/2052 (`:139-147`), `ticks=true` (`:148`).
- `:156-169` `swing`: `setAnimation`, timer `getAnimLength`, restore `old_anim/old_flags` (`:160`), `ticks=false`, master `removeUser` + `tryAdvanceQueue` (`:162-165`).
- `:171-188` `getWalkableTiles` (master only): west 2x3 `{{x-1,y-1},{x,y-1},{x-1,y},{x,y},{x-1,y+1},{x,y+1}}` (`:177-181`); else 3x2 (`:183-186`).
- `:190-207` `afterLoad` `<184` re-pair + `Door.afterLoad`.
- No `orientations`, no `use_position`, no `handyman_position`, no `supports_creation_for_map`.
- Same placement/rooms as left: `edit_room.lua:498-500,49,71,600,741,1340-1371`; `dna_fixer.lua:38`, `ward.lua:45`, `operating_theatre.lua:43`.

## 2. Original TH data — Documented fact unless noted
- `base_config.lua:273`: thob 53 `StartCost=0, StartAvail=1, StartStrength=10, AvailableForLevel=1` comment `53 Double Door Part #2`.
- `original_strings.lua:177`: `swing_door2=S[2][54]`; `:1823` `S[40][54], -- no description`.
- EXE/SAM/LUT/`original_cells`/screenshot status identical to thob 52 (no V).

## 3. Comparison verdict

| Attribute | CorsixTH | TH proxy | Verdict |
|---|---|---|---|
| thob 53 | `swing_door_right.lua:23` | `base_config.lua:273` | match (proxy; EXE pending) |
| cost 0 / strength 10 / avail | `base_config.lua:273` | same | match (proxy) |
| idle north 2006 (west missing) | `swing_door_right.lua:28-31` | no anim decode | unverified |
| master walkable 6 tiles | `swing_door_right.lua:171-188` | no EXE mask/overlay | unverified |
| swing 2032/34 + 2048/52 | `swing_door_right.lua:120-169` | no anim decode | unverified |
| queue advance on close | `swing_door_right.lua:162-165` | TH had room queues | Inference |
| west-missing fallback | `entities/object.lua:64-75` | unknown (comment hints cut anim) | unverified |

Inherits `Door` queue/flags/early_list — see Door-object-deep.md (`door.lua:40-50,56-136,150-208`).

## 4. Footprint-compare [Inference]
- Master-only 6-tile mask; west vs non-west split. `setTile` inherited from `Door` (`door.lua:99-136`): `doorNorth/tallNorth` or `doorWest/tallWest` + `buildable/doNotIdle` on all 6 walkables. Slave tile itself gets no independent flags (empty set).
- Commented `--west=2050,--1998` suggests abandoned west anim; current fallback may flip north incorrectly — needs anim-viewer check, not footprint change.

## 5. Fact vs Inference vs Hypothesis
- Fact: thob/cost/north anim/6-tile masks/swing anims/pairing/asserts/save stubs as cited.
- Inference: master-driven queue + 6-tile block models TH double door; west comment is leftover experiment.
- Hypothesis: 6-tile masks + flipped-north west anim equal vanilla (needs overlay + anim decode + disasm).

## 6. Strict / minimal + next + pass/fail
- PASS(strict): FAIL — no overlay, no soak. PASS(minimal): N/A (west-anim question is visual, not walk-through).
- Overall: UNVERIFIED (`[T+C]`, V pending).
- Next: anim-viewer 2006 vs 1998/2050; TH screenshot overlay both orients; `original_cells` vs SAM; disassemble thob-53; soak + save/load + `busted`/`luacheck`.
