# CorsixTH Safe Fix Patterns

> Anti-patterns, safe templates, and BP catalog quick-reference

---

## Related Pages

- [[regression-index]] — Test coverage for each pattern
- [[performance]] — Performance implications
- [[coverage-dashboard]] — Coverage gaps

---

## Pattern Quick-Reference

| ID | Pattern | Severity | Fix Template |
|----|---------|----------|--------------|
| BP-001 | Entity Iteration Skip | Critical | Deferred destruction |
| BP-002 | Save/Load Migration Missing | High | Version-gated init |
| BP-003 | Room Crash Entity Leak | High | No-break flush loop |
| BP-004 | Pathfinding Door Cross | Medium | Door state check |
| BP-005 | Queue Priority Inversion | Medium | Correct comparison |
| BP-006 | Modal Dialog Stack Leak | Medium | Clear modal_window |
| BP-007 | Lua/C++ Boundary Nil | High | Nil guard |
| BP-008 | Entity Double Destroy | Critical | Early return |
| BP-009 | Room State Inconsistency | High | Symmetric enter/leave |
| BP-010 | Deferred Destruction Leak | Critical | Guaranteed flush |
| BP-011 | Animation Frame Overflow | Low | Frame modulo |
| BP-012 | Sound Callback Leak | Medium | Cleanup in onDestroy |
| BP-013 | String Proxy Encoding | Low | UTF-8 validation |
| BP-014 | Config Migration Skip | High | Default initialization |
| BP-015 | Modal Input Leak | Medium | Modal dispatch check |

---

## Anti-Patterns to Avoid

### ❌ Modifying Collection During Iteration

```lua
-- BAD: BP-001 - Skips entities
for i, entity in ipairs(self.entities) do
    if entity:shouldDestroy() then
        self:destroyEntity(entity)  -- Shifts table!
    end
end

-- GOOD: Deferred destruction
function World:destroyEntity(entity)
    if self.current_tick_entity then
        entity.to_destroy = true
        table.insert(self.entities_to_destroy, entity)
    else
        -- Immediate removal when not in tick
    end
end
```

### ❌ Early Break in Flush Loop

```lua
-- BAD: BP-003 - Leaks entities
function World:_flushDestroyedEntities()
    for i = #self.entities, 1, -1 do
        if self.entities[i].to_destroy then
            table.remove(self.entities, i)
            break  -- Only removes ONE entity!
        end
    end
end

-- GOOD: Process ALL marked entities
function World:_flushDestroyedEntities()
    for i = #self.entities, 1, -1 do
        if self.entities[i].to_destroy then
            table.remove(self.entities, i)
            -- NO BREAK - continue loop
        end
    end
end
```

### ❌ Missing Version Gate in afterLoad

```lua
-- BAD: BP-002 - Crashes on old saves
function MyClass:afterLoad(old, new)
    self:SuperClassAfterLoad(old, new)
    -- self.new_field is nil for old saves!
    print(self.new_field.name)  -- CRASH
end

-- GOOD: Version-gated initialization
function MyClass:afterLoad(old, new)
    self:SuperClassAfterLoad(old, new)
    if old < VERSION_WHEN_FIELD_ADDED then
        self.new_field = DEFAULT_VALUE
    end
end
```

### ❌ Nil Passed Across Lua/C++ Boundary

```cpp
// BAD: BP-007 - Crashes on nil
int l_some_function(lua_State* L) {
    auto obj = luaT_testuserdata<MyClass>(L, 1);
    obj->doSomething();  // Crash if nil!
}

// GOOD: Nil guard
int l_some_function(lua_State* L) {
    auto obj = luaT_testuserdata<MyClass>(L, 1);
    if (!obj) {
        return luaL_error(L, "expected MyClass, got nil");
    }
    obj->doSomething();  // Safe
}
```

### ❌ Double Destroy Without Guard

```lua
-- BAD: BP-008 - Crashes on double destroy
function World:destroyEntity(entity)
    -- No guard - can be called twice!
    entity.to_destroy = true
    table.insert(self.entities_to_destroy, entity)
end

-- GOOD: Idempotent guard
function World:destroyEntity(entity)
    if entity.to_destroy then
        return  -- Already queued
    end
    entity.to_destroy = true
    table.insert(self.entities_to_destroy, entity)
end
```

