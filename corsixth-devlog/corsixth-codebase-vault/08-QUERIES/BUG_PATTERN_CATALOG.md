# CorsixTH Bug Pattern Catalog

> Comprehensive catalog of recurring bug patterns with root causes, fixes, and prevention strategies

---

## Pattern Index

| ID | Pattern | Severity | Frequency | Detection |
|----|---------|----------|-----------|-----------|
| BP-001 | Entity Iteration Skip | Critical | High | Unit test, manual |
| BP-002 | Save/Load Migration Missing | High | Medium | Load old save, test |
| BP-003 | Room Crash Entity Leak | High | Medium | Stress test, smoke test |
| BP-004 | Pathfinding Door Cross | Medium | Low | Manual, edge cases |
| BP-005 | Queue Priority Inversion | Medium | Low | Unit test, integration |
| BP-006 | Modal Dialog Stack Leak | Medium | Low | Manual, UI test |
| BP-007 | Lua/C++ Boundary Nil | High | Medium | Static analysis, test |
| BP-008 | Entity Double Destroy | Critical | Low | Unit test, stress |
| BP-009 | Room State Inconsistency | High | Medium | State dump, test |
| BP-010 | Deferred Destruction Leak | Critical | Low | Smoke test, stress |
| BP-011 | Animation Frame Overflow | Low | Rare | Visual, automated |
| BP-012 | Sound Callback Leak | Medium | Rare | Memory profile, test |
| BP-013 | String Proxy Encoding | Low | Rare | I18n test, log |
| BP-014 | Config Migration Skip | High | Medium | Load old config |
| BP-015 | Modal Input Leak | Medium | Low | UI test, manual |

---

## BP-001: Entity Iteration Skip

**ID:** BP-001  
**Severity:** Critical  
**Frequency:** High (every entity destruction during tick)  

### Description
When iterating `self.entities` with `ipairs` during the main tick loop, calling `destroyEntity` on an entity shifts subsequent elements left, causing the loop to skip the next entity.

### Root Cause
`ipairs` uses numeric index iteration. `table.remove(self.entities, i)` shifts all elements at indices > i left by one position. The loop counter `i` increments, but the element that shifted into position `i` is never visited.

### Symptoms
- Entities silently stop receiving `tick()` calls
- Patients/staff freeze mid-action
- No error message, silent corruption
- Reproducible with cascading destructions

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/world.lua` | 971-978 | Main tick loop |
| `Lua/world.lua` | 1844-1893 | destroyEntity / _flushDestroyedEntities |
| `Lua/world.lua` | 1055-1065 | onEndDay loop |
| `Lua/world.lua` | 1179-1186 | onEndMonth loop |

### Fix Template
```lua
-- Use deferred destruction pattern
function World:destroyEntity(entity)
  if self.current_tick_entity then
    entity.to_destroy = true
    table.insert(self.entities_to_destroy, entity)
    entity:onDestroy()  -- Immediate cleanup
  else
    -- Immediate removal (no iteration in progress)
    for i, e in ipairs(self.entities) do
      if e == entity then
        table.remove(self.entities, i)
        break
      end
    end
    entity:onDestroy()
  end
end

function World:_flushDestroyedEntities()
  -- Iterate BACKWARDS to avoid shifting issues
  for i = #self.entities, 1, -1 do
    if self.entities[i].to_destroy then
      table.remove(self.entities, i)
    end
  end
  -- Clear flags
  for _, e in ipairs(self.entities_to_destroy) do
    e.to_destroy = nil
  end
  self.entities_to_destroy = {}
end
```

### Prevention Checklist
- [ ] Never modify `self.entities` during `ipairs` iteration
- [ ] Always use deferred destruction when inside tick loop
- [ ] Use backward iteration (`#entities, 1, -1`) when removing during flush
- [ ] Add unit test for cascading destruction (3+ entities)
- [ ] Add unit test for self-destruction during own tick

### Related PRs/Issues
- PR #3504 - Fix #1467: Deferred entity destruction
- Issue #1467 - Entity skipping bug

### Test Coverage
- `world_spec.lua`: 23 test cases covering:
  - Immediate destruction outside loop
  - Deferred removal during iteration
  - Multi-entity flush in one pass
  - No entities skipped when earlier destroyed
  - Self-destruction during own tick
  - Cascading destruction (onDestroy triggers more)
  - Entities added during loop still ticked
  - Old savegame compatibility (nil queue)

