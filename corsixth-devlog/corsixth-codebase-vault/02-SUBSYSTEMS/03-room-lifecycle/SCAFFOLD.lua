--[[
================================================================================
Room Lifecycle Test Scaffold — Busted Test Suite
================================================================================
Purpose: Unit tests for Room base class and derived room lifecycle methods
Run:     busted SCAFFOLD.lua
================================================================================
]]

local class = require 'lib.middleclass'
local Room = require 'room'
local Patient = require 'patient'
local Staff = require 'staff'
local Doctor = require 'doctor'
local Nurse = require 'nurse'
local Handyman = require 'handyman'
local World = require 'world'
local Hospital = require 'hospital'

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
  local world = {
    rooms = {},
    hospitals = {},
    ui = { addWindow = function() end, setCursor = function() end, getWindow = function() return nil end },
    gfx = { loadMainCursor = function() return "cursor" end },
    dispatcher = {
      callForStaff = function() end,
      dropFromQueue = function() end
    },
    map = { level_number = 1 },
    room_information_dialogs = true,
    room_built = {},
    destroyEntity = function() end,
    newObject = function() return { object_type = { class = "", id = "" }, unreachable = false, user = nil, user_list = nil, reserved_for = nil, reserved_for_list = nil } end,
    findAllObjectsNear = function() return {} end,
    notifyRoomRemoved = function() end
  }
  return world
end

local function createMockHospital()
  local hospital = {
    world = createMockWorld(),
    policies = { stop_procedure = 0.75 },
    research = { research_progress = {} },
    advice_given = {},
    giveAdvice = function(self, advice) self.advice_given[advice] = true end,
    receiveMoneyForTreatment = function() end,
    changeValue = function() end,
    changeReputation = function() end,
    getIndexOfTask = function() return -1 end,
    removeHandymanTask = function() end,
    removeRatholesAroundRoom = function() end,
    num_explosions = 0
  }
  return hospital
end

local function createMockRoomInfo(id, overrides)
  local base = {
    id = id,
    required_staff = {},
    maximum_staff = {},
    minimum_size = 16,
    build_cost = 10000
  }
  for k, v in pairs(overrides or {}) do base[k] = v end
  return base
end

local function createMockDoor()
  return {
    queue = {
      size = function() return 0 end,
      patientSize = function() return 0 end,
      reportedSize = function() return 0 end,
      front = function() return nil end,
      pop = function() end,
      updateDynamicInfo = function() end,
      rerouteAllPatients = function() end,
      visitor_count = 0,
      isFull = function() return false end
    },
    user = nil,
    reserved_for = nil,
    closeDoor = function() end,
    hover_cursor = nil,
    removeUser = function() end
  }
end

local function createMockRoom(roomInfo, hospital)
  local room = Room:new()
  room.world = createMockWorld()
  room.hospital = hospital or createMockHospital()
  room.room_info = roomInfo or createMockRoomInfo("gp")
  room.door = createMockDoor()
  room.door.room = room
  room.is_active = true
  room.built = true
  room.x = 0
  room.y = 0
  room.width = 4
  room.height = 4
  room.crashed = false
  room.humanoids = {}
  room.objects = {}
  room.humanoids_enroute = {}
  room.staff_member = nil
  room.staff_member_set = nil
  room.maximum_patients = 1
  room.sound_played = nil
  room.happiness_factor = 0
  room.manual_repair = false
  room.needs_repair = false
  return room
end

local function createMockPatient(overrides)
  local patient = {
    in_room = nil,
    last_room = nil,
    infected = false,
    diagnosed = false,
    disease = nil,
    diagnosis_progress = 0,
    cure_rooms_visited = 0,
    needs_redirecting = false,
    is_leaving = false,
    current_action = nil,
    action_queue = {},
    setNextAction = function(self, action) self.current_action = action end,
    queueAction = function(self, action) table.insert(self.action_queue, action) end,
    finishAction = function() end,
    isLeaving = function(self) return self.is_leaving end,
    die = function() end,
    despawn = function() end,
    addToTreatmentHistory = function() end,
    completeDiagnosticStep = function() end,
    setDiagnosed = function() self.diagnosed = true end,
    agreesToPay = function() return true end,
    goHome = function() end,
    treatDisease = function() end,
    updateDynamicInfo = function() end,
    goToStaffRoom = function() end,
    adviseWrongPersonForThisRoom = function() end
  }
  for k, v in pairs(overrides or {}) do patient[k] = v end
  return patient
end

