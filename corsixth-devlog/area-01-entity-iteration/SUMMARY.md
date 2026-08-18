# Entity Iteration & Destruction Patterns in CorsixTH

## Complete Analysis

This document provides a comprehensive analysis of how CorsixTH handles entity iteration and deferred destruction. The pattern is critical for maintaining game stability when entities can be destroyed during their own tick or the tick of another entity.

---

## 1. Core Architecture

### The Three Iteration Loops

CorsixTH has **three distinct entity iteration loops** in `world.lua`, each with identical deferred-destruction scaffolding:

| Loop | Function | Line Range | Entities Processed |
|------|----------|------------|-------------------|
| **Per-tick** | `World:onTick()` | 971–978 | All entities with `ticks == true` |
| **Per-day** | `World:onEndDay()` | 1055–1065 | Humanoids + Plants |
| **Per-month** | `World:onEndMonth()` | 1179–1186 | Entities with `checkForDeadlock` method |

Each loop follows this exact structure:

```lua
for _, entity in ipairs(self.entities) do
  if entity.ticks and not entity.to_destroy then  -- Guard condition varies per loop
    self.current_tick_entity = entity              -- Marks "we are inside a loop"
    entity:tick()                                  -- Or tickDay / checkForDeadlock
  end
end
self.current_tick_entity = nil                     -- Clears the marker
self:_flushDestroyedEntities()                     -- Removes queued entities
```

### The Deferred Destruction Mechanism

**File:** `world.lua:1844–1893`

```lua
function World:destroyEntity(entity)
  if entity.to_destroy then
    return  -- Already queued; onDestroy already ran
  end
  if self.current_tick_entity then
    -- INSIDE an iteration loop → DEFER removal
    entity.to_destroy = true
    local queue = self.entities_to_destroy
    if not queue then
      queue = {}
      self.entities_to_destroy = queue
    end
    queue[#queue + 1] = entity
    entity:onDestroy()  -- Run cleanup immediately
  else
    -- OUTSIDE any loop → REMOVE immediately
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
  local queue = self.entities_to_destroy
  if not queue or #queue == 0 then
    return  -- Handles old savegames (nil queue)
  end
  self.entities_to_destroy = {}  -- Reset queue for next loop
  for i = #self.entities, 1, -1 do
    if self.entities[i].to_destroy then
      table.remove(self.entities, i)
    end
  end
  for _, entity in ipairs(queue) do
    entity.to_destroy = nil  -- Clear the flag
  end
end
```

---

## 2. Why Deferred Destruction?

### The Problem: Table Mutation During Iteration

Lua's `ipairs` iterates by integer index. If you `table.remove` an element at index `i` during iteration:

```
Initial: [e1, e2, e3, e4]  (indices 1,2,3,4)
Iteration i=1: process e1
Iteration i=2: process e2 → destroys e1
  table.remove shifts: [e2, e3, e4]  (e2 now at index 1, e3 at 2, e4 at 3)
Iteration i=3: process e4  ← SKIPS e3!
```

**Result:** Entities after the removed one get skipped.

### The Solution: Mark-and-Sweep

1. **Mark phase** (during loop): Set `entity.to_destroy = true`, add to `entities_to_destroy` queue, call `onDestroy()` immediately for cleanup.
2. **Sweep phase** (after loop): Iterate `self.entities` **backwards** and remove all marked entities.

**Backwards iteration** avoids the index-shift problem:
```
[i=4] remove? no
[i=3] remove? yes → remove, indices 1-2 unaffected
[i=2] remove? no
[i=1] remove? no
```

---

## 3. Key Invariants

### Invariant 1: `current_tick_entity` is the Loop Guard
- `current_tick_entity` is **non-nil** only during entity iteration.
- `destroyEntity` checks this to decide: defer vs. immediate.
- Cleared **before** `_flushDestroyedEntities()`.

