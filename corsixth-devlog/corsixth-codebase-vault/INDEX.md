# CorsixTH Codebase Study Index

> A structured study of the CorsixTH codebase — from repository structure to runtime behavior and individual features.

---

## 1. Study Overview

**Purpose:** Understand how CorsixTH works, from repository structure to runtime behavior and individual features.

**Project:** CorsixTH (open-source reimplementation of Theme Hospital)

**Primary questions:**
- How is the application structured?
- How do the major systems interact?
- How does the simulation work?
- How are entities represented?
- How does data flow through the system?
- Which architectural patterns are used?

---

## 2. Start Here

### Fundamentals

- [[CODEBASE_MAP]] — Master map of entire codebase
- [[CODEBASE_INSIGHTS]] — Architectural patterns and insights
- [[CLASS_MAPPING]] — 195 classes across 10 categories
- [[world-entity-flow]] — World → Entity lifecycle (includes flush point details)
- [[save-load-migrations]] — Save/load architecture

### Core Concepts

- [[01-entity-iteration/SUMMARY]] — Entity loop, deferred destruction
- [[02-class-hierarchy/SUMMARY]] — Lua class system
- [[03-room-lifecycle/SUMMARY]] — Room build/use/destroy
- [[04-patient-lifecycle/SUMMARY]] — Patient spawn/care/cure
- [[12-saveload-migrations/SUMMARY]] — Save/load version gates

---

## 3. Architecture

- [[world-entity-flow]] — World → Entity lifecycle (includes flush point details)
- [[save-load-migrations]] — Save/load architecture
- [[entity-action-system]] — Action dispatch patterns
- [[room-hospital-hierarchy]] — Room → Hospital ownership chain
- [[ui-dialog-hierarchy]] — UI widget tree
- [[performance]] — Tracy profiling, optimization

### Major Systems

- [[03-room-lifecycle/SUMMARY]] — Rooms
- [[04-patient-lifecycle/SUMMARY]] — Patients
- [[05-staff-training/SUMMARY]] — Staff
- [[17-ui-system/SUMMARY]] — UI
- [[15-calls-dispatcher/SUMMARY]] — Event dispatch

---

## 4. Subsystems (26 Areas)

### Simulation Core

| Area | Status | Summary |
|------|--------|---------|
| [[01-entity-iteration/SUMMARY]] | Complete | Entity iteration, deferred destruction, #1467 fix |
| [[02-class-hierarchy/SUMMARY]] | Complete | 10 class categories, 195 classes, inheritance |
| [[06-queue-management/SUMMARY]] | Complete | Patient queuing, priority, room entry |
| [[15-calls-dispatcher/SUMMARY]] | Complete | Priority-based job dispatch, 5 call types |

### Hospital Management

| Area | Status | Summary |
|------|--------|---------|
| [[03-room-lifecycle/SUMMARY]] | Complete | Room build/use/destroy lifecycle |
| [[07-financial-system/SUMMARY]] | Complete | Income, expenses, balance tracking |
| [[08-reputation-system/SUMMARY]] | Complete | Hospital reputation, awards, leagues |
| [[09-research-tree/SUMMARY]] | Complete | Research points, unlockable items |

### People

| Area | Status | Summary |
|------|--------|---------|
| [[04-patient-lifecycle/SUMMARY]] | Complete | Patient spawn → treatment → cure/death |
| [[05-staff-training/SUMMARY]] | Complete | Staff skills, training, level progression |
| [[10-emergency-system/SUMMARY]] | Complete | Emergency events, helicopter, timers |
| [[11-epidemic-system/SUMMARY]] | Complete | Contagious outbreaks, vaccination, cover-up |

### World & Objects

| Area | Status | Summary |
|------|--------|---------|
| [[16-object-placement/SUMMARY]] | Complete | Footprints, orientations, master-slave |
| [[14-heating-system/SUMMARY]] | Complete | Boiler, radiators, costs, disasters |
| [[13-data-formats/SUMMARY]] | Complete | Disease/room/object schemas |

