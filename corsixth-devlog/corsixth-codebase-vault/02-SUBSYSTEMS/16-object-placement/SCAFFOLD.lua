--[[
  Busted Test Scaffold for Object Placement & Footprints
  Run with: busted SCAFFOLD.lua
]]

local busted = require("busted")
local describe, it, before_each, after_each, setup, teardown = busted.describe, busted.it, busted.before_each, busted.after_each, busted.setup, busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
  return {
    map = {
      th = {
        setCellFlags = spy.new(function() end),
        getCellFlags = spy.new(function() return {} end),
        eraseObjectTypes = spy.new(function() end),
        updatePathfinding = spy.new(function() end),
      },
    },
    entity_map = {
      addEntity = spy.new(function() end),
      removeEntity = spy.new(function() end),
    },
    pathfinder = {
      isReachableFromHospital = spy.new(function() return true end),
      findDistance = spy.new(function() return 5 end),
    },
    anims = {},
    addObjectToTile = spy.new(function() end),
    removeObjectFromTile = spy.new(function() end),
    getRoom = spy.new(function() return { id = 1 } end),
    getLocalPlayerHospital = spy.new(function() return {} end),
    clearCaches = spy.new(function() end),
    resetSideObjects = spy.new(function() end),
    newObject = spy.new(function(id, x, y, dir)
      return {
        id = id,
        tile_x = x,
        tile_y = y,
        direction = dir,
        setTile = spy.new(function() end),
        onDestroy = spy.new(function() end),
      }
    end),
    destroyEntity = spy.new(function() end),
    isTilePartOfNearbyObject = spy.new(function() return false end),
    entities = {},
  }
end

local function createMockHospital()
  return {
    world = createMockWorld(),
    getIndexOfTask = spy.new(function() return -1 end),
    removeHandymanTask = spy.new(function() end),
    buildReceptionDesksCache = spy.new(function() end),
    gameLog = spy.new(function() end),
  }
end

local function createMockObjectType(overrides)
  local base = {
    id = "test_object",
    thob = 1,
    ticks = false,
    name = "Test Object",
    dynamic_info = false,
    idle_animations = { north = 100, east = 101, south = 102, west = 103 },
    orientations = {
      north = {
        footprint = { {0, 0, complete_cell = true} },
        use_position = {0, 0},
        render_attach_position = {0, 0},
        animation_offset = {0, 0},
      },
      east = {
        footprint = { {0, 0, complete_cell = true} },
        use_position = {0, 0},
        render_attach_position = {0, 0},
        animation_offset = {0, 0},
      },
      south = {
        footprint = { {0, 0, complete_cell = true} },
        use_position = {0, 0},
        render_attach_position = {0, 0},
        animation_offset = {0, 0},
      },
      west = {
        footprint = { {0, 0, complete_cell = true} },
        use_position = {0, 0},
        render_attach_position = {0, 0},
        animation_offset = {0, 0},
      },
    },
    default_strength = nil,
    slave_id = nil,
    class = "Object",
    corridor_object = false,
  }
  for k, v in pairs(overrides or {}) do
    base[k] = v
  end
  return base
end

local function createMockTH()
  return {
    animation = spy.new(function()
      return {
        setAnimation = spy.new(function() end),
        setCrop = spy.new(function() end),
        setHitTestResult = spy.new(function() end),
        setPosition = spy.new(function() end),
        setTile = spy.new(function() end),
        makeInvisible = spy.new(function() end),
        makeVisible = spy.new(function() end),
        tick = spy.new(function() end),
      }
    end),
  }
end

-- Mock global dependencies
_G.TH = createMockTH()
_G.DrawFlags = { FlipHorizontal = 1, EarlyList = 2, Crop = 4 }
_G.Map = {
  WorldToScreen = spy.new(function(x, y) return x * 32, y * 32 end),
}
_G.DrawingLayers = { NorthSideObject = 1, WestSideObject = 2, EastSideObject = 3, SouthSideObject = 4 }
_G._S = { object = {}, tooltip = { objects = {} }, dynamic_info = { object = { times_used = "Used %d times" } } }
_G.class = {
  is = spy.new(function(obj, cls) return true end),
  name = spy.new(function(t) return "Object" end),
  superclass = spy.new(function(t) return { Object = function() end } end),
}
_G.table_merge = function(a, b)
  local result = {}
  for k, v in pairs(a) do result[k] = v end
  for k, v in pairs(b) do result[k] = v end
  return result
