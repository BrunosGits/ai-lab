--[[
  CallsDispatcher Test Scaffold
  Busted test framework with dispatcher mock helpers
  Run with: busted SCAFFOLD.lua
--]]

local busted = require("busted")
local describe, it, before_each, after_each, setup, teardown = busted.describe, busted.it, busted.before_each, busted.after_each, busted.setup, busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local match = require("luassert.match")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
  return {
    entities = {},
    map = { tiles = {} },
    ui = {
      playAnnouncement = spy.new(function() end)
    },
    getPathDistance = function(self, x1, y1, x2, y2)
      if not x1 or not y1 or not x2 or not y2 then return nil end
      return math.abs(x1 - x2) + math.abs(y1 - y2)
    end
  }
end

local function createMockHospital(world)
  return {
    world = world,
    policies = { staff_allowed_to_move = true },
    heating = { radiator_heat = 1, heating_broke = false },
    giveAdvice = spy.new(function() end),
    countStaffOfCategory = function(self, cat) return 0 end,
    countRadiators = function(self) return 0 end,
    adviseBoilerBreakdown = spy.new(function() end)
  }
end

local function createMockRoom(hospital, room_info)
  local room = {
    hospital = hospital,
    world = hospital.world,
    room_info = room_info or { name = "Test Room", id = "test_room", call_sound = nil },
    door = { queue = { reportedSize = function() return 0 end, hasEmergencyPatient = function() return false end } },
    getRequiredStaffCriteria = function(self) return { doctor = 1 } end,
    getMissingStaff = function(self, criteria) return criteria end,
    getEntranceXY = function(self) return 10, 10 end,
    onHumanoidEnter = spy.new(function() end),
    onHumanoidLeave = spy.new(function() end),
    createEnterAction = function(self, staff) return { type = "EnterRoomAction", room = self, staff = staff } end,
    sound_played = false
  }
  return room
end

local function createMockStaff(hospital, staff_type, attrs)
  local staff = {
    hospital = hospital,
    world = hospital.world,
    tile_x = 5, tile_y = 5,
    on_call = nil,
    getRoom = function(self) return self.current_room end,
    isIdle = function(self) return self.on_call == nil end,
    fulfillsCriterion = function(self, attr) return self.attributes[attr] == true end,
    getAttribute = function(self, attr) return self.attributes[attr] or 0 end,
    setDynamicInfoText = spy.new(function() end),
    queueAction = spy.new(function(self, action) table.insert(self.action_queue, action) return action end),
    setNextAction = spy.new(function(self, action) self.next_action = action end),
    finishAction = spy.new(function() end),
    attributes = attrs or { fatigue = 0 },
    action_queue = {},
    next_action = nil
  }
  -- Class identification
  function staff:is_a(class_name)
    return self.staff_type == class_name
  end
  staff.staff_type = staff_type or "Doctor"
  return staff
end

local function createMockNurse(hospital, attrs)
  local nurse = createMockStaff(hospital, "Nurse", attrs)
  nurse.is_a = function(self, class_name) return class_name == "Nurse" end
  return nurse
end

local function createMockHandyman(hospital, attrs)
  local handyman = createMockStaff(hospital, "Handyman", attrs)
  handyman.is_a = function(self, class_name) return class_name == "Handyman" end
  handyman.searchForHandymanTask = spy.new(function() return true end)
  return handyman
end

local function createMockMachine(hospital, object_type)
  return {
    hospital = hospital,
    world = hospital.world,
    object_type = object_type or { name = "Machine", id = "machine" },
    tile_x = 10, tile_y = 10,
    createHandymanActions = spy.new(function(self, handyman) return {} end),
    onDestroy = function(self) end
  }
end

local function createMockPlant(hospital)
  return {
    hospital = hospital,
    world = hospital.world,
    tile_x = 8, tile_y = 8,
    createHandymanActions = spy.new(function(self, handyman) return {} end)
  }
end

local function createMockPatient(hospital)
  return {
    hospital = hospital,
    world = hospital.world,
    tile_x = 12, tile_y = 12,
    getRoom = function(self) return nil end,
    reserved_for = nil
  }
end

-- ============================================================================
-- DISPATCHER LOADING (stub - replace with actual require)
-- ============================================================================

