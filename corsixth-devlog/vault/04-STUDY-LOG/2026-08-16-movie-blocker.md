---
date: 2026-08-16
tags: [study-log]
areas: [01-entity-iteration, 12-saveload-migrations]
prs: [3504]
---

# 2026-08-16 - The fix that held, and the movie that blocked the test

## Goals
- [x] Validate deferred-destruction fix for #1467 on full game data
- [x] Fix smoketest intro-movie blocker
- [x] Full matrix pass

## What I Did
- Validated the deferred-destruction fix for #1467 on full game data (offscreen, xvfb, demo)
- Fixed smoketest intro-movie blocker with `TheApp.moviePlayer:stop()`
- Added JSONL heartbeat telemetry to smoketest
- Full matrix pass: offscreen (3/3), xvfb (3/3), demo control (2/2) all green
- luacheck clean (297 files), 86/86 unit tests pass
- Negative control confirmed bug reproduction

## What I Learned
A timeout with no output is usually pipe buffering, not a hang. Add heartbeats. And always check whether the game is actually running its tick loop — intro movies, paused states, and menu loops will silently skip it.

## Feelings / notes
The negative control failing on cue (dummy C was skipped) is still the best confirmation a fix works.

## Time Spent
- **Start:** 
- **End:** 
- **Total:** ~2h

## Next Session
- [ ] Clean up fork and create clean PR
- [ ] Address maintainer feedback

## Links
- Related PRs: [PR-3504](https://github.com/CorsixTH/CorsixTH/pull/3504)
