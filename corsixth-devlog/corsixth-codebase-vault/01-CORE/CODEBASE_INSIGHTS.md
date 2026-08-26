# CorsixTH Codebase Insights

> For safe, minimal bug fixes | Generated: 2026-08-17

---

## 1. Entity Iteration is Fragile

The main game loop (`world.lua:971`) iterates `self.entities` with `ipairs`. Any modification during iteration causes skips. The deferred destruction system (`to_destroy` + `_flushDestroyedEntities`) was added specifically to fix #1467. **Any new code that modifies `self.entities` during iteration will reintiterate the same class of bug.**

**Key loop structure:**
```lua
-- world.lua:971-978
for _, entity in ipairs(self.entities) do
    if entity.ticks and not entity.to_destroy then
        self.current_tick_entity = entity
        entity:tick()
    end
end
self.current_tick_entity = nil
self:_flushDestroyedEntities()
```

**Related loops:**
- `onEndDay` (`world.lua:1055-1065`): filters by `Humanoid`/`Plant`, calls `tickDay()`
- `onEndMonth` (`world.lua:1179-1186`): calls `checkForDeadlock()`
- `markRoomAsBuilt` (`world.lua:648-652`): calls `notifyNewRoom()`

---

## 2. Two Different Collection Types

| Collection | Type | Iterator | Notes |
|-----------|------|----------|-------|
| `self.entities` | Dense array | `ipairs` | No gaps allowed |
| `self.rooms` | Sparse array | `pairs` | Rooms can be deleted, leaving gaps |
| `room.humanoids` | Set (key→true) | `pairs` | All humanoids in room |
| `room.objects` | Set (key→true) | `pairs` | All objects in room |
| `room.humanoids_enroute` | Set (key→true) | `pairs` | Humanoids walking to room |

Mixing `ipairs` on a sparse collection or `pairs` on a dense one = bugs.

---

## 3. Destruction Has Two Paths

**During tick** (`current_tick_entity` set):
1. Set `entity.to_destroy = true`
2. Append to `entities_to_destroy` queue
3. Call `entity:onDestroy()` immediately
4. Entity stays in `entities` until flushed

**Outside tick**:
1. Direct `table.remove` from `entities`
2. Call `entity:onDestroy()`

**Code at `world.lua:1844-1872`:**
```lua
function World:destroyEntity(entity)
  if entity.to_destroy then
    return  -- Already queued
  end
  if self.current_tick_entity then
    -- Deferred path
    entity.to_destroy = true
    local queue = self.entities_to_destroy
    if not queue then
      queue = {}
      self.entities_to_destroy = queue
    end
    queue[#queue + 1] = entity
    entity:onDestroy()
  else
    -- Immediate path
    for i, e in ipairs(self.entities) do
      if e == entity then
        table.remove(self.entities, i)
        break
      end
    end
    entity:onDestroy()
  end
end
```

---

## 4. Room Crash = Cascading Destructions

`room.lua:857-964` (`crashRoom`) destroys all humanoids AND objects in one call. This means **multiple entities get `to_destroy=true` in a single tick** — exactly why no `break` in `_flushDestroyedEntities`.

**Implication for PR #3504:** The `_flushDestroyedEntities` loop must process ALL marked entities, not just the first one found.

---

## 5. Test Patterns Are Lightweight

Tests use `setmetatable(world, {__index = World})` with stub entities — no full engine needed.

**Pattern from `world_spec.lua`:**
```lua
local function makeEntity(name)
  return {
    ticks = true, tick_count = 0, to_destroy = false,
    name = name,
    tick = function(self) self.tick_count = self.tick_count + 1 end,
    onDestroy = function() end,
  }
end

local function makeWorld(entities)
  local world = {
    entities = entities,
    entities_to_destroy = {},
    current_tick_entity = nil,
  }
  setmetatable(world, {__index = World})
  return world
end
```

**Key insight:** You can write focused tests by:
1. Creating stub entities with `ticks=true` and `tick()`/`onDestroy()` mocks
2. Building a minimal world table with just the fields your code touches
3. Using `runTickLoop(world)` helpers that mirror the real loop structure

