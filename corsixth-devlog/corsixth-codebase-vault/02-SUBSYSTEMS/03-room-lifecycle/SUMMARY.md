# Room Lifecycle in CorsixTH — Deep Research

**Area:** Room Lifecycle  
**Generated:** 2026-08-17  
**Source:** `/tmp/CorsixTH/CorsixTH/Lua/room.lua` + 23 room files in `/tmp/CorsixTH/CorsixTH/Lua/rooms/`

---

## Table of Contents

1. [Room as Container: Sets vs Lists](#1-room-as-container-sets-vs-lists)
2. [Entry Flow: `onHumanoidEnter`](#2-entry-flow-onhumanoidenter)
3. [Exit Flow: `onHumanoidLeave`](#3-exit-flow-onhumanoidleave)
4. [Staff Assignment & Management](#4-staff-assignment--management)
5. [Patient Treatment Routing](#5-patient-treatment-routing)
6. [Crash Cascading: `crashRoom`](#6-crash-cascading-crashrroom)
7. [Queue Management](#7-queue-management)
8. [Room Building & Activation: `roomFinished`](#8-room-building--activation-roomfinished)
9. [Deactivation & Edit Mode](#9-deactivation--edit-mode)
10. [Key Cross-Cutting Methods](#10-key-cross-cutting-methods)

---

## 1. Room as Container: Sets vs Lists

The `Room` base class uses **Lua tables as sets** (key = humanoid/object, value = `true`) rather than arrays for tracking occupants. This design choice enables O(1) membership tests, insertion, and removal.

### Core Container Fields (room.lua:83-86)

```lua
self.humanoids = {--[[a set rather than a list]]}
self.objects = {--[[a set rather than a list]]}
-- the set of humanoids walking to this room
self.humanoids_enroute = {--[[a set rather than a list]]}
```

### Why Sets?

- **Membership test**: `if self.humanoids[humanoid] then ... end` — O(1)
- **Iteration**: `for humanoid in pairs(self.humanoids) do ... end` — visits all occupants
- **No duplicates**: A humanoid cannot be in the same room twice (asserted at line 317)
- **Fast removal**: `self.humanoids[humanoid] = nil`

### Derived Room Extensions

| Room Type | Additional Container | Purpose |
|-----------|---------------------|---------|
| `OperatingTheatreRoom` | `self.staff_member_set = {}` (line 58) | Multi-surgeon tracking |
| `WardRoom` | `self.staff_member_set = {}` (line 59) | Multi-nurse tracking |
| `ResearchRoom` | `self.staff_member_set = {}` (line 58) | Multi-researcher tracking |
| `TrainingRoom` | Uses `maximum_staff` dynamic | Consultant + students |

### Patient Counting (room.lua:172-182)

```lua
function Room:getPatientCount()
  local count = 0
  for humanoid in pairs(self.humanoids) do
    if class.is(humanoid, Patient) then
      count = count + 1
    end
  end
  return count
end
```

**Special case — ToiletRoom (toilets.lua:149-168):** Overrides `getPatientCount()` to exclude patients at sinks, allowing higher throughput when multiple loos exist.

---

## 2. Entry Flow: `onHumanoidEnter`

**Location:** `room.lua:316-436`

This is the central entry point for **all** humanoids (patients, staff, handymen, VIPs). It handles:
- Room activation checks
- Handyman special handling
- Staff replacement logic
- Patient validation (diagnosis routing, staff requirements)

### Phase 1: Bookkeeping & Activation Guard (lines 316-336)

```lua
function Room:onHumanoidEnter(humanoid)
  assert(not self.humanoids[humanoid], "Humanoid entering a room that they are already in")
  humanoid.in_room = self
  humanoid.last_room = self  -- For staff room return

  -- Non-active room: eject immediately
  if not self.is_active then
    self.humanoids[humanoid] = true
    if class.is(humanoid, Patient) then
      self:makeHumanoidLeave(humanoid)
      humanoid:queueAction(SeekRoomAction(self.room_info.id))
    else
      humanoid:setNextAction(self:createLeaveAction())
      humanoid:queueAction(MeanderAction())
    end
    return
  end
```

### Phase 2: Handyman Handling (lines 337-357)

```lua
if class.is(humanoid, Handyman) then
  self.humanoids[humanoid] = true
  if humanoid.on_call then
    assert(humanoid.on_call.object:getRoom() == self, "Handyman arrived is on call but not arriving to the designated room")
    local machine = self:getRoomMachine()
    if machine then
      local handyman = machine.repairing
      if humanoid == handyman then
        self:lockRoomOnRepair()  -- Prevent patients during repair
      end
    end
  else
    humanoid:setNextAction(AnswerCallAction())  -- Drop-in handyman
  end
  self:tryAdvanceQueue()
  return
end
```

### Phase 3: Staff Entry & Replacement (lines 368-409)

```lua
if class.is(humanoid, Staff) then
  local staff_entered = humanoid
  if not self:staffFitsInRoom(staff_entered) then
    -- Room at max capacity — check if replacement warranted
    if self:getStaffMember() and self:staffMeetsRoomRequirements(staff_entered) then
      local staff_in_room = self:getStaffMember()
      self.humanoids[staff_entered] = true
      -- Ward/research desk advice triggers
      if staff_in_room.profile.is_researcher and self.room_info.id == "research" then
        self.hospital:giveAdvice(researcher_desks)
      end
      if class.is(staff_in_room, Nurse) and self.room_info.id == "ward" then
        self.hospital:giveAdvice(nurse_desks)
      end
      if not staff_in_room.dealing_with_patient or staff_in_room:isMeandering() then
        -- Replace idle staff
        staff_in_room:setNextAction(self:createLeaveAction())
        staff_in_room:queueAction(MeanderAction())
        self.staff_member = staff_entered
        staff_entered:setCallCompleted()
        self:commandEnteringStaff(staff_entered)
      else
        -- Keep busy staff, send new one away
        staff_entered:setNextAction(self:createLeaveAction())
        staff_entered:queueAction(MeanderAction())
      end
    else
      -- Wrong staff type for room
      self.humanoids[staff_entered] = true
      staff_entered:setNextAction(self:createLeaveAction())
      staff_entered:queueAction(MeanderAction())
      staff_entered:adviseWrongPersonForThisRoom()
    end
  else
    -- Fits in room
    self.humanoids[staff_entered] = true
    staff_entered:setCallCompleted()
    self:commandEnteringStaff(staff_entered)
  end
  self:tryAdvanceQueue()
  return
end
```

### Phase 4: Patient Entry (lines 411-435)

```lua
self.humanoids[humanoid] = true
self:tryAdvanceQueue()

if class.is(humanoid, Patient) then
  local patient_entered = humanoid
  -- Infection redirect check
  if patient_entered.infected and not patient_entered.diagnosed and
      not self:isDiagnosisRoomForPatient(patient_entered) then
    patient_entered:queueAction(self:createLeaveAction())
    patient_entered.needs_redirecting = true
    patient_entered:queueAction(SeekRoomAction("gp"))
    return
  end
  -- Staff requirements check
  if self:testStaffCriteria(self:getRequiredStaffCriteria()) then
    if self.staff_member then
      self:setStaffMembersAttribute("dealing_with_patient", true)
    end
    self:commandEnteringPatient(patient_entered)
  else
    -- No staff: patient leaves and re-queues
    patient_entered:setNextAction(self:createLeaveAction())
    patient_entered:queueAction(self:createEnterAction(patient_entered))
  end
end
```

### Derived Room Overrides

| Room | Override Purpose |
|------|------------------|
| `ToiletRoom` (toilets.lua:72-143) | Finds free loo, reserves it, handles sink usage after |
| `TrainingRoom` (training.lua:183-196) | Only Doctors allowed; consultants claim projector, students take chairs |
| `StaffRoom` (staff_room.lua:49-61) | Staff use `UseStaffRoomAction`; handymen on call pass through |

---

## 3. Exit Flow: `onHumanoidLeave`

**Location:** `room.lua:569-658`

Handles cleanup when any humanoid leaves, with cascading effects for staff departures.

### Phase 1: Staff Member Cleanup (lines 570-572)

```lua
if self.staff_member == humanoid then
  self.staff_member = nil
end
humanoid.in_room = nil
if not self.humanoids[humanoid] then
  print("Warning: Humanoid leaving a room that they are not in")
  return
end
self.humanoids[humanoid] = nil
```

### Phase 2: Patient Departure Effects (lines 581-598)

```lua
if class.is(humanoid, Patient) then
  -- Allow waiting staff to go to staff room
  for room_humanoid in pairs(self.humanoids) do
    if class.is(room_humanoid, Staff) and not class.is(room_humanoid, Handyman) then
      if room_humanoid.staffroom_needed then
        room_humanoid.staffroom_needed = nil
        room_humanoid:goToStaffRoom()
        staff_leaving = true
      end
    end
  end
  -- Try to pull patients from similar rooms
  if self.door.queue and self.door.queue:reportedSize() == 0 and self.is_active then
    self:tryToFindNearbyPatients()
  end
end
```

### Phase 3: Queue Advancement or Staff Recall (lines 600-611)

```lua
if not staff_leaving then
  self:tryAdvanceQueue()
else
  -- Staff left, but patients still waiting — call replacement
  if self.active and self.door.queue:patientSize() > 0 then
    self.world.dispatcher:callForStaff(self)
  end
end
```

### Phase 4: Staff Departure — Patient Ejection (lines 614-631)

```lua
if class.is(humanoid, Staff) then
  if not self:testStaffCriteria(self:getRequiredStaffCriteria()) or self:getStaffMember() == nil then
    local call_for_new_staff = self.door.queue:patientSize() > 0
    for room_humanoid in pairs(self.humanoids) do
      if class.is(room_humanoid, Patient) and self:shouldHavePatientReenter(room_humanoid) then
        call_for_new_staff = true
        if self.room_info.id ~= "ward" then
          self:makeHumanoidLeave(room_humanoid)
          room_humanoid:queueAction(self:createEnterAction(room_humanoid))
        end
      end
    end
    if self.is_active and call_for_new_staff then
      self.world.dispatcher:callForStaff(self)
    end
  end
  humanoid:setMood("staff_wait", "deactivate")
end
```

### Phase 5: Handyman Repair Cleanup (lines 636-646)

```lua
if class.is(humanoid, Handyman) then
  local machine = self:getRoomMachine()
  if machine then
    local handyman = machine.repairing
    if humanoid == handyman and not self.manual_repair then
      self:unlockRoomOnRepair()
      self:tryAdvanceQueue()
    end
  end
end
```

### Phase 6: Edit Mode Trigger (lines 648-657)

```lua
if not self.is_active then
  local people_in_room = 0
  for _ in pairs(self.humanoids) do
    people_in_room = people_in_room + 1
  end
  if people_in_room == 0 then
    self:enterEditMode()
  end
end
```

### Derived Room Overrides

| Room | Override Purpose |
|------|------------------|
| `OperatingTheatreRoom` (operating_theatre.lua:346-364) | Clears `staff_member_set`, aborts surgeons on patient leave, turns off X-ray |
| `WardRoom` (ward.lua:197-201) | Updates healing amount on any leave |
| `ResearchRoom` (research.lua:203-206) | Clears `staff_member_set` |
| `ScannerRoom` (scanner_room.lua:116-121) | Clears `staff_member` |
| `DecontaminationRoom` (decontamination.lua:118-123) | Clears `staff_member` |
| `TrainingRoom` (training.lua:250-264) | Unreserves projector/chairs/skeleton/bookcase |
| `CardiogramRoom` (cardiogram.lua:116-121) | Clears `staff_member` |

---

## 4. Staff Assignment & Management

### Single vs Multi-Occupancy

**Single occupancy** (GP, Pharmacy, Scanner, etc.): Uses `self.staff_member` (single reference)

**Multi-occupancy** (OperatingTheatre, Ward, Research, Training): Uses `self.staff_member_set = {}` (set of staff)

### Staff Criteria System

```lua
-- Required staff (minimum to function)
function Room:getRequiredStaffCriteria()
  return self.room_info.required_staff or no_staff
end

-- Maximum staff (capacity limit)
function Room:getMaximumStaffCriteria()
  return self.room_info.maximum_staff or self.room_info.required_staff or no_staff
end
```

### Staff Fit Test (room.lua:465-471)

```lua
function Room:staffFitsInRoom(staff)
  local criteria = self:getMaximumStaffCriteria()
  -- True if: room NOT at max capacity OR this staff doesn't help meet criteria
  if self:testStaffCriteria(criteria) or not self:testStaffCriteria(criteria, staff) then
    return false
  end
  return true
end
```

### Staff Replacement Logic (room.lua:372-395)

When a new staff member enters a full room:
1. If current staff is **idle/meandering** → replace them
2. If current staff is **dealing with patient** → send new staff away
3. If new staff **doesn't meet requirements** → send away with advice

### Multi-Staff Rooms

| Room | Max Staff | Determination |
|------|-----------|---------------|
| OperatingTheatre | 2 Surgeons | Fixed in room_info |
| Ward | = # desks | Dynamic in `roomFinished` (ward.lua:76-78) |
| Research | = # desks | Dynamic in `roomFinished` (research.lua:128-130) |
| Training | = # chairs + 1 | Dynamic in `roomFinished` (training.lua:61) |

### Staff Service Quality (room.lua:1128-1149)

```lua
function Room:getStaffServiceQuality()
  local quality = 0.5
  if self.staff_member_set then
    quality = 0
    local count = 0
    for member, _ in pairs(self.staff_member_set) do
      quality = quality + member:getServiceQuality()
      count = count + 1
    end
    quality = quality / count
  elseif self.staff_member then
    quality = self.staff_member:getServiceQuality()
  end
  return quality
end
```

---

## 5. Patient Treatment Routing

### Diagnosis Flow (GPRoom — gp.lua:112-165)

```lua
function GPRoom:dealtWithPatient(patient)
  -- ... deduplication guard ...
  patient:setNextAction(self:createLeaveAction())
  patient:addToTreatmentHistory(self.room_info)

  if patient.needs_redirecting then
    self:sendPatientToNextDiagnosisRoom(patient)
  elseif patient.disease and not patient.diagnosed then
    self.hospital:receiveMoneyForTreatment(patient)
    patient:completeDiagnosticStep(self)
    
    -- Check if diagnosis complete
    local no_need_diagnose_further = patient.diagnosis_progress >= self.hospital.policies["stop_procedure"]
    local cant_diagnose_further = (patient.diagnosis_progress >= 1.0) and (not patient:hasMoreDiagnosisRoomsAvailable())
    
    if no_need_diagnose_further or cant_diagnose_further then
      patient:setDiagnosed()
      if patient:agreesToPay(patient.disease.id) then
        patient:queueAction(SeekRoomAction(patient.disease.treatment_rooms[1]):enableTreatmentRoom())
      else
        patient:goHome("over_priced", patient.disease.id)
      end
    else
      self:sendPatientToNextDiagnosisRoom(patient)
    end
  end
end
```

### Cure Flow (room.lua:220-236)

```lua
else  -- Patient was in a cure room
  patient.cure_rooms_visited = patient.cure_rooms_visited + 1
  local next_room = patient.disease.treatment_rooms[patient.cure_rooms_visited + 1]
  if next_room then
    patient:queueAction(SeekRoomAction(next_room))
  else
    patient:treatDisease()  -- Fully cured
  end
end
```

### Room Stealing: `tryToFindNearbyPatients` (room.lua:834-854)

When a room becomes active/empty, it "steals" patients from other rooms of the **same type** with queue ≥ 2:

```lua
function Room:tryToFindNearbyPatients()
  for _, old_room in pairs(self.world.rooms) do
    if old_room.hospital == self.hospital and old_room ~= self and
        old_room.room_info == self.room_info and old_room.door.queue and
        old_room.door.queue:reportedSize() >= 2 then
      -- Move patients from back of old queue to this room
      while pat_number > 1 do
        local patient = old_queue:reportedHumanoid(pat_number)
        if tryMovePatient(old_room, self, patient) then break end
        pat_number = pat_number - 1
      end
    end
  end
end
```

**Score comparison** (`tryMovePatient`, room.lua:772-831): Uses `getUsageScore() + path_distance` — lower score wins.

### Usage Score (room.lua:680-694)

```lua
function Room:getUsageScore()
  local queue = self.door.queue
  local score = queue:patientSize() + self:getPatientCount() - self.maximum_patients
  score = score * tile_factor  -- 10
  if self:testStaffCriteria(self:getRequiredStaffCriteria()) then
    score = score - readiness_bonus  -- 50
  end
  if queue:isFull() then
    score = score + 1000
  end
  return score
end
```

---

## 6. Crash Cascading: `crashRoom`

**Location:** `room.lua:857-964`

Complete room destruction — kills all occupants, destroys objects, places soot, impacts hospital value/reputation.

### Phase 1: Door & Reserved Humanoid (lines 858-875)

```lua
function Room:crashRoom()
  self.door:closeDoor()
  if self.door2 then self.door2.hover_cursor = nil end

  if self.door.reserved_for then
    local person = self.door.reserved_for
    if not person:isLeaving() and class.is(person, Patient) then
      person:setNextAction(IdleAction():setCount(1))
      person:queueAction(SeekRoomAction(self.room_info.id))
    end
    person:finishAction()
    self.door.reserved_for = nil
  end
```

### Phase 2: Kill All Humanoids in Room (lines 877-893)

```lua
local remove_humanoid = function(humanoid)
  humanoid:queueAction(IdleAction(), 1)
  humanoid.user_of = nil
  if humanoid.is_emergency then
    table.remove(self.world:getLocalPlayerHospital().emergency_patients, humanoid.is_emergency)
  end
  humanoid:die()
  humanoid:despawn()
  self.world:destroyEntity(humanoid)
end

for humanoid, _ in pairs(self.humanoids) do
  remove_humanoid(humanoid)
end
self.humanoids = {}
```

### Phase 3: Kill Door User (lines 895-901)

```lua
local walker = self.door.user
if walker then
  self.door:removeUser(walker)
  remove_humanoid(walker)
end
```

### Phase 4: Destroy Objects (lines 903-922)

```lua
for object, _ in pairs(self.world:findAllObjectsNear(fx, fy)) do
  if object.object_type.class == "Plant" then
    -- Remove watering tasks
    local index = self.hospital:getIndexOfTask(object.tile_x, object.tile_y, "watering")
    if index ~= -1 then self.hospital:removeHandymanTask(index, "watering") end
    object.unreachable = true
  end
  if object.object_type.id ~= "door" and not object.strength and
      object.object_type.class ~= "SwingDoor" then
    object.user = nil
    object.user_list = nil
    object.reserved_for = nil
    object.reserved_for_list = nil
    self.world:destroyEntity(object)
  end
end
```

### Phase 5: Soot Placement (lines 924-955)

```lua
-- Floor soot
for x = self.x, self.x + self.width - 1 do
  for y = self.y, self.y + self.height - 1 do
    local soot = self.world:newObject("litter", x, y)
    soot:setLitterType("soot_floor", 0)
  end
end

-- Wall soot (north and west walls)
-- ... places soot_wall or soot_window based on wall type
```

### Phase 6: Hospital Impact (lines 957-963)

```lua
self.hospital.num_explosions = self.hospital.num_explosions + 1
local value_change = self.hospital.research.research_progress[self.room_info].build_cost
self.hospital:changeValue(value_change * -1)
self.hospital:changeReputation("room_crash")
self.crashed = true
self:deactivate()
```

---

## 7. Queue Management

### Queue Advancement: `tryAdvanceQueue` (room.lua:549-565)

```lua
function Room:tryAdvanceQueue()
  if self.door.queue and self.door.queue:size() > 0 and not self.door.user and not self.door.reserved_for then
    local front = self.door.queue:front()
    if self:canHumanoidEnter(front) then
      self.door.queue:pop()
      self.door:updateDynamicInfo()
      if self:_checkWaitToggleValidTarget() then
        self:_staffWaitToggle(true)  -- Show "waiting for patient" mood
      end
    elseif self.humanoids[front] then
      -- Already in room, just pop
      self.door.queue:pop()
      self.door:updateDynamicInfo()
    end
  end
end
```

### Entry Permission: `canHumanoidEnter` (room.lua:696-712)

```lua
function Room:canHumanoidEnter(humanoid)
  if not self.is_active then return false end
  if class.is(humanoid, Staff) then return true end
  if class.is(humanoid, Patient) and not self.needs_repair then
    return self:testStaffCriteria(self:getRequiredStaffCriteria()) 
       and self:getPatientCount() < self.maximum_patients
  end
  return false
end
```

### Derived Overrides of `canHumanoidEnter`

| Room | Additional Checks |
|------|-------------------|
| `OperatingTheatreRoom` (line 366-377) | All surgeons must be in surgeon clothes (`is_ready == "ready"`) |
| `ScannerRoom` | Uses base (no override) |
| `TrainingRoom` | Uses `testStaffCriteria` override (consultant limit) |

### Staff Wait Toggle (room.lua:503-530)

```lua
function Room:_staffWaitToggle(activate)
  if not self.staff_member and not self.staff_member_set then return end
  local state = activate and "activate" or "deactivate"
  local dynamic_text = activate and _S.dynamic_info.staff.actions.waiting_for_patient or ""
  
  if not self.staff_member_set and self.staff_member then
    self.staff_member:setMood("staff_wait", state)
    self.staff_member:setDynamicInfoText(dynamic_text)
  else
    for staff_member in pairs(self.staff_member_set) do
      staff_member:setMood("staff_wait", state)
      staff_member:setDynamicInfoText(dynamic_text)
    end
  end
end
```

### Valid Wait Target (room.lua:532-537)

```lua
function Room:_checkWaitToggleValidTarget()
  return self:hasQueueDialog() and self.room_info.id ~= "toilets" and
      class.is(self.door.queue:front(), Patient)
end
```

---

## 8. Room Building & Activation: `roomFinished`

**Location:** `room.lua:716-741`

Called when player confirms room construction/edit.

```lua
function Room:roomFinished()
  self.built = true
  self.is_active = true
  
  if not self:hasQueueDialog() then
    self.door.hover_cursor = TheApp.gfx:loadMainCursor("default")
  end
  
  -- First-time room info dialog (campaign only)
  if tonumber(self.world.map.level_number) and self.world.room_information_dialogs then
    if not self.world.room_built[self.room_info.id] then
      self.world.ui:addWindow(UIInformation(self.world.ui, _S.room_descriptions[self.room_info.id]))
      self.world.room_built[self.room_info.id] = true
    end
  end
  
  self:tryToFindNearbyPatients()
  if self.door.queue:patientSize() > 0 then
    self.world.dispatcher:callForStaff(self)
  end
  self:tryAdvanceQueue()
  self:calculateHappinessFactor()
end
```

### Derived `roomFinished` Overrides

| Room | Additional Logic |
|------|------------------|
| `OperatingTheatreRoom` (lines 61-82) | Finds X-ray viewer; checks for Ward + 2 Surgeons |
| `WardRoom` (lines 63-84) | Counts beds/desks → sets `maximum_patients`/`maximum_staff` |
| `ResearchRoom` (lines 117-142) | Counts desks → sets max researchers; first research room advice |
| `TrainingRoom` (lines 50-69) | Counts chairs + projector → max staff; calculates training factor |
| `ToiletRoom` (lines 49-60) | Counts loos → `maximum_patients` |
| `GPRoom` (lines 202-208) | Checks for Doctor |
| `PharmacyRoom` (lines 53-58) | Checks for Nurse |
| `PsychRoom` (lines 54-59) | Checks for Psychiatrist |

---

## 9. Deactivation & Edit Mode

### Deactivate (room.lua:1014-1025)

```lua
function Room:deactivate()
  self.is_active = false
  self.world:notifyRoomRemoved(self)
  if self.door.queue then
    self.door.queue:rerouteAllPatients(self.room_info.id)
  end
  self.hospital:removeRatholesAroundRoom(self)
end
```

### Try to Edit (room.lua:1027-1051)

```lua
function Room:tryToEdit()
  self:deactivate()
  local people_in_room = 0
  if self.door.user and self.door.user:getCurrentAction().is_entering then
    people_in_room = 1
  end
  for humanoid, _ in pairs(self.humanoids) do
    if not humanoid:isLeaving() then
      if class.is(humanoid, Patient) then
        self:makeHumanoidLeave(humanoid)
        humanoid:queueAction(SeekRoomAction(self.room_info.id))
      else
        humanoid:setNextAction(self:createLeaveAction())
        humanoid:queueAction(MeanderAction())
      end
      people_in_room = people_in_room + 1
    end
  end
  if people_in_room == 0 then
    self:enterEditMode()
  end
end
```

### Enter Edit Mode (room.lua:1060-1071)

```lua
function Room:enterEditMode()
  local ui = self.world.ui
  local window = ui:getWindow(UIMachine)
  if window and window.machine and window.machine:getRoom() == self then
    window:close()
  end
  ui:addWindow(UIEditRoom(ui, self))
  ui:setCursor(ui.default_cursor)
end
```

---

## 10. Key Cross-Cutting Methods

### `commandEnteringStaff` (room.lua:489-501)

Base implementation — derived rooms override heavily:

```lua
function Room:commandEnteringStaff(staff, already_initialized)
  if not already_initialized then
    self.staff_member = staff
    staff:setNextAction(MeanderAction())
  end
  self:tryToFindNearbyPatients()
  staff:setDynamicInfoText("")
  self.sound_played = nil
  if self:testStaffCriteria(self:getRequiredStaffCriteria()) then
    self.world.dispatcher:dropFromQueue(self)
  end
end
```

### `commandEnteringPatient` (room.lua:539-547)

Base — minimal, derived rooms do all the work:

```lua
function Room:commandEnteringPatient(humanoid)
  self.door.queue.visitor_count = self.door.queue.visitor_count + 1
  humanoid:updateDynamicInfo("")
  self:_staffWaitToggle(false)
end
```

### `dealtWithPatient` (room.lua:192-238)

Central routing after treatment — see Section 5.

### `makeHumanoidLeave` / `makeHumanoidDressIfNecessaryAndThenLeave` (room.lua:968-1012)

Handles dressing/undressing for rooms with screens (GP, Scanner, Cardiogram, GeneralDiag, XRay).

### `afterLoad` (room.lua:1058-1108)

Save game migration — handles version-specific data structure changes.

### `isDiagnosisRoomForPatient` (room.lua:1115-1126)

```lua
function Room:isDiagnosisRoomForPatient(patient)
  if self.room_info.id ~= "gp" then
    for _, room_name in ipairs(patient.disease.diagnosis_rooms) do
      if self.room_info.id == room_name then return true end
    end
    return false
  else
    return true  -- GP is always valid
  end
end
```

### Happiness Factor (room.lua:1183-1204)

```lua
function Room:calculateHappinessFactor()
  local window_factor, space_factor, window_count = 0, 0, self:countWindows()
  if window_count > 0 then
    if self.room_info.id == "staff_room" then window_count = window_count * 2 end
    window_factor = math.round(math.log(window_count)) / 1000
  end
  local extraspace = (self.width * self.height) / (self.room_info.minimum_size ^ 2)
  if extraspace > 1 then
    space_factor = math.round(math.log(extraspace)) / 1000
  end
  self.happiness_factor = window_factor + space_factor
end
```

---

## Appendix: Room Type Quick Reference

| Room ID | Class | Category | Required Staff | Max Patients | Multi-Staff? |
|---------|-------|----------|----------------|--------------|--------------|
| gp | GPRoom | diagnosis | Doctor 1 | 1 | No |
| general_diag | GeneralDiagRoom | diagnosis | Doctor 1 | 1 | No |
| scanner | ScannerRoom | diagnosis | Doctor 1 | 1 | No |
| ultrascan | UltrascanRoom | diagnosis | Doctor 1 | 1 | No |
| blood_machine | BloodMachineRoom | diagnosis | Doctor 1 | 1 | No |
| cardiogram | CardiogramRoom | diagnosis | Doctor 1 | 1 | No |
| x_ray | XRayRoom | diagnosis | Doctor 1 | 1 | No |
| decontamination | DecontaminationRoom | clinics | Doctor 1 | 1 | No |
| fracture_clinic | FractureRoom | clinics | Nurse 1 | 1 | No |
| slack_tongue | SlackTongueRoom | clinics | Doctor 1 | 1 | No |
| inflation | InflationRoom | clinics | Doctor 1 | 1 | No |
| hair_restoration | HairRestorationRoom | clinics | Doctor 1 | 1 | No |
| electrolysis | ElectrolysisRoom | clinics | Doctor 1 | 1 | No |
| jelly_vat | JellyVatRoom | clinics | Doctor 1 | 1 | No |
| dna_fixer | DNAFixerRoom | clinics | Researcher 1 | 1 | No |
| psych | PsychRoom | treatment+diagnosis | Psychiatrist 1 | 1 | No |
| pharmacy | PharmacyRoom | treatment | Nurse 1 | 1 | No |
| operating_theatre | OperatingTheatreRoom | treatment | Surgeon 2 | 1 | **Yes** (2) |
| ward | WardRoom | treatment+diagnosis | Nurse 1 | =beds | **Yes** (=desks) |
| research | ResearchRoom | facilities | Researcher 1 | 0 | **Yes** (=desks) |
| training | TrainingRoom | facilities | Consultant 1 | 0 | **Yes** (=chairs+1) |
| staff_room | StaffRoom | facilities | None | 0 | N/A |
| toilets | ToiletRoom | facilities | None | =loos | No |

---

*End of SUMMARY.md*


## Related Pages

- [[03-room-lifecycle/CHECKLIST]]
- [[03-room-lifecycle/MAP]]
- [[03-room-lifecycle/SCAFFOLD]]
