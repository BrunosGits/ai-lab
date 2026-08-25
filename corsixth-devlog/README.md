# CorsixTH Contributions

A record of my journey contributing to CorsixTH, the open source reimplementation
of the 1997 Bullfrog game Theme Hospital: understanding a codebase with Lua game
logic on a C++ engine, finding issues, sending patches and learning how a large
open source project actually works.

## Progress

- **#1793** (broken Lua docs links): Fixed missing `TheMoviePlayer:play()` documentation that caused Lua syntax errors when referencing the movie player API. Updated `src/script/api.lua` to properly expose `play()`, `stop()`, `isPlaying()`, and `setVolume()` methods. Verified with demo and full game data across all test modes.
- **#1467** (entities table modified inside an `ipairs` loop): Fixed unsafe iteration over `world.entities` during entity destruction. Implemented cleaner pattern using deferred destruction: entities are flagged for deletion in `Entity:_deleteLater()` and actually removed in `World:_flushDestroyedEntities()` during `World:afterLoad()` or via `v265` heartbeat. Tested extensively across all four test configurations (demo/full game × graphical/headless).
- **#3372** (properly destroy entities on pickup again): Active work-in-progress. Designing snapshot-and-destroy mechanism with tile reservation system to prevent race conditions during entity pickup. Will reuse the deferred-destruction machinery from #1467. Implementation pending.
- **#2469** (right-mouse panning glitches) and **#1738** (handymen watering plants in benches): Queued for investigation after #3372 completion. Preliminary analysis suggests #2469 involves camera boundary checks in `ViewManager:update()`, while #1738 relates to tile validity checks in handyman job scheduling.

## Environment & Testing Strategy

Building, unit tests and smoke runs happen on the VPS with Theme Hospital data. The test matrix validates functionality across:

| Test Dimension | Options | Details |
|----------------|---------|---------|
| **Data Source** | Demo data (included) \| Full game (legal copy) | Demo data provides baseline; full game tests with all 22 rooms, epidemics, and edge cases |
| **Execution Mode** | Graphical (xvfb) \| Headless (`SDL_VIDEODRIVER=offscreen`) | Graphical for visual validation; headless for faster CI runs |
| **Test Type** | Unit tests \| Smoke tests \| CI pipelines | Unit tests via `lua src/test/`, smoke via `./corsixth --smoketest`, CI via GitHub Actions |

### Smoke Test Enhancements
- `TheApp.moviePlayer:stop()` prevents intro movie from blocking `World:onTick` during automated runs
- `SMOKE_HEARTBEAT=1` enables JSONL telemetry output for CI observability and performance tracking
- Control runs validate baseline behavior before/after changes
- All PRs tested across 4x2 = 8 test configurations minimum

## License

MIT
