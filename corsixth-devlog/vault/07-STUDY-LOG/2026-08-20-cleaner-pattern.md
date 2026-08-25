---
date: 2026-08-20
tags: [study-log]
areas: [01-entity-iteration, 12-saveload-migrations]
prs: [3504]
---

# 2026-08-20 - Cleaner pattern implemented, PR #3504 updated

## Goals
- [x] Implement cleaner pattern for #1467 fix
- [x] Remove lazy guards in destroyEntity and _flushDestroyedEntities
- [x] Add afterLoad initialization for entities_to_destroy
- [x] Bump SAVEGAME_VERSION to 265 with proper comment
- [x] Update tests to match new invariant

## What I Did
- Added `entities_to_destroy = {}` initialization in `World:afterLoad` for `old < 265`
- Bumped `SAVEGAME_VERSION` from 264 → 265 with comment "Deferred entity destruction fix"
- Removed lazy queue creation in `destroyEntity`
- Removed lazy guard in `_flushDestroyedEntities`
- Updated `world_spec.lua` tests to match new invariant (queue always exists)
- All 84 tests pass, luacheck clean, build succeeds
- CI running on PR #3504

## What I Learned
The save/load migration pattern in CorsixTH is well established — version gates in `afterLoad`, permanent object registration, permanent table inversion. Following it makes the fix feel native. The version bump (264→265) is the right signal for a savegame-invariant change, even though the lazy approach worked. Clean architecture pays off in review.

## Feelings / notes
The maintainer feedback (lewri) was spot on. The invariant approach is cleaner and matches how `object_counts`, `room_built`, bench count etc. are handled. Satisfying to see the queue become a true invariant.

## Time Spent
- **Start:** 9:01am
- **End:** 9:59am
- **Total:** 58 min

## Next Session
- [ ] Wait for lewri re-review on PR #3504
- [ ] Monitor CI results
- [ ] Start work on #3372 (pickup destroy)

## Links
- Related PRs: [PR-3504](https://github.com/CorsixTH/CorsixTH/pull/3504)
- Code refs: `world.lua:destroyEntity`, `world.lua:_flushDestroyedEntities`, `world.lua:afterLoad`