### Invariant 2: `onDestroy` Runs Exactly Once
- Called immediately when `destroyEntity` is invoked (deferred or immediate).
- Guarded by `entity.to_destroy` check at start of `destroyEntity`.
- Even if queued multiple times, `onDestroy` runs once.

### Invariant 3: `entities_to_destroy` Queue is Per-Loop
- Created lazily (handles old savegames without the field).
- Reset to `{}` at start of `_flushDestroyedEntities()`.
- Survives across loops if error interrupts flush (see §6).

### Invariant 4: `to_destroy` Flag is Cleared After Flush
- Allows entity to be destroyed again in future loops if somehow resurrected (not typical).
- Prevents stale flag from affecting new loops.

---

## 4. Edge Cases & Tested Scenarios

### 4.1 Immediate Destruction (Outside Loop)
```lua
world:destroyEntity(e1)
-- e1 removed from entities immediately
-- e1.onDestroy() called
-- entities_to_destroy unchanged
```
**Test:** `world_spec.lua:108–118`

### 4.2 Deferred Destruction (During Loop)
```lua
world.current_tick_entity = e2
world:destroyEntity(e2)
-- e2.to_destroy = true
-- e2 added to entities_to_destroy
-- e2.onDestroy() called
-- e2 STAYS in self.entities until flush
```
**Test:** `world_spec.lua:130–150`

### 4.3 No Double-Queue
```lua
world.current_tick_entity = e1
world:destroyEntity(e1)
world:destroyEntity(e1)  -- Second call
-- entities_to_destroy length = 1
```
**Test:** `world_spec.lua:152–161`

### 4.4 Multiple Deferred in One Loop
```lua
world.current_tick_entity = e2
world:destroyEntity(e2)
world:destroyEntity(e4)
-- Both queued, both flushed together
```
**Test:** `world_spec.lua:163–177`

### 4.5 Earlier Entity Destroyed Mid-Loop (No Skip)
```lua
e2.tick = function()
  world:destroyEntity(e1)  -- Already ticked (index < current)
  world:destroyEntity(e4)  -- Not yet ticked (index > current)
end
-- e1, e2, e3 all tick. e4 destroyed, no tick.
```
**Test:** `world_spec.lua:189–211`

### 4.6 Later Entity Destroyed Early (No Tick)
```lua
e1.tick = function()
  world:destroyEntity(e3)  -- e3 not yet ticked
end
-- e1 ticks, e2 ticks, e3 destroyed (no tick), e4 ticks
```
**Test:** `world_spec.lua:213–228`

### 4.7 Self-Destruction During Tick
```lua
e1.tick = function()
  world:destroyEntity(self)  -- Destroy self
end
-- e1 ticks once, onDestroy runs, e1 removed after loop
-- e2 ticks normally
```
**Test:** `world_spec.lua:230–245`

### 4.8 Cascading Destruction (onDestroy → destroyEntity)
```lua
e2.tick = function() world:destroyEntity(e3) end
e3.onDestroy = function() world:destroyEntity(e4) end
-- e2 ticks → destroys e3 → e3.onDestroy destroys e4
-- All three marked, all flushed after loop
```
**Test:** `world_spec.lua:247–270`

### 4.9 Entities Added During Loop (ipairs Sees Them)
```lua
e2.tick = function()
  world.entities[#world.entities + 1] = e4  -- Append during iteration
end
-- ipairs in Lua 5.1+ sees new elements at end
-- e4 ticks in SAME loop
```
**Test:** `world_spec.lua:272–288`

### 4.10 Interrupted Loop (Error Recovery)
```lua
world.current_tick_entity = e1
world:destroyEntity(e2)  -- Queued
world.current_tick_entity = nil  -- Error handler clears WITHOUT flush
-- Next loop:
runTickLoop(world)  -- Flushes e2 from previous loop
```
**Test:** `world_spec.lua:290–306`
**Real code:** `app.lua:1242–1248` clears `current_tick_entity` on timer error.

