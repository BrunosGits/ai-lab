# CorsixTH Save/Load & Migration Architecture

## Executive Summary

CorsixTH employs a **two-layer persistence architecture** combining a high-performance C++ binary serializer with a Lua wrapper that manages game-specific object graphs, permanent object registration, and versioned migration hooks. The system supports **73 classes** with `afterLoad(old, new)` methods, enabling backward compatibility across hundreds of savegame versions.

---

## 1. Two-Layer Architecture

### 1.1 C++ Binary Layer (`persist_lua.cpp` / `persist_lua.h`)

The C++ layer implements a **custom binary format** with:

- **Variable-length integer encoding** (VLQ/LEB128-style) for compact storage
- **Object deduplication** via reference counting — each unique object written once
- **Cycle detection** — handles circular references in object graphs
- **Type tags** (16 distinct types, `PERSIST_TCOUNT = 16`):
  - Basic: `LUA_TNIL`, `LUA_TBOOLEAN`/`PERSIST_TTRUE`, `LUA_TNUMBER`/`PERSIST_TINTEGER`, `LUA_TSTRING`
  - Complex: `LUA_TTABLE`/`PERSIST_TTABLE_WITH_META`, `LUA_TFUNCTION`, `LUA_TUSERDATA`
  - Special: `PERSIST_TPERMANENT`, `PERSIST_TPROTOTYPE`

#### Writer (`lua_persist_basic_writer`)
- Maintains `next_index` counter for object IDs
- Uses Lua environment table as **object → index cache**
- `write_stack_object()` checks cache first, writes new objects via `write_object_raw()`
- `fast_write_stack_object()` optimizes userdata with `__persist` metamethod
- Prototype persistence: extracts `--[[persistable:name]]` annotated functions from source files

#### Reader (`lua_persist_basic_reader`)
- Reads type tag, dispatches to type-specific handler
- **Two-pass userdata depersistence**: 
  1. `__pre_depersist` (optional, for C++ placement new)
  2. `__depersist` (main deserialization)
- **Deferred `__depersist` calls**: objects needing second pass queued in metatable array
- Sync marker `0x42` validates userdata integrity

### 1.2 Lua Wrapper Layer (`persistance.lua`)

The Lua layer provides **game-aware persistence**:

```lua
-- persistance.lua:236-252
function SaveGame()
  local state = {
    ui = TheApp.ui,
    world = TheApp.world,
    map = TheApp.map,
    random = math.randomdump(),
  }
  state.map:prepareForSave()
  local result, err, obj = persist.dump(state, MakePermanentObjectsTable(false))
  state.map:afterSave()
  return result
end
```

```lua
-- persistance.lua:286-321
function LoadGame(data)
  local objtable = MakePermanentObjectsTable(true)
  local state = assert(persist.load(data, objtable))
  -- Version heuristic for pre-166 saves
  if not state.world.gfx_set then
    state.world.gfx_set = gfxSetHeuristic(state.map, state.world)
  end
  if not TheApp:checkCompatibility(state.world.savegame_version, state.world.gfx_set) then return end
  
  state.ui:resync(TheApp.ui)
  TheApp.ui = state.ui
  TheApp.world = state.world
  TheApp.map = state.map
  math.randomseed(state.random)
  
  -- Cursor/menu bar fixup
  TheApp.ui.menu_bar.ui = TheApp.ui
  TheApp.ui.menu_bar:onChangeLanguage()
  
  TheApp.world.map:registerTemperatureDisplayMethod()
  TheApp.audio:playSoundEffects(TheApp.config.play_sounds)
  TheApp:afterLoad()  -- Triggers migration cascade
  TheApp.world:resetAnimations()
  TheApp.ui:onChangeResolution()
end
```

---

## 2. Permanent Object Registration

### 2.1 `permanent(name, value)` / `unpermanent(name)`

```lua
-- persistance.lua:50-64
function permanent(name, ...)
  if select('#', ...) == 0 then
    return function (...) return permanent(name, ...) end
  end
  local value = ...
  assert(value ~= nil)
  assert(saved_permanents[name] == nil)
  saved_permanents[name] = value
  return value
end

function unpermanent(name)
  assert(saved_permanents[name] ~= nil)
  saved_permanents[name] = nil
end
```

**Usage**: Modules register singletons/global objects that should be referenced by identity, not serialized:

```lua
-- In object definitions
permanent("objects.radiator", radiator_type)

-- In C++ bindings
permanent("TH.some_class", th_class_table)
```

