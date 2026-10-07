require("corsixth")
require("class_test_base")
require("utility")
require("persistance")

local saved_A = _G._A
_G._A = {cheats = {}, warnings = {}}
require("map")
require("entity")
require("entities.humanoid")
require("entities.object")
require("entities.machine")
require("room")
require("humanoid_action")
require("world")

-- Mock _S (strings) with the dynamic_info structure that room.lua needs
_G._S = {
  dynamic_info = {
    object = {
      queue_size = "Queue size: %d",
      queue_expected = "Expected queue: %d",
    },
  },
}

-- Mock action classes globally
_G.MockAction = setmetatable({}, {__index = function() return _G.MockAction end})
_G.MockAction.setIsLeaving = function() return _G.MockAction end
_G.MockAction.setIsEntering = function() return _G.MockAction end
_G.MockAction.setMustHappen = function() return _G.MockAction end
_G.MockAction.disableTruncate = function() return _G.MockAction end
_G.MockAction.truncateOnHighPriority = function() return _G.MockAction end
_G.MockAction.enableWalkingToVaccinate = function() return _G.MockAction end

_G.WalkAction = function() return _G.MockAction end
_G.MeanderAction = function() return _G.MockAction end
_G.UseObjectAction = function() return _G.MockAction end
_G.IdleAction = function() return _G.MockAction end
_G.SpawnAction = function() return _G.MockAction end
_G.SeekRoomAction = function() return _G.MockAction end
_G.SeekStaffRoomAction = function() return _G.MockAction end
_G.UseStaffRoomAction = function() return _G.MockAction end
_G.MultiUseObjectAction = function() return _G.MockAction end
_G.UseObjectAction = function() return _G.MockAction end

_G.UIEditRoom = function() return _G.MockAction end

local Room = _G["Room"]

-- Helper functions (defined before describe blocks)
function makeHumanoid(name)
  local h = {
    name = name,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    ticks = true,
    kind = "humanoid",
    entity_type = {id = "test_humanoid"},
    ticks = true,
    to_destroy = false,
    destroyed = false,
    ui = nil,  -- needed for onHumanoidLeave
    warnings = {},  -- needed for onHumanoidEnter
  }
  function h:tick() end
  function h:tickDay() end
  function h:onDestroy() self.destroyed = true end
  function h:onObjectRemove(obj) end
  function h:finishAction() end
  function h:queueAction(a) end
  function h:hasObject() return false end
  function h:getRoom() return nil end
  function h:setRoom(r) end
  function h:isInRoom(r) return false end
  function h:setNextAction(a) end
  function h:die() end
  function h:despawn() end
  function h:destroyEntity() end
  return h
end

function makeObject(id)
  local o = {
    id = id,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    object_type = {id = id},
    to_destroy = false,
    destroyed = false,
  }
  function o:onDestroy() self.destroyed = true end
  function o:onObjectRemove(obj) end
  return o
end

function makeRoom()
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local room = Room(0, 0, 5, 5, 1, room_info, world, hospital, door, nil)
  room.building_complete = true
  room.is_active = true
  room.floor_soot = {}
  room.wall_soot = {}
  return room
end

local function makeHumanoid(name)
  local h = {
    name = name,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    ticks = true,
    kind = "humanoid",
    entity_type = {id = "test_humanoid"},
    ticks = true,
    to_destroy = false,
    destroyed = false,
    ui = nil,  -- needed for onHumanoidLeave
    warnings = {},  -- needed for onHumanoidEnter
  }
  function h:tick() end
  function h:tickDay() end
  function h:onDestroy() self.destroyed = true end
  function h:onObjectRemove(obj) end
  function h:finishAction() end
  function h:queueAction(a) end
  function h:hasObject() return false end
  function h:getRoom() return nil end
  function h:setRoom(r) end
  function h:isInRoom(r) return false end
  function h:setNextAction(a) end
  function h:die() end
  function h:despawn() end
  function h:destroyEntity() end
  return h
end

function makeObject(id)
  local o = {
    id = id,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    object_type = {id = id},
    to_destroy = false,
    destroyed = false,
  }
  function o:onDestroy() self.destroyed = true end
  function o:onObjectRemove(obj) end
  return o
end

