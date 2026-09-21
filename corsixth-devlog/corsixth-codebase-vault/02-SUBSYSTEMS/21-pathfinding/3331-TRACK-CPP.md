# 3331 C++ Track Result: no change needed (verify only)

> Executed in this session under the [[3331-TRACKS]] contract
> (C++ files only, no commits, no pushes, no comments).
> Repo state verified read only, zero C++ edits made.

## Related Pages

- [[3331-TRACKS]] — Shared contract plus Nemotron brief
- [[3331-WALL-WALKING-STUDY]] — Spark track study plus matrix
- [[MAP]] — Finder line index

## Code verification (master 8af1610a)

- All four finders (`basic`, `hospital`, `idle`, `object_visitor`)
  funnel neighbour recording through
  `record_neighbour_if_passable` (`th_pathfind.cpp:92`),
  which refuses unpassable neighbours unconditionally
  (218a9006, in master). No finder can emit a wall transiting
  route. There is no remaining start tile exemption to narrow.
- Fail clean path: empty heap returns false, `push_result`
  pushes nil plus "no path" (`th_pathfind.cpp:536`),
  Lua `getPath` returns nil, `action_walk_start`
  (walk.lua:419) idles and finishes. Verified in code.
- `hospital_finder` additionally refuses unpassable starts
  outright. Consistent with the contract.

## Live trap test (full surround, headless, Release)

- Doctor ringed fully (3x3 unpassable including center),
  walkTo ordered, 300 ticks: position static, 0 wall entries,
  ticks healthy, run completes. Action label oscillates
  walk/idle across samples as the queue retries, position
  never changes, no hang.
- Bench escape (study matrix): VIP leaves covered tile onto
  passable tiles, no punch. Escape path works live.

## Verdict

The C++ side already implements the narrowed behavior the
contract requires. No C++ change proposed. The remaining fix
is the Spark Lua recalc gate alone (branch fix/3331-walk-gate),
which relies on exactly the fail clean behavior verified here.