---

## 6. `calls_dispatcher` Scans All Entities

`calls_dispatcher.lua:296` iterates `ipairs(world.entities)` to find staff. If entity ordering changes unexpectedly (e.g., from a destruction bug), staff assignment behavior changes silently — no crash, just wrong behavior.

---

## 7. Key Lifecycle Hooks

| Hook | Location | Purpose |
|------|----------|---------|
| `Entity:onDestroy()` | `entity.lua:281-289` | Clears mood, sets tile to nil, calls `onPickUp`, cleans up sound callbacks |
| `Entity:onPickUp()` | `entity.lua:292-294` | Calls `world.dispatcher:dropFromQueue(self)` |
| `Entity:tickDay()` | `entity.lua:299-300` | Empty stub; overridden in subclasses |
| `Entity:tick()` | `entity.lua:199-227` | Advances animation, processes timer countdown |
| `Entity:afterLoad()` | `entity.lua:341-342` | Stub for save-game compatibility migration |
| `Entity:eraseObject()` | `entity.lua:355-357` | Gives entity a chance to clear from map before reset |
| `Entity:notifyNewRoom()` | `entity.lua:311-312` | Called when new room is built |
| `Humanoid:onDestroy()` | `humanoid.lua:441-452` | Notifies occupant-change objects, calls `unregisterCallbacks()` |

---

## 8. Room as Container

Rooms maintain three **sets** (not lists):
- `self.humanoids` — all humanoids physically inside
- `self.objects` — all objects inside
- `self.humanoids_enroute` — humanoids walking toward the room

**Entry flow** (`room.lua:316-436`):
- Sets `humanoid.in_room = self`
- Adds to `self.humanoids[humanoid] = true`
- Tests staff criteria, calls `commandEnteringStaff()` or `commandEnteringPatient()`

**Exit flow** (`room.lua:569-658`):
- Clears `humanoid.in_room`
- Removes from `self.humanoids`
- May trigger staff to go to staffroom

---

## 9. State Management Patterns

**Entity core state:**
- `self.ticks` — Boolean; if true, entity gets `tick()` calls
- `self.to_destroy` — Boolean; set during deferred destruction
- `self.world` — Back-reference to World
- `self.tile_x, self.tile_y` — Current map position

**Patient state:**
- `self.diagnosis_progress` — Float (0 to ~2.5)
- `self.disease` — Current disease object
- `self.diagnosed` — Boolean
- `self.cured`, `self.dead` — Terminal states

**Room state:**
- `self.is_active` — Room accepts patients
- `self.crashed` — Room has exploded
- `self.needs_repair` — Locks room during handyman repair

---

## 10. Risk Areas for Changes

| Area | Risk | Notes |
|------|------|-------|
| `humanoid.lua` | HIGH | Core logic, touches everything |
| `world.lua` | HIGH | Game loop, simulation |
| `hospital.lua` | HIGH | Room/building management |
| `entity.lua` | MEDIUM | Base entity behavior |
| `room.lua` | MEDIUM | Room logic shared by all rooms |
| `calls_dispatcher.lua` | MEDIUM | AI coordination |
| Specific disease/room files | LOW | Isolated functionality |
| Dialog/UI files | LOW | Visual only |

---

## 11. Recommended Workflow for Minimal Changes

1. **Identify exact bug** — Reproduce first
2. **Find minimal fix location** — Use `grep` to trace related code
3. **Write failing test** — In corresponding `_spec.lua`
4. **Apply minimal fix** — Change only what's necessary
5. **Run full test suite** — Ensure no regressions
6. **Manual test** — Verify in-game behavior

---

## 12. Running Tests

```bash
cd CorsixTH/Luatest
busted --lpath=../Lua/?.lua
```

---

## 13. Building

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```


## Related Pages

- [[CLASS_MAPPING]]
- [[CODEBASE_MAP]]
- [[TEST_IMPLEMENTATIONS]]
- [[safe-fix-patterns]]
