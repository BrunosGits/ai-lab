---
pr: 3494
title: "Fix #1793: Broken Lua docs links on GitHub Pages"
status: merged
branch: fix-1793-lua-docs-links
base: master
repo: CorsixTH/CorsixTH
created: 2026-08-11
updated: 2026-08-11
labels: [docs, lua]
reviewers: [TheCycoONE]
related_areas: [17-ui-system, 18-cpp-bindings]
---

# PR #3494: Fix #1793 - Broken Lua docs links on GitHub Pages

## Summary
LDocGen generated class and index pages only, never a page per source file, while file-tree links pointed at pages that never existed.

## Changes
| File | Change |
|------|--------|
| `LDocGen/main.lua` | Added per-file page generation |
| `LDocGen/templates/file.htlua` | New template for file pages |
| `LDocGen/templates/lua_file_tree.htlua | Updated tree template |

/## Review Status
| Reviewer | Status | Notes |
|----------|--------|-------|
| TheCycoONE | ✅ APPROVED | |

/## CI Status
All checks passed.

## Next Steps*- [${] Merge complete