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

## Spark track test results (2026-09-21, branch fix/3331-walk-gate, uncommitted)

Implemented the proposed 4 line Lua change on a master based branch
(walk.lua only, luacheck 0 warnings 0 errors with repo config).
Temporary WALK_REPATH prints proved the new branch fires exactly in
the covered plus wall ahead case (1 firing in 100 ticks), then removed.
Same scenario on pristine Lua prints 3 walk onto blocked attempts.

- Blueprint drop test (cover 3x3 mid walk, 3441.sav Doctor): 0 wall
  entries in 100 and 400 tick soaks, run completes, no hang.
- VIP bench escape rerun: same legal escape as baseline, 0 new
  violations, 500 ticks, no door crash this time.
- 3382 nurses rerun: identical to baseline (40 stationary on covered
  samples, no crash). 3404 rerun: 0 bad, clean.
- Residual risk stands: a stuck humanoid repaths every tick (one A
  star each). Bounded and rare, tick counter guard possible.

## Failed lane coverage (2026-09-21, review plus test-writer subagents
unavailable in API sessions, covered manually)

Review lane (maintainer style): no blockers. Comments reference
(#3331) inline which matches the accepted GH number pattern from
PR 3526 review. Minimality holds, trimmed plus must_happen plus
door branch preserved, VIP crash proven independent (data issue:
VIP and others lack door anims). Possible asks: explain the one
unreproduced 22 minute stall in the PR body for transparency.

Test lane: no walk action specs exist in Luatest (only entity
creation specs like humanoid_spec, 4 tests). The gate lives in a
timer driven closure needing a full world plus map, so a busted
unit test would be mock scaffolding with little value and no
precedent. Headless traces (bench escape, blueprint drop,
VIP regression, nurse parity, full surround trap, soaks) are the
de facto verification for this area. Recommend citing them in
the PR body instead of a committed spec.

## Final verdicts (2026-09-22, dual model plus 3 reviewer lanes)

Spark plus Nemotron plus explore plus fixer tracks, unanimous SHIP
(the review and test-writer subagent types cannot run in API
sessions, both lanes covered manually instead). Truth table,
stuck trace, storm cost (surrounded failure is O(1), no guard
needed), lint parity, and full matrix all green. Two latent C++
finds (object_visitor destination, idle promote order) filed as
out of scope, not bundled.

## Outreach (2026-09-21)

Posted intent plus direction question on #3331
(issuecomment-5766825188), asking Alberth and ARGAMX whether the
walk.lua recalc gate or the pathfinder side is the better place.
Waiting on reply before implementing. No fix code written.

## Adjacent latent find (not claimed)

Near tick 550 of the save 3 trace, the VIP routed through the
fracture_clinic door without door animations and errored at
`walk.lua:347`. Needs a clean repro before claiming it is a real
bug rather than fallout of the odd bench tile state.
