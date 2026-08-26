# CorsixTH Regression Test Index

> Bug ID → Test File → Source File mapping for regression tracking

---

## Related Pages

- [[performance]] — Tracy profiling and optimization
- [[safe-fix-patterns]] — Anti-patterns and fix templates
- [[coverage-dashboard]] — Coverage metrics and gaps

---

## Test File Summary

| Test File | Type | Tests | What It Tests |
|-----------|------|-------|---------------|
| `Luatest/spec/class_spec.lua` | Unit | 6 | Class instantiation, inheritance, type system |
| `Luatest/spec/date_spec.lua` | Unit | 17 | Date arithmetic, comparisons, edge cases |
| `Luatest/spec/utility_spec.lua` | Unit | 11 | Serialization, array_join, cycle detection |
| `Luatest/spec/announcer_spec.lua` | Unit | ~8 | Announcer queue logic |
| `Luatest/spec/entities/humanoid_spec.lua` | Unit | ~15 | Humanoid state, actions |
| `Luatest/spec/entities/humanoids/vip_spec.lua` | Unit | ~10 | VIP behavior |
| `Luatest/spec/entities/humanoids/staff/doctor_spec.lua` | Unit | ~12 | Doctor specialization |
| `Luatest/spec/entities/machine_spec.lua` | Unit | ~8 | Machine state, repairs |
| `Luatest/spec/entities/object_spec.lua` | Unit | ~10 | Object lifecycle |
| `Luatest/spec/dialogs/bottom_pannel_spec.lua` | Unit | ~6 | UI panel rendering |
| `CppTest/test_th_lua.cpp` | C++ Unit | ~20 | Lua binding correctness |
| `CppTest/test_th_lua_map.cpp` | C++ Unit | ~15 | Map loading, tile flags |
| `CppTest/test_th_lua_ui.cpp` | C++ Unit | ~12 | UI rendering, font metrics |
| `CppTest/test_th_strings.cpp` | C++ Unit | ~8 | String encoding, translation |

**Total:** ~148 test cases across 14 test files

---

## Bug Pattern → Test Coverage Matrix

| Bug Pattern | ID | Test File | Coverage Status |
|-------------|-----|-----------|-----------------|
| Entity Iteration Skip | BP-001 | `world_spec.lua` (23 tests) | ✅ Covered |
| Save/Load Migration Missing | BP-002 | None | ❌ Manual only |
| Room Crash Entity Leak | BP-003 | `world_spec.lua` (cascading) | ✅ Covered |
| Pathfinding Door Cross | BP-004 | None | ❌ Manual only |
| Queue Priority Inversion | BP-005 | `queue_spec.lua` | ⚠️ Partial |
| Modal Dialog Stack Leak | BP-006 | None | ❌ Manual only |
| Lua/C++ Boundary Nil | BP-007 | None | ❌ Manual only |
| Entity Double Destroy | BP-008 | `world_spec.lua` (idempotent) | ✅ Covered |
| Room State Inconsistency | BP-009 | None | ❌ Manual only |
| Deferred Destruction Leak | BP-010 | `world_spec.lua` (interrupt) | ✅ Covered |
| Animation Frame Overflow | BP-011 | None | ❌ Manual only |
| Sound Callback Leak | BP-012 | None | ❌ Manual only |
| String Proxy Encoding | BP-013 | None | ❌ Manual only |
| Config Migration Skip | BP-014 | None | ❌ Manual only |
| Modal Input Leak | BP-015 | None | ❌ Manual only |

---

## Test File → Source File Mapping

### Lua Unit Tests

| Test File | Source File | What It Tests |
|-----------|-------------|---------------|
| `class_spec.lua` | `Lua/class.lua` | OOP system |
| `date_spec.lua` | `Lua/date.lua` | Date arithmetic |
| `utility_spec.lua` | `Lua/utility.lua` | Serialization, helpers |
| `announcer_spec.lua` | `Lua/announcer.lua` | Announcement queue |
| `humanoid_spec.lua` | `Lua/entities/humanoid.lua` | Entity behavior |
| `vip_spec.lua` | `Lua/entities/humanoids/vip.lua` | VIP special logic |
| `doctor_spec.lua` | `Lua/entities/humanoids/staff/doctor.lua` | Doctor AI |
| `machine_spec.lua` | `Lua/entities/machine.lua` | Machine state |
| `object_spec.lua` | `Lua/entities/object.lua` | Object lifecycle |
| `bottom_pannel_spec.lua` | `Lua/dialogs/bottom_panel.lua` | UI panel |

### C++ Unit Tests

