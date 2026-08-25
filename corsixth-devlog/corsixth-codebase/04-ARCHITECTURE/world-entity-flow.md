# World → Entity Destruction Flow

## Overview
The entity destruction system prevents iteration skipping when `destroyEntity` is called during an `ipairs` loop over `world.entities`.

## Core Problem
```lua
for _, entity in ipairs(world.entities) do
  entity:tick()  -- may call destroyEntity on another entity
end
```
If `destroyEntity` removes an entity mid-loop, subsequent entities shift left, skipping the next one.

## Solution: Deferred Destruction
```
World:tick()
  → for entity in ipairs(entities)
      → entity:tick()  -- may call destroyEntity()
          → if current_tick_entity: queue in entities_to_destroy
          → else: immediate remove
  → _flushDestroyedEntities()
      → backward iteration remove queued entities
```

## Key Components

### 1. `World:destroyEntity(entity)` (world.lua:1844)
```lua
function World:destroyEntity(entity)
  if entity.to_destroy then return end
  if self.current_tick_entity then
    entity.to_destroy = true
    self.entities_to_destroy[#self.entities_to_destroy + 1] = entity
    entity:onDestroy()
  else
    for i, e in ipairs(self.entities) do
      if e == entity then table.remove(self.entities, i); break end
    end
    entity:onDestroy()
  end
end
```

### 2. `World:_flushDestroyedEntities()` (world.lua:1849)
```lua
function World:_flushDestroyedEntities()
  local queue = self.entities_to_destroy
  if #queue == 0 then return end
  self.entities_to_destroy = {}
  for i = #self.entities, 1, -1 do
    if self.entities[i].to_destroy then table.remove(self.entities, i) end
  end
  for _, entity in ipairs(queue) do entity.to_destroy = nil end
end
```

### 3. `World:afterLoad(old, new)` - Queue Initialization (world.lua:2552)
```lua
if old < 265 then
  self.entities_to_destroy = {}  -- Deferred entity destruction queue
end
```

## Constructor Initialization (world.lua:63)
```lua
function World:World(app, free_build_mode)
  self.entities = {}
  self.entities_to_destroy = {}  -- New games get queue immediately
  -- ...
end
```

## Save/Load Integration
```
LoadGame()
  → persist.load() → deserialize state
  → World:afterLoad(old, new)
      → if old < 265: entities_to_destroy = {}
  → TheApp:afterLoad()
```

## Version History
| Version | Change |
|---------|--------|
| 264 | SDL 3 migration |
| **265** | **Deferred entity destruction fix** (this PR) |

## Tests (world_spec.lua)
| Test | Coverage |
|------|----------|
| Immediate destroy | Entity removed immediately outside iteration |
| Deferred destroy | Entity queued, removed after loop |
| No-skip | Middle entity destroys first, third not skipped |
| Self-destruct | Entity destroys itself during tick |
| Cascading | Destroy triggers another destroy |
| Old-save compat | `old < 265` initializes queue |
| Plant tickDay | Plant branch sets `current_tick_entity` |
| checkForDeadlock | Iteration with destroyEntity |
| Nested iterations | Loop within loop |

## Cross-References
- [[PR-3504]] - Implementation PR
- [[save-load-migrations]] - Migration pattern details
- [[entity-action-system]] - How actions call destroyEntity
- Area: [[01-CODEBASE/01-entity-iteration]]