---

## BP-002: Save/Load Migration Missing

**ID:** BP-002  
**Severity:** High  
**Frequency:** Medium (every version bump)  

### Description
New fields added to classes are not initialized when loading old savegames, causing nil reference errors or default behavior changes.

### Root Cause
`afterLoad(old, new)` migration not updated for new fields. Version gates (`if old < N then`) missing for new schema changes.

### Symptoms
- `attempt to index nil value` on new fields
- Old saves crash on load
- New features silently disabled for old saves
- Inconsistent state between new/new and old/new games

### Affected Files
| File | Migration Function |
|------|-------------------|
| `Lua/app.lua` | `App:afterLoad` (lines 1995-2054) |
| `Lua/world.lua` | `World:afterLoad` (lines 2552-2962) |
| `Lua/entity.lua` | `Entity:afterLoad` (lines 341-342) |
| `Lua/humanoid.lua` | `Humanoid:afterLoad` |
| `Lua/patient.lua` | `Patient:afterLoad` |
| `Lua/entities/object.lua` | `Object:afterLoad` |
| 73+ classes with `afterLoad` | Various |

### Fix Template
```lua
function MyClass:afterLoad(old, new)
  self:SuperClassAfterLoad(old, new)  -- Chain to parent
  
  if old < VERSION_WHEN_FIELD_ADDED then
    self.new_field = DEFAULT_VALUE
    -- Or compute from existing data
    self.new_field = self:computeDefault()
  end
end
```

### Prevention Checklist
- [ ] Every new field has version-gated initialization in `afterLoad`
- [ ] Version constant defined in `base_config.lua` or similar
- [ ] Test loading saves from at least 2 major versions back
- [ ] Add `afterLoad` test for new field initialization
- [ ] Document migration in changelog

### Related PRs/Issues
- PR #3504 - Lazy `entities_to_destroy` creation for old saves
- Multiple version bumps with migration gates

### Test Coverage
- `world_spec.lua`: Tests for nil queue lazy creation (lines 429-438, 440-456)
- No automated old-save loading tests in CI

---

## BP-003: Room Crash Entity Leak

**ID:** BP-003  
**Severity:** High  
**Frequency:** Medium (on room crash events)  

### Description
When a room crashes (`crashRoom`), all entities inside are destroyed simultaneously. If the flush loop has a `break` or only processes one entity per flush, remaining entities leak with `to_destroy = true` forever.

### Root Cause
`crashRoom` calls `destroyEntity` on all humanoids and objects in the room. Multiple entities get `to_destroy = true` in a single tick. The flush loop must process ALL marked entities, not just one.

### Symptoms
- Entities remain in `self.entities` with `to_destroy = true`
- Leaked entities never tick again (guarded by `not entity.to_destroy`)
- Memory leak, entity count grows
- Eventually hits entity limit or performance degrades

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/room.lua` | 857-964 | `crashRoom` destroys all entities |
| `Lua/world.lua` | 1885-1889 | `_flushDestroyedEntities` loop |
| `Lua/world.lua` | 1849-1862 | `destroyEntity` deferred path |

### Fix Template
```lua
function World:_flushDestroyedEntities()
  -- NO BREAK - process ALL marked entities
  for i = #self.entities, 1, -1 do
    if self.entities[i].to_destroy then
      table.remove(self.entities, i)
      -- NO BREAK HERE - continue loop
    end
  end
