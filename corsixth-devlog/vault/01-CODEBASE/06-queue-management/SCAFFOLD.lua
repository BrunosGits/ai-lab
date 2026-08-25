--[[
  Busted Test Scaffold for CorsixTH Queue Management
  Run with: busted SCAFFOLD.lua
]]

local Queue = require("queue")
local class = require("class")

-- ============================================================
-- MOCK HELPERS
-- ============================================================

local function mockHumanoid(type_name, overrides)
  local h = {
    humanoid_class = type_name,
    is_emergency = false,
    hospital = {
      hosp_cheats = {
        isCheatActive = function(self, name) return false end
      }
    },
    getAttribute = function(self, attr)
      if attr == "health" then return overrides.health or 1.0 end
      return 0.5
    end,
    getRoom = function(self) return overrides.room end,
    setMood = function() end,
    setNextAction = function() end,
    queueAction = function() end,
    isLeaving = function(self) return overrides.is_leaving or false end,
    getCurrentAction = function() return { name = "idle" } end,
    action_queue = {},
    world = {
      getPathDistance = function() return 5 end,
      getIdleTile = function() return 1, 1 end,
      getFreeBench = function() return nil end,
    },
  }
  
  -- Class identification
  function h:is_a(class_name)
    return self.humanoid_class == class_name
  end
  
  -- Class module compatibility
  local class_mod = { is = function(obj, cls) return obj:is_a(cls) end }
  if type_name == "Patient" then
    class_mod.Patient = {}
    class_mod.Staff = {}
    class_mod.Vip = {}
    class_mod.Inspector = {}
  end
  
  return h, class_mod
end

local function mockDoor(room)
  return {
    room = room,
    tile_x = 10, tile_y = 10,
    queue = nil,
    updateDynamicInfo = function() end,
    getRoom = function(self) return self.room end,
    reserved_for = nil,
    user = nil,
  }
end

local function mockRoom(id)
  return {
    room_info = { id = id, name = id },
    door = nil,
    humanoids = {},
    is_active = true,
    staff_member = nil,
    tryAdvanceQueue = function(self) end,
    canHumanoidEnter = function(self, h) return true end,
    hasQueueDialog = function() return true end,
    _checkWaitToggleValidTarget = function() return false end,
    _staffWaitToggle = function() end,
    testStaffCriteria = function() return true end,
    getRequiredStaffCriteria = function() return {} end,
  }
end

-- Patch global class.is for tests
_G.class = _G.class or {}
_G.class.is = function(obj, cls)
  if obj and obj.humanoid_class then
    return obj.humanoid_class == cls
  end
  return false
end

-- ============================================================
-- TEST SUITE
-- ============================================================