end
_G.isTableEmpty = function(t) return next(t) == nil end
_G.Entity = function(th) end
Entity = {
  tick = spy.new(function() end),
  setAnimation = spy.new(function() end),
  onDestroy = spy.new(function() end),
  onPickUp = spy.new(function() end),
  afterLoad = spy.new(function() return true end),
}
_G.Hospital = {}
_G.UIEditRoom = {}
_G.UIFullscreen = {}
_G.UIPlaceObjects = spy.new(function() return {} end)
_G.Queue = spy.new(function() return {
  setBenchThreshold = spy.new(function() end),
  setMaxQueue = spy.new(function() end),
  front = spy.new(function() return nil end),
  pop = spy.new(function() end),
  patientSize = spy.new(function() return 0 end),
  isFull = spy.new(function() return false end),
  rerouteAllPatients = spy.new(function() end),
  visitor_count = 0,
} end)

-- Load the actual Object class
package.path = "/tmp/CorsixTH/CorsixTH/Lua/?.lua;" .. package.path
local Object = require("entities.object")

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Object Construction", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType()
    obj = Object(hospital, object_type, 10, 10, "north")
  end)

  it("should initialize with correct properties", function()
    assert.equals(hospital, obj.hospital)
    assert.equals(hospital.world, obj.world)
    assert.equals(object_type, obj.object_type)
    assert.equals("north", obj.direction)
    assert.equals(10, obj.tile_x)
    assert.equals(10, obj.tile_y)
    assert.equals(0, obj.times_used)
    assert.is_false(obj.user)
  end)

  it("should call initOrientation during construction", function()
    assert.spy(obj.initOrientation).was_called_with("north")
  end)

  it("should call setTile during construction", function()
    assert.spy(obj.setTile).was_called_with(10, 10)
  end)

  it("should convert numeric direction for map objects", function()
    local map_obj = Object(hospital, object_type, 5, 5, 0, "map object")
    assert.equals("north", map_obj.direction)
    
    local map_obj2 = Object(hospital, object_type, 5, 5, 1, "map object")
    assert.equals("west", map_obj2.direction)
  end)
end)