end
```

### Prevention Checklist
- [ ] Never add `break` in `_flushDestroyedEntities` loop
- [ ] Use backward iteration for safe removal
- [ ] Test room crash with 5+ entities inside
- [ ] Verify all `to_destroy` flags cleared after flush
- [ ] Monitor entity count in smoke tests

### Related PRs/Issues
- PR #3504 - Discussion about `break` in flush loop
- Room crash mechanics in `room.lua:857`

### Test Coverage
- `world_spec.lua`: Cascading destruction test (lines 247-270)
- `smoketest.lua`: Room crash simulation

---

## BP-004: Pathfinding Door Cross

**ID:** BP-004  
**Severity:** Medium  
**Frequency:** Low (edge cases)  

### Description
Entities pathfinding through doors may cross from wrong side, get stuck in door frames, or fail to find path when door is the only passage.

### Root Cause
- Door tiles have special passability flags
- `idle_tile_finder` avoids crossing doors (lines 246-270 in th_pathfind.cpp)
- Door direction affects passability asymmetrically
- `object_visitor` respects door directions but `basic_pathfinder` may not

### Symptoms
- Staff/patients stuck at doorways
- Pathfinding fails when room only accessible through door
- Entities walk through closed doors
- Entities unable to exit room after door placed

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Src/th_pathfind.cpp` | 246-270 | Door avoidance in idle_tile_finder |
| `Src/th_pathfind.cpp` | 379-461 | object_visitor door logic |
| `Src/th_map.cpp` | Tile flags | Door passability flags |
| `Lua/entities/object.lua` | Door class | Door passability setup |

### Fix Template
```cpp
// In pathfinder: ensure door tiles are traversable when open
// Check door state (open/closed) before marking as avoid
bool canPassThroughDoor(const level_map& map, int x, int y, Direction dir) {
  auto door = map.getDoorAt(x, y);
  return door && door->isOpen() && door->allowsDirection(dir);
}
```

### Prevention Checklist
- [ ] Test pathfinding through all door types (swing, entrance)
- [ ] Verify door state (open/closed) affects pathfinding
- [ ] Test entity crossing from both sides of door
- [ ] Verify `idle_tile_finder` doesn't over-avoid doors

### Related PRs/Issues
- Door pathfinding issues in `idle_tile_finder`
- Swing door pairing logic in `objects/doors/`

### Test Coverage
- No dedicated pathfinding tests in CI
- Manual testing required

---

## BP-005: Queue Priority Inversion

**ID:** BP-005  
**Severity:** Medium  
**Frequency:** Low  

### Description
Lower-priority patients jump ahead of higher-priority ones due to incorrect priority comparison or queue insertion logic.

### Root Cause
- Priority values inverted (1=highest vs 6=highest confusion)
- `Queue:push` inserts at wrong position
- Emergency patients not properly prioritized over VIPs

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/queue.lua` | 166-188 | Priority system |
| `Lua/queue.lua` | 201-249 | `push`/`pop` logic |
| `Lua/objects/reception_desk.lua` | Queue handling | Reception queue |
| `Lua/objects/door.lua` | Door queue | Room queues |

### Fix Template
```lua
-- Priority: 1=highest (leaving), 6=lowest (regular)
-- Ensure comparison uses correct ordering
function Queue:insertByPriority(humanoid, priority)
  local insertAt = #self + 1
  for i = #self, 1, -1 do
    if self[i].priority <= priority then  -- Higher priority = lower number
      insertAt = i + 1
      break
    end
  end
  table.insert(self, insertAt, humanoid)
end
```

### Prevention Checklist
- [ ] Verify priority constants: 1=highest, 6=lowest
- [ ] Test emergency > VIP > regular ordering
- [ ] Test queue-jump cheat (health < 10%)
- [ ] Verify leaving patients (priority 1) always first

### Related PRs/Issues
- Queue priority bugs in `queue.lua:166-188`

### Test Coverage
- `queue_spec.lua`: Priority ordering tests
- Integration tests needed

---

## BP-006: Modal Dialog Stack Leak

**ID:** BP-006  
**Severity:** Medium  
**Frequency:** Low  

### Description
Modal dialogs not properly removed from stack, causing input to be blocked by invisible dialogs, or multiple modals stacking incorrectly.

### Root Cause
- `modal_window` not cleared on close
- Nested modals not handled correctly
- `close()` doesn't clean up `modal_window` reference

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/window.lua` | 130-145 | `close()` cleanup |
| `Lua/ui.lua` | 266+ | `modal_window` management |
| `Lua/dialogs/*.lua` | Various | Dialog `close()` overrides |

### Fix Template
```lua
function Window:close()
  -- Clean up modal state
  if self.ui and self.ui.modal_window == self then
    self.ui.modal_window = nil
  end
  -- ... existing cleanup
end
```

### Prevention Checklist
- [ ] Every `close()` clears `modal_window` if self
- [ ] Test nested modal open/close sequences
- [ ] Verify ESC key closes topmost modal only
- [ ] Test modal blocks input to background windows