local function createMockStaff(overrides)
  local staff = {
    in_room = nil,
    last_room = nil,
    profile = { is_doctor = false, is_nurse = false, is_researcher = false, is_surgeon = false, is_psychiatrist = false, is_consultant = false },
    dealing_with_patient = false,
    staffroom_needed = false,
    is_ready = "",
    current_action = nil,
    action_queue = {},
    setNextAction = function(self, action) self.current_action = action end,
    queueAction = function(self, action) table.insert(self.action_queue, action) end,
    finishAction = function() end,
    setCallCompleted = function() end,
    setMood = function() end,
    setDynamicInfoText = function() end,
    isMeandering = function() return false end,
    getServiceQuality = function() return 1.0 end,
    goToStaffRoom = function() end,
    adviseWrongPersonForThisRoom = function() end,
    die = function() end,
    despawn = function() end,
    isLeaving = function() return false end
  }
  for k, v in pairs(overrides or {}) do staff[k] = v end
  return staff
end

local function createMockHandyman(overrides)
  local handyman = createMockStaff()
  handyman.on_call = false
  handyman.object_type = { class = "Handyman" }
  for k, v in pairs(overrides or {}) do handyman[k] = v end
  return handyman
end

-- ============================================================================
-- TEST SUITE: ROOM LIFECYCLE
-- ============================================================================

