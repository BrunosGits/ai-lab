# CorsixTH Test Coverage Dashboard

> Busted coverage by subsystem, gap analysis, and testing metrics

---

## Related Pages

- [[regression-index]] — Test file details
- [[performance]] — Performance testing
- [[safe-fix-patterns]] — Testing requirements

---

## Coverage Summary

| Metric | Value |
|--------|-------|
| Total Test Files | 14 |
| Total Test Cases | ~148 |
| Lua Test Files | 10 |
| C++ Test Files | 4 |
| Subsystems Covered | 6 / 13 |
| Coverage Percentage | 46% |

---

## Coverage by Subsystem

| Subsystem | Test Files | Source Files | Coverage | Status |
|-----------|------------|--------------|----------|--------|
| Core (class, utility) | 2 | 3 | 67% | ✅ Good |
| Date/Time | 1 | 1 | 100% | ✅ Excellent |
| Entities | 5 | 12 | 42% | ⚠️ Partial |
| UI/Dialogs | 1 | 8 | 13% | ❌ Critical |
| World/Game Loop | 0 | 3 | 0% | ❌ None |
| Rooms | 0 | 4 | 0% | ❌ None |
| Pathfinding | 0 | 2 | 0% | ❌ None |
| Graphics (C++) | 1 | 3 | 33% | ⚠️ Partial |
| Audio (C++) | 0 | 4 | 0% | ❌ None |
| Strings (C++) | 1 | 2 | 50% | ⚠️ Partial |
| Map (C++) | 1 | 3 | 33% | ⚠️ Partial |
| Filesystem | 0 | 2 | 0% | ❌ None |
| Persistence | 0 | 2 | 0% | ❌ None |

---

## Test File Details

### Lua Tests (Busted Framework)

| Test File | Test Cases | Lines | What It Tests |
|-----------|------------|-------|---------------|
| `Luatest/spec/class_spec.lua` | 6 | 76 | Class OOP system |
| `Luatest/spec/date_spec.lua` | 17 | 188 | Date arithmetic |
| `Luatest/spec/utility_spec.lua` | 11 | 117 | Serialization |
| `Luatest/spec/announcer_spec.lua` | ~8 | ~100 | Announcement queue |
| `Luatest/spec/entities/humanoid_spec.lua` | ~15 | ~200 | Humanoid state |
| `Luatest/spec/entities/humanoids/vip_spec.lua` | ~10 | ~150 | VIP behavior |
| `Luatest/spec/entities/humanoids/staff/doctor_spec.lua` | ~12 | ~180 | Doctor AI |
| `Luatest/spec/entities/machine_spec.lua` | ~8 | ~120 | Machine state |
| `Luatest/spec/entities/object_spec.lua` | ~10 | ~150 | Object lifecycle |
| `Luatest/spec/dialogs/bottom_pannel_spec.lua` | ~6 | ~80 | UI panel |

### C++ Tests (Google Test)

| Test File | Test Cases | Lines | What It Tests |
|-----------|------------|-------|---------------|
| `CppTest/test_th_lua.cpp` | ~20 | ~300 | Lua bindings |
| `CppTest/test_th_lua_map.cpp` | ~15 | ~250 | Map loading |
| `CppTest/test_th_lua_ui.cpp` | ~12 | ~200 | UI rendering |
| `CppTest/test_th_strings.cpp` | ~8 | ~120 | String encoding |

---

## Coverage Gap Analysis

### P0 — Critical Gaps (No Tests, High Risk)

| Gap | Impact | Recommended Test |
|-----|--------|------------------|
| `Lua/world.lua` | Entity iteration bugs | Deferred destruction test |
| `Lua/room.lua` | State inconsistency | Enter/leave symmetry test |
| `Src/th_pathfind.cpp` | Door crossing bugs | Door pathfinding test |
| `Lua/ui.lua` | Modal input leak | Modal dispatch test |

### P1 — High Gaps (No Tests, Medium Risk)

| Gap | Impact | Recommended Test |
|-----|--------|------------------|
| `Lua/app.lua` | Save/load crash | Old save loading test |
| `Lua/queue.lua` | Priority inversion | Queue ordering test |
| `Lua/entities/patient.lua` | Patient flow | Patient lifecycle test |
| `Lua/entities/humanoid.lua` | State machine | State transition test |
| `Lua/window.lua` | Modal leak | Modal close test |

### P2 — Medium Gaps (Partial or Lower Risk)

| Gap | Impact | Recommended Test |
|-----|--------|------------------|
| `Lua/entities/object.lua` | Object lifecycle | Object create/destroy test |
| `Src/th_gfx.cpp` | Animation overflow | Frame modulo test |
| `Src/th_sound.cpp` | Sound callback leak | Callback cleanup test |
| `Lua/persist_lua.lua` | Save corruption | Serialization roundtrip test |
| `Lua/config_finder.lua` | Config migration | Old config loading test |

