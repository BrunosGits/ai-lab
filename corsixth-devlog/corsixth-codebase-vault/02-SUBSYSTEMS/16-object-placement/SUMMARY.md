# Object Placement & Footprints in CorsixTH

## Overview

This document provides a comprehensive analysis of the object placement system in CorsixTH, covering object construction, the 4-direction orientation system, footprint tiles with their flags, use positions, direction parameter mapping, and the master-slave pattern for linked objects.

---

## 1. Object Construction

### 1.1 Constructor (`Object:Object`)

**File:** `Lua/entities/object.lua:36-59`

```lua
function Object:Object(hospital, object_type, x, y, direction, etc)
  assert(class.is(hospital, Hospital), "First argument is not a Hospital instance.")

  local th = TH.animation()
  self:Entity(th)

  if etc == "map object" then
    if direction % 2 == 0 then
      direction = "north"
    else
      direction = "west"
    end
  end

  self.ticks = object_type.ticks
  self.object_type = object_type
  self.hospital = hospital
  self.world = hospital.world
  self.user = false
  self.times_used = 0
  self:updateDynamicInfo()
  self:initOrientation(direction)
  self:setTile(x, y)
end
```

**Key Steps:**
1. Creates base animation handle via `TH.animation()`
2. Initializes parent `Entity` class
3. Handles "map object" direction conversion (numeric → cardinal)
4. Stores references to hospital, world, object_type
5. Initializes usage counters (`times_used = 0`)
6. Calls `updateDynamicInfo()` for dynamic text
7. Calls `initOrientation(direction)` to set up footprint and animation
8. Calls `setTile(x, y)` to occupy footprint tiles

### 1.2 Orientation Initialization (`initOrientation`)

**File:** `Lua/entities/object.lua:64-110`

```lua
function Object:initOrientation(direction)
  self.direction = direction
  local object_type = self.object_type

  -- Decide the animation and the draw flags for it.
  local flags = 0
  local anim = object_type.idle_animations[direction]
  if not anim then
    anim = object_type.idle_animations[orient_mirror[direction]]
    flags = DrawFlags.FlipHorizontal
  end
  local footprint = object_type.orientations
  footprint = footprint and footprint[direction]
  if footprint and footprint.early_list then
    flags = flags + DrawFlags.EarlyList
  end

  local rap = footprint and footprint.render_attach_position
  if rap and rap[1] and type(rap[1]) == "table" then
    self.split_anims = {self.th}
    self.split_anim_positions = rap
    self.th:setCrop(rap[1].column)
    for i = 2, #rap do
      local point = rap[i]
      local th = TH.animation()
      th:setCrop(point.column)
      th:setHitTestResult(self)
      th:setPosition(Map:WorldToScreen(1-point[1], 1-point[2]))
      self.split_anims[i] = th
    end
  else
    self.split_anims = nil
    self.split_anim_positions = nil
  end
  if footprint and footprint.animation_offset then
    self:setPosition(unpack(footprint.animation_offset))
  end
  footprint = footprint and footprint.footprint
  if footprint then
    self.footprint = footprint
  else
    self.footprint = nil
  end
  self:setAnimation(anim, flags)
end
```

**Responsibilities:**
- Sets `self.direction`
- Selects correct idle animation for direction (with mirror fallback via `orient_mirror`)
- Handles `DrawFlags.FlipHorizontal` for mirrored orientations
- Processes `early_list` flag for render ordering
- Sets up split animations for multi-tile render objects (`render_attach_position` as table)
- Applies `animation_offset` for visual positioning
- Extracts and stores `footprint` table
- Calls `setAnimation()` to apply animation and flags

---

## 2. Orientation System (4 Directions)

### 2.1 Direction Constants

The system uses four cardinal directions:
- **north** (facing up/negative Y)
- **east** (facing right/positive X)
- **south** (facing down/positive Y)
- **west** (facing left/negative X)

### 2.2 Mirror Mapping

**File:** `Lua/entities/object.lua:29-34`

```lua
local orient_mirror = {
  north = "west",
  west = "north",
  east = "south",
  south = "east",
}
```

When an object doesn't have an animation for a specific direction, it falls back to its mirror direction with horizontal flip.

### 2.3 Direction Parameters