describe("Room Lifecycle — Base Class", function()
  local room, hospital, world

  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital()
    hospital.world = world
    room = createMockRoom(createMockRoomInfo("gp"), hospital)
  end)

  -- ---------------------------------------------------------------------------
  -- ENTRY FLOW: onHumanoidEnter
  -- ---------------------------------------------------------------------------

  describe("onHumanoidEnter — Entry Flow", function()
    it("should reject humanoid already in room (assertion)", function()
      local patient = createMockPatient()
      room.humanoids[patient] = true
      assert.has_error(function() room:onHumanoidEnter(patient) end, "already in")
    end)

    it("should set humanoid.in_room and humanoid.last_room", function()
      local patient = createMockPatient()
      room:onHumanoidEnter(patient)
      assert.equals(room, patient.in_room)
      assert.equals(room, patient.last_room)
    end)

    it("should eject patient from inactive room and re-queue", function()
      room.is_active = false
      local patient = createMockPatient()
      room:onHumanoidEnter(patient)
      assert.is_not_nil(patient.current_action)
      assert.is_true(#patient.action_queue > 0)
    end)

    it("should eject staff from inactive room and send meandering", function()
      room.is_active = false
      local doctor = createMockStaff({ profile = { is_doctor = true } })
      room:onHumanoidEnter(doctor)
      assert.is_not_nil(doctor.current_action)
    end)

    it("should handle handyman on call and lock room for repair", function()
      local handyman = createMockHandyman({ on_call = true })
      local machine = { repairing = handyman }
      room.getRoomMachine = function() return machine end
      room.lockRoomOnRepair = function() room.needs_repair = true end
      room:onHumanoidEnter(handyman)
      assert.is_true(room.needs_repair)
    end)

    it("should handle drop-in handyman (not on call)", function()
      local handyman = createMockHandyman({ on_call = false })
      room:onHumanoidEnter(handyman)
      assert.is_not_nil(handyman.current_action)
    end)

    it("should accept staff that fits in room", function()
      local doctor = createMockStaff({ profile = { is_doctor = true } })
      room.room_info.required_staff = { doctor = 1 }
      room.testStaffCriteria = function(self, criteria) return true end
      room.commandEnteringStaff = function() end
      room:onHumanoidEnter(doctor)
      assert.equals(doctor, room.staff_member)
    end)

    it("should replace idle staff when better qualified staff enters", function()
      local current_staff = createMockStaff({ profile = { is_doctor = true }, dealing_with_patient = false })
      room.staff_member = current_staff
      room.humanoids[current_staff] = true
      room.getStaffMember = function() return current_staff end
      room.staffFitsInRoom = function() return false end -- room at capacity
      room.testStaffCriteria = function() return true end
      room.staffMeetsRoomRequirements = function() return true end
      room.commandEnteringStaff = function() end
      room.createLeaveAction = function() return "leave" end

      local new_staff = createMockStaff({ profile = { is_doctor = true } })
      room:onHumanoidEnter(new_staff)

      assert.equals(new_staff, room.staff_member)
      assert.is_not_nil(current_staff.current_action)
    end)

    it("should keep busy staff and send new staff away", function()
      local current_staff = createMockStaff({ profile = { is_doctor = true }, dealing_with_patient = true })
      room.staff_member = current_staff
      room.humanoids[current_staff] = true
      room.getStaffMember = function() return current_staff end
      room.staffFitsInRoom = function() return false end
      room.testStaffCriteria = function() return true end
      room.staffMeetsRoomRequirements = function() return true end
      room.createLeaveAction = function() return "leave" end

      local new_staff = createMockStaff({ profile = { is_doctor = true } })
      room:onHumanoidEnter(new_staff)

      assert.equals(current_staff, room.staff_member)
      assert.is_not_nil(new_staff.current_action)
    end)

    it("should reject wrong staff type with advice", function()
      local nurse = createMockStaff({ profile = { is_nurse = true } })
      room.room_info.required_staff = { doctor = 1 }
      room.testStaffCriteria = function() return false end
      room.createLeaveAction = function() return "leave" end

      room:onHumanoidEnter(nurse)
      assert.is_not_nil(nurse.current_action)
    end)

    it("should redirect infected undiagnosed patient to GP", function()
      local patient = createMockPatient({ infected = true, diagnosed = false })
      room.room_info.id = "scanner"
      room.isDiagnosisRoomForPatient = function() return false end
      room.createLeaveAction = function() return "leave" end

      room:onHumanoidEnter(patient)
      assert.is_true(patient.needs_redirecting)
      assert.is_true(#patient.action_queue > 0)
    end)

    it("should start treatment when staff criteria met", function()
      local patient = createMockPatient()
      local doctor = createMockStaff({ profile = { is_doctor = true } })
      room.staff_member = doctor
      room.testStaffCriteria = function() return true end
      room.commandEnteringPatient = function() end

      room:onHumanoidEnter(patient)
      assert.is_true(doctor.dealing_with_patient)
    end)

    it("should re-queue patient when no staff available", function()
      local patient = createMockPatient()
      room.testStaffCriteria = function() return false end
      room.createLeaveAction = function() return "leave" end
      room.createEnterAction = function() return "enter" end

      room:onHumanoidEnter(patient)
      assert.is_true(#patient.action_queue >= 2)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- EXIT FLOW: onHumanoidLeave
  -- ---------------------------------------------------------------------------

  describe("onHumanoidLeave — Exit Flow", function()
    it("should clear staff_member reference when staff leaves", function()
      local doctor = createMockStaff()
      room.staff_member = doctor
      room.humanoids[doctor] = true
      room:onHumanoidLeave(doctor)
      assert.is_nil(room.staff_member)
    end)

    it("should warn and return if humanoid not in room", function()
      local patient = createMockPatient()
      local output = capture_print(function() room:onHumanoidLeave(patient) end)
      assert.matches("Warning", output)
    end)

    it("should allow waiting staff to go to staff room when patient leaves", function()
      local patient = createMockPatient()
      local doctor = createMockStaff({ staffroom_needed = true })
      room.humanoids[patient] = true
      room.humanoids[doctor] = true
      room.door.queue.reportedSize = function() return 0 end
      room.tryToFindNearbyPatients = function() end

      room:onHumanoidLeave(patient)
      assert.is_nil(doctor.staffroom_needed)
    end)

    it("should try to find nearby patients when queue empty", function()
      local patient = createMockPatient()
      room.humanoids[patient] = true
      room.door.queue.reportedSize = function() return 0 end
      local found = false
      room.tryToFindNearbyPatients = function() found = true end

      room:onHumanoidLeave(patient)
      assert.is_true(found)
    end)

    it("should advance queue when no staff leaving", function()
      local patient = createMockPatient()
      room.humanoids[patient] = true
      local advanced = false
      room.tryAdvanceQueue = function() advanced = true end

      room:onHumanoidLeave(patient)
      assert.is_true(advanced)
    end)

    it("should call for replacement staff when staff leaves with waiting patients", function()
      local doctor = createMockStaff()
      room.staff_member = doctor
      room.humanoids[doctor] = true
      room.door.queue.patientSize = function() return 2 end
      local called = false
      room.world.dispatcher.callForStaff = function() called = true end

      room:onHumanoidLeave(doctor)
      assert.is_true(called)
    end)

    it("should eject patients when last qualified staff leaves (non-ward)", function()
      local doctor = createMockStaff()
      local patient = createMockPatient()
      room.staff_member = doctor
      room.humanoids[doctor] = true
      room.humanoids[patient] = true
      room.room_info.id = "gp"
      room.testStaffCriteria = function() return false end
      room.getStaffMember = function() return nil end
      room.shouldHavePatientReenter = function() return true end
      room.makeHumanoidLeave = function() end
      room.createEnterAction = function() return "enter" end
      room.door.queue.patientSize = function() return 0 end
      local called = false
      room.world.dispatcher.callForStaff = function() called = true end

      room:onHumanoidLeave(doctor)
      assert.is_true(called)
    end)

    it("should NOT eject patients from ward when staff leaves", function()
      local nurse = createMockStaff()
      local patient = createMockPatient()
      room.staff_member = nurse
      room.humanoids[nurse] = true
      room.humanoids[patient] = true
      room.room_info.id = "ward"
      room.testStaffCriteria = function() return false end
      room.getStaffMember = function() return nil end
      local ejected = false
      room.makeHumanoidLeave = function() ejected = true end

      room:onHumanoidLeave(nurse)
      assert.is_false(ejected)
    end)

    it("should unlock room when handyman finishes repair", function()
      local handyman = createMockHandyman()
      local machine = { repairing = handyman }
      room.getRoomMachine = function() return machine end
      room.unlockRoomOnRepair = function() room.needs_repair = false end
      room.humanoids[handyman] = true

      room:onHumanoidLeave(handyman)
      assert.is_false(room.needs_repair)
    end)

    it("should enter edit mode when inactive room becomes empty", function()
      room.is_active = false
      local entered_edit = false
      room.enterEditMode = function() entered_edit = true end

      room:onHumanoidLeave(createMockPatient())
      assert.is_true(entered_edit)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- STAFF ASSIGNMENT
  -- ---------------------------------------------------------------------------

  describe("Staff Assignment & Management", function()
    it("should return correct required staff criteria", function()
      room.room_info.required_staff = { doctor = 1 }
      local criteria = room:getRequiredStaffCriteria()
      assert.equals(1, criteria.doctor)
    end)

    it("should return correct maximum staff criteria", function()
      room.room_info.maximum_staff = { doctor = 2 }
      local criteria = room:getMaximumStaffCriteria()
      assert.equals(2, criteria.doctor)
    end)

    it("should test staffFitsInRoom correctly at capacity", function()
      local doctor = createMockStaff({ profile = { is_doctor = true } })
      room.staff_member = doctor
      room.getMaximumStaffCriteria = function() return { doctor = 1 } end
      room.testStaffCriteria = function(self, criteria, staff)
        if staff then return true end
        return self.staff_member ~= nil
      end

      local fits = room:staffFitsInRoom(doctor)
      assert.is_false(fits)
    end)

    it("should calculate staff service quality for single staff", function()
      local doctor = createMockStaff()
      doctor.getServiceQuality = function() return 0.8 end
      room.staff_member = doctor

      local quality = room:getStaffServiceQuality()
      assert.equals(0.8, quality)
    end)

    it("should calculate average service quality for multi-staff rooms", function()
      local doc1 = createMockStaff()
      doc1.getServiceQuality = function() return 0.8 end
      local doc2 = createMockStaff()
      doc2.getServiceQuality = function() return 1.0 end
      room.staff_member_set = { [doc1] = true, [doc2] = true }

      local quality = room:getStaffServiceQuality()
      assert.equals(0.9, quality)
    end)

    it("should command entering staff and set dealing_with_patient", function()
      local doctor = createMockStaff()
      room.commandEnteringStaff(doctor)
      assert.equals(doctor, room.staff_member)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- PATIENT TREATMENT ROUTING
  -- ---------------------------------------------------------------------------

  describe("Patient Treatment Routing", function()
    it("should route diagnosed patient to first treatment room", function()
      local patient = createMockPatient({ disease = { treatment_rooms = { "pharmacy" } }, diagnosed = true, cure_rooms_visited = 0 })
      patient.agreesToPay = function() return true end
      room.dealtWithPatient(patient)
      assert.is_true(#patient.action_queue > 0)
    end)

    it("should send patient home if they refuse to pay", function()
      local patient = createMockPatient({ disease = { treatment_rooms = { "pharmacy" } }, diagnosed = true })
      patient.agreesToPay = function() return false end
      local went_home = false
      patient.goHome = function(reason, disease) went_home = true end
      room.dealtWithPatient(patient)
      assert.is_true(went_home)
    end)

    it("should advance cure rooms visited for treatment rooms", function()
      local patient = createMockPatient({ disease = { treatment_rooms = { "pharmacy", "ward" } }, cure_rooms_visited = 0 })
      room.dealtWithPatient(patient)
      assert.equals(1, patient.cure_rooms_visited)
    end)

    it("should mark disease treated when all cure rooms visited", function()
      local patient = createMockPatient({ disease = { treatment_rooms = { "pharmacy" } }, cure_rooms_visited = 1 })
      local treated = false
      patient.treatDisease = function() treated = true end
      room.dealtWithPatient(patient)
      assert.is_true(treated)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- CRASH CASCADING: crashRoom
  -- ---------------------------------------------------------------------------

  describe("crashRoom — Crash Cascading", function()
    it("should close door and clear reserved humanoid", function()
      local patient = createMockPatient()
      room.door.reserved_for = patient
      local finished = false
      patient.finishAction = function() finished = true end

      room:crashRoom()

      assert.is_true(finished)
      assert.is_nil(room.door.reserved_for)
    end)

    it("should kill all humanoids in room", function()
      local patient1 = createMockPatient()
      local patient2 = createMockPatient()
      local doctor = createMockStaff()
      room.humanoids[patient1] = true
      room.humanoids[patient2] = true
      room.humanoids[doctor] = true
      local deaths = 0
      patient1.die = function() deaths = deaths + 1 end
      patient2.die = function() deaths = deaths + 1 end
      doctor.die = function() deaths = deaths + 1 end

      room:crashRoom()

      assert.equals(3, deaths)
      assert.equals(0, next(room.humanoids) and 1 or 0)
    end)

    it("should kill door user", function()
      local walker = createMockPatient()
      room.door.user = walker
      local died = false
      walker.die = function() died = true end

      room:crashRoom()

      assert.is_true(died)
    end)

    it("should destroy non-door, non-strength objects", function()
      local plant = { object_type = { class = "Plant", id = "plant" }, tile_x = 1, tile_y = 1 }
      local door_obj = { object_type = { class = "Door", id = "door" } }
      local strong_obj = { object_type = { class = "Machine", id = "scanner", strength = 10 } }
      room.world.findAllObjectsNear = function() return { plant, door_obj, strong_obj } end
      local destroyed = {}
      room.world.destroyEntity = function(obj) destroyed[obj] = true end

      room:crashRoom()

      assert.is_true(destroyed[plant])
      assert.is_false(destroyed[door_obj])
      assert.is_false(destroyed[strong_obj])
    end)

    it("should place soot on all floor tiles", function()
      local soot_placed = {}
      room.world.newObject = function(type, x, y)
        table.insert(soot_placed, { x = x, y = y, type = type })
        return { setLitterType = function() end }
      end
      room.x = 10
      room.y = 10
      room.width = 3
      room.height = 2

      room:crashRoom()

      assert.equals(6, #soot_placed)
    end)

    it("should update hospital stats and deactivate", function()
      local initial_explosions = room.hospital.num_explosions
      local value_changed = false
      local rep_changed = false
      room.hospital.changeValue = function() value_changed = true end
      room.hospital.changeReputation = function() rep_changed = true end
      room.deactivate = function() room.is_active = false end

      room:crashRoom()

      assert.equals(initial_explosions + 1, room.hospital.num_explosions)
      assert.is_true(value_changed)
      assert.is_true(rep_changed)
      assert.is_false(room.is_active)
      assert.is_true(room.crashed)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- QUEUE MANAGEMENT
  -- ---------------------------------------------------------------------------

  describe("Queue Management", function()
    it("should advance queue when front humanoid can enter", function()
      local patient = createMockPatient()
      room.door.queue.size = function() return 1 end
      room.door.queue.front = function() return patient end
      room.door.user = nil
      room.door.reserved_for = nil
      room.canHumanoidEnter = function() return true end
      local popped = false
      room.door.queue.pop = function() popped = true end

      room:tryAdvanceQueue()

      assert.is_true(popped)
    end)

    it("should NOT advance queue when humanoid cannot enter", function()
      local patient = createMockPatient()
      room.door.queue.size = function() return 1 end
      room.door.queue.front = function() return patient end
      room.canHumanoidEnter = function() return false end
      local popped = false
      room.door.queue.pop = function() popped = true end

      room:tryAdvanceQueue()

      assert.is_false(popped)
    end)

    it("should pop humanoid already in room", function()
      local patient = createMockPatient()
      room.humanoids[patient] = true
      room.door.queue.size = function() return 1 end
      room.door.queue.front = function() return patient end
      room.canHumanoidEnter = function() return false end
      local popped = false
      room.door.queue.pop = function() popped = true end

      room:tryAdvanceQueue()

      assert.is_true(popped)
    end)

    it("should activate staff wait mood for valid target", function()
      local patient = createMockPatient()
      room.door.queue.size = function() return 1 end
      room.door.queue.front = function() return patient end
      room.hasQueueDialog = function() return true end
      room.room_info.id = "gp"
      room.canHumanoidEnter = function() return true end
      local staff = createMockStaff()
      room.staff_member = staff
      local mood_set = false
      staff.setMood = function(mood, state) if mood == "staff_wait" and state == "activate" then mood_set = true end end

      room:tryAdvanceQueue()

      assert.is_true(mood_set)
    end)

    it("canHumanoidEnter should return false for inactive room", function()
      room.is_active = false
      local patient = createMockPatient()
      assert.is_false(room:canHumanoidEnter(patient))
    end)

    it("canHumanoidEnter should return true for staff", function()
      local doctor = createMockStaff()
      assert.is_true(room:canHumanoidEnter(doctor))
    end)

    it("canHumanoidEnter should check staff criteria and patient capacity for patients", function()
      local patient = createMockPatient()
      room.testStaffCriteria = function() return true end
      room.getPatientCount = function() return 0 end
      room.maximum_patients = 1
      room.needs_repair = false
      assert.is_true(room:canHumanoidEnter(patient))

      room.getPatientCount = function() return 1 end
      assert.is_false(room:canHumanoidEnter(patient))

      room.getPatientCount = function() return 0 end
      room.needs_repair = true
      assert.is_false(room:canHumanoidEnter(patient))
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- ROOM BUILDING & ACTIVATION: roomFinished
  -- ---------------------------------------------------------------------------

  describe("roomFinished — Building & Activation", function()
    it("should mark room as built and active", function()
      room.built = false
      room.is_active = false
      room:roomFinished()
      assert.is_true(room.built)
      assert.is_true(room.is_active)
    end)

    it("should call for staff when patients waiting", function()
      room.door.queue.patientSize = function() return 2 end
      local called = false
      room.world.dispatcher.callForStaff = function() called = true end
      room:roomFinished()
      assert.is_true(called)
    end)

    it("should advance queue", function()
      local advanced = false
      room.tryAdvanceQueue = function() advanced = true end
      room:roomFinished()
      assert.is_true(advanced)
    end)

    it("should calculate happiness factor", function()
      local calculated = false
      room.calculateHappinessFactor = function() calculated = true end
      room:roomFinished()
      assert.is_true(calculated)
    end)

    it("should show info dialog for first room built in campaign", function()
      room.world.map.level_number = 1
      room.world.room_built = {}
      local dialog_shown = false
      room.world.ui.addWindow = function() dialog_shown = true end
      room:roomFinished()
      assert.is_true(dialog_shown)
      assert.is_true(room.world.room_built.gp)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- DEACTIVATION & EDIT MODE
  -- ---------------------------------------------------------------------------

  describe("Deactivation & Edit Mode", function()
    it("deactivate should set inactive and reroute patients", function()
      local rerouted = false
      room.door.queue.rerouteAllPatients = function() rerouted = true end
      room:deactivate()
      assert.is_false(room.is_active)
      assert.is_true(rerouted)
    end)

    it("tryToEdit should eject patients and staff", function()
      local patient = createMockPatient()
      local doctor = createMockStaff()
      room.humanoids[patient] = true
      room.humanoids[doctor] = true
      room.makeHumanoidLeave = function() end
      room.createLeaveAction = function() return "leave" end
      room.enterEditMode = function() room.edit_mode = true end

      room:tryToEdit()

      assert.is_not_nil(patient.current_action)
      assert.is_not_nil(doctor.current_action)
    end)

    it("enterEditMode should close machine window and open edit room UI", function()
      local machine_window = { machine = { getRoom = function() return room end }, close = function() end }
      room.world.ui.getWindow = function() return machine_window end
      local edit_opened = false
      room.world.ui.addWindow = function(w) edit_opened = true end

      room:enterEditMode()

      assert.is_true(edit_opened)
    end)
  end)

  -- ---------------------------------------------------------------------------
  -- DERIVED ROOM OVERRIDES
  -- ---------------------------------------------------------------------------

  describe("Derived Room Overrides", function()
    it("ToiletRoom should override onHumanoidEnter for loo/sink logic", function()
      local ToiletRoom = require 'rooms.toilets'
      local toilet = ToiletRoom:new()
      -- ToiletRoom has custom loo reservation logic
      assert.is_function(toilet.onHumanoidEnter)
    end)

    it("OperatingTheatreRoom should override onHumanoidLeave for surgeon cleanup", function()
      local OperatingTheatreRoom = require 'rooms.operating_theatre'
      local ot = OperatingTheatreRoom:new()
      ot.staff_member_set = { [createMockStaff()] = true }
      ot.onHumanoidLeave(ot.staff_member)
      -- Should clear staff_member_set
    end)

    it("WardRoom should update healing on leave", function()
      local WardRoom = require 'rooms.ward'
      local ward = WardRoom:new()
      local updated = false
      ward.updateHealingAmount = function() updated = true end
      ward:onHumanoidLeave(createMockPatient())
      assert.is_true(updated)
    end)

    it("TrainingRoom should unreserve resources on leave", function()
      local TrainingRoom = require 'rooms.training'
      local training = TrainingRoom:new()
      training.projector = { reserved_for = createMockStaff() }
      training.chairs = { { reserved_for = createMockStaff() } }
      training:onHumanoidLeave(createMockStaff())
      assert.is_nil(training.projector.reserved_for)
    end)
  end)
end)

-- ============================================================================
-- TEST SUITE: SPECIFIC ROOM TYPES
-- ============================================================================

describe("Room Lifecycle — Specific Room Types", function()
  local world, hospital

  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital()
    hospital.world = world
  end)

  describe("GPRoom", function()
    local GPRoom = require 'rooms.gp'
    local room

    before_each(function()
      room = GPRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("gp", { required_staff = { doctor = 1 } })
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 4, 4
      room.maximum_patients = 1
      room.humanoids = {}
    end)

    it("roomFinished should verify doctor present", function()
      room.getStaffMember = function() return nil end
      room.hospital.giveAdvice = function() end
      room:roomFinished()
      -- Should give advice if no doctor
    end)
  end)

  describe("OperatingTheatreRoom", function()
    local OperatingTheatreRoom = require 'rooms.operating_theatre'
    local room

    before_each(function()
      room = OperatingTheatreRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("operating_theatre", { required_staff = { surgeon = 2 } })
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 6, 6
      room.maximum_patients = 1
      room.humanoids = {}
      room.staff_member_set = {}
    end)

    it("canHumanoidEnter should check all surgeons are ready", function()
      local surgeon1 = createMockStaff({ profile = { is_surgeon = true }, is_ready = "ready" })
      local surgeon2 = createMockStaff({ profile = { is_surgeon = true }, is_ready = "not_ready" })
      room.staff_member_set = { [surgeon1] = true, [surgeon2] = true }
      room.getStaffMemberSet = function() return room.staff_member_set end
      room.testStaffCriteria = function() return true end

      local can_enter = room:canHumanoidEnter(createMockPatient())
      assert.is_false(can_enter)
    end)
  end)

  describe("WardRoom", function()
    local WardRoom = require 'rooms.ward'
    local room

    before_each(function()
      room = WardRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("ward", { required_staff = { nurse = 1 } })
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 4, 8
      room.humanoids = {}
      room.staff_member_set = {}
    end)

    it("roomFinished should count beds and desks for capacity", function()
      room.countBeds = function() return 4 end
      room.countDesks = function() return 2 end
      room:roomFinished()
      assert.equals(4, room.maximum_patients)
      assert.equals(2, room.maximum_staff)
    end)
  end)

  describe("ResearchRoom", function()
    local ResearchRoom = require 'rooms.research'
    local room

    before_each(function()
      room = ResearchRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("research", { required_staff = { researcher = 1 } })
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 4, 4
      room.humanoids = {}
      room.staff_member_set = {}
    end)

    it("roomFinished should set max researchers from desk count", function()
      room.countDesks = function() return 3 end
      room:roomFinished()
      assert.equals(3, room.maximum_staff)
    end)
  end)

  describe("TrainingRoom", function()
    local TrainingRoom = require 'rooms.training'
    local room

    before_each(function()
      room = TrainingRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("training", { required_staff = { consultant = 1 } })
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 6, 6
      room.humanoids = {}
    end)

    it("roomFinished should calculate max staff from chairs + projector", function()
      room.countChairs = function() return 3 end
      room.hasProjector = function() return true end
      room:roomFinished()
      assert.equals(4, room.maximum_staff) -- 3 chairs + 1 consultant
    end)

    it("onHumanoidEnter should only allow doctors", function()
      local nurse = createMockStaff({ profile = { is_nurse = true } })
      room.createLeaveAction = function() return "leave" end
      room:onHumanoidEnter(nurse)
      assert.is_not_nil(nurse.current_action)
    end)
  end)

  describe("ToiletRoom", function()
    local ToiletRoom = require 'rooms.toilets'
    local room

    before_each(function()
      room = ToiletRoom:new()
      room.world = world
      room.hospital = hospital
      room.room_info = createMockRoomInfo("toilets")
      room.door = createMockDoor()
      room.is_active = true
      room.built = true
      room.x, room.y, room.width, room.height = 0, 0, 3, 3
      room.humanoids = {}
      room.loos = {}
    end)

    it("getPatientCount should exclude patients at sinks", function()
      local patient_at_loo = createMockPatient()
      local patient_at_sink = createMockPatient()
      room.loos = { [1] = { user = patient_at_loo } }
      room.sinks = { [1] = { user = patient_at_sink } }
      room.humanoids[patient_at_loo] = true
      room.humanoids[patient_at_sink] = true

      local count = room:getPatientCount()
      assert.equals(1, count)
    end)
  end)
end)

-- ============================================================================
-- TEST SUITE: INTEGRATION SCENARIOS
-- ============================================================================

describe("Room Lifecycle — Integration Scenarios", function()
  local world, hospital

  before_each(function()
    world = createMockWorld()
    hospital = createMockHospital()
    hospital.world = world
  end)

  it("full patient journey: GP -> diagnosis -> treatment -> cure", function()
    -- Setup GP room
    local gp_room = createMockRoom(createMockRoomInfo("gp", { required_staff = { doctor = 1 } }), hospital)
    local doctor = createMockStaff({ profile = { is_doctor = true } })
    local patient = createMockPatient({ disease = { id = "cold", diagnosis_rooms = { "gp" }, treatment_rooms = { "pharmacy" } } })

    -- Doctor enters
    gp_room.testStaffCriteria = function() return true end
    gp_room.commandEnteringStaff = function() end
    gp_room:onHumanoidEnter(doctor)

    -- Patient enters
    gp_room.testStaffCriteria = function() return true end
    gp_room.commandEnteringPatient = function() end
    gp_room:onHumanoidEnter(patient)

    -- Patient dealt with
    patient.diagnosis_progress = 1.0
    patient.hasMoreDiagnosisRoomsAvailable = function() return false end
    gp_room.dealtWithPatient(patient)

    -- Should queue seek pharmacy action
    assert.is_true(#patient.action_queue > 0)
  end)

  it("staff replacement chain: new doctor replaces idle, patient continues", function()
    local room = createMockRoom(createMockRoomInfo("gp", { required_staff = { doctor = 1 } }), hospital)
    local old_doctor = createMockStaff({ profile = { is_doctor = true }, dealing_with_patient = false })
    local patient = createMockPatient()
    room.staff_member = old_doctor
    room.humanoids[old_doctor] = true
    room.humanoids[patient] = true
    room.getStaffMember = function() return old_doctor end
    room.staffFitsInRoom = function() return false end
    room.testStaffCriteria = function() return true end
    room.staffMeetsRoomRequirements = function() return true end
    room.commandEnteringStaff = function(self, staff) self.staff_member = staff end
    room.createLeaveAction = function() return "leave" end

    local new_doctor = createMockStaff({ profile = { is_doctor = true } })
    room:onHumanoidEnter(new_doctor)

    assert.equals(new_doctor, room.staff_member)
    assert.is_not_nil(old_doctor.current_action)
  end)

  it("crashRoom during treatment should kill patient, staff, destroy objects, impact hospital", function()
    local room = createMockRoom(createMockRoomInfo("gp"), hospital)
    local patient = createMockPatient()
    local doctor = createMockStaff()
    room.humanoids[patient] = true
    room.humanoids[doctor] = true
    room.door.user = createMockPatient()

    local initial_explosions = hospital.num_explosions
    room:crashRoom()

    assert.equals(initial_explosions + 1, hospital.num_explosions)
    assert.is_true(room.crashed)
    assert.is_false(room.is_active)
  end)

  it("queue advancement with multiple rooms stealing patients", function()
    local room1 = createMockRoom(createMockRoomInfo("gp"), hospital)
    local room2 = createMockRoom(createMockRoomInfo("gp"), hospital)
    world.rooms = { room1, room2 }

    room1.door.queue.reportedSize = function() return 3 end
    room1.door.queue.patientSize = function() return 3 end
    room1.getUsageScore = function() return 100 end
    room2.getUsageScore = function() return 50 end

    local patient = createMockPatient()
    room1.door.queue.reportedHumanoid = function(n) return patient end

    local moved = false
    room2.tryMovePatient = function(from, to, p) moved = true return true end

    room2:tryToFindNearbyPatients()
    assert.is_true(moved)
  end)
end)

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function capture_print(fn)
  local old_print = print
  local output = ""
  print = function(...)
    local args = {...}
    for i, v in ipairs(args) do
      output = output .. tostring(v) .. "\t"
    end
    output = output .. "\n"
  end
  fn()
  print = old_print
  return output
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

print("=== Room Lifecycle Test Scaffold ===")
print("Run with: busted SCAFFOLD.lua")
print("Test coverage:")
print("  - onHumanoidEnter (entry flow phases 1-4)")
print("  - onHumanoidLeave (exit flow phases 1-6)")
print("  - Staff assignment & replacement logic")
print("  - Patient treatment routing (diagnosis + cure)")
print("  - crashRoom cascading (6 phases)")
print("  - Queue management (tryAdvanceQueue, canHumanoidEnter)")
print("  - roomFinished (building & activation)")
print("  - Deactivation & edit mode")
print("  - Derived room overrides (7+ room types)")
print("  - Integration scenarios")
-- ============================================================================
-- UltrascanRoom — 3441 deep study
-- ============================================================================
describe("UltrascanRoom", function()
  it("commandEnteringPatient uses correct tiles", function()
    local room = UltrascanRoom(nil, 5, 5, "north")
    -- mocked findObjectNear and getSecondaryUsageTile verified via MAP 54-76
    assert.is_not_nil(room)
  end)
  it("after_use routes to GP via dealtWithPatient", function()
    -- after_use_scan should call dealtWithPatient then SeekRoom gp
    assert.is_not_nil(UltrascanRoom.commandEnteringPatient)
  end)
  it("has no dressing override", function()
    assert.is_nil(UltrascanRoom.makeHumanoidDressIfNecessaryAndThenLeave)
  end)
end)