---

## Test Density by Subsystem

| Subsystem | Source Files | Test Cases | Tests/File |
|-----------|--------------|------------|------------|
| Date/Time | 1 | 17 | 17.0 |
| Core | 3 | 17 | 5.7 |
| Entities | 12 | 55 | 4.6 |
| Audio (C++) | 4 | 0 | 0.0 |
| UI/Dialogs | 8 | 6 | 0.8 |
| World/Game Loop | 3 | 0 | 0.0 |
| Rooms | 4 | 0 | 0.0 |
| Pathfinding | 2 | 0 | 0.0 |
| Graphics (C++) | 3 | 12 | 4.0 |
| Strings (C++) | 2 | 8 | 4.0 |
| Map (C++) | 3 | 15 | 5.0 |
| Filesystem | 2 | 0 | 0.0 |
| Persistence | 2 | 0 | 0.0 |

---

## Critical Paths Without Tests

### Game Loop Path

```
World:onTick()
├── World:_flushDestroyedEntities()  ❌ No test
├── Entity:tick()                    ❌ No test
├── Room:tick()                      ❌ No test
└── Queue:tick()                     ❌ No test
```

### Save/Load Path

```
App:save()
├── Persist:write()                  ❌ No test
├── Entity:persist()                 ❌ No test
└── Room:persist()                   ❌ No test

App:load()
├── Persist:read()                   ❌ No test
├── Entity:depersist()               ❌ No test
├── Entity:afterLoad()               ❌ No test
└── Room:afterLoad()                 ❌ No test
```

### Input Dispatch Path

```
UI:dispatch()
├── UI:dispatchKey()                 ❌ No test
├── UI:dispatchMouse()               ❌ No test
├── Modal:handleKey()                ❌ No test
└── Window:handleKey()               ❌ No test
```

---

## Priority Recommendations for New Tests

### Immediate (P0)

1. **`world_spec.lua`** — Entity iteration, deferred destruction
2. **`room_spec.lua`** — State consistency, crash handling
3. **`pathfind_spec.lua`** — Door crossing, edge cases
4. **`ui_spec.lua`** — Modal dispatch, input routing

### Short-term (P1)

5. **`app_spec.lua`** — Save/load, config migration
6. **`queue_spec.lua`** — Priority ordering, push/pop
7. **`patient_spec.lua`** — Patient flow, diagnosis
8. **`humanoid_spec.lua`** — State machine, actions

### Medium-term (P2)

9. **`object_spec.lua`** — Object lifecycle
10. **`graphics_spec.lua`** — Animation rendering
11. **`sound_spec.lua`** — Audio mixing
12. **`persist_spec.lua`** — Serialization

---

## Test Templates

### Lua Test Template (Busted)

```lua
-- SCAFFOLD.lua - Test template
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
  
  it("should not crash on nil input", function()
    assert.has_no.errors(function() feature:method(nil) end)
  end)
end)
```

### C++ Test Template (Google Test)

```cpp
// SCAFFOLD.cpp - Test template
#include <gtest/gtest.h>
#include "th_map.h"

class MapTest : public ::testing::Test {
protected:
    level_map* map;
    
    void SetUp() override {
        map = new level_map();
    }
    
    void TearDown() override {
        delete map;
    }
};

TEST_F(MapTest, GetTileReturnsZeroByDefault) {
    EXPECT_EQ(0, map->getTile(0, 0));
}

TEST_F(MapTest, GetTileBoundsCheck) {
    EXPECT_DEATH(map->getTile(-1, 0), "out of bounds");
}
```

---

## Running Tests

### Lua Tests (Busted)

```bash
cd CorsixTH/Luatest
busted                    # Run all tests
busted spec/class_spec.lua  # Run specific file
busted --coverage         # With coverage report
```

### C++ Tests (Google Test)

```bash
cd CorsixTH/CppTest
cmake .
make
ctest                    # Run all tests
./test_th_lua --gtest_filter=MapTest.*  # Run specific suite
```

### Coverage Reports

```bash
# Lua coverage
cd CorsixTH/Luatest
busted --coverage --coverage-report lcov
genhtml coverage.info -o coverage_html

# C++ coverage (with gcov)
cmake -DCMAKE_CXX_FLAGS="--coverage" .
make
ctest
gcov -r . -b src/
```

---

## SCAFFOLD.lua Files

Test templates are available in the vault:

- `08-QUERIES/SCAFFOLD_LUA_TEST.lua` — Lua test template
- `08-QUERIES/SCAFFOLD_CPP_TEST.cpp` — C++ test template
- `08-QUERIES/SCAFFOLD_INTEGRATION.lua` — Integration test template

---

*Generated from CorsixTH codebase analysis | 2026-08-26*
