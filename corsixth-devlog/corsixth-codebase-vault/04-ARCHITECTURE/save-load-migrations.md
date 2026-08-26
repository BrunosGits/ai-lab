# Save/Load Migration Architecture

## Overview
CorsixTH employs a two-layer persistence architecture combining a high-performance C++ binary serializer with a Lua wrapper that manages game-specific object graphs, permanent object registration, and versioned migration hooks.

## Two-Layer Architecture

### 1. C++ Binary Layer (`persist_lua.cpp` / `persist_lua.h`)
Custom binary format with:
- Variable-length integer encoding (VLQ/LEB128-style)
- Object deduplication via reference counting
- Cycle detection for circular references
- 16 type tags (PERSIST_TCOUNT = 16): nil, boolean, number, string, table, function, userdata, permanent, prototype, etc.

**Writer** (`lua_persist_basic_writer`): Maintains `next_index` counter, uses Lua environment table as object→index cache.

**Reader** (`lua_persist_basic_reader`): Two-pass userdata depersistence - `__pre_depersist` then `__depersist`, with deferred calls for circular refs.

### 2. Lua Wrapper Layer (`persistance.lua`)
Game-aware persistence:
```lua
function SaveGame()
  local state = { ui = TheApp.ui, world = TheApp.world, map = TheApp.map, random = math.randomdump() }
  state.map:prepareForSave()
  local result = persist.dump(state, MakePermanentObjectsTable(false))
  state.map:afterSave()
  return result
end

function LoadGame(data)
  local objtable = MakePermanentObjectsTable(true)
  local state = assert(persist.load(data, objtable))
  -- Version heuristic for pre-166 saves
  TheApp:afterLoad()  -- Triggers migration cascade
end
```

## Permanent Object Registration

### `permanent(name, value)` / `unpermanent(name)`
Register singletons/global objects referenced by identity, not serialized:
```lua
permanent("objects.radiator", radiator_type)
permanent("TH.some_class", th_class_table)
```

### `MakePermanentObjectsTable(inverted)` — Bidirectional Mapping

**Forward (saving)**: object → persistable name string
- Global functions: `permanent[fn] = "some_function"`
- Lua classes: class table, metatable, methods
- C libraries: `permanent[TH] = "TH"`
- App subsystems: `permanent[TheApp.config] = {global_fetch, "TheApp", "config"}`
- Graphics: `permanent[gfx_obj] = {load_method, args...}`

**Inverted (loading)**: persistable name → object resolver
- Direct references for simple values
- `__index` metamethod executes fetch instructions

## Migration Call Graph
```
App:afterLoad()
├── App migrations (v87: gates_to_hell, v114: rathole)
├── Map:afterLoad() — parcel tiles, difficulty, pathfinding, trophies
├── UI:afterLoad() → Window:afterLoad() → child windows
└── World:afterLoad() — Core gameplay migrations
    ├── v4: room_built
    ├── v6: hospital value recalc
    ├── v10: object_counts categories
    ├── v12: animation_manager
    ├── v17: radiation_shield objects
    ├── v27: CallsDispatcher
    ├── v30: nextEmergency
    ├── v31: hours_per_day = 50
    ├── v37: spawn rate from level config
    ├── v43: reception_desk count
    ├── v47: bench count
    ├── v52: litter cleanup
    ├── v57: user_actions_allowed
    ├── v61: room_remove_callbacks
    ├── v64: staff profile world ref
    ├── v66: staff room reservation fix
    ├── v77: has_vomitted
    ├── v83: Chewbacca patient anim
    ├── v87: gates_to_hell object
    ├── v114: rathole object
    ├── v120: pathfinding rebuild
    ├── v133: staff migration (chained)
    ├── v134: staff_change_callbacks
    ├── v161: trophy hotfix
    ├── v164: non_visuals_available
    ├── v175: MaxSalary config
    ├── v187: GBV Tired default
    ├── v210: mood enum rename (sad→dying)
    ├── v212: epidemic coverup field rename
    └── Entity delegation: entities:afterLoad(), epidemic, earthquake, hospital
```

## Version Gate Pattern
```lua
if old < 265 then
  -- Migration for saves older than version 265
  self.entities_to_destroy = {}
end

-- ALWAYS call parent LAST
ParentClass.afterLoad(self, old, new)
```

## Key Invariants
| Invariant | Description |
|-----------|-------------|
| Parent `afterLoad` called last | Child migrations assume parent state is valid |
| Version gates use `< old_version` | `if old < 265` means "migrate if loaded from < 265" |
| `original_savegame_version` preserved | Tracks original creation version for logging |
| Permanents exist at load time | `MakePermanentObjectsTable` runs before depersistence |
| Sync marker `0x42` validates userdata | Corruption detected if marker missing |
| Deferred `__depersist` for cross-refs | Objects referencing each other need 2nd pass |
| Prototypes reloaded from source | `--[[persistable:name]]` must match exactly |

## Version History Highlights
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
| **265** | **Deferred entity destruction fix** |

## Migration Examples

### Adding New Object Types (App:afterLoad)
```lua
if old < 87 then
  local new_object = corsixth.require("objects.gates_to_hell")
  Object.processTypeDefinition(new_object)
  self.objects[new_object.id] = new_object
  self.world:newObjectType(new_object)
end
```

### Data Structure Migration (World:afterLoad)
```lua
if old < 10 then
  self.object_counts = {extinguisher=0, radiator=0, plant=0, general=0}
  for _, obj in ipairs(all_objects) do
    self.object_counts[obj.object_type.count_category] += 1
  end
end
```

### Enum/Constant Renaming (Humanoid:afterLoad)
```lua
if old < 210 then
  -- Renamed mood states: sad7→sad2, sad2-sad6→dying1-dying5
  if self:isMoodActive("sad2") then
    self:setMood("sad2", "deactivate")
    self:setMood("dying1", "activate")
  end
end
```

### Field Removal/Renaming (Epidemic:afterLoad)
```lua
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

### Map Data Recalculation (Map:afterLoad)
```lua
if old < 6 then
  self.parcelTileCounts = {}
  for plot = 1, self.th:getPlotCount() do
    self.parcelTileCounts[plot] = self.th:getParcelTileCount(plot)
  end
end
if old < 57 then
  -- Reset all cell buildable flags
  for x = 1, self.width do
    for y = 1, self.height do
      self:setCellFlags(x, y, {buildableNorth=true, buildableSouth=true, buildableWest=true, buildableEast=true})
    end
  end
end
if old < 120 then
  self.th:updatePathfinding()  -- Rebuild pathfinding graph
end
```

### Machine-Specific Fixes (Machine:afterLoad)
```lua
function Machine:afterLoad(old, new)
  if old < 15 then
    if self.object_type.id == "cardio" then
      self.world.map.th:setCellFlags(self.tile_x, self.tile_y, {thob = self.object_type.thob})
    end
  end
  if old < 54 then
    local room = self:getRoom()
    if room.crashed then self:removeHandymanRepairTask() end
  end
  self:updateDynamicInfo()
  return Object.afterLoad(self, old, new)
end
```

## Cross-References
- [[world-entity-flow]] - How entity destruction integrates with save/load
- [[entity-action-system]] - How actions interact with persistence
- Area: [[01-CODEBASE/12-saveload-migrations]]


## Related Pages

- [[entity-action-system]]
- [[performance]]
- [[room-hospital-hierarchy]]
- [[ui-dialog-hierarchy]]
- [[world-entity-flow]]