---

## Safe Fix Templates

### Template 1: Deferred Entity Destruction

```lua
-- For: BP-001, BP-003, BP-008, BP-010

function World:destroyEntity(entity)
    if entity.to_destroy then
        return  -- BP-008: Guard
    end
    
    if self.current_tick_entity then
        -- During tick: defer removal
        entity.to_destroy = true
        table.insert(self.entities_to_destroy, entity)
        entity:onDestroy()  -- Immediate cleanup
    else
        -- Outside tick: immediate removal
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
    -- BP-003: No break, process ALL
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

### Template 2: Version-Gated Migration

```lua
-- For: BP-002, BP-014

function MyClass:afterLoad(old, new)
    self:SuperClassAfterLoad(old, new)  -- Chain to parent
    
    if old < VERSION_WHEN_FIELD_ADDED then
        self.new_field = DEFAULT_VALUE
        -- Or compute from existing data
        self.new_field = self:computeDefault()
    end
end

-- Config migration
function ConfigFinder:afterLoad(old, new)
    if old < VERSION_WITH_NEW_OPTION then
        self:new_option = BASE_CONFIG.default_value
    end
end
```

### Template 3: Room State Consistency

```lua
-- For: BP-009

function Room:onHumanoidEnter(humanoid)
    self.humanoids[humanoid] = true
    humanoid.in_room = self
    self.humanoids_enroute[humanoid] = nil
end

function Room:onHumanoidLeave(humanoid)
    -- Always clean up, even if humanoid already nil
    if self.humanoids[humanoid] then
        self.humanoids[humanoid] = nil
        humanoid.in_room = nil
    end
    self.humanoids_enroute[humanoid] = nil  -- Always clear
end

function Room:crashRoom()
    -- Clear ALL sets
    for humanoid in pairs(self.humanoids) do
        self:destroyEntity(humanoid)
    end
    for object in pairs(self.objects) do
        self:destroyEntity(object)
    end
    self.humanoids = {}
    self.objects = {}
    self.humanoids_enroute = {}
end
```

### Template 4: Modal Dialog Safety

```lua
-- For: BP-006, BP-015

function Window:close()
    -- Clean up modal state
    if self.ui and self.ui.modal_window == self then
        self.ui.modal_window = nil
    end
    -- ... existing cleanup
end

function UI:dispatchKey(key)
    -- BP-015: Check modal first
    if self.modal_window then
        self.modal_window:handleKey(key)
        return  -- Don't dispatch to background
    end
    -- ... normal dispatch
end
```

### Template 5: Sound Callback Cleanup

```lua
-- For: BP-012

function Entity:onDestroy()
    -- Remove sound callbacks
    if self.played_sound_callbacks then
        for _, callback in ipairs(self.played_sound_callbacks) do
            self.world:removeSoundCallback(callback)
        end
        self.played_sound_callbacks = nil
    end
    -- ... existing cleanup
end
```

---

## Testing Requirements by Pattern

| Pattern | Required Tests | Priority |
|---------|---------------|----------|
| BP-001 | Cascading destruction (3+ entities) | P0 |
| BP-002 | Load save from 2+ versions back | P1 |
| BP-003 | Room crash with 5+ entities | P0 |
| BP-004 | Pathfinding through all door types | P1 |
| BP-005 | Emergency > VIP > regular ordering | P1 |
| BP-006 | Nested modal open/close sequences | P2 |
| BP-007 | Nil passed to all C++ bindings | P1 |
| BP-008 | Double destroy scenario | P0 |
| BP-009 | Entity teleportation without notification | P1 |
| BP-010 | Exception during tick | P0 |
| BP-011 | Animation speed changes at runtime | P3 |
| BP-012 | Sound playing during destruction | P2 |
| BP-013 | Special characters in dialog text | P3 |
| BP-014 | Config from 2+ versions ago | P1 |
| BP-015 | Input during modal dialog | P2 |

---

## Code Examples

### Example 1: Safe Entity Iteration

```lua
-- Problem: BP-001 - Entity skipping during tick
-- Solution: Deferred destruction with backward flush