### 2.2 `MakePermanentObjectsTable(inverted)` — Bidirectional Mapping

This is the **core of the permanent object system**. It builds a comprehensive registry mapping:

#### Forward Mode (`inverted = false`) — **Saving**
Maps **object → persistable name string**:

```lua
-- Global functions
permanent[some_function] = "some_function"

-- Lua classes: Class table, metatable, methods
permanent[MyClass] = "MyClass.1"
permanent[MyClass_mt] = "MyClass.2"
permanent[MyClass.method] = "MyClass.method"
permanent[MyClass_mt.__index.method] = "MyClass._metatable.method"

-- C libraries (package.loaded)
permanent[TH] = "TH"
permanent[TH.some_func] = "TH.some_func"
permanent[TH.Class] = "TH.Class"
permanent[TH.Class_mt_env] = "TH.Class.<mt>"  -- Metatable call environment

-- App subsystems
permanent[TheApp] = "TheApp"
permanent[TheApp.config] = {global_fetch, "TheApp", "config"}
permanent[TheApp.objects.radiator] = {global_fetch, "TheApp", "objects", "radiator"}

-- Graphics load_info (weak keys)
permanent[gfx_obj] = {load_method, args...}

-- User-registered permanents
permanent[my_object] = "my_custom_name"
```

#### Inverted Mode (`inverted = true`) — **Loading**
Maps **persistable name → object resolver**:

```lua
-- For simple values: direct reference
permanent["TheApp.config"] = TheApp.config

-- For fetch instructions: __index metamethod executes the fetch
getmetatable(permanent).__index = function(_, k)
  if type(k) == "table" then
    return k[1](unpack(k, 2))  -- Calls global_fetch("TheApp", "config")
  end
end
```

**Critical Design**: During save, the writer looks up objects in this table. During load, the reader uses the inverted table to resolve permanent references back to live objects.

---

## 3. SaveGame / LoadGame Flow

### 3.1 SaveGame Flow

```
SaveGame()
├── Capture state: {ui, world, map, random}
├── map:prepareForSave()           -- Flush transient map state
├── persist.dump(state, permanents)
│   ├── lua_persist_basic_writer.init()
│   │   ├── Create env table with permanents[1] = permanent_table
│   │   └── Set up metatable with __gc, prototype cache
│   ├── write_stack_object(root_state)
│   │   ├── For each object: check cache → write or reference
│   │   ├── Tables: write metatable, then key/value pairs (nil-terminated)
│   │   ├── Functions: write prototype (file:line → name), upvalues, env
│   │   ├── Userdata: write metatable, env, call __persist, sync marker 0x42
│   │   └── Permanents: write PERSIST_TPERMANENT tag + name
│   └── Return binary string
├── map:afterSave()                -- Restore transient map state
└── Write to file (SaveGameFile)
```

### 3.2 LoadGame Flow

```
LoadGameFile(filename)
├── Read binary data
└── LoadGame(data)
    ├── MakePermanentObjectsTable(true)  -- Inverted resolver table
    ├── persist.load(data, objtable)
    │   ├── lua_persist_basic_reader.init()
    │   │   ├── Env: [0]=permanents, [-1]=proto code, [-2]=proto files, [-3]=self
    │   │   └── Metatable with __gc
    │   ├── read_stack_object() → root state table
    │   │   ├── Read type tag
    │   │   ├── If index ≥ 16: lookup cached object
    │   │   ├── If PERSIST_TPERMANENT: read name, resolve via permanents table
    │   │   ├── Tables: create, read metatable, read key/value until nil
    │   │   ├── Functions: load prototype factory, read upvalues, read env
    │   │   ├── Userdata: 
    │   │   │   ├── Read metatable, get __depersist_size
    │   │   │   ├── Create userdata (placement new in __pre_depersist)
    │   │   │   ├── Read env, set metatable
    │   │   │   ├── Call __depersist(userdata, reader)
    │   │   │   ├── If returns true: queue for 2nd __depersist pass
    │   │   │   └── Verify sync marker 0x42
    │   │   └── Cache all new objects by index
    │   └── finish(): verify all bytes consumed, run deferred __depersist calls
    ├── Version heuristic for pre-166 saves (gfx_set)
    ├── Compatibility check (TheApp:checkCompatibility)
    ├── Resync UI: state.ui:resync(TheApp.ui)
    ├── Swap globals: TheApp.ui/world/map = loaded versions
    ├── Restore RNG: math.randomseed(state.random)
    ├── Fix cursor & menu_bar references
    ├── TheApp:afterLoad()           -- **Migration entry point**
    ├── TheApp.world:resetAnimations()
    └── TheApp.ui:onChangeResolution()
```

