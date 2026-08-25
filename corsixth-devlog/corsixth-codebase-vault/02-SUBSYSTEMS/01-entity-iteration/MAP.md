# Entity Iteration & Destruction — File:Line Index

Complete cross-reference for all iteration-related code in CorsixTH.

---

## world.lua — Core Iteration Loops

| Lines | Function | Description |
|-------|----------|-------------|
| 971–978 | `World:onTick()` | Main per-tick entity loop |
| 972 | | `if entity.ticks and not entity.to_destroy then` |
| 973 | | `self.current_tick_entity = entity` |
| 974 | | `entity:tick()` |
| 977 | | `self.current_tick_entity = nil` |
| 978 | | `self:_flushDestroyedEntities()` |
| 1055–1065 | `World:onEndDay()` | Per-day loop (humanoids + plants) |
| 1056 | | `if entity.ticks and class.is(entity, Humanoid) and not entity.to_destroy then` |
| 1057 | | `self.current_tick_entity = entity` |
| 1058 | | `entity:tickDay()` |
| 1059–1061 | | `elseif class.is(entity, Plant) and not entity.to_destroy then` |
| 1060 | | `self.current_tick_entity = entity` |
| 1061 | | `entity:tickDay()` |
| 1064 | | `self.current_tick_entity = nil` |
| 1065 | | `self:_flushDestroyedEntities()` |
| 1179–1186 | `World:onEndMonth()` | Per-month deadlock check loop |
| 1180 | | `if entity.checkForDeadlock and not entity.to_destroy then` |
| 1181 | | `self.current_tick_entity = entity` |
| 1182 | | `entity:checkForDeadlock()` |
| 1185 | | `self.current_tick_entity = nil` |
| 1186 | | `self:_flushDestroyedEntities()` |

---

## world.lua — Destruction Mechanism

| Lines | Function | Description |
|-------|----------|-------------|
| 63 | `World:World()` | `self.entities_to_destroy = {}` initialization |
| 1844–1872 | `World:destroyEntity(entity)` | Core destruction function |
| 1845–1848 | | Early return if `entity.to_destroy` |
| 1849–1862 | | **Deferred path**: `current_tick_entity` set → mark, queue, onDestroy |
| 1853 | | `entity.to_destroy = true` |
| 1856–1859 | | Lazy queue creation for old savegames |
| 1861 | | `queue[#queue + 1] = entity` |
| 1862 | | `entity:onDestroy()` — runs immediately |
| 1863–1870 | | **Immediate path**: linear search + `table.remove` + onDestroy |
| 1877–1893 | `World:_flushDestroyedEntities()` | Sweep phase |
| 1878 | | `local queue = self.entities_to_destroy` |
| 1879–1883 | | Handle nil/empty queue (old savegame) |
| 1884 | | `self.entities_to_destroy = {}` — reset for next loop |
| 1885–1888 | | **Backwards iteration** removing marked entities |
| 1890–1892 | | Clear `to_destroy` flag on queued entities |

---

## world.lua — Other Entity Iterations (Non-Tick Loops)

| Lines | Context | Notes |
|-------|---------|-------|
| 648 | `World:save()` | Iterates for serialization — no destruction |
| 1864 | `destroyEntity` immediate path | Linear search for entity |
| 2460 | `World:getEntitiesInRoom()` | Filter helper — no destruction |
| 2500 | `World:findObject()` | Search helper |
| 2504 | `World:findObjects()` | Search helper |
| 2578 | `World:updateRoomObjects()` | Room-related iteration |
| 2776 | `World:onGameHourChanged()` | Hourly update |
| 2829 | `World:onGameMonthChanged()` | Monthly update |
| 2925 | `World:updateStaffRoom()` | Staff room iteration |

---

## entity.lua — Entity Lifecycle

| Lines | Function | Description |
|-------|----------|-------------|
| 281–289 | `Entity:onDestroy()` | Cleanup: mood, tile, pickup, audio |
| 283 | | `self:setMoodInfo()` |
| 284 | | `self:setTile(nil)` |
| 285 | | `self:onPickUp()` |
| 286–288 | | Audio cleanup |
| 292–294 | `Entity:onPickUp()` | `self.world.dispatcher:dropFromQueue(self)` |

---

## app.lua — Error Recovery

| Lines | Context | Description |
|-------|---------|-------------|
| 1242–1248 | `App:handleError()` | Timer error handler |
| 1242 | | `if self.world.current_tick_entity then` |
| 1247–1248 | | `local entity = self.world.current_tick_entity; self.world.current_tick_entity = nil` |
| 1249–1253 | | Shows entity-specific dialog (Patient/Staff) |
| 1254–1262 | | Recovery dialog: disables entity.ticks, restores handler |

---

## world_spec.lua — Test Coverage (23 Tests)

