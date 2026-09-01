# Object Placement Methods - File:Line Index

## Core Object Class (`Lua/entities/object.lua`)

### Construction & Initialization
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:Object` | 36-59 | Constructor - creates object, sets up orientation, places on tile |
| `Object:initOrientation` | 64-110 | Sets direction, animation, footprint, split animations, render position |

### Slave Mixin
| Method | Lines | Description |
|--------|-------|-------------|
| `Object.slaveMixinClass` | 113-187 | Adds slave creation, movement, destruction, event redirection to a class |

### Use Positions
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:_getUsageTile` | 280-289 | Gets single use position by name (internal) |
| `Object.getXYforUsePosition` | 297-318 | Static: calculates absolute world coords for use position |
| `Object:usePositionNames` | 322-331 | Returns list of all use position names |
| `Object:getAllUsageTiles` | 336-344 | Returns all use positions as merged table |
| `Object:getSecondaryUsageTile` | 348-356 | Returns x,y for use_position_secondary |

### Walkable Tiles
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:getWalkableTiles` | 360-368 | Returns list of only_passable tiles in footprint |
| `Object.getComplementaryPassableFlag` | 381-383 | Returns opposite travel flag (North↔South, East↔West) |

### Direction Parameters
| Method | Lines | Description |
|--------|-------|-------------|
| `Object.directionParameters` | 385-393 | Returns table with x/y offsets, buildable/passable/needed_side flags per direction |

### Tile Management
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:setTile` | 395-442 | Moves object, deoccupies old tiles, occupies new tiles |
| `Object:occupyTilesByObjectFootprintAt` | 465-549 | Sets map flags for footprint tiles (buildable=false, passable, directional) |
| `Object:deoccupyTilesByObjectFootprintAt` | 554-607 | Restores map flags when object removed/moved |

### Rendering & Animation
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:setPosition` | 207-221 | Sets screen position (handles split animations) |
| `Object:setAnimation` | 223-241 | Sets animation (handles split animations with Crop flag) |
| `Object:getRenderAttachTile` | 249-261 | Returns primary render tile coordinates |
| `Object:tick` | 189-205 | Advances split animations |
| `Object:setInvisible` | 612-628 | Shows/hides object (handles split animations) |

### Dynamic Info & Usage
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:incrementUsedCount` | 264-266 | Increments times_used counter |
| `Object:updateDynamicInfo` | 269-274 | Updates dynamic info text with usage count |

### User Management
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:setUser` | 634-645 | Assigns user to object |
| `Object:removeUser` | 649-675 | Removes user from object |
| `Object:addReservedUser` | 680-691 | Reserves object for user |
| `Object:removeReservedUser` | 698-722 | Removes reservation |
| `Object:isReservedFor` | 726-748 | Checks if reserved for user |

### Lifecycle
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:isMachine` | 751-753 | Returns false (overridden by Machine class) |
| `Object:onClick` | 760-825 | Handles click - pickup, room editing |
| `Object:eraseObject` | 827-829 | Erases object type from map |
| `Object:resetAnimation` | 831-835 | Resets map cell flags and animation |
| `Object:onDestroy` | 837-848 | Cleanup: remove from room, reset usage, rebuild pathfinding |
| `Object:rebuildPassableCellFlags` | 850-856 | Updates pathfinding for SideObjects |
| `Object:onPickUp` | 858-861 | Reset usage when picked up |
| `Object:resetUsageAndReservaton` | 863-866 | Cancels usage and denies reservations |
| `Object:cancelUsage` | 868-878 | Notifies users object removed |
| `Object:denyReservation` | 880-890 | Notifies reservers object removed |
| `Object:afterLoad` | 892-922 | Version migration handling |

### Type Definition Processing
| Method | Lines | Description |
|--------|-------|-------------|
| `Object.processTypeDefinition` | 926-1047 | Normalizes object definitions at load time |