---

## 4. `afterLoad(old, new)` Pattern with Version Gates

### 4.1 Migration Invocation Chain

```lua
-- app.lua:1995-2058
function App:afterLoad()
  local old = self.world.savegame_version or 0
  local new = self.savegame_version
  
  if old == 0 then
    self.world.game_log = {}
    self.world:gameLog("Created Gamelog on load of old (pre-versioning) savegame.")
  end
  if not self.world.original_savegame_version then
    self.world.original_savegame_version = old
  end
  
  -- Log version info
  -- ...
  
  -- Version-gated migrations
  if old < 87 then
    local new_object = corsixth.require("objects.gates_to_hell")
    Object.processTypeDefinition(new_object)
    self.objects[new_object.id] = new_object
    self.world:newObjectType(new_object)
  end
  
  if old < 114 then
    local rathole_type = corsixth.require("objects.rathole")
    Object.processTypeDefinition(rathole_type)
    self.objects[rathole_type.id] = rathole_type
    self.world:newObjectType(rathole_type)
  end
  
  -- Delegate to subsystems
  self.map:afterLoad(old, new)
  self.ui:afterLoad(old, new)
  self.world:afterLoad(old, new)
end
```

### 4.2 World:afterLoad — Core Gameplay Migrations

```lua
-- world.lua:2552-2765+
function World:afterLoad(old, new)
  self:setUI(self.ui)
  self:applyLevelStartPrices()
  
  if old < 4 then
    self.room_built = {}
  end
  if old < 6 then
    -- Recalculate hospital value from scratch
    local value = self.map.parcelTileCounts[...] * 25 + 20000
    for _, room in pairs(self.rooms) do ... end
    for _, object in ipairs(self.entities) do ... end
    self.hospitals[1].value = value
  end
  if old < 10 then
    -- Initialize object_counts categories
    self.object_counts = {extinguisher=0, radiator=0, plant=0, general=0}
    for _, obj in ipairs(all_objects) do
      self.object_counts[obj.object_type.count_category] += 1
    end
  end
  if old < 43 then
    self.object_counts.reception_desk = 0
    -- recount...
  end
  if old < 47 then
    self.object_counts.bench = 0
    -- recount...
  end
  -- ... 50+ more version gates up to current version
  
  -- Delegate to entities
  for _, obj in ipairs(self.entities) do
    obj:afterLoad(old, new)
  end
  self.earthquake:afterLoad(old, new)
end
```

### 4.3 Class Hierarchy Migration Chaining

**Critical Pattern**: Child classes **must call parent `afterLoad`**:

```lua
-- humanoid.lua:361-418
function Humanoid:afterLoad(old, new)
  if old < 38 and new >= 38 then
    self.attributes["health"] = math.random(60, 100) / 100
  end
  if old < 42 and new >= 42 then
    if self:isType("Slack Female Patient") then
      self.die_anims = die_animations["Slack Female Patient"]
    end
  end
  -- ... more gates ...
  
  -- Delegate to action queue
  for _, action in pairs(self.action_queue) do
    HumanoidAction.afterLoad(action, old, new)
  end
  
  -- Call parent
  Entity.afterLoad(self, old, new)
end

-- staff.lua:666-736
function Staff:afterLoad(old, new)
  if old < 133 and new >= 133 then
    -- Migration specific to version 133
    Humanoid.afterLoad(self, old, 133)
    self:afterLoad(133, new)  -- Re-run with new bounds
  end
  Humanoid.afterLoad(self, old, new)
end
```

---

## 5. Migration Examples

### 5.1 Adding New Object Types (App:afterLoad)

```lua
-- app.lua:2032-2044
if old < 87 then
  local new_object = corsixth.require("objects.gates_to_hell")
  Object.processTypeDefinition(new_object)
  self.objects[new_object.id] = new_object
  self.world:newObjectType(new_object)
end
```

### 5.2 Data Structure Migration (World:afterLoad)