**File:** `Lua/entities/object.lua:385-393`

```lua
function Object.directionParameters()
  return
    {
      north = { x = 0, y = -1, buildable_flag = "buildableNorth", passable_flag = "travelNorth", needed_side = "need_north_side"},
      east  = { x = 1, y = 0, buildable_flag = "buildableEast",  passable_flag = "travelEast",  needed_side = "need_east_side"},
      south = { x = 0, y = 1, buildable_flag = "buildableSouth", passable_flag = "travelSouth", needed_side = "need_south_side"},
      west  = { x = -1, y = 0, buildable_flag = "buildableWest",  passable_flag = "travelWest",  needed_side = "need_west_side"}
    }
end
```

Each direction maps to:
| Direction | X Offset | Y Offset | Buildable Flag | Passable Flag | Needed Side Flag |
|-----------|----------|----------|----------------|---------------|------------------|
| north     | 0        | -1       | buildableNorth | travelNorth   | need_north_side  |
| east      | 1        | 0        | buildableEast  | travelEast    | need_east_side   |
| south     | 0        | 1        | buildableSouth | travelSouth   | need_south_side  |
| west      | -1       | 0        | buildableWest  | travelWest    | need_west_side   |

---

## 3. Footprint Tiles

### 3.1 Footprint Structure

The footprint is an array of tile definitions relative to the object's origin tile. Each entry is a table with:

```lua
{ x_offset, y_offset, [flags...] }
```

### 3.2 Tile Flags

| Flag | Type | Description |
|------|------|-------------|
| `only_passable` | boolean | Tile is walkable but not buildable (e.g., space in front of bed) |
| `complete_cell` | boolean | Tile is fully occupied (solid, not passable) |
| `optional` | boolean | Tile is optional - only used if conditions met (room match, reachable) |
| `invisible` | boolean | Tile exists for logic but not rendered |
| `only_side` | boolean | Tile is a side-object tile (edge of tile) |
| `need_north_side` | boolean | Requires north side of tile to be free |
| `need_south_side` | boolean | Requires south side of tile to be free |
| `need_east_side` | boolean | Requires east side of tile to be free |
| `need_west_side` | boolean | Requires west side of tile to be free |

### 3.3 Example: Bed Footprint (North)

**File:** `Lua/objects/bed.lua:74-80`

```lua
north = {
  footprint = { 
    {1, -1, only_passable = true},           -- Passable tile at (1, -1)
    {-1, -1, complete_cell = true},          -- Solid tile at (-1, -1)
    {0, -1, complete_cell = true},           -- Solid tile at (0, -1)
    {-1, 0, complete_cell = true},           -- Solid tile at (-1, 0)
    {0, 0, complete_cell = true}             -- Solid tile at (0, 0) - origin
  },
  use_position = {1, -1},
  early_list = true,
}
```

**Visual Layout (North-facing bed):**
```
    Y=-1        Y=0
X=-1  [███]    [███]   (complete_cell)
X=0   [███]    [███]   (complete_cell, origin)
X=1   [···]     -      (only_passable - patient stands here)
```

### 3.4 Example: Cast Remover (Complex Footprint)

**File:** `Lua/objects/machines/cast_remover.lua:120-134`

```lua
north = {
  use_position = {0, 0},
  handyman_position = {{0, -2}, {-1, -1}},
  walk_in_tile = {0, -1},
  use_position_secondary = {0, -1},
  finish_use_position_secondary = {1, -1},
  footprint = { 
    {-1, -1, complete_cell = true}, 
    {0, -1, only_passable = true}, 
    {1, -1, only_passable = true},
    {-1, 0, complete_cell = true}, 
    {0, 0, only_passable = true, complete_cell = true},
    {-1, 1, only_passable = true, need_west_side = true},
    {-1, -2, only_passable = true, invisible = true, optional = true},
    {-2, -1, only_passable = true, invisible = true, optional = true} 
  },
  render_attach_position = {-1, 1},
  smoke_position = {0, 0},
}
```

---

## 4. Use Positions

### 4.1 Position Names

**File:** `Lua/entities/object.lua:320-331`