### Infrastructure

| Area | Status | Summary |
|------|--------|---------|
| [[12-saveload-migrations/SUMMARY]] | Complete | Two-layer persistence, 73 afterLoad classes |
| [[17-ui-system/SUMMARY]] | Complete | Window/widget framework, GameUI, dialogs |
| [[18-cpp-bindings/SUMMARY]] | Complete | Lua/C++ binding infrastructure, luaT templates |
| [[20-cicd-pipeline/SUMMARY]] | Complete | GitHub Actions, AppVeyor, 9 linters |

### Graphics & Audio

| Area | Status | Summary |
|------|--------|---------|
| [[19-animation-graphics/SUMMARY]] | Complete | Lua Graphics class, sprite sheets, palettes |
| [[22-animation-sprite/SUMMARY]] | Complete | C++ sprite/bitmap/palette/animation classes |
| [[23-map-tile/SUMMARY]] | Complete | Dual-layer C++/Lua map architecture |
| [[24-audio-system/SUMMARY]] | Complete | Two-layer audio: Lua Audio + C++ sound_player |

### Pathfinding & Config

| Area | Status | Summary |
|------|--------|---------|
| [[21-pathfinding/SUMMARY]] | Complete | A* with 4 finder types, min-heap, dirty list |
| [[25-localization-strings/SUMMARY]] | Complete | String loading, UTF-8/CP437, CJK, FreeType |
| [[26-config-settings/SUMMARY]] | Complete | config_finder.lua + base_config.lua |

---

## 5. C++ Engine Deep Dives

### Completed

| Area | Status | Summary |
|------|--------|---------|
| [[audio-system/SUMMARY]] | Complete | sound_archive, sound_player, SDL_mixer |
| [[persistence-binary/SUMMARY]] | Complete | lua_persist, zigzag encoding, permanent objects |
| [[iso-filesystem/SUMMARY]] | Complete | ISO 9660 parser for TH .iso images |

### Planned

| Area | Status | Summary |
|------|--------|---------|
| [[core-graphics/SUMMARY]] | Planned | Sprite sheets, animations, fonts, particles |
| [[sdl2-backend/SUMMARY]] | Planned | SDL2 rendering, OpenGL, shaders |
| [[midi-xmi/SUMMARY]] | Planned | XMI→MIDI conversion, device management |
| [[world-to-screen/SUMMARY]] | Planned | Coordinate systems, camera, tile rendering |
| [[entity-rendering/SUMMARY]] | Planned | Entity drawing pipeline, layers, animation states |

---

## 6. Data Formats

- [[MASTER_CROSSREF]] — Disease ↔ Room ↔ Object cross-reference matrix
- [[diseases/CATALOG]] — 34 disease definitions
- [[rooms/CATALOG]] — 23 room definitions
- [[objects/CATALOG]] — 62 objects (41 base + 15 machines + 4 doors + 2 other)
- [[walls/CATALOG]] — 5 wall types
- [[level-config/CATALOG]] — 13 town configs, difficulty settings

---

## 7. Investigations

### Bug Patterns

- [[BUG_PATTERN_CATALOG]] — 15 bug patterns with root causes, fixes, prevention
- [[safe-fix-patterns]] — Anti-patterns and safe fix templates

### Test Coverage

- [[coverage-dashboard]] — Busted coverage by subsystem, gap analysis
- [[regression-index]] — Bug → Test → Source mapping
- [[TEST_IMPLEMENTATIONS]] — Test file inventory

### Open Questions

- [[open-issues]] — TODOs/FIXMEs from source code
- [[code-refs]] — Cross-references to specific code locations

---

## 8. PR Tracking