```lua
-- world.lua:2587-2613
if old < 10 then
  self.object_counts = {extinguisher=0, radiator=0, plant=0, general=0}
  for _, obj_list in pairs(self.objects) do
    for _, obj in ipairs(obj_list) do
      local count_cat = obj.object_type.count_category
      if count_cat then
        self.object_counts[count_cat] = self.object_counts[count_cat] + 1
      end
    end
  end
end

if old < 43 then
  self.object_counts.reception_desk = 0
  for _, obj_list in pairs(self.objects) do
    for _, obj in ipairs(obj_list) do
      if obj.object_type.count_category == "reception_desk" then
        self.object_counts.reception_desk = self.object_counts.reception_desk + 1
      end
    end
  end
end
```

### 5.3 Enum/Constant Renaming (Humanoid:afterLoad)

```lua
-- humanoid.lua:398-410
if old < 210 then
  -- Renamed mood states: sad7→sad2, sad2-sad6→dying1-dying5
  if self:isMoodActive("sad2") then
    self:setMood("sad2", "deactivate")
    self:setMood("dying1", "activate")
  end
  if self:isMoodActive("sad7") then
    self:setMood("sad7", "deactivate")
    self:setMood("sad2", "activate")
  end
end
```

### 5.4 Field Removal/Renaming (Epidemic:afterLoad)

```lua
-- epidemic.lua:754-761
function Epidemic:afterLoad(old, new)
  if old < 106 then
    self.level_config = nil  -- Removed field
  end
  if old < 212 then
    self.coverup_selected = self.coverup_in_progress
    self.coverup_in_progress = nil  -- Renamed field
  end
end
```

### 5.5 Map Data Recalculation (Map:afterLoad)

```lua
-- map.lua:856-955
function Map:afterLoad(old, new)
  if old < 6 then
    self.parcelTileCounts = {}
    for plot = 1, self.th:getPlotCount() do
      self.parcelTileCounts[plot] = self.th:getParcelTileCount(plot)
    end
  end
  if old < 57 then
    -- Reset all cell buildable flags
    local flags = {buildableNorth=true, buildableSouth=true, buildableWest=true, buildableEast=true}
    for x = 1, self.width do
      for y = 1, self.height do
        self:setCellFlags(x, y, flags)
      end
    end
  end
  if old < 120 then
    self.th:updatePathfinding()  -- Rebuild pathfinding graph
  end
  if old < 161 then
    -- Hotfix for trophy bug
    self.hotfix1 = nil
    self.level_config.awards_trophies.TrophyAllCuredBonus = 20000
    self.level_config.awards_trophies.AllCuresBonus = 5000
  end
end
```

### 5.6 Machine-Specific Fixes (Machine:afterLoad)

```lua
-- entities/machine.lua:503-519
function Machine:afterLoad(old, new)
  if old < 15 then
    if self.object_type.id == "cardio" then
      -- Fix corrupted THOB value in map
      self.world.map.th:setCellFlags(self.tile_x, self.tile_y, {
        thob = self.object_type.thob
      })
    end
  end
  if old < 54 then
    local room = self:getRoom()
    if room.crashed then
      self:removeHandymanRepairTask()
    end
  end
  self:updateDynamicInfo()
  return Object.afterLoad(self, old, new)
end
```

---

## 6. Code Examples

### 6.1 Registering a Permanent Object

```lua
-- In a module that creates a singleton
local MySystem = {}
permanent("systems.my_system", MySystem)

-- Later, to remove (e.g., on mod unload)
unpermanent("systems.my_system")
```

### 6.2 Implementing `__persist` / `__depersist` for C++ Userdata

```lua
-- In Lua binding for a C++ class
local MyClass_mt = {
  __persist = function(self, writer)
    -- writer is a lua_persist_writer
    writer:write_int(self.some_field)
    writer:write_string(self.other_field)
    writer:write_stack_object(self.child_object)
  end,
  
  __depersist = function(self, reader)
    -- reader is a lua_persist_reader
    self.some_field = reader:read_int()
    self.other_field = reader:read_string()
    self.child_object = reader:read_stack_object()
  end,
  
  __depersist_size = 64,  -- Size of C++ object in bytes
  
  __pre_depersist = function(self, reader)
    -- Called before __depersist, for C++ placement new
    -- Typically not needed from Lua side
  end,
}
```

### 6.3 Making a Lua Function Persistable

```lua
--[[persistable:my_module.my_callback]]
local function my_callback(param)
  -- This function can now be serialized
  -- The persist system records: "my_module.my_callback" → file:line
  -- On load, it reloads the function from source
  return param * 2
end

-- Register as permanent if it's a callback that might be saved
permanent("my_module.my_callback", my_callback)
```

### 6.4 Adding a New Migration Gate