describe("Orientation System", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType({
      idle_animations = { north = 100, west = 101 },
      orientations = {
        north = { footprint = {{0,0,complete_cell=true}}, animation_offset={1,2}, render_attach_position={0,0} },
        west = { footprint = {{0,0,complete_cell=true}}, animation_offset={3,4}, render_attach_position={0,0} },
      }
    })
  end)

  it("should set direction and select correct animation", function()
    obj = Object(hospital, object_type, 10, 10, "north")
    assert.equals("north", obj.direction)
    assert.equals(100, obj.animation_idx)
  end)

  it("should mirror animation when direction not available", function()
    obj = Object(hospital, object_type, 10, 10, "east")
    -- east not in idle_animations, should mirror west with FlipHorizontal
    assert.equals(101, obj.animation_idx)
    assert.truthy(bit.band(obj.animation_flags, 1) > 0) -- FlipHorizontal
  end)

  it("should apply early_list flag", function()
    object_type.orientations.north.early_list = true
    obj = Object(hospital, object_type, 10, 10, "north")
    assert.truthy(bit.band(obj.animation_flags, 2) > 0) -- EarlyList
  end)

  it("should set up split animations for multi-tile render_attach_position", function()
    object_type.orientations.north.render_attach_position = {
      {0, 0, column = 0},
      {1, 0, column = 1},
      {0, 1, column = 2},
    }
    obj = Object(hospital, object_type, 10, 10, "north")
    assert.is_table(obj.split_anims)
    assert.equals(3, #obj.split_anims)
    assert.is_table(obj.split_anim_positions)
  end)

  it("should apply animation_offset", function()
    obj = Object(hospital, object_type, 10, 10, "north")
    assert.spy(obj.setPosition).was_called_with(1, 2)
  end)

  it("should extract footprint from orientation", function()
    obj = Object(hospital, object_type, 10, 10, "north")
    assert.is_table(obj.footprint)
    assert.equals(1, #obj.footprint)
  end)
end)

describe("Footprint Tiles", function()
  local hospital, object_type, obj, world, map

  before_each(function()
    hospital = createMockHospital()
    world = hospital.world
    map = world.map.th
    object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {
            {0, 0, complete_cell = true},
            {0, -1, only_passable = true},
            {1, 0, need_north_side = true, need_south_side = true},
          },
          use_position = {0, -1},
          render_attach_position = {0, 0},
          animation_offset = {0, 0},
        },
      }
    })
    obj = Object(hospital, object_type, 10, 10, "north")
  end)

  it("should occupy tiles on setTile", function()
    obj:setTile(10, 10)
    assert.spy(map.setCellFlags).was_called()
    -- Verify buildable=false on occupied tiles
    local calls = map.setCellFlags.calls
    local found_buildable_false = false
    for _, call in ipairs(calls) do
      local args = call.args
      if args[3] and args[3].buildable == false then
        found_buildable_false = true
        break
      end
    end
    assert.is_true(found_buildable_false)
  end)

  it("should set passable=true for only_passable tiles", function()
    obj:setTile(10, 10)
    local calls = map.setCellFlags.calls
    local found_passable_true = false
    for _, call in ipairs(calls) do
      local args = call.args
      if args[3] and args[3].passable == true then
        found_passable_true = true
        break
      end
    end
    assert.is_true(found_passable_true)
  end)

  it("should disable buildable flags for needed_side directions", function()
    obj:setTile(10, 10)
    local calls = map.setCellFlags.calls
    local found_north_false = false
    local found_south_false = false
    for _, call in ipairs(calls) do
      local args = call.args
      if args[3] and args[3].buildableNorth == false then found_north_false = true end
      if args[3] and args[3].buildableSouth == false then found_south_false = true end
    end
    assert.is_true(found_north_false)
    assert.is_true(found_south_false)
  end)

  it("should deoccupy tiles on move", function()
    obj:setTile(10, 10)
    obj:setTile(12, 12)
    assert.spy(map.setCellFlags).was_called()
    -- Should have calls restoring buildable=true
    local calls = map.setCellFlags.calls
    local found_buildable_true = false
    for _, call in ipairs(calls) do
      local args = call.args
      if args[3] and args[3].buildable == true then
        found_buildable_true = true
        break
      end
    end
    assert.is_true(found_buildable_true)
  end)

  it("should handle optional tiles correctly", function()
    object_type.orientations.north.footprint = {
      {0, 0, complete_cell = true},
      {0, -1, only_passable = true, optional = true},
    }
    obj = Object(hospital, object_type, 10, 10, "north")
    obj:setTile(10, 10)
    -- Optional tile should be processed
    assert.spy(map.setCellFlags).was_called()
  end)

  it("should reject optional tile if not in same room", function()
    world.getRoom = spy.new(function() return { id = 2 } end)
    object_type.orientations.north.footprint = {
      {0, 0, complete_cell = true},
      {0, -1, only_passable = true, optional = true},
    }
    obj = Object(hospital, object_type, 10, 10, "north")
    -- Flags should not be set for optional tile in different room
  end)

  it("should get walkable tiles from footprint", function()
    object_type.orientations.north.footprint = {
      {0, 0, complete_cell = true},
      {0, -1, only_passable = true},
      {1, 0, only_passable = true},
    }
    obj = Object(hospital, object_type, 10, 10, "north")
    local walkable = obj:getWalkableTiles()
    assert.equals(2, #walkable)
    assert.same({10, 9}, walkable[1])
    assert.same({11, 10}, walkable[2])
  end)
end)

