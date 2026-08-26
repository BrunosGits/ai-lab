# CorsixTH Codebase Map

## Project Overview
- **Language**: Lua (primary), C++ (core engine)
- **Lines of Code**: ~131k lines across 298 Lua files
- **Test Framework**: Busted (via Luarocks)
- **Build System**: CMake with vcpkg

## Directory Structure

### Core Game Logic (`CorsixTH/Lua/`)
| Module | Files | Description |
|--------|-------|-------------|
| **app.lua** | 1 | Main application entry point |
| **world.lua** | 1 | World simulation, game loop |
| **hospital.lua** | 1 | Hospital management, buildings, rooms |
| **game_ui.lua** | 1 | Game UI, HUD, menus |
| **ui.lua** | 1 | Core UI components |
| **window.lua** | 1 | Window management |
| **graphics.lua** | 1 | Rendering, sprites, animations |
| **audio.lua** | 1 | Sound/music system |
| **map.lua** | 1 | Map generation, tiles |
| **entity.lua** | 1 | Base entity class |
| **entity_map.lua** | 1 | Entity spatial indexing |

### Entities (`CorsixTH/Lua/entities/`)
| File | Lines | Description |
|------|-------|-------------|
| **humanoid.lua** | ~48k | Patient/staff/visitor base logic |
| **machine.lua** | ~21k | Diagnostic/treatment machines |
| **object.lua** | ~37k | Furniture, decorations, objects |

#### Humanoids (`entities/humanoids/`)
- `staff/` - Doctor, nurse, handyman, receptionist
- `patients/` - Patient logic, diseases
- `vip.lua` - VIP visitors

#### Humanoid Actions (`humanoid_actions/`)
- `staff_*.lua` - Staff-specific behaviors
- `patient_*.lua` - Patient behaviors  
- `use_object.lua`, `pickup.lua`, `meander.lua`, etc.

### Diseases (`diseases/`)
34 disease definition files (e.g., `bloaty_head.lua`, `fractured_bones.lua`, `invisibility.lua`)

### Rooms (`rooms/`)
22 room types (GP, pharmacy, operating_theatre, ward, research, training, etc.)

### Objects (`objects/`)
40+ object types including machines, furniture, doors, decorations
- `machines/` - Diagnostic/treatment equipment
- `doors/` - Door variants

### Dialogs (`dialogs/`)
UI dialogs for rooms, staff, diseases, finances, etc.

### Diagnosis (`diagnosis/`)
Diagnostic logic per disease type

### Supporting Modules
| File | Description |
|------|-------------|
| `class.lua` | OOP class system |
| `utility.lua` | Helper functions |
| `strings.lua` | Localization strings |
| `config_finder.lua` | Config file discovery |
| `base_config.lua` | Default configuration |
| `persistance.lua` | Save/load system |
| `research_department.lua` | Research tree |
| `epidemic.lua` | Epidemic events |
| `earthquake.lua` | Disaster events |
| `endconditions.lua` | Level win/lose conditions |
| `staff_profile.lua` | Staff stats/skills |
| `announcer.lua` | In-game announcements |
| `queue.lua` | Queue management |
| `calls_dispatcher.lua` | Event dispatching |

## Test Structure (`CorsixTH/Luatest/spec/`)
Mirrors `Lua/` hierarchy with `_spec.lua` suffix:
- `world_spec.lua` - World simulation tests
- `entities/humanoid_spec.lua` - Humanoid tests
- `entities/humanoids/staff/doctor_spec.lua` - Staff tests
- `dialogs/bottom_panel_spec.lua` - UI tests
- `utility_spec.lua`, `date_spec.lua`, `class_spec.lua`

## Key Architectural Patterns
1. **Class-based OOP** via `class.lua` (single inheritance, mixins)
2. **Entity-Component** style: Entities have behaviors via action modules
3. **Event-driven**: `calls_dispatcher` for cross-system communication
4. **Data-driven**: Diseases, rooms, objects defined in data files
5. **State machines**: Humanoid actions implement state-based behavior

## Running Tests
```bash
cd CorsixTH/Luatest
busted --lpath=../Lua/?.lua
```

## Building
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

## Risk Areas for Changes
| Area | Risk | Notes |
|------|------|-------|
| `humanoid.lua` | HIGH | Core logic, touches everything |
| `world.lua` | HIGH | Game loop, simulation |
| `hospital.lua` | HIGH | Room/building management |
| `entity.lua` | MEDIUM | Base entity behavior |
| `room.lua` | MEDIUM | Room logic shared by all rooms |
| Specific disease/room files | LOW | Isolated functionality |

## Recommended Workflow for Minimal Changes
1. **Identify exact bug** - Reproduce first
2. **Find minimal fix location** - Use grep to trace related code
3. **Write failing test** - In corresponding `_spec.lua`
4. **Apply minimal fix** - Change only what's necessary
5. **Run full test suite** - Ensure no regressions
6. **Manual test** - Verify in-game behavior


## Related Pages

- [[CLASS_MAPPING]]
- [[CODEBASE_INSIGHTS]]
- [[TEST_IMPLEMENTATIONS]]
- [[safe-fix-patterns]]