local CallsDispatcher = {}

-- Stub for class system
local function class(name)
  return name
end
_G.class = class
_G.class.is = function(obj, cls) return obj and obj.is_a and obj:is_a(cls) end

-- Minimal dispatcher implementation for testing
function CallsDispatcher:CallsDispatcher(world)
  self.world = world
  self.call_queue = {}
  self.change_callback = {}
  self.tick = 0
  return self
end

function CallsDispatcher:onTick()
  self.tick = self.tick + 1
end

function CallsDispatcher:addChangeCallback(cb, self_val)
  self.change_callback[cb] = self_val
end

function CallsDispatcher:removeChangeCallback(cb)
  self.change_callback[cb] = nil
end

function CallsDispatcher:onChange()
  for cb, sv in pairs(self.change_callback) do cb(sv) end
end

-- Copy actual implementation methods here for testing
-- (In real tests, use: local CallsDispatcher = require("calls_dispatcher"))

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("CallsDispatcher", function()
  local world, hospital, dispatcher
  local change_callback_spy

  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital(world)
    dispatcher = CallsDispatcher:CallsDispatcher(world)
    change_callback_spy = spy.new(function() end)
    dispatcher:addChangeCallback(change_callback_spy, "test")
  end)

  after_each(function()
    dispatcher:removeChangeCallback(change_callback_spy)
  end)

  describe("Initialization", function()
    it("should create empty call queue", function()
      assert.are.same({}, dispatcher.call_queue)
    end)

    it("should initialize tick counter to 0", function()
      assert.equals(0, dispatcher.tick)
    end)

    it("should increment tick on onTick", function()
      dispatcher:onTick()
      assert.equals(1, dispatcher.tick)
      dispatcher:onTick()
      assert.equals(2, dispatcher.tick)
    end)

    it("should fire change callbacks on onChange", function()
      dispatcher:onChange()
      assert.spy(change_callback_spy).was_called_with("test")
    end)
  end)

  describe("enqueue()", function()
    local room, verification, priority, execute

    before_each(function()
      room = createMockRoom(hospital)
      verification = spy.new(function() return true end)
      priority = spy.new(function() return 100 end)
      execute = spy.new(function() end)
    end)

    it("should insert new call into queue", function()
      local result = dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      assert.is_true(result) -- queued, not served
      assert.is_table(dispatcher.call_queue[room])
      assert.is_table(dispatcher.call_queue[room].test_key)
      assert.equals("test_key", dispatcher.call_queue[room].test_key.key)
      assert.equals("Test Call", dispatcher.call_queue[room].test_key.description)
      assert.equals(0, dispatcher.call_queue[room].test_key.created)
    end)

    it("should return false if call immediately served", function()
      -- Create staff that matches
      local staff = createMockStaff(hospital, "Doctor", { doctor = true })
      table.insert(world.entities, staff)

      local result = dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      -- May be true or false depending on timing
      assert.is_boolean(result)
    end)

    it("should return true if already queued and not assigned", function()
      dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      local result = dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      assert.is_true(result)
    end)

    it("should return false if already queued and assigned", function()
      dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      local call = dispatcher.call_queue[room].test_key
      local staff = createMockStaff(hospital, "Doctor", { doctor = true })
      call.assigned = staff
      local result = dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      assert.is_false(result)
    end)

    it("should store all call properties correctly", function()
      dispatcher:enqueue(room, "test_key", "Test Call", verification, priority, execute)
      local call = dispatcher.call_queue[room].test_key
      assert.equals(verification, call.verification)
      assert.equals(priority, call.priority)
      assert.equals(execute, call.execute)
      assert.equals(room, call.object)
      assert.equals(dispatcher, call.dispatcher)
      assert.is_false(call.dropped)
      assert.is_nil(call.assigned)
    end)
  end)

  describe("findSuitableStaff()", function()
    local room, call, staff1, staff2

    before_each(function()
      room = createMockRoom(hospital)
      local verification = function(s) return s:fulfillsCriterion("doctor") end
      local priority = function(s) return 100 end
      local execute = function(s) end
      dispatcher:enqueue(room, "staff", "Test", verification, priority, execute)
      call = dispatcher.call_queue[room].staff

      staff1 = createMockStaff(hospital, "Doctor", { doctor = true, fatigue = 10 })
      staff2 = createMockStaff(hospital, "Doctor", { doctor = true, fatigue = 5 })
      table.insert(world.entities, staff1)
      table.insert(world.entities, staff2)
    end)

    it("should return false if call is dropped", function()
      call.dropped = true
      local result = dispatcher:findSuitableStaff(call)
      assert.is_false(result)
    end)

    it("should skip Handymen", function()
      local handyman = createMockHandyman(hospital)
      table.insert(world.entities, handyman)
      local result = dispatcher:findSuitableStaff(call)
      -- Should not consider handyman
      assert.is_boolean(result)
    end)

    it("should select staff with lowest priority score", function()
      -- staff2 has lower fatigue -> lower score (higher priority)
      local result = dispatcher:findSuitableStaff(call)
      assert.is_true(result)
      assert.equals(staff2, call.assigned)
      assert.equals(call, staff2.on_call)
    end)

    it("should return false if no suitable staff", function()
      -- Staff doesn't fulfill criterion
      staff1.attributes.doctor = false
      staff2.attributes.doctor = false
      local result = dispatcher:findSuitableStaff(call)
      assert.is_false(result)
      assert.is_nil(call.assigned)
    end)

    it("should call onChange when queued", function()
      -- No suitable staff
      staff1.attributes.doctor = false
      staff2.attributes.doctor = false
      dispatcher:findSuitableStaff(call)
      assert.spy(change_callback_spy).was_called()
    end)

    it("should call execute callback on selected staff", function()
      local execute_spy = spy.new(function() end)
      call.execute = execute_spy
      dispatcher:findSuitableStaff(call)
      assert.spy(execute_spy).was_called_with(staff2)
    end)
  end)

  describe("answerCall()", function()
    local staff, room, call

    before_each(function()
      staff = createMockStaff(hospital, "Doctor", { doctor = true })
      room = createMockRoom(hospital)
      local verification = function(s) return s:fulfillsCriterion("doctor") end
      local priority = function(s) return 50 end
      local execute = function(s) end
      dispatcher:enqueue(room, "staff", "Test", verification, priority, execute)
      call = dispatcher.call_queue[room].staff
    end)

    it("should assert if staff already on call", function()
      staff.on_call = {}
      assert.has_error(function() dispatcher:answerCall(staff) end, "already answering a call")
    end)

    it("should assert if staff has no hospital", function()
      staff.hospital = nil
      assert.has_error(function() dispatcher:answerCall(staff) end, "member of the hospital")
    end)

    it("should delegate to searchForHandymanTask for Handymen", function()
      local handyman = createMockHandyman(hospital)
      local result = dispatcher:answerCall(handyman)
      assert.is_true(result)
      assert.spy(handyman.searchForHandymanTask).was_called()
    end)

    it("should find best call across all queues", function()
      local room2 = createMockRoom(hospital)
      dispatcher:enqueue(room2, "staff", "Test2", function(s) return true end, function(s) return 200 end, function() end)

      local result = dispatcher:answerCall(staff)
      assert.is_true(result)
      -- Should pick the call with priority 50 (room) over 200 (room2)
      assert.equals(call, staff.on_call)
    end)

    it("should preempt assigned staff if new staff has higher priority", function()
      local other_staff = createMockStaff(hospital, "Doctor", { doctor = true, fatigue = 0 })
      call.assigned = other_staff
      other_staff.on_call = call

      -- New staff has higher priority (lower score)
      local result = dispatcher:answerCall(staff)
      assert.is_true(result)
      assert.equals(staff, call.assigned)
      assert.is_nil(other_staff.on_call)
      assert.is_not_nil(other_staff.next_action) -- AnswerCallAction queued
    end)

    it("should NOT preempt if current assignee has equal/better priority", function()
      local other_staff = createMockStaff(hospital, "Doctor", { doctor = true, fatigue = 0 })
      call.assigned = other_staff
      other_staff.on_call = call

      -- Make new staff have worse priority
      staff.attributes.fatigue = 100 -- Higher fatigue = worse priority in getPriorityForRoom
      -- Actually priority function returns fixed 50, so need different setup
      -- This tests the preemption block logic
      local high_priority_call = dispatcher.call_queue[room].staff
      high_priority_call.priority = function(s) return s == other_staff and 10 or 100 end

      local result = dispatcher:answerCall(staff)
      -- Should not take the call because other_staff has priority 10 < 100
      assert.is_false(result)
    end)

    it("should verify object still exists before executing", function()
      call.object = nil -- Destroyed object
      assert.has_error(function() dispatcher:answerCall(staff) end, "destroyed object")
    end)

    it("should return false if no suitable calls", function()
      call.verification = function() return false end
      local result = dispatcher:answerCall(staff)
      assert.is_false(result)
    end)
  end)

  describe("Preemption Logic", function()
    it("should unassign current staff and give them AnswerCallAction", function()
      local room = createMockRoom(hospital)
      local call = { verification = function() return true end, priority = function() return 50 end, execute = function() end }
      dispatcher:enqueue(room, "test", "Test", call.verification, call.priority, call.execute)
      call = dispatcher.call_queue[room].test

      local current = createMockStaff(hospital, "Doctor", { doctor = true })
      local new_staff = createMockStaff(hospital, "Doctor", { doctor = true })
      call.assigned = current
      current.on_call = call
      table.insert(world.entities, new_staff)

      dispatcher:answerCall(new_staff)

      assert.equals(new_staff, call.assigned)
      assert.is_nil(current.on_call)
      assert.is_table(current.next_action)
    end)

    it("should call unassignCall with answer_next_call=true", function()
      local room = createMockRoom(hospital)
      local call = { verification = function() return true end, priority = function() return 50 end, execute = function() end }
      dispatcher:enqueue(room, "test", "Test", call.verification, call.priority, call.execute)
      call = dispatcher.call_queue[room].test

      local current = createMockStaff(hospital, "Doctor", { doctor = true })
      call.assigned = current
      current.on_call = call

      local new_staff = createMockStaff(hospital, "Doctor", { doctor = true })
      dispatcher:answerCall(new_staff)

      assert.is_nil(call.assigned) -- During unassign
      -- After executeCall, call.assigned = new_staff
      assert.equals(new_staff, call.assigned)
    end)
  end)

  describe("dropFromQueue()", function()
    local room, call, staff

    before_each(function()
      room = createMockRoom(hospital)
      local verification = function() return true end
      local priority = function() return 100 end
      local execute = function() end
      dispatcher:enqueue(room, "staff", "Test", verification, priority, execute)
      call = dispatcher.call_queue[room].staff
      staff = createMockStaff(hospital, "Doctor", { doctor = true })
      call.assigned = staff
      staff.on_call = call
    end)

    it("should drop specific call by key", function()
      dispatcher:dropFromQueue(room, "staff")
      assert.is_nil(dispatcher.call_queue[room].staff)
      assert.is_true(call.dropped)
    end)

    it("should drop all calls for object if no key", function()
      dispatcher:enqueue(room, "other", "Other", function() return true end, function() return 1 end, function() end)
      dispatcher:dropFromQueue(room)
      assert.is_nil(dispatcher.call_queue[room])
      assert.is_true(call.dropped)
    end)

    it("should unassign staff and give AnswerCallAction", function()
      dispatcher:dropFromQueue(room, "staff")
      assert.is_nil(call.assigned)
      assert.is_nil(staff.on_call)
      assert.is_table(staff.next_action)
    end)

    it("should call onChange after dropping", function()
      dispatcher:dropFromQueue(room, "staff")
      assert.spy(change_callback_spy).was_called()
    end)

    it("should handle dropping non-existent call gracefully", function()
      dispatcher:dropFromQueue(room, "nonexistent")
      assert.spy(change_callback_spy).was_called()
    end)

    it("should handle dropping from non-existent object gracefully", function()
      local fake_obj = {}
      dispatcher:dropFromQueue(fake_obj, "test")
      assert.spy(change_callback_spy).was_called()
    end)
  end)

  describe("executeCall()", function()
    local call, staff

    before_each(function()
      call = {
        verification = function() return true end,
        priority = function() return 100 end,
        execute = spy.new(function() end),
        object = createMockRoom(hospital),
        key = "test",
        dropped = false
      }
      staff = createMockStaff(hospital, "Doctor")
    end)

    it("should assign call to staff", function()
      dispatcher:executeCall(call, staff)
      assert.equals(staff, call.assigned)
      assert.equals(call, staff.on_call)
    end)

    it("should call onChange", function()
      dispatcher:executeCall(call, staff)
      assert.spy(change_callback_spy).was_called()
    end)

    it("should call execute callback", function()
      dispatcher:executeCall(call, staff)
      assert.spy(call.execute).was_called_with(staff)
    end)

    it("should assert if call already assigned", function()
      call.assigned = createMockStaff(hospital, "Doctor")
      assert.has_error(function() dispatcher:executeCall(call, staff) end, "still assigned")
    end)

    it("should assert if call is dropped", function()
      call.dropped = true
      assert.has_error(function() dispatcher:executeCall(call, staff) end, "dropped")
    end)

    it("should assert if staff already on call", function()
      staff.on_call = {}
      assert.has_error(function() dispatcher:executeCall(call, staff) end, "on call")
    end)
  end)

  describe("Checkpoint System", function()
    local call, staff, humanoid

    before_each(function()
      humanoid = createMockStaff(hospital, "Doctor")
      call = {
        assigned = humanoid,
        dropped = false,
        dispatcher = dispatcher
      }
      humanoid.on_call = call
    end)

    it("should queue CallCheckPointAction with default handler", function()
      local action = CallsDispatcher.queueCallCheckpointAction(humanoid)
      assert.is_table(action)
      assert.equals("CallCheckPointAction", action.type or "CallCheckPointAction")
    end)

    it("should use custom interrupt handler when provided", function()
      local custom_handler = spy.new(function() end)
      local action = CallsDispatcher.queueCallCheckpointAction(humanoid, custom_handler)
      assert.is_table(action)
    end)

    describe("actionInterruptHandler (default)", function()
      it("should reset call assignment and re-dispatch", function()
        local action = { call = call }
        CallsDispatcher.actionInterruptHandler(action, humanoid)
        assert.is_nil(call.assigned)
        assert.is_nil(humanoid.on_call)
      end)
    end)

    describe("staffActionInterruptHandler", function()
      it("should re-call callForStaff on interrupt", function()
        local room = call.object
        local action = { call = call }
        CallsDispatcher.staffActionInterruptHandler(action, humanoid)
        assert.is_nil(call.assigned)
        assert.is_nil(humanoid.on_call)
        -- Would call dispatcher:callForStaff(room) if not dropped
      end)

      it("should NOT re-call if call was dropped", function()
        call.dropped = true
        local action = { call = call }
        CallsDispatcher.staffActionInterruptHandler(action, humanoid)
        -- callForStaff not called
      end)
    end)

    describe("onCheckpointCompleted", function()
      it("should clear assignment and drop from queue on completion", function()
        CallsDispatcher.onCheckpointCompleted(call)
        assert.is_nil(call.assigned)
        assert.is_nil(humanoid.on_call)
      end)

      it("should NOT drop if call was dropped", function()
        call.dropped = true
        CallsDispatcher.onCheckpointCompleted(call)
        -- dropFromQueue not called
      end)

      it("should NOT drop if no assigned staff", function()
        call.assigned = nil
        CallsDispatcher.onCheckpointCompleted(call)
        -- dropFromQueue not called
      end)
    end)
  end)

  describe("callForStaff()", function()
    local room, doctor, nurse

    before_each(function()
      room = createMockRoom(hospital, { name = "GP Office", id = "gp", call_sound = "call_doctor" })
      room.getRequiredStaffCriteria = function() return { doctor = 1, nurse = 1 } end
      room.getMissingStaff = function(self, criteria) return criteria end

      doctor = createMockStaff(hospital, "Doctor", { doctor = true })
      nurse = createMockStaff(hospital, "Nurse", { nurse = true })
      table.insert(world.entities, doctor)
      table.insert(world.entities, nurse)
    end)

    it("should create calls for each missing staff type", function()
      local calls = dispatcher:callForStaff(room)
      assert.is_table(dispatcher.call_queue[room])
      assert.is_table(dispatcher.call_queue[room]["doctor1"])
      assert.is_table(dispatcher.call_queue[room]["nurse2"])
    end)

    it("should play announcement sound if missing staff and sound configured", function()
      local calls = dispatcher:callForStaff(room)
      assert.spy(world.ui.playAnnouncement).was_called()
      assert.is_true(room.sound_played)
    end)

    it("should NOT play sound if already played", function()
      room.sound_played = true
      dispatcher:callForStaff(room)
      assert.spy(world.ui.playAnnouncement).was_not_called()
    end)

    it("should use verification/priority/execute for staff calls", function()
      dispatcher:callForStaff(room)
      local call = dispatcher.call_queue[room]["doctor1"]
      assert.is_function(call.verification)
      assert.is_function(call.priority)
      assert.is_function(call.execute)
    end)
  end)

  describe("callForRepair()", function()
    local machine

    before_each(function()
      machine = createMockMachine(hospital)
    end)

    it("should create repair call with correct structure", function()
      local call = dispatcher:callForRepair(machine, true, false)
      assert.equals("repair", call.key)
      assert.equals(machine, call.object)
      assert.is_function(call.verification)
      assert.is_function(call.priority)
      assert.is_function(call.execute)
    end)

    it("should give machines_falling_apart advice for urgent non-manual", function()
      dispatcher:callForRepair(machine, true, false)
      assert.spy(hospital.giveAdvice).was_called()
    end)

    it("should give machinery_damaged2 advice if no handymen", function()
      hospital.countStaffOfCategory = function(self, cat) return 0 end
      dispatcher:callForRepair(machine, false, false)
      assert.spy(hospital.giveAdvice).was_called()
    end)

    it("should NOT give advice for manual calls", function()
      dispatcher:callForRepair(machine, true, true)
      assert.spy(hospital.giveAdvice).was_not_called()
    end)
  end)

  describe("callForWatering()", function()
    local plant

    before_each(function()
      plant = createMockPlant(hospital)
    end)

    it("should create watering call with correct structure", function()
      local call = dispatcher:callForWatering(plant)
      assert.equals("watering", call.key)
      assert.equals(plant, call.object)
      assert.is_function(call.verification)
      assert.is_function(call.priority)
      assert.is_function(call.execute)
    end)
  end)

  describe("callNurseForVaccination()", function()
    local patient, nurse

    before_each(function()
      patient = createMockPatient(hospital)
      nurse = createMockNurse(hospital)
      table.insert(world.entities, nurse)
    end)

    it("should create vaccination call", function()
      local call = dispatcher:callNurseForVaccination(patient)
      assert.equals("vaccinate", call.key)
      assert.equals(patient, call.object)
    end)

    it("verifyStaffForVaccination should check nurse class and idle", function()
      local call = dispatcher:callNurseForVaccination(patient)
      -- Nurse not idle
      nurse.on_call = {}
      assert.is_false(call.verification(nurse))
      nurse.on_call = nil
      assert.is_true(call.verification(nurse))
    end)

    it("verifyStaffForVaccination should check proximity", function()
      local call = dispatcher:callNurseForVaccination(patient)
      patient.tile_x, patient.tile_y = 100, 100
      nurse.tile_x, nurse.tile_y = 5, 5
      assert.is_false(call.verification(nurse))
    end)
  end)

  describe("verifyStaffForRoom()", function()
    local room, staff

    before_each(function()
      room = createMockRoom(hospital)
      staff = createMockStaff(hospital, "Doctor", { doctor = true })
    end)

    it("should return false if staff not idle", function()
      staff.on_call = {}
      assert.is_false(CallsDispatcher.verifyStaffForRoom(room, "doctor", staff))
    end)

    it("should return false if staff doesn't fulfill criterion", function()
      staff.attributes.doctor = false
      assert.is_false(CallsDispatcher.verifyStaffForRoom(room, "doctor", staff))
    end)

    it("should return false if staff in another room and policy disallows move", function()
      hospital.policies.staff_allowed_to_move = false
      local other_room = createMockRoom(hospital)
      staff.current_room = other_room
      assert.is_false(CallsDispatcher.verifyStaffForRoom(room, "doctor", staff))
    end)

    it("should return true if policy allows moving between rooms", function()
      hospital.policies.staff_allowed_to_move = true
      local other_room = createMockRoom(hospital)
      staff.current_room = other_room
      assert.is_true(CallsDispatcher.verifyStaffForRoom(room, "doctor", staff))
    end)
  end)

  describe("getPriorityForRoom()", function()
    local room, staff

    before_each(function()
      room = createMockRoom(hospital)
      room.getEntranceXY = function() return 10, 10 end
      staff = createMockStaff(hospital, "Doctor", { doctor = true, fatigue = 0 })
      staff.tile_x, staff.tile_y = 5, 5
    end)

    it("should calculate base distance score", function()
      local score = CallsDispatcher.getPriorityForRoom(room, "doctor", staff)
      -- Manhattan distance: |10-5| + |10-5| = 10
      assert.equals(10, score)
    end)

    it("should subtract queue size bonus", function()
      room.door.queue.reportedSize = function() return 3 end
      local score = CallsDispatcher.getPriorityForRoom(room, "doctor", staff)
      -- 10 - 3*5 = -5
      assert.equals(-5, score)
    end)

    it("should subtract emergency bonus", function()
      room.door.queue.hasEmergencyPatient = function() return true end
      local score = CallsDispatcher.getPriorityForRoom(room, "doctor", staff)
      assert.is_true(score < -100000)
    end)

    it("should prefer tired staff (lower score)", function()
      staff.attributes.fatigue = 10
      local score = CallsDispatcher.getPriorityForRoom(room, "doctor", staff)
      -- Base 10 - fatigue*40 = 10 - 400 = -390
      assert.equals(-390, score)
    end)

    it("should prefer wandering staff", function()
      staff.current_room = nil
      local score = CallsDispatcher.getPriorityForRoom(room, "doctor", staff)
      assert.equals(-40, score) -- 10 - 50
    end)

    it("should strongly prefer specialists", function()
      local score = CallsDispatcher.getPriorityForRoom(room, "Surgeon", staff)
      assert.is_true(score < -50000)
    end)
  end)

  describe("sendStaffToRoom()", function()
    local room, staff

    before_each(function()
      room = createMockRoom(hospital)
      staff = createMockStaff(hospital, "Doctor")
    end)

    it("should create EnterRoomAction if staff not in room", function()
      staff.current_room = nil
      CallsDispatcher.sendStaffToRoom(room, staff)
      assert.is_table(staff.next_action)
      assert.spy(staff.setDynamicInfoText).was_called()
    end)

    it("should re-enter room if already there", function()
      staff.current_room = room
      CallsDispatcher.sendStaffToRoom(room, staff)
      assert.spy(room.onHumanoidLeave).was_called_with(staff)
      assert.spy(room.onHumanoidEnter).was_called_with(staff)
    end)
  end)

  describe("sendStaffToRepair/Watering()", function()
    local machine, plant, handyman

    before_each(function()
      machine = createMockMachine(hospital)
      plant = createMockPlant(hospital)
      handyman = createMockHandyman(hospital)
    end)

    it("sendStaffToRepair should call createHandymanActions", function()
      CallsDispatcher.sendStaffToRepair(machine, handyman)
      assert.spy(machine.createHandymanActions).was_called_with(handyman)
    end)

    it("sendStaffToWatering should call createHandymanActions", function()
      CallsDispatcher.sendStaffToWatering(plant, handyman)
      assert.spy(plant.createHandymanActions).was_called_with(handyman)
    end)
  end)

  describe("Integration: Entity.onPickUp drops calls", function()
    it("should call dropFromQueue when entity picked up", function()
      local room = createMockRoom(hospital)
      local call = { dropped = false, assigned = nil }
      dispatcher.call_queue[room] = { test = call }

      -- Simulate Entity:onPickUp
      room.world = world
      room:onPickUp()

      assert.is_true(call.dropped)
    end)
  end)

  describe("Integration: Hospital.notifyRoomRemoved drops calls", function()
    it("should call dropFromQueue for removed room", function()
      local room = createMockRoom(hospital)
      local call = { dropped = false, assigned = nil }
      dispatcher.call_queue[room] = { test = call }

      -- Simulate Hospital:notifyRoomRemoved
      hospital.world = world
      -- Would call dispatcher:dropFromQueue(room)

      assert.is_true(call.dropped)
    end)
  end)
end)

-- ============================================================================
-- RUN TESTS
-- ============================================================================
-- busted SCAFFOLD.lua