### 4.11 Old Savegame (Missing entities_to_destroy)
```lua
world.entities_to_destroy = nil  -- Old savegame
world.current_tick_entity = e1
world:destroyEntity(e2)
-- Lazy creates queue, works normally
```
**Test:** `world_spec.lua:429–456`

### 4.12 Stray Entity (Not in World)
```lua
stray = makeEntity("stray")  -- Never added to world
world.current_tick_entity = e1
world:destroyEntity(stray)
-- stray.onDestroy() called
-- stray.to_destroy = true
-- stray added to queue
-- Flush: stray not in entities, just flag cleared
```
**Test:** `world_spec.lua:458–474`

### 4.13 Double Flush Safety
```lua
world:_flushDestroyedEntities()
world:_flushDestroyedEntities()  -- Second call
-- No-op, no crash
```
**Test:** `world_spec.lua:476–488`

### 4.14 Nested Iteration
```lua
e2.tick = function()
  for _, inner in ipairs(world.entities) do  -- Nested loop
    if inner == e3 then world:destroyEntity(e3) end
  end
end
-- current_tick_entity still e2 (outer)
-- e3 queued, flushed after OUTER loop ends
```
**Test:** `world_spec.lua:490–510`

### 4.15 tickDay Loop (Humanoids + Plants)
```lua
-- Separate loop, same pattern
for _, entity in ipairs(self.entities) do
  if entity.kind == "humanoid" and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:tickDay()
  elseif class.is(entity, Plant) and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:tickDay()
  end
end
```
**Test:** `world_spec.lua:367–410`

### 4.16 checkForDeadlock Loop
```lua
for _, entity in ipairs(self.entities) do
  if entity.checkForDeadlock and not entity.to_destroy then
    self.current_tick_entity = entity
    entity:checkForDeadlock()
  end
end
```
**Test:** `world_spec.lua:412–427`

---

## 5. Correct vs. Incorrect Patterns

### ✅ CORRECT: Defer During Iteration
```lua
function Entity:tick()
  if self.shouldDie then
    self.world:destroyEntity(self)  -- Safe: defers if in loop
  end
end

function Room:onDestroy()
  for _, obj in ipairs(self.objects) do
    self.world:destroyEntity(obj)  -- Safe: cascading, defers
  end
end
```

### ✅ CORRECT: Immediate Outside Loop
```lua
function World:loadGame()
  for _, entity in ipairs(self.entities) do
    if entity.corrupted then
      self:destroyEntity(entity)  -- No loop → immediate removal
    end
  end
end
```

### ✅ CORRECT: Check to_destroy Before Work
```lua
function World:onTick()
  for _, entity in ipairs(self.entities) do
    if entity.ticks and not entity.to_destroy then  -- GUARD
      self.current_tick_entity = entity
      entity:tick()
    end
  end
  -- ...
end
```

### ❌ INCORRECT: Direct table.remove During Loop
```lua
function Entity:tick()
  if self.shouldDie then
    for i, e in ipairs(self.world.entities) do
      if e == self then
        table.remove(self.world.entities, i)  -- BREAKS ITERATION
        break
      end
    end
  end
end
```

### ❌ INCORRECT: Forgetting to_destroy Guard
```lua
function World:onTick()
  for _, entity in ipairs(self.entities) do
    if entity.ticks then  -- Missing: and not entity.to_destroy
      entity:tick()  -- Dead entity gets ticked!
    end
  end
end
```

### ❌ INCORRECT: Clearing current_tick_entity Before Flush
```lua
function World:onTick()
  for _, entity in ipairs(self.entities) do
    -- ...
  end
  self.current_tick_entity = nil
  -- ERROR HERE: crash before flush
  self:_flushDestroyedEntities()  -- Never reached
end
```
**Real-world:** `app.lua:1248` clears `current_tick_entity` on error, but next loop flushes stale queue.