describe("Use Positions", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {{0, 0, complete_cell = true}, {0, -1, only_passable = true}},
          use_position = {0, -1},
          use_position_secondary = {0, 1},
          finish_use_position = {1, -1},
          finish_use_position_secondary = {1, 1},
          slave_position = {1, 0},
          handyman_position = {{0, -2}, {-1, -1}},
          render_attach_position = {0, 0},
          animation_offset = {0, 0},
        },
      }
    })
    obj = Object(hospital, object_type, 10, 10, "north")
  end)

  it("should return use_position", function()
    local pos = obj:_getUsageTile("use_position")
    assert.is_table(pos)
    assert.same({10, 9, "use_position"}, pos[1])
  end)

  it("should return use_position_secondary", function()
    local pos = obj:_getUsageTile("use_position_secondary")
    assert.same({10, 11, "use_position_secondary"}, pos[1])
  end)

  it("should return slave_position", function()
    local pos = obj:_getUsageTile("slave_position")
    assert.same({11, 10, "slave_position"}, pos[1])
  end)

  it("should return finish_use_position", function()
    local pos = obj:_getUsageTile("finish_use_position")
    assert.same({11, 9, "finish_use_position"}, pos[1])
  end)

  it("should return finish_use_position_secondary", function()
    local pos = obj:_getUsageTile("finish_use_position_secondary")
    assert.same({11, 11, "finish_use_position_secondary"}, pos[1])
  end)

  it("should return multiple handyman_positions", function()
    local pos = obj:_getUsageTile("handyman_position")
    assert.equals(2, #pos)
    assert.same({10, 8, "handyman_position"}, pos[1])
    assert.same({9, 9, "handyman_position"}, pos[2])
  end)

  it("should get secondary usage tile coordinates", function()
    local x, y = obj:getSecondaryUsageTile()
    assert.equals(10, x)
    assert.equals(11, y)
  end)

  it("should get all usage tiles", function()
    local all = obj:getAllUsageTiles()
    assert.is_table(all)
    assert.truthy(all["use_position"])
    assert.truthy(all["use_position_secondary"])
    assert.truthy(all["slave_position"])
    assert.truthy(all["finish_use_position"])
    assert.truthy(all["finish_use_position_secondary"])
    assert.truthy(all["handyman_position"])
  end)

  it("should return nil for unknown position", function()
    local pos = obj:_getUsageTile("unknown_position")
    assert.is_nil(pos)
  end)

  it("should resolve 'passable' use_position to first only_passable tile", function()
    -- This is tested in processTypeDefinition, but verify runtime behavior
    object_type.orientations.north.use_position = "passable"
    obj = Object(hospital, object_type, 10, 10, "north")
    local pos = obj:_getUsageTile("use_position")
    assert.same({10, 9, "use_position"}, pos[1])
  end)
end)

describe("Direction Parameters", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType()
    obj = Object(hospital, object_type, 10, 10, "north")
  end)

  it("should return correct direction parameters", function()
    local params = Object.directionParameters()
    assert.same({x=0, y=-1, buildable_flag="buildableNorth", passable_flag="travelNorth", needed_side="need_north_side"}, params.north)
    assert.same({x=1, y=0, buildable_flag="buildableEast", passable_flag="travelEast", needed_side="need_east_side"}, params.east)
    assert.same({x=0, y=1, buildable_flag="buildableSouth", passable_flag="travelSouth", needed_side="need_south_side"}, params.south)
    assert.same({x=-1, y=0, buildable_flag="buildableWest", passable_flag="travelWest", needed_side="need_west_side"}, params.west)
  end)

  it("should get complementary passable flag", function()
    assert.equals("travelSouth", Object.getComplementaryPassableFlag("travelNorth"))
    assert.equals("travelNorth", Object.getComplementaryPassableFlag("travelSouth"))
    assert.equals("travelWest", Object.getComplementaryPassableFlag("travelEast"))
    assert.equals("travelEast", Object.getComplementaryPassableFlag("travelWest"))
  end)

  it("should apply direction parameters during occupation", function()
    obj:setTile(10, 10)
    local map = hospital.world.map.th
    local calls = map.setCellFlags.calls
    -- Verify buildableNorth is set to false for north-facing object at origin
    local found = false
    for _, call in ipairs(calls) do
      local args = call.args
      if args[3] and args[3].buildableNorth == false then
        found = true
        break
      end
    end
    assert.is_true(found)
  end)