describe("Queue Management", function()
  local queue, room, door, class_mock
  
  before_each(function()
    room = mockRoom("gp")
    door = mockDoor(room)
    room.door = door
    
    queue = Queue()
    door.queue = queue
    queue:setPriorityForSameRoom(door)
    
    class_mock = {
      Patient = {},
      Staff = {},
      Vip = {},
      Inspector = {},
      is = function(obj, cls) return obj.humanoid_class == cls end
    }
  end)
  
  -- ------------------------------------------------------------
  -- PRIORITY ORDERING TESTS
  -- ------------------------------------------------------------
  describe("Priority Ordering", function()
    it("leaving patients get priority 1 (highest)", function()
      local leaving = mockHumanoid("Patient", { room = room, is_leaving = true })
      local regular = mockHumanoid("Patient", { room = nil })
      
      queue:push(regular)
      queue:push(leaving)
      
      assert.are.equal(leaving, queue:front())
      assert.are.equal(regular, queue:back())
    end)
    
    it("staff get priority 2 (after leaving)", function()
      local staff = mockHumanoid("Staff", {})
      local regular = mockHumanoid("Patient", {})
      local leaving = mockHumanoid("Patient", { room = room, is_leaving = true })
      
      queue:push(regular)
      queue:push(staff)
      queue:push(leaving)
      
      assert.are.equal(leaving, queue[1])
      assert.are.equal(staff, queue[2])
      assert.are.equal(regular, queue[3])
    end)
    
    it("VIP/Inspector get priority 3", function()
      local vip = mockHumanoid("Vip", {})
      local inspector = mockHumanoid("Inspector", {})
      local staff = mockHumanoid("Staff", {})
      local regular = mockHumanoid("Patient", {})
      
      queue:push(regular)
      queue:push(vip)
      queue:push(staff)
      queue:push(inspector)
      
      -- Order: leaving (none), staff, VIP, Inspector, regular
      assert.are.equal(staff, queue[1])
      assert.are.equal(vip, queue[2])
      assert.are.equal(inspector, queue[3])
      assert.are.equal(regular, queue[4])
    end)
    
    it("emergency patients get priority 4", function()
      local emergency = mockHumanoid("Patient", {})
      emergency.is_emergency = true
      local regular = mockHumanoid("Patient", {})
      local staff = mockHumanoid("Staff", {})
      
      queue:push(regular)
      queue:push(emergency)
      queue:push(staff)
      
      assert.are.equal(staff, queue[1])
      assert.are.equal(emergency, queue[2])
      assert.are.equal(regular, queue[3])
    end)
    
    it("queue-jump cheat gives priority 5 for critical health", function()
      local critical = mockHumanoid("Patient", { health = 0.05 })
      critical.hospital.hosp_cheats.isCheatActive = function(self, name)
        return name == "queuejump"
      end
      local regular = mockHumanoid("Patient", { health = 1.0 })
      local emergency = mockHumanoid("Patient", {})
      emergency.is_emergency = true
      
      queue:push(regular)
      queue:push(critical)
      queue:push(emergency)
      
      assert.are.equal(emergency, queue[1])  -- Emergency (4) before cheat (5)
      assert.are.equal(critical, queue[2])   -- Cheat (5) before regular (6)
      assert.are.equal(regular, queue[3])
    end)
    
    it("queue-jump cheat inactive falls back to regular priority", function()
      local critical = mockHumanoid("Patient", { health = 0.05 })
      critical.hospital.hosp_cheats.isCheatActive = function(self, name) return false end
      local regular = mockHumanoid("Patient", { health = 1.0 })
      
      queue:push(regular)
      queue:push(critical)
      
      -- Both priority 6, insertion order preserved (critical inserted after regular)
      assert.are.equal(regular, queue[1])
      assert.are.equal(critical, queue[2])
    end)
    
    it("regular patients get priority 6 (lowest)", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      assert.are.equal(p1, queue[1])
      assert.are.equal(p2, queue[2])
      assert.are.equal(p3, queue[3])
    end)
  end)
  
  -- ------------------------------------------------------------
  -- PUSH/POP TESTS
  -- ------------------------------------------------------------
  describe("Push/Pop Operations", function()
    it("push adds to correct priority position", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      assert.are.equal(1, queue:size())
      assert.are.equal(p1, queue:front())
      
      queue:push(p2)
      assert.are.equal(2, queue:size())
      assert.are.equal(p1, queue:front())
      assert.are.equal(p2, queue:back())
    end)
    
    it("pop removes front and returns it", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      
      local popped = queue:pop()
      assert.are.equal(p1, popped)
      assert.are.equal(1, queue:size())
      assert.are.equal(p2, queue:front())
    end)
    
    it("pop decrements reported_size for patients", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      assert.are.equal(2, queue:reportedSize())
      
      queue:pop()
      assert.are.equal(1, queue:reportedSize())
    end)
    
    it("pop does not decrement reported_size for staff", function()
      local staff = mockHumanoid("Staff", {})
      local patient = mockHumanoid("Patient", {})
      
      queue:push(staff)      -- Staff priority 2, not reported
      queue:push(patient)    -- Patient priority 6, reported
      
      assert.are.equal(1, queue:reportedSize())
      assert.are.equal(2, queue:size())
      
      queue:pop()  -- Removes staff
      assert.are.equal(1, queue:reportedSize())  -- Unchanged
      assert.are.equal(1, queue:size())
    end)
    
    it("pop calls onLeaveQueue callback", function()
      local callback_called = false
      local patient = mockHumanoid("Patient", {})
      local callbacks = {
        onLeaveQueue = function() callback_called = true end
      }
      
      queue:push(patient, callbacks)
      queue:pop()
      
      assert.is_true(callback_called)
    end)
    
    it("pop calls onChangeQueuePosition for remaining", function()
      local positions = {}
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1, { onChangeQueuePosition = function(h) positions[h] = 1 end })
      queue:push(p2, { onChangeQueuePosition = function(h) positions[h] = 2 end })
      queue:push(p3, { onChangeQueuePosition = function(h) positions[h] = 3 end })
      
      queue:pop()
      
      assert.is_true(positions[p2] == 1)  -- p2 moved from pos 2 to 1
      assert.is_true(positions[p3] == 2)  -- p3 moved from pos 3 to 2
    end)
  end)
  
  -- ------------------------------------------------------------
  -- MOVE TESTS
  -- ------------------------------------------------------------
  describe("Move Operations", function()
    it("move swaps positions iteratively", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      local p4 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      queue:push(p4)
      
      -- Move p1 (index 1) to index 3
      queue:move(1, 3)
      
      assert.are.equal(p2, queue[1])
      assert.are.equal(p3, queue[2])
      assert.are.equal(p1, queue[3])
      assert.are.equal(p4, queue[4])
    end)
    
    it("move handles backward direction", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      -- Move p3 (index 3) to index 1
      queue:move(3, 1)
      
      assert.are.equal(p3, queue[1])
      assert.are.equal(p1, queue[2])
      assert.are.equal(p2, queue[3])
    end)
    
    it("move does nothing for invalid indices", function()
      local p1 = mockHumanoid("Patient", {})
      queue:push(p1)
      
      queue:move(1, 1)      -- Same index
      queue:move(5, 1)      -- Out of bounds
      queue:move(1, 5)      -- Out of bounds
      
      assert.are.equal(p1, queue[1])
      assert.are.equal(1, queue:size())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- MOVEPATIENT TESTS (relative to reported patients)
  -- ------------------------------------------------------------
  describe("MovePatient Operations", function()
    it("movePatient respects reported patient indexing", function()
      local staff = mockHumanoid("Staff", {})
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(staff)   -- Index 1, not reported
      queue:push(p1)      -- Index 2, reported #1
      queue:push(p2)      -- Index 3, reported #2
      queue:push(p3)      -- Index 4, reported #3
      
      assert.are.equal(3, queue:reportedSize())
      assert.are.equal(4, queue:size())
      
      -- Move reported patient #2 (p2) to front
      queue:movePatient(2, 'front')
      
      -- Queue: staff, p2, p1, p3
      assert.are.equal(staff, queue[1])
      assert.are.equal(p2, queue[2])
      assert.are.equal(p1, queue[3])
      assert.are.equal(p3, queue[4])
    end)
    
    it("movePatient 'back' moves to end of reported patients", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      queue:movePatient(1, 'back')
      
      assert.are.equal(p2, queue[1])
      assert.are.equal(p3, queue[2])
      assert.are.equal(p1, queue[3])
    end)
    
    it("movePatient numeric index is 1-based offset", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      queue:movePatient(1, 2)  -- Move 1st to position 2
      
      assert.are.equal(p2, queue[1])
      assert.are.equal(p1, queue[2])
      assert.are.equal(p3, queue[3])
    end)
  end)
  
  -- ------------------------------------------------------------
  -- SIZE LIMIT TESTS
  -- ------------------------------------------------------------
  describe("Size Limits", function()
    it("isFull returns true when size >= max_size", function()
      queue:setMaxQueue(2)
      
      queue:push(mockHumanoid("Patient", {}))
      assert.is_false(queue:isFull())
      
      queue:push(mockHumanoid("Patient", {}))
      assert.is_true(queue:isFull())
    end)
    
    it("setMaxQueue clamps to 0-30", function()
      queue:setMaxQueue(-5)
      assert.are.equal(0, queue.max_size)
      
      queue:setMaxQueue(50)
      assert.are.equal(30, queue.max_size)
      
      queue:setMaxQueue(10)
      assert.are.equal(10, queue.max_size)
    end)
    
    it("increaseMaxSize respects clamp", function()
      queue:setMaxQueue(28)
      queue:increaseMaxSize(5)
      assert.are.equal(30, queue.max_size)
    end)
    
    it("decreaseMaxSize respects clamp", function()
      queue:setMaxQueue(3)
      queue:decreaseMaxSize(5)
      assert.are.equal(0, queue.max_size)
    end)
  end)
  
  -- ------------------------------------------------------------
  -- BENCH THRESHOLD TESTS
  -- ------------------------------------------------------------
  describe("Bench Threshold", function()
    it("setBenchThreshold sets standing count", function()
      queue:setBenchThreshold(3)
      assert.are.equal(3, queue.bench_threshold)
    end)
    
    it("first N reported patients must stand (simulated)", function()
      queue:setBenchThreshold(2)
      
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      -- In action_queue_on_change_position, first 2 reported patients
      -- would have must_stand = true
      assert.are.equal(2, queue.bench_threshold)
      assert.are.equal(3, queue:reportedSize())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- DISPLAY FILTERING TESTS
  -- ------------------------------------------------------------
  describe("Display Filtering (reported_priority_threshold)", function()
    it("leaving patients not in reportedSize", function()
      local leaving = mockHumanoid("Patient", { room = room, is_leaving = true })
      local patient = mockHumanoid("Patient", {})
      
      queue:push(leaving)
      queue:push(patient)
      
      assert.are.equal(2, queue:size())
      assert.are.equal(1, queue:reportedSize())  -- Only patient
    end)
    
    it("staff not in reportedSize", function()
      local staff = mockHumanoid("Staff", {})
      local patient = mockHumanoid("Patient", {})
      
      queue:push(staff)
      queue:push(patient)
      
      assert.are.equal(2, queue:size())
      assert.are.equal(1, queue:reportedSize())
    end)
    
    it("VIP/Inspector not in reportedSize", function()
      local vip = mockHumanoid("Vip", {})
      local inspector = mockHumanoid("Inspector", {})
      local patient = mockHumanoid("Patient", {})
      
      queue:push(vip)
      queue:push(inspector)
      queue:push(patient)
      
      assert.are.equal(3, queue:size())
      assert.are.equal(1, queue:reportedSize())
    end)
    
    it("emergency patients in reportedSize", function()
      local emergency = mockHumanoid("Patient", {})
      emergency.is_emergency = true
      local patient = mockHumanoid("Patient", {})
      
      queue:push(emergency)
      queue:push(patient)
      
      assert.are.equal(2, queue:size())
      assert.are.equal(2, queue:reportedSize())
    end)
    
    it("queue-jump cheat patients in reportedSize", function()
      local critical = mockHumanoid("Patient", { health = 0.05 })
      critical.hospital.hosp_cheats.isCheatActive = function(self, name)
        return name == "queuejump"
      end
      local patient = mockHumanoid("Patient", {})
      
      queue:push(critical)
      queue:push(patient)
      
      assert.are.equal(2, queue:size())
      assert.are.equal(2, queue:reportedSize())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- REMOVE TESTS
  -- ------------------------------------------------------------
  describe("Remove Operations", function()
    it("remove by index", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      local p3 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      queue:push(p3)
      
      local removed = queue:remove(2)
      assert.are.equal(p2, removed)
      assert.are.equal(2, queue:size())
      assert.are.equal(p1, queue[1])
      assert.are.equal(p3, queue[2])
    end)
    
    it("removeValue by reference", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      
      local result = queue:removeValue(p1)
      assert.is_true(result)
      assert.are.equal(1, queue:size())
      assert.are.equal(p2, queue[1])
    end)
    
    it("removeValue returns false for missing", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      
      local result = queue:removeValue(p2)
      assert.is_false(result)
      assert.are.equal(1, queue:size())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- EXPECTED HUMANOIDS TESTS
  -- ------------------------------------------------------------
  describe("Expected Humanoids", function()
    it("expect/unexpect tracks patients", function()
      local patient = mockHumanoid("Patient", {})
      local staff = mockHumanoid("Staff", {})
      
      queue:expect(patient, function() end)
      queue:expect(staff, function() end)
      
      assert.are.equal(1, queue:expectedSize())
      
      queue:unexpect(patient)
      assert.are.equal(0, queue:expectedSize())
    end)
    
    it("expected callbacks called on reroute", function()
      local callback_called = false
      local patient = mockHumanoid("Patient", {})
      
      queue:expect(patient, function() callback_called = true end)
      queue:rerouteAllPatients("gp")
      
      assert.is_true(callback_called)
    end)
  end)
  
  -- ------------------------------------------------------------
  -- REROUTE TESTS
  -- ------------------------------------------------------------
  describe("Reroute All Patients", function()
    it("reroutes patients to room", function()
      local patient = mockHumanoid("Patient", {})
      local staff = mockHumanoid("Staff", {})
      
      queue:push(patient)
      queue:push(staff)
      
      queue:rerouteAllPatients("gp")
      
      assert.are.equal(0, queue:size())
      assert.is_nil(queue.callbacks[patient])
      assert.is_nil(queue.callbacks[staff])
    end)
    
    it("reroute with nil sends to reception", function()
      local patient = mockHumanoid("Patient", {})
      queue:push(patient)
      
      queue:rerouteAllPatients(nil)
      
      assert.are.equal(0, queue:size())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- REPORTED HUMANOID ACCESS
  -- ------------------------------------------------------------
  describe("Reported Humanoid Access", function()
    it("reportedHumanoid(1) returns first patient", function()
      local staff = mockHumanoid("Staff", {})
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(staff)
      queue:push(p1)
      queue:push(p2)
      
      assert.are.equal(p1, queue:reportedHumanoid(1))
      assert.are.equal(p2, queue:reportedHumanoid(2))
    end)
    
    it("front/back return absolute first/last", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:push(p2)
      
      assert.are.equal(p1, queue:front())
      assert.are.equal(p2, queue:back())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- SAME ROOM PRIORITY TESTS
  -- ------------------------------------------------------------
  describe("Same Room Priority (Leaving)", function()
    it("humanoid from same room gets leaving priority", function()
      local door2 = mockDoor(room)  -- Same room
      local door3 = mockDoor(mockRoom("ward"))  -- Different room
      
      local queue1 = Queue()
      queue1:setPriorityForSameRoom(door2)
      
      local leaving = mockHumanoid("Patient", { room = room })
      local entering = mockHumanoid("Patient", { room = nil })
      
      queue1:push(entering)
      queue1:push(leaving)
      
      assert.are.equal(leaving, queue1:front())
    end)
    
    it("no same_room_priority means no leaving priority", function()
      local queue1 = Queue()
      -- No setPriorityForSameRoom called
      
      local leaving = mockHumanoid("Patient", { room = room })
      local entering = mockHumanoid("Patient", { room = nil })
      
      queue1:push(entering)
      queue1:push(leaving)
      
      -- Leaving treated as regular (priority 6)
      assert.are.equal(entering, queue1:front())
      assert.are.equal(leaving, queue1:back())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- PATIENT SIZE TESTS
  -- ------------------------------------------------------------
  describe("Patient Size Calculation", function()
    it("patientSize = reportedSize + expectedSize", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      
      queue:push(p1)
      queue:expect(p2, function() end)
      
      assert.are.equal(1, queue:reportedSize())
      assert.are.equal(1, queue:expectedSize())
      assert.are.equal(2, queue:patientSize())
    end)
  end)
  
  -- ------------------------------------------------------------
  -- EDGE CASES
  -- ------------------------------------------------------------
  describe("Edge Cases", function()
    it("empty queue operations safe", function()
      assert.are.equal(0, queue:size())
      assert.are.equal(0, queue:reportedSize())
      assert.is_nil(queue:front())
      assert.is_nil(queue:back())
      assert.is_nil(queue:pop())
      assert.is_nil(queue:remove(1))
    end)
    
    it("hasEmergencyPatient detects emergency", function()
      local p1 = mockHumanoid("Patient", {})
      local p2 = mockHumanoid("Patient", {})
      p2.is_emergency = true
      
      queue:push(p1)
      assert.is_false(queue:hasEmergencyPatient())
      
      queue:push(p2)
      assert.is_true(queue:hasEmergencyPatient())
    end)
    
    it("visitor_count increments on pop", function()
      local patient = mockHumanoid("Patient", {})
      queue:push(patient)
      
      assert.are.equal(0, queue.visitor_count)
      queue:pop()
      assert.are.equal(1, queue.visitor_count)
    end)
  end)
end)

-- ============================================================
-- INTEGRATION TEST HELPERS (for manual testing)
-- ============================================================

local function printQueueState(q, label)
  print("=== " .. label .. " ===")
  print("size: " .. q:size())
  print("reportedSize: " .. q:reportedSize())
  print("expectedSize: " .. q:expectedSize())
  print("patientSize: " .. q:patientSize())
  print("max_size: " .. q.max_size)
  print("bench_threshold: " .. q.bench_threshold)
  for i = 1, q:size() do
    local h = q[i]
    local pri = h.is_leaving and 1 or (h.humanoid_class == "Staff" and 2) or
                (h.humanoid_class == "Vip" or h.humanoid_class == "Inspector") and 3 or
                (h.is_emergency and 4) or 6
    print(string.format("  [%d] %s (pri=%d, reported=%s)", i, h.humanoid_class, pri,
      i > q:size() - q.reported_size and "yes" or "no"))
  end
end

-- Example usage:
-- local q = Queue()
-- q:push(mockHumanoid("Patient", {}))
-- q:push(mockHumanoid("Staff", {}))
-- printQueueState(q, "Test Queue")

return {
  mockHumanoid = mockHumanoid,
  mockDoor = mockDoor,
  mockRoom = mockRoom,
  printQueueState = printQueueState,
}