### State Management
| Method | Lines | Description |
|--------|-------|-------------|
| `Object:getState` | 1057-1059 | Returns {times_used} for save |
| `Object:setState` | 1068-1072 | Restores times_used from save |

### SideObject Subclass
| Method | Lines | Description |
|--------|-------|-------------|
| `SideObject:SideObject` | 1080-1082 | Constructor |
| `SideObject:getDrawingLayer` | 1084-1105 | Returns render layer based on direction (with trash bin special case) |

---

## Object Definitions (Examples)

### Bed (`Lua/objects/bed.lua`)
| Component | Lines |
|-----------|-------|
| Object definition | 21-101 |
| `idle_animations` | 30-33 |
| `usage_animations` | 35-64 |
| `orientations` (north, east, south, west) | 73-101 |
| Footprint per direction | 75-77, 82-84, 89-91, 96-98 |
| `use_position` per direction | 78, 85, 92, 99 |
| `render_attach_position` (south only) | 93 |
| `early_list` (north, east) | 79, 86 |

### Operating Table (`Lua/objects/machines/operating_table.lua`)
| Component | Lines |
|-----------|-------|
| Object definition | 21-121 |
| `slave_id` | 23 |
| `idle_animations` | 40-42 |
| `usage_animations` | 43-49 |
| `multi_usage_animations` | 50-77 |
| `orientations` (north, east) | 94-121 |
| `slave_position` per direction | 105, 117 |
| `use_position` / `use_position_secondary` | 96-97, 109-110 |
| Class `OperatingTable` with `slaveMixinClass()` | 123-135 |

### Cast Remover (`Lua/objects/machines/cast_remover.lua`)
| Component | Lines |
|-----------|-------|
| Object definition | 21-151 |
| `default_strength` | 30 |
| `multi_usage_animations` | 51-72 |
| `orientations` (north, east) | 120-149 |
| Complex footprint with flags | 127-131, 141-145 |
| `handyman_position` as multiple tiles | 123, 137 |
| `use_position_secondary`, `finish_use_position_secondary` | 125-126, 139-140 |
| `walk_in_tile` | 124, 138 |
| `smoke_position` | 133, 147 |
| `early_list` (east) | 146 |

### Reception Desk (`Lua/objects/reception_desk.lua`)
| Component | Lines |
|-----------|-------|
| Object definition | 21-67 |
| `corridor_object = 1` | 28 |
| `orientations` (all 4 directions) | 34-66 |
| Footprint with `need_*_side` flags | 36-38, 44-46, 52-54, 60-62 |
| `use_position` / `use_position_secondary` per direction | 40-41, 48-49, 56-57, 64-65 |
| Class `ReceptionDesk` | 71-262 |
| Queue management, staff finding | 76-261 |

### Loo (`Lua/objects/loo.lua`)
| Component | Lines |
|-----------|-------|
| Object definition | 21-132 |
| `use_position = "passable"` (auto-resolve) | 123, 128 |
| `use_animate_from_use_position` | 124, 129 |
| Simple 2-tile footprints | 122, 127 |

---

## Key Data Structures

### Footprint Tile Entry
```lua
{ x_offset, y_offset, 
  only_passable = bool,
  complete_cell = bool,
  optional = bool,
  invisible = bool,
  only_side = bool,
  need_north_side = bool,
  need_south_side = bool,
  need_east_side = bool,
  need_west_side = bool
}
```

### Orientation Table
```lua
{
  footprint = { ... },
  use_position = {x, y} or "passable",
  use_position_secondary = {x, y},
  slave_position = {x, y},
  finish_use_position = {x, y},
  finish_use_position_secondary = {x, y},
  handyman_position = {x, y} or {{x1,y1}, {x2,y2}},
  walk_in_tile = {x, y},
  render_attach_position = {x, y} or {{x,y,column}, ...},
  animation_offset = {x, y},
  early_list = bool,
  smoke_position = {x, y},
  pathfind_allowed_dirs = { [0]=true, [1]=true, ... }, -- set by processTypeDefinition
  adjacent_to_solid_footprint = { {x,y}, ... }, -- set by processTypeDefinition
}
```