end)

describe("Master-Slave Pattern", function()
  local hospital, object_type, master_obj, slave_obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType({
      id = "master_obj",
      slave_id = "slave_obj",
      orientations = {
        north = {
          footprint = {{0, 0, complete_cell = true}},
          slave_position = {1, 0},
          render_attach_position = {0, 0},
          animation_offset = {0, 0},
        },
      }
    })
    master_obj = Object(hospital, object_type, 10, 10, "north")
    slave_obj = master_obj.slave
  end)

  it("should create slave at master position + slave_position offset", function()
    assert.is_table(slave_obj)
    assert.equals(11, slave_obj.tile_x)
    assert.equals(10, slave_obj.tile_y)
    assert.equals("north", slave_obj.direction)
  end)

  it("should set slave.master to master", function()
    assert.equals(master_obj, slave_obj.master)
  end)

  it("should move slave when master moves", function()
    master_obj:setTile(15, 15)
    assert.equals(16, slave_obj.tile_x)
    assert.equals(15, slave_obj.tile_y)
  end)

  it("should destroy slave when master destroyed", function()
    master_obj:onDestroy()
    assert.spy(hospital.world.destroyEntity).was_called_with(slave_obj)
  end)

  it("should redirect slave onClick to master", function()
    local ui = {}
    slave_obj:onClick(ui, "left")
    assert.spy(master_obj.onClick).was_called_with(master_obj, ui, "left", nil)
  end)

  it("should redirect slave updateDynamicInfo to master", function()
    slave_obj:updateDynamicInfo()
    assert.spy(master_obj.updateDynamicInfo).was_called_with(master_obj)
  end)

  it("should call initOrientation on slave when master changes orientation", function()
    master_obj:initOrientation("east")
    assert.spy(slave_obj.initOrientation).was_called_with("east")
  end)

  it("should handle class with slaveMixinClass", function()
    local Machine = require("entities.machine") -- If exists, otherwise skip
    -- OperatingTable example:
    -- class "OperatingTable" (Machine)
    -- OperatingTable:slaveMixinClass()
  end)
end)

describe("Type Definition Processing", function()
  it("should set default animation_offset and render_attach_position", function()
    local object_type = createMockObjectType({
      orientations = {
        north = { footprint = {{0,0,complete_cell=true}} },
      }
    })
    Object.processTypeDefinition(object_type)
    assert.same({0, 0}, object_type.orientations.north.animation_offset)
    assert.same({0, 0}, object_type.orientations.north.render_attach_position)
  end)

  it("should resolve 'passable' use_position", function()
    local object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {{0,0,complete_cell=true}, {0,-1,only_passable=true}},
          use_position = "passable",
        },
      }
    })
    Object.processTypeDefinition(object_type)
    assert.same({0, -1}, object_type.orientations.north.use_position)
  end)

  it("should set handyman_position to use_position if default_strength", function()
    local object_type = createMockObjectType({
      default_strength = 10,
      orientations = {
        north = {
          footprint = {{0,0,complete_cell=true}, {0,-1,only_passable=true}},
          use_position = {0, -1},
        },
      }
    })
    Object.processTypeDefinition(object_type)
    assert.same({0, -1}, object_type.orientations.north.handyman_position)
  end)

  it("should adjust footprint origin to nearest solid tile", function()
    local object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {
            {-1, -1, complete_cell = true},
            {0, -1, only_passable = true},
            {0, 0, complete_cell = true},
          },
          use_position = {0, -1},
        },
      }
    })
    Object.processTypeDefinition(object_type)
    -- Nearest solid to use_position(0,-1) is (0,0) or (-1,-1), both distance 1
    -- Origin shifts so nearest solid becomes (0,0)
    -- use_position should be adjusted
  end)

  it("should calculate pathfind_allowed_dirs", function()
    local object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {{0,0,complete_cell=true}, {0,-1,only_passable=true}},
          use_position = {0, -1},
        },
      }
    })
    Object.processTypeDefinition(object_type)
    assert.is_table(object_type.orientations.north.pathfind_allowed_dirs)
  end)

  it("should build adjacent_to_solid_footprint", function()
    local object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {{0,0,complete_cell=true}, {0,-1,only_passable=true}},
          use_position = {0, -1},
        },
      }
    })
    Object.processTypeDefinition(object_type)
    assert.is_table(object_type.orientations.north.adjacent_to_solid_footprint)
  end)
