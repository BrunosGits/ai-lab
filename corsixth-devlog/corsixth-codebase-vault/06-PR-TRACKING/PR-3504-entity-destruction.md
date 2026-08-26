---
pr: 3504
title: "Fix #1467: Deferred entity destruction to prevent iteration skip"
status: review
branch: fix-1467-clean
base: master
repo: CorsixTH/CorsixTH
created: 2026-08-18
updated: 2026-08-24
labels: [bug, entity-system, savegame]
reviewers: [TheCycoONE, lewri]
related_areas: [01-entity-iteration, 12-saveload-migrations]
---

# PR #3504: Fix #1467 - Deferred entity destruction to prevent iteration skip

## Summary
Deferred entity destruction to prevent iteration skip when `destroyEntity` is called during `ipairs` loop over `world.entities`.

## Changes
| File | Change |
|------|--------|
| `app.lua` | `SAVEGAME_VERSION` 264 → 265 (deferred entity destruction fix) |
| `world.lua` | `afterLoad` init `entities_to_destroy` for `old < 265` |
| `world.lua` | Removed lazy guards in `destroyEntity` & `_flushDestroyedEntities` |
| `world_spec.lua` | Removed 2 tests for old lazy behavior (84 tests) |

## Review Status
| Reviewer | Status | Notes |
|----------|--------|-------|
| TheCycoONE | ✅ APPROVED | |
| lewri | ⚠️ CHANGES_REQUESTED | Savegame bump line comment |

## CI Status
All checks passing (Linux Lua 5.1, LuaJIT, vcpkg Lua 5.5, Windows, AppVeyor).

## Discussion Highlights
- @TheCycoONE: "smoketest.lua is a new sort of thing... looks brittle"
- @lewri: "Iterating backwards is a good way to go" (validated approach)
- @lewri: "update the savegame bump line in app.lua" → **DONE**

## Next Steps
- [ ] Wait for lewri re-review
- [ ] Merge on approval


## Related Pages

- [[PR-1738-handyman-plants]]
- [[PR-2469-mouse-panning]]
- [[PR-3372-pickup-destroy]]
- [[PR-3494-docs-links]]