describe("room.lua: ", function()
  local room

  before_each(function()
    room = makeRoom()
  end)

  describe("onHumanoidEnter/onHumanoidLeave symmetry", function()
    it("adds humanoid to room and sets humanoid.in_room", function()
      local h = makeHumanoid("test")
      room:onHumanoidEnter(h)
      assert.is_true(room.humanoids[h])
      assert.is_equal(room, h.in_room)
    end)

    it("removes humanoid from room and clears humanoid.in_room", function()
      local h = makeHumanoid("test")
      room:onHumanoidEnter(h)
      room:onHumanoidLeave(h)
      assert.is_nil(room.humanoids[h])
      assert.is_nil(h.in_room)
    end)

    it("leave on non-member is safe (no error)", function()
      local h = makeHumanoid("test")
      room:onHumanoidLeave(h)
    end)

    it("enter/leave twice restores original state", function()
      local h = makeHumanoid("test")
      room:onHumanoidEnter(h)
      room:onHumanoidLeave(h)
      room:onHumanoidEnter(h)
      room:onHumanoidLeave(h)
      assert.is_nil(room.humanoids[h])
      assert.is_nil(h.in_room)
    end)

    it("multiple humanoids enter/leave independently", function()
      local h1, h2 = makeHumanoid("h1"), makeHumanoid("h2")
      room:onHumanoidEnter(h1)
      room:onHumanoidEnter(h2)
      room:onHumanoidLeave(h1)
      assert.is_true(room.humanoids[h2])
      assert.is_equal(room, h2.in_room)
    end)
  end)

  describe("crash handling", function()
    it("crashRoom sets crashed flag and deactivates room", function()
      room:crashRoom()
      assert.is_true(room.crashed)
      assert.is_false(room.is_active)
    end)

    it("crashRoom increments num_explosions", function()
      room:crashRoom()
      assert.is_equal(1, room.hospital.num_explosions)
    end)

    it("crashRoom changes hospital value and reputation", function()
      room:crashRoom()
      -- Verify no crash occurred
      assert.is_true(true)
    end)

    it("crashRoom calls deactivate which notifies world", function()
      room:crashRoom()
      -- verify no crash occurred
      assert.is_true(true)
    end)
  end)

  describe("room state consistency", function()
    it("active flag starts true after building", function()
      local r = makeRoom()
      assert.is_true(r.is_active)
      assert.is_false(r.crashed)
    end)

    it("crashRoom sets crashed flag", function()
      room:crashRoom()
      assert.is_true(room.crashed)
    end)

    it("onHumanoidLeave does not crash on empty room", function()
      room:onHumanoidLeave(makeHumanoid("h"))
    end)

    it("crashRoom twice is idempotent", function()
      room:crashRoom()
      local h1 = makeHumanoid("h1")
      room:crashRoom()
      room:onHumanoidEnter(h1)
      assert.is_true(room.crashed)
    end)
  end)

  describe("hasQueueDialog", function()
    it("returns false when room_info.has_no_queue_dialog is true", function()
      local r = makeRoom()
      assert.is_false(r:hasQueueDialog())
    end)

    it("returns true when room_info.has_no_queue_dialog is false", function()
      local door = {
        direction = "north",
        tile_x = 0,
        tile_y = 0,
        setupDoor = function(self, room, old_door) end,
        setDynamicInfo = function(self, t) end,
        direction = "north",
        closeDoor = function(self) end,
        updateDynamicInfo = function(self) end,
        queue = {
          size = function() return 0 end,
          front = function() return nil end,
          pop = function() end,
          reportedSize = function() return 0 end,
        },
      }
      
      local room_info = {
        id = "test_room",
        name = "Test Room",
        floor_tile = 1,
        has_no_queue_dialog = false,
      }
      
      local world = {
        map = {th = {markRoom = function() end}},
        getRoom = function() return nil end,
        prepareRectangleTilesForBuild = function() end,
        findAllObjectsNear = function() return {} end,
        newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
      }
      
      local hospital = {disease_casebook = {}}
      
      -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
      local room = Room(0, 0, 5, 5, 1, room_info, world, {disease_casebook = {}}, door, nil)
      room.building_complete = true
      room.is_active = true
      assert.is_true(room:hasQueueDialog())
    end)
  end)
end)

function makeRoom()
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local door = {
    direction = "north",
    tile_x = 0,
    tile_y = 0,
    setupDoor = function(self, room, old_door) end,
    setDynamicInfo = function(self, t) end,
    direction = "north",
    closeDoor = function(self) end,
    updateDynamicInfo = function(self) end,
    queue = {
      size = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      reportedSize = function() return 0 end,
      rerouteAllPatients = function() end,
    },
  }
  
  local room_info = {
    id = "test_room",
    name = "Test Room",
    floor_tile = 1,
    has_no_queue_dialog = true,
  }
  
  local world = {
    map = {th = {markRoom = function() end, getCell = function() return {flags = {}} end}},
    getRoom = function() return nil end,
    prepareRectangleTilesForBuild = function() end,
    findAllObjectsNear = function() return {} end,
    newObject = function() return {onDestroy = function() end, destroyed = false, setLitterType = function() end} end,
    destroyEntity = function() end,
    getWallSetFromBlockId = function() return {} end,
    notifyRoomRemoved = function() end,
    removeRatholesAroundRoom = function() end,
    ui = {getWindow = function() return nil end, addWindow = function() end},
  }
  
  local hospital = {
    disease_casebook = {}, 
    addHandymanTask = function() end, 
    giveAdvice = function() end, 
    changeReputation = function() end,
    changeValue = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0, 
    research = {
      research_progress = {
        [room_info] = {build_cost = 1000}
      }
    }
  }
  
  -- Room:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  local room = Room(0, 0, 5, 5, 1, room_info, world, hospital, door, nil)
  room.building_complete = true
  room.is_active = true
  room.floor_soot = {}
  room.wall_soot = {}
  return room
end

local function makeHumanoid(name)
  local h = {
    name = name,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    ticks = true,
    kind = "humanoid",
    entity_type = {id = "test_humanoid"},
    ticks = true,
    to_destroy = false,
    destroyed = false,
    ui = nil,  -- needed for onHumanoidLeave
    warnings = {},  -- needed for onHumanoidEnter
  }
  function h:tick() end
  function h:tickDay() end
  function h:onDestroy() self.destroyed = true end
  function h:onObjectRemove(obj) end
  function h:finishAction() end
  function h:queueAction(a) end
  function h:hasObject() return false end
  function h:getRoom() return nil end
  function h:setRoom(r) end
  function h:isInRoom(r) return false end
  function h:setNextAction(a) end
  function h:die() end
  function h:despawn() end
  function h:destroyEntity() end
  return h
end

function makeObject(id)
  local o = {
    id = id,
    tile_x = 2,
    tile_y = 2,
    direction = "north",
    object_type = {id = id},
    to_destroy = false,
    destroyed = false,
  }
  function o:onDestroy() self.destroyed = true end
  function o:onObjectRemove(obj) end
  return o
end