```lua
function Object:usePositionNames()
  return {
    "use_position",
    "use_position_secondary",
    "slave_position",
    "finish_use_position",
    "finish_use_position_secondary",
    "handyman_position",
  }
end
```

### 4.2 Position Definitions

| Position | Purpose | Example Usage |
|----------|---------|---------------|
| `use_position` | Primary interaction tile (where user stands) | Patient at bed, receptionist at desk |
| `use_position_secondary` | Secondary interaction tile | Second patient at reception, nurse at machine |
| `slave_position` | Offset for slave object (master-slave) | Operating table B position |
| `finish_use_position` | Where user ends after interaction | Patient leaving bed |
| `finish_use_position_secondary` | Secondary finish position | Nurse leaving machine |
| `handyman_position` | Repair position(s) for handyman | Can be single `{x,y}` or multiple `{{x1,y1},{x2,y2}}` |

### 4.3 Getting Use Positions

**File:** `Lua/entities/object.lua:291-318`

```lua
function Object:getXYforUsePosition(object_x, object_y, object_layout, usage_position_name)
  local usage_tile_offset = object_layout[usage_position_name]
  if usage_tile_offset then
    local first = usage_tile_offset[1]
    local second = usage_tile_offset[2]
    if type(first) == "table" then -- Multiple positions (e.g., handyman_position)
      local result = {}
      for _, xy in ipairs(usage_tile_offset) do
        local x = object_x + xy[1]
        local y = object_y + xy[2]
        table.insert(result, {x, y, usage_position_name})
      end
      return result
    else -- Single position
      local x = object_x + first
      local y = object_y + second
      return {{x, y, usage_position_name}}
    end
  else
    return nil
  end
end
```

### 4.4 Example: Operating Table Positions

**File:** `Lua/objects/machines/operating_table.lua:94-121`

```lua
north = {
  use_position = {-1, -2},           -- Surgeon position
  use_position_secondary = {-2, -1}, -- Nurse/assistant position
  footprint = {
    {-2, -1, only_passable = true},
    {-1, -1, complete_cell = true}, {-1, -2, only_passable = true},
    {0, -1, complete_cell = true}, {0, -2, complete_cell = true},
    {1, 0, complete_cell = true}, {1, -2, complete_cell = true}, {1, -1, only_passable = true},
  },
  render_attach_position = {0, -1},
  slave_position = {1, -1},          -- Operating table B at (1, -1)
  smoke_position = {0, 0},
}
```

---

## 5. Direction Parameter Mapping

### 5.1 Application in Footprint Occupation

**File:** `Lua/entities/object.lua:462-549` (occupyTilesByObjectFootprintAt)

Key logic for `only_side` tiles:
```lua
if xy.only_side then
  local par = direction_parameters[direction]
  flags_to_set[par["buildable_flag"]] = false
  passable_flag, next_tile_x, next_tile_y = par["passable_flag"], x + par["x"], y + par["y"]
```

For regular footprint tiles, it checks all 4 directions:
```lua
for _, value in pairs(direction_parameters) do
  if coordinatesAreInFootprint(self.footprint, xy[1] + value["x"], xy[2] + value["y"]) or
  xy.complete_cell or xy[value["needed_side"]] then
    if map:getCellFlags(x, y, flags)[value["buildable_flag"]] == 0 then
      change_flags = false
    end
    flags_to_set[value["buildable_flag"]] = false
  end
end
```

### 5.2 Buildable Flag Logic

A tile's `buildable<Direction>` flag is set to `false` when:
1. The adjacent tile in that direction is part of the footprint, OR
2. The tile has `complete_cell = true`, OR
3. The tile has the corresponding `need_<direction>_side = true`

### 5.3 Passable Flag Logic

For `only_side` tiles:
- Sets `travel<Direction>` to `false` on the object tile
- Sets complementary `travel<OppositeDirection>` to `false` on adjacent tile
- Tracks `self.set_passable_flags = true` for cleanup on deoccupation

---

## 6. Master-Slave Pattern

### 6.1 Slave Mixin

**File:** `Lua/entities/object.lua:113-187`