| Lines | Test Name | Scenario |
|-------|-----------|----------|
| 108–118 | removes entity immediately outside an entities loop | Immediate destroy |
| 120–128 | destroys entity not present in the list | Stray entity immediate |
| 130–150 | defers removal while iterating the entities list | Basic deferral |
| 152–161 | queues an entity for destruction only once | Idempotent queue |
| 163–177 | flushes multiple deferred destructions in one pass | Multi-defer flush |
| 179–187 | flush does nothing with an empty queue | Empty flush |
| 189–211 | does not skip entities when an earlier entity is destroyed mid-loop | No-skip earlier |
| 213–228 | does not tick an entity destroyed earlier in the same loop | No-tick later |
| 230–245 | destroys itself during its tick and is removed after the loop | Self-destroy |
| 247–270 | handles cascading destructions during a single loop | Cascade onDestroy |
| 272–288 | ticks entities added to the list during the loop | Added during loop |
| 290–306 | recovers when the loop is interrupted before flushing | Error recovery |
| 308–321 | does nothing when destroying an already queued entity outside a loop | Double-destroy queued |
| 323–338 | destroys immediately outside a loop even with pending queued entities | Immediate with pending |
| 340–365 | reuses the queue across consecutive loops | Queue reuse |
| 367–388 | does not skip entities destroyed during the tickDay loop | tickDay no-skip |
| 390–410 | defers destruction triggered by a plant during the tickDay loop | tickDay plant defer |
| 412–427 | does not skip entities destroyed during the checkForDeadlock loop | Deadlock no-skip |
| 429–438 | flush does nothing when the queue is missing (old savegame) | Old savegame flush |
| 440–456 | creates the queue lazily when destroying during a loop on an old savegame | Old savegame defer |
| 458–474 | destroys an entity not in the list during a loop without side effects | Stray in loop |
| 476–488 | flush is safe to call twice in a row | Double flush |
| 490–510 | destroys from a nested iteration still defer until the outer loop ends | Nested iteration |

---

## Other Files — External Iterations

| File | Line | Context |
|------|------|---------|
| `hospitals/player_hospital.lua` | 499 | `for _, e in ipairs(self.world.entities) do` — UI/query |
| `hospital.lua` | 2172 | `for _, v in ipairs(self.world.entities) do` — Hospital logic |
| `dialogs/edit_room.lua` | 272 | `for _, entity in ipairs(world.entities) do` — Room editor |
| `objects/reception_desk.lua` | 179 | `for _, entity in ipairs(self.world.entities) do` — Reception logic |
| `calls_dispatcher.lua` | 296 | `for _, e in ipairs(self.world.entities) do` — Dispatcher |
| `dialogs/machine_dialog.lua` | 144 | `for _, entity in ipairs(ui.app.world.entities) do` — Machine UI |

**Note:** These external iterations are **read-only** (queries/UI). They do NOT destroy entities during iteration. If they need to destroy, they must call `world:destroyEntity(entity)` which handles deferral correctly.

---

## Key Variables — Cross-Reference

| Variable | Defined | Used In |
|----------|---------|---------|
| `self.entities` | `world.lua:62` | All loops, destroyEntity, flush, external |
| `self.entities_to_destroy` | `world.lua:63` | destroyEntity, _flushDestroyedEntities |
| `self.current_tick_entity` | `world.lua:973` (first use) | All 3 loops, destroyEntity, app.lua error handler |
| `entity.to_destroy` | `world.lua:1853` | All 3 loop guards, destroyEntity, flush |
| `entity.destroyed` | `entity.lua:281` (set in onDestroy) | Test assertions, external checks |

---

## Call Graph: destroyEntity Flow

```
destroyEntity(entity)
├── if entity.to_destroy → return
├── if self.current_tick_entity (IN LOOP)
│   ├── entity.to_destroy = true
│   ├── lazy create entities_to_destroy
│   ├── queue[#queue+1] = entity
│   └── entity:onDestroy()  ← CLEANUP RUNS NOW
└── else (OUTSIDE LOOP)
    ├── linear search self.entities
    ├── table.remove(self.entities, i)
    └── entity:onDestroy()  ← CLEANUP RUNS NOW

_flushDestroyedEntities()
├── queue = self.entities_to_destroy
├── if not queue or #queue==0 → return
├── self.entities_to_destroy = {}
├── for i = #self.entities, 1, -1
│   └── if self.entities[i].to_destroy → table.remove
└── for _, entity in ipairs(queue)
    └── entity.to_destroy = nil
```

---

## Savegame Compatibility Points

| Feature | Added In | Old Savegame Handling |
|---------|----------|----------------------|
| `entities_to_destroy` table | Deferred destruction PR | `world.lua:1856–1859` lazy create |
| `entity.to_destroy` flag | Deferred destruction PR | Defaults to `nil` → falsey in guards |
| `_flushDestroyedEntities` nil check | Deferred destruction PR | `world.lua:1879–1883` early return |

---

## Grep Patterns for Future Searches

```bash
# All iteration loops
grep -n "for _, entity in ipairs(self.entities)" Lua/world.lua

# All destruction calls
grep -n "destroyEntity" Lua/world.lua Lua/entity.lua Lua/*.lua

# All flush calls
grep -n "_flushDestroyedEntities" Lua/world.lua

# All current_tick_entity uses
grep -n "current_tick_entity" Lua/world.lua Lua/app.lua

# All to_destroy checks
grep -n "to_destroy" Lua/world.lua Lua/entity.lua
```

---

**Generated from:** CorsixTH codebase analysis  
**Core files:** `world.lua` (3055 lines), `entity.lua` (373 lines), `world_spec.lua` (511 lines), `app.lua` (2188 lines)


## Related Pages

- [[01-entity-iteration/SUMMARY]]
- [[01-entity-iteration/CHECKLIST]]
- [[01-entity-iteration/SCAFFOLD]]