### Related PRs/Issues
- Modal dialog bugs in UI system

### Test Coverage
- No automated modal stack tests
- Manual UI testing required

---

## BP-007: Lua/C++ Boundary Nil

**ID:** BP-007  
**Severity:** High  
**Frequency:** Medium  

### Description
Nil values passed across Lua/C++ boundary cause crashes or undefined behavior. C++ code expects valid userdata but receives nil.

### Root Cause
- Lua passes nil to C++ function expecting userdata
- `luaT_testuserdata` doesn't validate nil
- `TH` module functions called with nil arguments
- `luaT_touserdata_base` returns nil for invalid types

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Src/th_lua.h` | 380-416 | `luaT_testuserdata` |
| `Src/th_lua.cpp` | Various | Binding functions |
| `Lua/*.lua` | Various | Calls to `TH.*` |

### Fix Template
```cpp
// In C++ binding: validate before use
int l_some_function(lua_State* L) {
  auto obj = luaT_testuserdata<MyClass>(L, 1);
  if (!obj) {
    return luaL_error(L, "expected MyClass, got nil");
  }
  // Safe to use obj
}
```

### Prevention Checklist
- [ ] All C++ bindings validate userdata before dereferencing
- [ ] Lua wrapper functions check for nil before calling TH
- [ ] Use `assert(entity)` in Lua before passing to TH
- [ ] Add nil checks in generated binding code

### Related PRs/Issues
- Nil dereference crashes in TH module

### Test Coverage
- No boundary nil tests in CI

---

## BP-008: Entity Double Destroy

**ID:** BP-008  
**Severity:** Critical  
**Frequency:** Low  

### Description
Entity destroyed twice - first time queues for deferred destruction, second time attempts immediate removal, causing crashes or corruption.

### Root Cause
- `destroyEntity` called twice on same entity
- First call sets `to_destroy = true`, queues entity
- Second call sees `to_destroy` already true but may still try to remove

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/world.lua` | 1844-1848 | Double-destroy guard |

### Fix Template
```lua
function World:destroyEntity(entity)
  if entity.to_destroy then
    return  -- Already queued, do nothing
  end
  -- ... rest of destruction logic
end
```

### Prevention Checklist
- [ ] Early return in `destroyEntity` if `entity.to_destroy`
- [ ] Test double-destroy scenario
- [ ] Verify `to_destroy` flag not cleared prematurely

### Related PRs/Issues
- `world.lua:1844-1848` guard exists
- Test in `world_spec.lua` lines 152-161 (idempotent queueing)

### Test Coverage
- `world_spec.lua`: "idempotent queueing" test (lines 152-161)

---

## BP-009: Room State Inconsistency

**ID:** BP-009  
**Severity:** High  
**Frequency:** Medium  

### Description
Room state (`humanoids`, `objects`, `humanoids_enroute` sets) becomes inconsistent with actual entity positions, causing entities to be "lost" or room logic to fail.

### Root Cause
- `onHumanoidEnter`/`onHumanoidLeave` not called symmetrically
- Entity moved without room notification
- `humanoids_enroute` not cleared on pathfinding failure
- Room crash/deactivation doesn't clear sets properly

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/room.lua` | 316-436 | `onHumanoidEnter` |
| `Lua/room.lua` | 569-658 | `onHumanoidLeave` |
| `Lua/room.lua` | 857-964 | `crashRoom` |
| `Lua/room.lua` | 1015-1025 | `deactivate` |

### Fix Template
```lua
function Room:onHumanoidLeave(humanoid)
  -- Always clean up, even if humanoid already nil
  if self.humanoids[humanoid] then
    self.humanoids[humanoid] = nil
    humanoid.in_room = nil
  end
  self.humanoids_enroute[humanoid] = nil  -- Always clear enroute
  -- ...
end
```

### Prevention Checklist
- [ ] Every `onHumanoidEnter` matched by `onHumanoidLeave`
- [ ] Crash/deactivation clears all sets
- [ ] Pathfinding failure clears `humanoids_enroute`
- [ ] Test entity teleportation without room notification

### Related PRs/Issues
- Room state bugs in various PRs

### Test Coverage
- `room_spec.lua`: Basic entry/exit tests
- Need more state consistency tests

---

## BP-010: Deferred Destruction Leak

**ID:** BP-010  
**Severity:** Critical  
**Frequency:** Low  

### Description
Entities marked `to_destroy = true` never get flushed because `_flushDestroyedEntities` not called, or queue corrupted.

### Root Cause
- `current_tick_entity` not cleared before flush
- Exception during tick prevents flush call
- `entities_to_destroy` queue corrupted (nil or corrupted table)

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/world.lua` | 974-978 | Tick loop flush |
| `Lua/world.lua` | 1065 | onEndDay flush |
| `Lua/world.lua` | 1186 | onEndMonth flush |

### Fix Template
```lua
-- Always flush in finally-like pattern
function World:onTick()
  local ok, err = pcall(function()
    -- ... tick logic
  end)
  self.current_tick_entity = nil
  self:_flushDestroyedEntities()  -- Always flush
  if not ok then error(err) end
end
```

### Prevention Checklist
- [ ] `_flushDestroyedEntities` called in ALL loop exit paths
- [ ] Use `pcall`/`finally` pattern for guaranteed flush
- [ ] Verify `entities_to_destroy` initialized in `World:new()`
- [ ] Test exception during tick doesn't leak entities

### Related PRs/Issues
- PR #3504 - Flush guarantees

### Test Coverage
- `world_spec.lua`: "Recovery when loop interrupted" test (lines 290-306)
- `world_spec.lua`: "Double-flush safety" test (lines 476-488)

---

## BP-011: Animation Frame Overflow

**ID:** BP-011  
**Severity:** Low  
**Frequency:** Rare  

### Description
Animation frame index exceeds sprite sheet bounds, causing rendering glitches or crashes.

### Root Cause
- Frame index not modulo'd by frame count
- Animation speed changes without frame clamp
- Corrupted animation data from save/load

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Src/th_gfx.cpp` | Animation rendering | Frame indexing |
| `Lua/graphics.lua` | Animation loading | Frame count validation |

### Prevention Checklist
- [ ] Frame index modulo frame count in renderer
- [ ] Validate frame count > 0 on load
- [ ] Test animation speed changes at runtime

---

## BP-012: Sound Callback Leak

**ID:** BP-012  
**Severity:** Medium  
**Frequency:** Rare  

### Description
Sound completion callbacks not cleaned up, causing memory leaks or crashes when callback fires for destroyed entity.

### Root Cause
- `played_sound_callbacks` table accumulates entries
- Entity destroyed but callback remains registered
- Callback fires for destroyed entity

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/audio.lua` | 55-58 | `played_sound_callbacks` |
| `Lua/entity.lua` | 281-289 | `onDestroy` cleans up callbacks |

### Prevention Checklist
- [ ] `Entity:onDestroy` removes sound callbacks
- [ ] Test sound playing during entity destruction
- [ ] Verify callback table doesn't grow unbounded

---

## BP-013: String Proxy Encoding

**ID:** BP-013  
**Severity:** Low  
**Frequency:** Rare  

### Description
String proxy encoding issues with special characters, RTL languages, or CJK fonts.

### Root Cause
- UTF-8 handling in string proxy
- Font fallback missing for CJK
- RTL text direction not handled

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/strings.lua` | String proxy | Encoding handling |
| `Src/th_gfx_font.cpp` | FreeType | Font rendering |

---

## BP-014: Config Migration Skip

**ID:** BP-014  
**Severity:** High  
**Frequency:** Medium  

### Description
Config file (`config.txt`) missing new options after update, causing defaults to be used instead of migrated values.

### Root Cause
- `config_finder.lua` doesn't migrate old configs
- New config options not added to `base_config.lua` defaults
- Hotkeys not migrated

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/config_finder.lua` | Config loading | Migration |
| `Lua/base_config.lua` | Defaults | New options |

### Prevention Checklist
- [ ] New config options added to `base_config.lua`
- [ ] Migration logic in `config_finder.lua`
- [ ] Test loading config from 2+ versions ago

---

## BP-015: Modal Input Leak

**ID:** BP-015  
**Severity:** Medium  
**Frequency:** Low  

### Description
Input events leak through modal dialogs, allowing interaction with background windows.

### Root Cause
- `modal_window` check missing in input dispatch
- Mouse/keyboard events not filtered by modal state

### Affected Files
| File | Lines | Role |
|------|-------|------|
| `Lua/ui.lua` | `dispatch()` | Input dispatch |
| `Lua/window.lua` | Input handlers | Modal check |

---

## Pattern Cross-Reference Matrix

| Pattern | Entity Iteration | Save/Load | Room | Pathfinding | Queue | UI/Modal | Lua/C++ | Animation | Sound | Config |
|---------|------------------|-----------|------|-------------|-------|----------|---------|-----------|-------|--------|
| BP-001 | ✅ | | | | | | | | | |
| BP-002 | | ✅ | | | | | | | | ✅ |
| BP-003 | ✅ | | ✅ | | | | | | | |
| BP-004 | | | | ✅ | | | | | | |
| BP-005 | | | | | ✅ | | | | | |
| BP-006 | | | | | | ✅ | | | | |
| BP-007 | | | | | | | ✅ | | | |
| BP-008 | ✅ | | | | | | | | | |
| BP-009 | | | ✅ | | | | | | | |
| BP-010 | ✅ | | | | | | | | | |
| BP-011 | | | | | | | | ✅ | | |
| BP-012 | | | | | | | | | ✅ | |
| BP-013 | | | | | | | | | | ✅ |
| BP-014 | | ✅ | | | | | | | | ✅ |
| BP-015 | | | | | | ✅ | | | | |

---

## Test Coverage Matrix

| Pattern | Unit Tests | Integration Tests | CI Coverage | Manual Only |
|---------|------------|-------------------|-------------|-------------|
| BP-001 | ✅ (23 tests) | ✅ | ✅ | |
| BP-002 | ❌ | ❌ | ❌ | ✅ |
| BP-003 | ✅ (cascading) | ✅ (smoke) | ❌ | |
| BP-004 | ❌ | ❌ | ❌ | ✅ |
| BP-005 | ✅ (queue_spec) | ❌ | ❌ | |
| BP-006 | ❌ | ❌ | ❌ | ✅ |
| BP-007 | ❌ | ❌ | ❌ | ✅ |
| BP-008 | ✅ (idempotent) | ❌ | ✅ | |
| BP-009 | ❌ | ❌ | ❌ | ✅ |
| BP-010 | ✅ (interrupt) | ✅ (smoke) | ❌ | |
| BP-011 | ❌ | ❌ | ❌ | ✅ |
| BP-012 | ❌ | ❌ | ❌ | ✅ |
| BP-013 | ❌ | ❌ | ❌ | ✅ |
| BP-014 | ❌ | ❌ | ❌ | ✅ |
| BP-015 | ❌ | ❌ | ❌ | ✅ |

---

## Recommendations for CI Improvement

1. **Add automated old-save loading tests** (BP-002)
2. **Add pathfinding integration tests** (BP-004)
3. **Add modal stack tests** (BP-006, BP-015)
4. **Add Lua/C++ boundary nil tests** (BP-007)
5. **Add room state consistency tests** (BP-009)
6. **Add config migration tests** (BP-014)
6. **Add animation/sound stress tests** (BP-011, BP-012)

---

## Quick Reference: Fix Templates

```lua
-- BP-001: Safe entity removal during iteration
for i = #entities, 1, -1 do if entities[i].to_destroy then table.remove(entities, i) end end

-- BP-002: Version-gated migration
if old < NEW_VERSION then self.new_field = DEFAULT end

-- BP-003: No break in flush loop
for i = #entities, 1, -1 do if entities[i].to_destroy then table.remove(entities, i) end end

-- BP-007: C++ nil guard
auto obj = luaT_testuserdata<MyClass>(L, 1); if (!obj) return luaL_error(L, "expected MyClass");

-- BP-010: Guaranteed flush
local ok, err = pcall(tickLogic); current_tick_entity = nil; flush(); if not ok then error(err) end
```

---

*Catalog version 1.0 | Generated from CorsixTH codebase analysis | Last updated: 2026-08-25*

## Related Pages

- [[code-refs]]
- [[coverage-dashboard]]
- [[open-issues]]
- [[pr-status]]
- [[regression-index]]
- [[test-coverage]]