```lua
function Object.slaveMixinClass(class_method_table)
  local name = class.name(class_method_table)
  local super = class.superclass(class_method_table)
  local super_constructor = super[class.name(super)]

  -- Constructor
  class_method_table[name] = function(self, hospital, object_type, x, y, direction, ...)
    super_constructor(self, hospital, object_type, x, y, direction, ...)
    if object_type.slave_id then
      local orientation = object_type.orientations
      orientation = orientation and orientation[direction]
      if orientation.slave_position then
        x = x + orientation.slave_position[1]
        y = y + orientation.slave_position[2]
      end
      self.slave = hospital.world:newObject(object_type.slave_id, x, y, direction, ...)
      self.slave.master = self
    end
  end
  -- ... redirect methods ...
end
```

### 6.2 Key Behaviors

1. **Construction**: Master creates slave at `master_position + slave_position` offset
2. **Destruction**: Master destroys slave in `onDestroy`
3. **Movement**: `setTile` moves both master and slave together
4. **Orientation**: `initOrientation` called on both
5. **Event Redirection**: Slave forwards `onClick`, `updateDynamicInfo`, `getDynamicInfo` to master

### 6.3 Usage Example: Operating Table

**File:** `Lua/objects/machines/operating_table.lua`

```lua
object.id = "operating_table"
object.slave_id = "operating_table_b"
-- ...
object.orientations = {
  north = {
    slave_position = {1, -1},  -- Slave at (1, -1) relative to master
    -- ...
  },
  east = {
    slave_position = {-1, 1},  -- Different offset for east orientation
    -- ...
  },
}

class "OperatingTable" (Machine)
OperatingTable:slaveMixinClass()
```

### 6.4 Slave Object Definition

**File:** `Lua/objects/machines/operating_table_b.lua` (referenced)

```lua
local object = {}
object.id = "operating_table_b"
object.thob = 31
-- Slave has its own animations, no orientations needed (inherits master's)
return object
```

---

## 7. Tile Occupation & Deoccupation

### 7.1 Occupy Tiles (`occupyTilesByObjectFootprintAt`)

**File:** `Lua/entities/object.lua:462-549`

Process:
1. Gets direction parameters for current orientation
2. Special case: trash bin (thob 50) treats east as west
3. Sets render attach tile for main animation
4. Registers object in world's entity map
5. Iterates footprint tiles:
   - Handles `optional` tiles (room match, reachability check)
   - For `only_side`: disables buildable flag, sets passable flags
   - For regular tiles: checks all 4 directions for adjacent footprint tiles or `need_*_side` flags
   - Sets `buildable = false` on occupied tiles
   - Sets `passable = true` only for `only_passable` tiles

### 7.2 Deoccupy Tiles (`deoccupyTilesByObjectFootprintAt`)

**File:** `Lua/entities/object.lua:551-607`

Process:
1. Removes from world entity map
2. Iterates footprint tiles:
   - For `only_side`: restores passable flags, re-enables buildable flag
   - For regular tiles: re-enables buildable flags for directions that were blocked
   - Restores `buildable = true` and `passable = true` if no other object claims the tile
   - Checks `isTilePartOfNearbyObject` for passable tiles (10-tile radius assumption)

---

## 8. Type Definition Processing

### 8.1 `processTypeDefinition`

**File:** `Lua/entities/object.lua:926-1047`

Called at load time to normalize object definitions:

1. **Count Categories**: Assigns `count_category` for UI limits
2. **Default Values**: Sets `animation_offset = {0,0}`, `render_attach_position = {0,0}`
3. **Use Position**: Resolves `"passable"` to first `only_passable` tile in footprint
4. **Handyman Position**: Defaults to `use_position` if `default_strength` exists
5. **Pathfind Allowed Dirs**: Calculates based on nearest solid tile to use_position
6. **Origin Adjustment**: Re-centers footprint so nearest solid tile to use_position becomes (0,0)
   - Adjusts all positions: use_position, use_position_secondary, finish_use_position, slave_position, render_attach_position, smoke_position
   - Converts render_attach_position to screen coordinates for animation_offset
7. **Adjacent Tiles**: Builds `adjacent_to_solid_footprint` list for placement validation

---

## 9. Code Examples

### 9.1 Creating a Simple Object