```lua
-- In YourClass:afterLoad(old, new)
function YourClass:afterLoad(old, new)
  -- Migration for saves older than version 250
  if old < 250 and new >= 250 then
    -- Fix/initialize new field
    self.new_field = self.old_field * 1.5
    self.old_field = nil
  end
  
  -- Always call parent
  ParentClass.afterLoad(self, old, new)
end
```

### 6.5 Testing Save/Load Round-trip

```lua
-- Test helper
local function test_save_load(entity)
  -- Save
  local data = SaveGame()
  assert(data, "SaveGame failed")
  
  -- Simulate version upgrade
  local old_version = TheApp.world.savegame_version
  TheApp.world.savegame_version = old_version + 10
  
  -- Load
  LoadGame(data)
  
  -- Verify entity still valid
  assert(entity.tile_x, "Entity lost position")
  assert(entity:isValid(), "Entity invalid after load")
end
```

---

## 7. Key Invariants & Gotchas

| Invariant | Description |
|-----------|-------------|
| **Parent `afterLoad` must be called** | Child migrations assume parent state is valid |
| **Version gates use `< old_version`** | `if old < 210 then` means "migrate if loaded from < 210" |
| **`original_savegame_version` preserved** | Tracks the *original* creation version for logging |
| **Permanents must exist at load time** | `MakePermanentObjectsTable` runs before depersistence |
| **Sync marker `0x42` validates userdata** | Corruption detected if marker missing |
| **Deferred `__depersist` for cross-refs** | Objects referencing each other need 2nd pass |
| **Prototypes reloaded from source files** | `--[[persistable:name]]` must match exactly |

---

## 8. Version History Highlights

| Version | Major Change |
|---------|-------------|
| 4 | `room_built` table introduced |
| 6 | Hospital value calculation, parcel tiles |
| 10 | `object_counts` categories |
| 12 | Animation manager reference |
| 15 | Cardio machine THOB fix |
| 17 | Radiation shield objects |
| 27 | CallsDispatcher added |
| 31 | Hours per day = 50 |
| 37 | Spawn rate from level config |
| 43 | Reception desk count category |
| 47 | Bench count category |
| 54 | Machine repair task fix |
| 57 | User actions allowed, cell buildable flags |
| 61 | Room remove callbacks, humanoid callbacks restructured |
| 64 | Staff profile world reference |
| 66 | Staff room reservation fix |
| 77 | `has_vomitted` field |
| 83 | Chewbacca patient animation fix |
| 87 | Gates to Hell object |
| 106 | Epidemic level_config removed |
| 114 | Rathole object |
| 120 | Pathfinding rebuild |
| 133 | Staff migration (chained) |
| 134 | Staff change callbacks |
| 161 | Trophy hotfix |
| 164 | Non-visual illness availability |
| 166 | Graphics set type (compatibility gate) |
| 175 | Max salary config |
| 187 | GBV Tired default |
| 210 | Mood enum rename (sad→dying) |
| 212 | Epidemic coverup field rename |
| 265 | Ultrascan footprint 4 tiles blocked (north {-1,1},{0,1} east {0,-1},{1,-1} passable→blocked) preserve old<265 |

Current version: **265** (app.lua:31 3441) (see `App.savegame_version` in `app.lua`)

---

## 9. Performance Characteristics

- **Save time**: O(objects) with deduplication — typically <100ms for large hospitals
- **Load time**: O(bytes) with single-pass + deferred pass — typically <200ms
- **Binary size**: Variable-length ints + deduplication keeps saves ~1-5MB
- **Memory**: Reader/writer use Lua stack + env tables, no large intermediate buffers

---

*Document generated from CorsixTH source analysis. Covers `persistance.lua`, `app.lua:1995-2058`, `world.lua:2552-2765+`, `persist_lua.h`, `persist_lua.cpp`, and all 73 `afterLoad` implementations.*


## Related Pages

- [[12-saveload-migrations/CHECKLIST]]
- [[12-saveload-migrations/MAP]]
- [[12-saveload-migrations/SCAFFOLD]]

## Ultrascan 3441 — Sprint 7
- persistable ultrascan_after_use in rooms/ultrascan.lua:64
- SAVEGAME_VERSION 265 app.lua:31, Object:afterLoad:892 old<265 preserve (no re-occupation)
- 4 tiles blocked (north {-1,1},{0,1} east {0,-1},{1,-1}) minimal symmetric, strict out-of-scope
- Save 3441 sha9b3f/bd381b validates no periodic crash on old<265
