---
pr: 3331
title: "Humanoids can walk through walls"
status: draft
branch: fix/3331-walk-gate
base: master
repo: CorsixTH/CorsixTH
created: 2026-04-29
updated: 2026-09-22
pr_number: 3556
labels: [P4 Low, walk, pathfinding]
reviewers: []
related_areas: [21-pathfinding, 03-room-lifecycle]
---

# PR 3331: Humanoids can walk through walls — Draft 3556

## Summary
Repath on obstacle ahead even from unpassable tiles. Two small
changes in `action_walk_tick` (walk.lua plus 12 minus 12):
`not_passable` drops the here passable requirement, and the repath
branch always stops and calls `on_restart`. No C++ change, no save
change. Stuck case fails into existing idle plus finish.

## Status
Draft PR #3556 opened 2026-09-22 (commit 01e9187d). Reply posted
on #3331 with the analysis below. Awaiting maintainer direction:
rebase onto #3489 or standalone.

## Landscape
- Open PR #3489 (ARGAMX) widens detection with a per step
  connectivity check but keeps the covered stance gate, so the
  bench case stays open. Stalled waiting on #3465 C++ helper.
  Reviewers already flagged the per step distance cost.
- Ours is the complementary half: covered stance repath with
  zero extra per step cost. Combined they cover everything.
- Related: #3382 (recalc trigger), #3404 (avoid flag, closed),
  merged PR #3340 (placement ban).

## Test
- Temporary prints: new branch fires exactly once in 100 ticks
  covered plus wall ahead. Pristine prints 3 walk onto blocked.
- VIP bench escape, 3382 and 3404 nurse traces, full surround
  trap (300 ticks static, no entry), 100 and 400 tick soaks.
- luacheck 0/0 with repo config. Dual model verdict: SHIP,
  unanimous (Spark plus Nemotron plus 3 reviewer lanes).

## Links
- Issue https://github.com/CorsixTH/CorsixTH/issues/3331
- PR https://github.com/CorsixTH/CorsixTH/pull/3556 (draft)
- Vault: [[02-SUBSYSTEMS/21-pathfinding/3331-WALL-WALKING-STUDY]]


## Related Pages

- [[PR-3372-pickup-destroy]]
- [[PR-3545-rle-encoder]]
- [[PR-3504-entity-destruction]]