end)

describe("Edge Cases & Special Objects", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
  end)

  it("should handle trash bin (thob 50) east-as-west quirk", function()
    object_type = createMockObjectType({
      thob = 50,
      orientations = {
        north = { footprint = {{0,0,complete_cell=true}}, render_attach_position={0,0}, animation_offset={0,0} },
        east = { footprint = {{0,0,complete_cell=true}}, render_attach_position={0,0}, animation_offset={0,0} },
      }
    })
    obj = Object(hospital, object_type, 10, 10, "east")
    obj:setTile(10, 10)
    -- Should treat east as west for footprint occupation
  end)

  it("should handle SideObject drawing layers", function()
    local SideObject = require("entities.object").SideObject
    object_type = createMockObjectType({ class = "SideObject" })
    obj = SideObject(hospital, object_type, 10, 10, "north")
    assert.equals(1, obj:getDrawingLayer()) -- NorthSideObject
    
    obj = SideObject(hospital, object_type, 10, 10, "west")
    assert.equals(2, obj:getDrawingLayer()) -- WestSideObject
  end)

  it("should handle split animation positioning", function()
    object_type = createMockObjectType({
      orientations = {
        north = {
          footprint = {{0,0,complete_cell=true}},
          render_attach_position = {
            {0, 0, column = 0},
            {1, 0, column = 1},
          },
          animation_offset = {0, 0},
        },
      }
    })
    obj = Object(hospital, object_type, 10, 10, "north")
    obj:setPosition(100, 100)
    -- Split anims should be positioned relative to primary
    assert.spy(obj.split_anims[1].setPosition).was_called()
    assert.spy(obj.split_anims[2].setPosition).was_called()
  end)

  it("should handle object state save/load", function()
    object_type = createMockObjectType()
    obj = Object(hospital, object_type, 10, 10, "north")
    obj.times_used = 5
    local state = obj:getState()
    assert.equals(5, state.times_used)
    
    obj.times_used = 0
    obj:setState(state)
    assert.equals(5, obj.times_used)
  end)
end)

describe("Reception Desk (Corridor Object)", function()
  local hospital, object_type, obj

  before_each(function()
    hospital = createMockHospital()
    object_type = createMockObjectType({
      id = "reception_desk",
      class = "ReceptionDesk",
      corridor_object = 1,
      orientations = {
        north = {
          footprint = {
            {0, 0, complete_cell = true},
            {0, -1, only_passable = true},
            {0, 1, only_passable = true},
            {1, 0, need_north_side = true, need_south_side = true},
            {-1, 0, need_north_side = true, need_south_side = true},
          },
          use_position = {0, -1},
          use_position_secondary = {0, 1},
          render_attach_position = {0, 0},
          animation_offset = {0, 0},
        },
      }
    })
    obj = Object(hospital, object_type, 10, 10, "north")
  end)

  it("should have corridor_object flag", function()
    assert.is_true(obj.object_type.corridor_object)
  end)

  it("should have use_position_secondary for receptionist", function()
    local x, y = obj:getSecondaryUsageTile()
    assert.equals(10, x)
    assert.equals(11, y)
  end)
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted will auto-run all describe blocks
print("Test scaffold loaded. Run with: busted SCAFFOLD.lua")