### ❌ INCORRECT: Not Iterating Backwards in Flush
```lua
function World:_flushDestroyedEntities()
  for i = 1, #self.entities do  -- FORWARD: breaks on consecutive removes
    if self.entities[i].to_destroy then
      table.remove(self.entities, i)
    end
  end
end
```

### ❌ INCORRECT: Modifying Queue During Flush
```lua
function World:_flushDestroyedEntities()
  for _, entity in ipairs(self.entities_to_destroy) do
    -- Bad: entity.onDestroy might call destroyEntity → modifies queue
    entity:onDestroy()  -- Already called in destroyEntity!
  end
end
```

---

## 6. Error Recovery & Robustness

### The Error Handler (app.lua:1242–1248)
```lua
if self.world and last_dispatch_type == "timer" and self.world.current_tick_entity then
  local entity = self.world.current_tick_entity
  self.world.current_tick_entity = nil  -- Clears WITHOUT flush
  -- Shows dialog, offers recovery
end
```

**Consequence:** If a timer error occurs mid-tick:
1. `current_tick_entity` cleared
2. `entities_to_destroy` queue **survives** (not flushed)
3. Next tick loop runs → `_flushDestroyedEntities()` cleans up previous loop's queue

**Test:** `world_spec.lua:290–306` verifies this recovery.

### Old Savegame Compatibility
- Savegames from before deferred destruction lack `entities_to_destroy` field.
- `destroyEntity` lazily creates it: `world.lua:1856–1859`
- `_flushDestroyedEntities` handles nil: `world.lua:1878–1883`
- **Test:** `world_spec.lua:429–456`

---

## 7. Code Locations Summary

| Concept | File | Lines |
|---------|------|-------|
| Main tick loop | `world.lua` | 971–978 |
| tickDay loop | `world.lua` | 1055–1065 |
| checkForDeadlock loop | `world.lua` | 1179–1186 |
| destroyEntity | `world.lua` | 1844–1872 |
| _flushDestroyedEntities | `world.lua` | 1877–1893 |
| Entity:onDestroy | `entity.lua` | 281–289 |
| Error handler | `app.lua` | 1242–1248 |
| Tests | `world_spec.lua` | 1–511 |

---

## 8. Design Principles

1. **Immediate cleanup, deferred removal** — `onDestroy` runs at destroy time (cleanup), table removal happens after loop (iteration safety).

2. **Single source of truth** — `destroyEntity` is the ONLY way to remove entities. Direct `table.remove` is forbidden during iteration.

3. **Idempotent destroy** — Calling `destroyEntity` twice is safe (guarded by `to_destroy`).

4. **Loop-agnostic queue** — Same `entities_to_destroy` serves all three loops. Flush runs after each.

5. **Backwards compatibility** — Lazy queue creation + nil checks handle old savegames.

6. **Test-driven invariants** — 23 test cases in `world_spec.lua` cover every edge case.

---

## 9. Common Pitfalls for Contributors

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Adding new iteration loop without `current_tick_entity` guard | Entities skipped/destroyed incorrectly | Copy the exact loop pattern from existing loops |
| Calling `destroyEntity` in `onDestroy` without understanding cascade | Double-destroy, queue corruption | It's SAFE — cascading is tested and works |
| Forgetting `not entity.to_destroy` in new loop | Dead entities ticked | Always copy the guard condition |
| Iterating `entities` in UI code without deferring | Crash/skip if entity dies | Use `destroyEntity`, not direct removal |
| Assuming `entities` is stable during tick | Bugs when entities spawn/die | Remember: `ipairs` sees appends; defer handles removes |

---

## 10. Conclusion

CorsixTH's entity iteration pattern is a **robust mark-and-sweep deferred destruction system** with:
- Three synchronized iteration loops
- Lazy initialization for savegame compatibility
- Comprehensive test coverage (23 cases)
- Error recovery that preserves queue integrity
- Cascading destruction support

**When modifying entity lifecycle code:** Always use `World:destroyEntity()`. Never manipulate `self.entities` directly during iteration. The pattern is simple but must be followed exactly.
