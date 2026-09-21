# 3331 Dual Track Contract (Spark Lua plus Nemotron C++)

> Shared context for two parallel tracks on issue #3331. Read this
> plus [[3331-WALL-WALKING-STUDY]] before writing any code.
> Rules for both tracks: no GitHub comments, no commits, no pushes.
> Heavy VPS game runs are staggered, never parallel (2 threads).

## Semantic contract (both tracks must preserve)

- `findPath` from an unpassable start tile returns an escape path
  when any passable adjacent chain exists, else it fails cleanly.
  It never returns a path transiting through unpassable tiles.
- Walk side: repath on obstacle ahead regardless of current tile
  passability. On path failure the humanoid idles and the action
  finishes via existing `action_walk_start` (walk.lua:419-432).
- Shared acceptance test (trap scenario): a humanoid fully
  surrounded by unpassable tiles must idle in place. Never clip
  through walls, never hang the tick loop.

## Track assignments

- Spark branch `fix/3331-walk-gate`, Lua only:
  `humanoid_actions/walk.lua` recalc gate (`not_passable` plus
  inner passable wrapper, lines 196-238). Trap test plus matrix
  rerun on the three issue saves.
- Nemotron branch `fix/3331-path-exemption`, C++ only:
  narrow the start tile exemption in `th_pathfind.cpp`
  (record_neighbour_if_passable and callers). Exit unpassable
  start stays allowed, transit through unpassable stays refused,
  fail clean stays fail clean.

## Nemotron brief (paste into its session)

Goal: narrow the pathfinder start tile exemption for #3331 so a
humanoid standing on an unpassable tile can leave it but can never
route through other unpassable tiles (walls, objects).

Context: issue #3331 plus comments (ARGAMX root cause, Alberth
proposal, TheCycoONE stuck caveat), #3382 (recalc trigger), #3404
(avoid flag initiative, closed), merged PR #3340 (placement ban).
Vault: `02-SUBSYSTEMS/21-pathfinding/3331-WALL-WALKING-STUDY.md`
plus MAP and SUMMARY in the same folder. Current master already
has unconditional refuse (218a9006) and avoid_tile cost 128, both
verified in tree. Test saves on the VPS under
`game_data/saves3331/` (3331 VIP bench, 3382 blueprint nurse,
3404 toilet nurse). Full CD data at `game_data/HOSP`, config at
`/tmp/rle_save_test/config.txt`, pristine Release binary at
`~/CorsixTH/build_base/CorsixTH/corsix-th`.

Constraints: keep the contract above. Touch only
`th_pathfind.cpp`/`th_pathfind.h`. Do not change the save format,
the decoder, or Lua files (Spark owns those). Log findings in a
new vault note `21-pathfinding/3331-TRACK-CPP.md`. No GitHub
comments, no commits, no pushes. Coordinate heavy runs with the
Spark track, staggered not parallel.

Deliverable: minimal diff plus headless evidence (trap test plus
at least the 3331 bench save trace), then wait for cross review.
