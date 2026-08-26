---
date: 2026-08-12
tags: [study-log]
areas: [01-entity-iteration, 12-saveload-migrations]
prs: [3504, 3494]
---

# 2026-08-12 - Squeezing the entity-loop bug until it squeaked

## Goals
- [x] Implement deferred-destruction fix for #1467
- [x] Fix old-savegame crash
- [x] Fix plant branch hole
- [x] Negative control test

## What I Did
- Implemented deferred-destruction fix for #1467 (world.entities walked with ipairs while handlers destroy other entities)
- 86 unit tests green
- Headless and GUI smoke tests plus negative control
- Fixed old-savegame crash (deserialiser never re-runs constructors, leaving new queue missing)
- Fixed plant branch hole (end-of-day loop never set iterating marker for plants)
- Moved to full game data for reliable tests

## What I Learned
A regression test's job is to fail when the bug comes back; the negative control tells you it can. The tests that catch you are about old savegames and the code path nobody remembers.

## Feelings / notes
The skip-repro failing on cue is the closest thing a headless server has to a high five.

## Time Spent
- **Total:** ~3h

## Links
- Related PRs: [PR-3504](https://github.com/CorsixTH/CorsixTH/pull/3504), [PR-3494](https://github.com/CorsixTH/CorsixTH/pull/3494)


## Related Pages

- [[2026-08-11-first-pr]]
- [[2026-08-16-movie-blocker]]
- [[2026-08-20-cleaner-pattern]]