local World = class("World")

function World:initialize()
    self.entities = {}
    self.entities_to_destroy = {}
    self.current_tick_entity = nil
end

function World:onTick()
    self.current_tick_entity = true
    
    -- Safe iteration - entities won't be removed here
    for _, entity in ipairs(self.entities) do
        if not entity.to_destroy then
            entity:tick()
        end
    end
    
    self.current_tick_entity = nil
    self:_flushDestroyedEntities()  -- Always flush
end

function World:destroyEntity(entity)
    if entity.to_destroy then
        return  -- Idempotent
    end
    
    if self.current_tick_entity then
        entity.to_destroy = true
        table.insert(self.entities_to_destroy, entity)
    else
        for i, e in ipairs(self.entities) do
            if e == entity then
                table.remove(self.entities, i)
                break
            end
        end
    end
    
    entity:onDestroy()
end

function World:_flushDestroyedEntities()
    -- Backward iteration - safe removal
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

### Example 2: Room State Management

```lua
-- Problem: BP-009 - Room state inconsistency
-- Solution: Symmetric enter/leave with crash cleanup

local Room = class("Room")

function Room:initialize(world)
    self.world = world
    self.humanoids = {}
    self.objects = {}
    self.humanoids_enroute = {}
end

function Room:onHumanoidEnter(humanoid)
    self.humanoids[humanoid] = true
    humanoid.in_room = self
    self.humanoids_enroute[humanoid] = nil
end

function Room:onHumanoidLeave(humanoid)
    if self.humanoids[humanoid] then
        self.humanoids[humanoid] = nil
        humanoid.in_room = nil
    end
    self.humanoids_enroute[humanoid] = nil
end

function Room:crashRoom()
    -- Destroy all entities in room
    for humanoid in pairs(self.humanoids) do
        self.world:destroyEntity(humanoid)
    end
    for object in pairs(self.objects) do
        self.world:destroyEntity(object)
    end
    
    -- Clear ALL state
    self.humanoids = {}
    self.objects = {}
    self.humanoids_enroute = {}
    self.is_active = false
end
```

### Example 3: C++ Nil Guard

```cpp
// Problem: BP-007 - Nil passed across boundary
// Solution: Validate before use

int l_map_get_tile(lua_State* L) {
    // Get map userdata
    level_map* pMap = luaT_testuserdata<level_map>(L, 1);
    if (!pMap) {
        return luaL_error(L, "map: expected level_map, got nil");
    }
    
    // Get coordinates
    int x = static_cast<int>(luaL_checkinteger(L, 2));
    int y = static_cast<int>(luaL_checkinteger(L, 3));
    
    // Bounds check
    if (x < 0 || x >= pMap->width || y < 0 || y >= pMap->height) {
        return luaL_error(L, "map: coordinates out of bounds");
    }
    
    // Safe to use
    lua_pushinteger(L, pMap->getTile(x, y));
    return 1;
}
```

---

## Prevention Checklist

### Before Modifying Entity Lists

- [ ] Is this inside a tick loop? → Use deferred destruction
- [ ] Am I using `ipairs`? → Switch to backward iteration for removal
- [ ] Can this be called twice? → Add idempotent guard
- [ ] Is `to_destroy` already true? → Early return

### Before Adding New Fields

- [ ] Define version constant in `base_config.lua`
- [ ] Add version-gated initialization in `afterLoad`
- [ ] Test loading save from previous version
- [ ] Document migration in changelog

### Before Modifying Room State

- [ ] Is `onHumanoidEnter` matched by `onHumanoidLeave`?
- [ ] Does crash/deactivation clear all sets?
- [ ] Does pathfinding failure clear `humanoids_enroute`?

### Before Passing to C++

- [ ] Is the value non-nil?
- [ ] Is it the correct userdata type?
- [ ] Are bounds checked for arrays/maps?

---

*Generated from CorsixTH codebase analysis | 2026-08-26*
