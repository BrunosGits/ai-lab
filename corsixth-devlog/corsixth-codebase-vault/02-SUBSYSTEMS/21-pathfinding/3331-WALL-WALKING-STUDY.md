# 3331 Wall Walking Study (pre fix, no code changed)

> Headless study on current master (8af1610a) covering #3331 plus
> #3340 (merged), #3382 and #3404 (both closed). No GitHub comments
> posted. Saves held on the VPS under `game_data/saves3331/`.

## Related Pages

- [[SUMMARY]] — Map persist layout, dual layer map
- [[MAP]] — File line index (pathfinder, walk action)
- [[CHECKLIST]]

## What already landed in master

- Unconditional refuse in `record_neighbour_if_passable`
  (`th_pathfind.cpp:97`, commit 218a9006, Alberth, Jun 20).
  A humanoid starting on an unpassable tile can still step onto
  passable neighbours, but never transit through unpassable ones.
- `avoid_tile` flag plus cost 128 (`th_map.h:141,165`,
  `th_pathfind.cpp:109`), used on room build.
- #3340 placement ban merged May 19 (`UIPlaceObjects:onMouseUp`
  refuses humanoid occupied tiles).
- `edit_room.lua:908` re-enables passable flags after
  `checkReachability()`.

## The hole still open

`humanoid_actions/walk.lua:196-232`. The repath branch requires
the current tile to be passable twice over: `not_passable` is
`here.passable and not there.passable`, and the branch itself is
wrapped in `if current tile passable`. Standing covered with a
wall ahead walks the stale path straight through it.

## Proposed solution (not implemented)

- `not_passable` becomes `(not flags_there.passable)`. Only the
  covered plus wall ahead case changes behaviour.
- Drop the inner passable wrapper so obstacle ahead always stops
  and calls `on_restart` (repath from wherever it stands).
- Stuck case is covered by existing code: `action_walk_start`
  (walk.lua:424) sends a pathless humanoid to idle and finishes
  the action next tick. No crash, no wall transit.
- Residual risk: repeated repath attempts each tick while stuck.
  Bounded and rare, tick counter guard possible if review asks.

## Headless matrix (build_base binary, Release, full CD data)

| Save | Setup | Result on master |
|------|-------|------------------|
| 3331 save 3 (room plus bench) | VIP starts unpassable | Escapes to passable tiles, no wall punch in 525 ticks |
| 3331 save 1 (control) | Normal walk | Clean, 0 bad samples in 500 ticks |
| 3382 save 2 (blueprint state) | 15 nurses | Nurses stand on covered tiles (precondition visible), no crossing observed as is |
| 3404 (pre setup) | 1 nurse | Clean wander, 0 bad samples in 800 ticks |

Full interactive repro of 3382 and 3404 needs UI build steps
(place blueprint, confirm, unpause). Left for the fix phase.

## Adjacent latent find (not claimed)

Near tick 550 of the save 3 trace, the VIP routed through the
fracture_clinic door without door animations and errored at
`walk.lua:347`. Needs a clean repro before claiming it is a real
bug rather than fallout of the odd bench tile state.