```lua
local object = {}
object.id = "my_chair"
object.thob = 42
object.name = "My Chair"
object.idle_animations = {
  north = 1001,
  east = 1002,
  south = 1003,
  west = 1004,
}
object.orientations = {
  north = {
    footprint = { {0, 0, complete_cell = true}, {0, -1, only_passable = true} },
    use_position = {0, -1},
  },
  east = {
    footprint = { {0, 0, complete_cell = true}, {1, 0, only_passable = true} },
    use_position = {1, 0},
  },
  south = {
    footprint = { {0, 0, complete_cell = true}, {0, 1, only_passable = true} },
    use_position = {0, 1},
  },
  west = {
    footprint = { {0, 0, complete_cell = true}, {-1, 0, only_passable = true} },
    use_position = {-1, 0},
  },
}
return object
```

### 9.2 Creating a Master-Slave Object

```lua
local object = {}
object.id = "my_machine"
object.slave_id = "my_machine_part"
object.thob = 50
object.default_strength = 10
object.idle_animations = { north = 2001 }
object.orientations = {
  north = {
    footprint = { 
      {0, 0, complete_cell = true}, 
      {0, -1, only_passable = true},
      {1, 0, complete_cell = true} 
    },
    use_position = {0, -1},
    handyman_position = {0, -2},
    slave_position = {1, 0},  -- Slave to the east
    render_attach_position = {0, 0},
  },
  -- ... other directions with appropriate slave_position
}
return object
```

### 9.3 Complex Footprint with Side Requirements

```lua
object.orientations = {
  north = {
    footprint = { 
      {0, 0, complete_cell = true},                           -- Origin
      {0, -1, only_passable = true},                          -- Front (passable)
      {1, 0, need_north_side = true, need_south_side = true}, -- Right (needs N+S sides free)
      {-1, 0, need_north_side = true, need_south_side = true},-- Left (needs N+S sides free)
    },
    use_position = {0, -1},
    use_position_secondary = {0, 1},
  },
}
```

---

## 10. Special Cases & Edge Cases

### 10.1 Trash Bin (thob 50) Orientation Bug

**File:** `Lua/entities/object.lua:468-471, 557-560`

```lua
-- In both occupy and deoccupy:
if self.object_type.thob == 50 and direction == "east" then
  direction = "west"
end
```

The trash bin uses west-facing graphics for east orientation.

### 10.2 Split Animations

When `render_attach_position` is a table of tables:
- Primary animation at `render_attach_position[1]`
- Additional animations created for each entry
- Each gets `setCrop(column)` and positioned via `Map:WorldToScreen`
- Used for large objects spanning multiple tiles visually

### 10.3 Early List Flag

`early_list = true` in orientation adds `DrawFlags.EarlyList` for render ordering (draws before other objects on same tile).

### 10.4 "passable" Use Position Shortcut

```lua
use_position = "passable"  -- Auto-resolves to first only_passable tile in footprint
```

### 10.5 Handyman Position as Multiple Tiles

```lua
handyman_position = {{0, -2}, {-1, -1}}  -- Handyman can repair from either tile
```

The `getXYforUsePosition` returns multiple entries for table-of-tables format.

---

## 11. Summary of Key Files & Line Ranges

| Component | File | Lines |
|-----------|------|-------|
| Object Constructor | `entities/object.lua` | 36-59 |
| initOrientation | `entities/object.lua` | 64-110 |
| Slave Mixin | `entities/object.lua` | 113-187 |
| Direction Parameters | `entities/object.lua` | 385-393 |
| Use Position Logic | `entities/object.lua` | 276-344 |
| Footprint Occupation | `entities/object.lua` | 462-549 |
| Footprint Deoccupation | `entities/object.lua` | 551-607 |
| Type Definition Processing | `entities/object.lua` | 926-1047 |
| Bed Example | `objects/bed.lua` | 73-101 |
| Operating Table (Slave) | `objects/machines/operating_table.lua` | 94-121 |
| Cast Remover (Complex) | `objects/machines/cast_remover.lua` | 120-149 |
| Reception Desk (Side) | `objects/reception_desk.lua` | 34-66 |

---

*Document generated from CorsixTH source code analysis. All line numbers reference the current codebase state.*


## Related Pages

- [[16-object-placement/CHECKLIST]]
- [[16-object-placement/MAP]]
- [[16-object-placement/SCAFFOLD]]