### Direction Parameters Table
```lua
{
  north = { x=0, y=-1, buildable_flag="buildableNorth", passable_flag="travelNorth", needed_side="need_north_side" },
  east  = { x=1, y=0, buildable_flag="buildableEast",  passable_flag="travelEast",  needed_side="need_east_side" },
  south = { x=0, y=1, buildable_flag="buildableSouth", passable_flag="travelSouth", needed_side="need_south_side" },
  west  = { x=-1, y=0, buildable_flag="buildableWest",  passable_flag="travelWest",  needed_side="need_west_side" },
}
```

### Mirror Mapping
```lua
orient_mirror = {
  north = "west",
  west = "north",
  east = "south",
  south = "east",
}
```

---

## Cross-References

### Methods Calling `directionParameters()`
- `occupyTilesByObjectFootprintAt` (line 466)
- `deoccupyTilesByObjectFootprintAt` (line 555)

### Methods Calling `getComplementaryPassableFlag()`
- `occupyTilesByObjectFootprintAt` (line 543)
- `deoccupyTilesByObjectFootprintAt` (line 572)
- `setPassableFlags` local function (line 459)

### Methods Using `orient_mirror`
- `initOrientation` (line 72)

### Methods Using `slaveMixinClass`
- `OperatingTable` (operating_table.lua:128)
- Any class with `object_type.slave_id`

### Methods Overriding `getWalkableTiles`
- `Door` (doors/*.lua) - for door walkable tiles

### Methods Overriding `onDestroy`
- `SideObject` (line 850-856) - calls `rebuildPassableCellFlags`
- `ReceptionDesk` (reception_desk.lua:216-244) - handles receptionist

### Methods Overriding `setTile`
- `ReceptionDesk` (reception_desk.lua:207-214) - checks for nearby staff
- Slave mixin (object.lua:168-184) - moves slave with master

---

## Version Migration Points (`afterLoad`)

| Version | Change | Lines |
|---------|--------|-------|
| < 52 | Hospital reference fix | 893-895 |
| < 57 | Footprint re-initialization, animation_offset, SideObject buildable flag | 896-911 |
| < 173 | Couch passable fix | 913-918 |

---

## Global Constants Referenced

| Constant | Source | Used In |
|----------|--------|---------|
| `DrawFlags.FlipHorizontal` | C++ | initOrientation (line 73) |
| `DrawFlags.EarlyList` | C++ | initOrientation (line 78) |
| `DrawFlags.Crop` | C++ | setAnimation (line 225) |
| `DrawingLayers.NorthSideObject` | C++ | SideObject:getDrawingLayer (line 1086) |
| `DrawingLayers.WestSideObject` | C++ | SideObject:getDrawingLayer (line 1088) |
| `DrawingLayers.EastSideObject` | C++ | SideObject:getDrawingLayer (line 1099) |
| `DrawingLayers.SouthSideObject` | C++ | SideObject:getDrawingLayer (line 1102) |
| `TH.animation()` | C++ binding | Object:Object (line 39), initOrientation (lines 88, 109) |
| `Map:WorldToScreen()` | C++ binding | initOrientation (line 91), setPosition (line 214) |

---

*Generated from CorsixTH source analysis. Line numbers current as of analysis date.*


## Related Pages

- [[16-object-placement/SUMMARY]]
- [[16-object-placement/CHECKLIST]]
- [[16-object-placement/SCAFFOLD]]


## 3441 Spec
- Busted spec: `CorsixTH/Luatest/spec/entities/ultrascanner_3441_spec.lua` (best location, mirrors 16-object-placement, 5000 ticks gate on/off)
- Vault results: `02-SUBSYSTEMS/16-object-placement/3441-TEST-RESULTS.md` (primary, indexed), `08-QUERIES/3441-test-results.md` secondary alias