| PR | Status | Topic |
|----|--------|-------|
| [[PR-3504-entity-destruction]] | In Review | Deferred entity destruction, #1467 fix |
| [[PR-3494-docs-links]] | Merged | Broken Lua docs links, LDocGen |
| [[PR-3372-pickup-destroy]] | Backlog | Entity destruction on pickup |
| [[PR-2469-mouse-panning]] | Backlog | Right-click panning + object placement |
| [[PR-1738-handyman-plants]] | Backlog | Handyman plant watering |

---

## 9. Study Logs

| Date | Topic |
|------|-------|
| [[2026-08-27-github-contributions-study]] | Study on GitHub contribution quality improvement practices |
| [[2026-08-20-cleaner-pattern]] | Cleaner pattern for #1467, afterLoad init, SAVEGAME_VERSION bump |
| [[2026-08-16-movie-blocker]] | Deferred-destruction validation, movie blocker smoketest fix |
| [[2026-08-12-entity-loop]] | Deferred-destruction fix, old-savegame crash, plant branch hole |
| [[2026-08-11-first-pr]] | Dev env setup, #1793 root-cause, LDocGen fix, PR #3494 |

---

## 10. Status Dashboard

### Subsystems (26/26 Complete)

| # | Area | Status |
|---|------|--------|
| 01 | entity-iteration | Complete |
| 02 | class-hierarchy | Complete |
| 03 | room-lifecycle | Complete |
| 04 | patient-lifecycle | Complete |
| 05 | staff-training | Complete |
| 06 | queue-management | Complete |
| 07 | financial-system | Complete |
| 08 | reputation-system | Complete |
| 09 | research-tree | Complete |
| 10 | emergency-system | Complete |
| 11 | epidemic-system | Complete |
| 12 | saveload-migrations | Complete |
| 13 | data-formats | Complete |
| 14 | heating-system | Complete |
| 15 | calls-dispatcher | Complete |
| 16 | object-placement | Complete |
| 17 | ui-system | Complete |
| 18 | cpp-bindings | Complete |
| 19 | animation-graphics | Complete |
| 20 | cicd-pipeline | Complete |
| 21 | pathfinding | Complete |
| 22 | animation-sprite | Complete |
| 23 | map-tile | Complete |
| 24 | audio-system | Complete |
| 25 | localization-strings | Complete |
| 26 | config-settings | Complete |

### C++ Engine (3/8 Complete)

| Area | Status |
|------|--------|
| audio-system | Complete |
| persistence-binary | Complete |
| iso-filesystem | Complete |
| core-graphics | Planned |
| sdl2-backend | Planned |
| midi-xmi | Planned |
| world-to-screen | Planned |
| entity-rendering | Planned |

### Data Formats (5/5 Complete)

| Catalog | Status |
|---------|--------|
| diseases | Complete |
| rooms | Complete |
| objects | Complete |
| walls | Complete |
| level-config | Complete |

---

## 11. Source Code References

When documenting code, always include:
- Repository: CorsixTH/CorsixTH
- File path: `CorsixTH/Lua/...` or `CorsixTH/Src/...`
- Class/function
- Relevant line range
- Git commit when relevant

Example: `CorsixTH/Lua/world.lua:1877` → [[01-entity-iteration/MAP]]

---

## 12. Vault Structure

```
corsixth-codebase-vault/
├── 00-META/              # Index, tags, templates
├── 01-CORE/              # Core reference documents
├── 02-SUBSYSTEMS/        # 26 subsystem areas (4 files each)
├── 03-CPP-ENGINE/        # C++ engine deep dives (5 files each)
├── 04-ARCHITECTURE/      # Cross-cutting architecture docs
├── 05-DATA-FORMATS/      # Data catalogs + cross-reference matrix
├── 06-PR-TRACKING/       # PR analysis and tracking
├── 07-STUDY-LOG/         # Daily study session logs
├── 08-QUERIES/           # Bug patterns, coverage, dashboards
└── 09-KANBAN/            # Visual kanban board (Obsidian canvas)
```

**Total:** ~181 markdown files | ~50,000 lines of documentation

---

## Related Pages

- [[tags]]
- [[index|Back to top]]