| Test File | Source File | What It Tests |
|-----------|-------------|---------------|
| `test_th_lua.cpp` | `Src/th_lua.cpp` | Lua binding layer |
| `test_th_lua_map.cpp` | `Src/th_map.cpp` | Map data structures |
| `test_th_lua_ui.cpp` | `Src/th_gfx_sdl.cpp` | Graphics rendering |
| `test_th_strings.cpp` | `Src/th_strings.cpp` | String handling |

---

## Source Files Without Tests

### High Priority (Critical Path)

| Source File | Subsystem | Risk |
|-------------|-----------|------|
| `Lua/world.lua` | Game Loop | Critical — tick, entity lifecycle |
| `Lua/room.lua` | Rooms | Critical — state, crash, entry/exit |
| `Lua/queue.lua` | Queues | High — priority, ordering |
| `Src/th_pathfind.cpp` | Pathfinding | High — A*, door handling |
| `Lua/ui.lua` | Input/Events | High — modal dispatch |

### Medium Priority (Important Logic)

| Source File | Subsystem | Risk |
|-------------|-----------|------|
| `Lua/app.lua` | Application | High — save/load, init |
| `Lua/entities/humanoid.lua` | Entities | Medium — behavior |
| `Lua/entities/patient.lua` | Entities | Medium — patient flow |
| `Lua/entities/object.lua` | Entities | Medium — object lifecycle |
| `Lua/window.lua` | UI | Medium — modal, close |

### Lower Priority (Stable/Simple)

| Source File | Subsystem | Risk |
|-------------|-----------|------|
| `Lua/date.lua` | Utility | Low — well tested |
| `Lua/utility.lua` | Utility | Low — well tested |
| `Lua/class.lua` | Core | Low — well tested |
| `Src/xmi2mid.cpp` | Audio | Low — conversion |
| `Src/iso_fs.cpp` | Filesystem | Low — ISO parsing |

---

## Coverage by Subsystem

| Subsystem | Test Files | Source Files | Coverage |
|-----------|------------|--------------|----------|
| Core (class, utility) | 2 | 3 | 67% |
| Date/Time | 1 | 1 | 100% |
| Entities | 5 | 12 | 42% |
| UI/Dialogs | 1 | 8 | 13% |
| World/Game Loop | 0 | 3 | 0% |
| Rooms | 0 | 4 | 0% |
| Pathfinding | 0 | 2 | 0% |
| Graphics (C++) | 1 | 3 | 33% |
| Audio (C++) | 0 | 4 | 0% |
| Strings (C++) | 1 | 2 | 50% |
| Map (C++) | 1 | 3 | 33% |
| Filesystem | 0 | 2 | 0% |
| Persistence | 0 | 2 | 0% |

---

## Missing Coverage by Priority

### P0 — Critical (No Tests, High Risk)

1. **`Lua/world.lua`** — Entity iteration, tick loop, deferred destruction
2. **`Lua/room.lua`** — Room state, crash, entry/exit
3. **`Src/th_pathfind.cpp`** — A* algorithm, door handling
4. **`Lua/ui.lua`** — Modal dispatch, input routing

### P1 — High (No Tests, Medium Risk)

5. **`Lua/app.lua`** — Save/load, config migration
6. **`Lua/queue.lua`** — Priority ordering, push/pop
7. **`Lua/entities/patient.lua`** — Patient flow, diagnosis
8. **`Lua/entities/humanoid.lua`** — State machine, actions
9. **`Lua/window.lua`** — Modal management

### P2 — Medium (Partial or Low Risk)

10. **`Lua/entities/object.lua`** — Object lifecycle
11. **`Src/th_gfx.cpp`** — Animation rendering
12. **`Src/th_sound.cpp`** — Audio mixing
13. **`Lua/persist_lua.lua`** — Save/load serialization
14. **`Lua/config_finder.lua`** — Config migration

### P3 — Low (Well-tested or Simple)

15. **`Lua/date.lua`** — 100% covered
16. **`Lua/utility.lua`** — Well covered
17. **`Lua/class.lua`** — Well covered

---

## Test Infrastructure

### Framework

- **Lua Tests:** [Busted](https://olivinelabs.com/busted/) (Lua unit testing)
- **C++ Tests:** Google Test (via CppTest/)
- **CI Integration:** GitHub Actions

### Running Tests

```bash
# Lua tests
cd CorsixTH/Luatest
busted

# C++ tests
cd CorsixTH/CppTest
cmake . && make && ctest
```

### Test Template

```lua
require("class_test_base")

describe("FeatureName", function()
  local feature

  setup(function()
    feature = FeatureName:new()
  end)

  it("should do expected behavior", function()
    assert.are.equal(expected, feature:method())
  end)

  it("should handle edge case", function()
    assert.has_error(function() feature:badCall() end)
  end)
end)
```

---

*Generated from CorsixTH codebase analysis | 2026-08-26*
