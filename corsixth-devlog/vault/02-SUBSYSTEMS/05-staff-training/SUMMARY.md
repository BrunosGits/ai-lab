# Staff Training Area - Comprehensive Technical Summary

## Overview

This document provides a complete technical overview of the Staff Training system in CorsixTH, covering staff hierarchy, fatigue/happiness management, staff room seeking behavior, salary progression, skill training mechanics, handyman tasks, receptionist special behaviors, and training room factor calculations with logarithmic scaling.

---

## 1. Staff Hierarchy & Types

### 1.1 Staff Class Structure

```
Staff (Base Class) - entities/humanoids/staff.lua
├── Doctor - entities/humanoids/staff/doctor.lua
├── Nurse - entities/humanoids/staff/nurse.lua
├── Handyman - entities/humanoids/staff/handyman.lua
└── Receptionist - entities/humanoids/staff/receptionist.lua
```

### 1.2 Base Staff Properties (staff.lua)

```lua
-- Core staff attributes
Staff = {
    -- Identity
    staff_type = "doctor",           -- "doctor", "nurse", "handyman", "receptionist"
    name = "Dr. Smith",
    character = "doctor_1",          -- Visual character variant
    
    -- Skills (0-100 scale, stored in staff_profile.lua)
    skills = {
        diagnosis = 50,              -- Doctor: affects diagnosis speed/accuracy
        treatment = 50,              -- Doctor/Nurse: affects treatment speed
        surgery = 50,                -- Doctor: surgery success rate
        research = 50,               -- Doctor: research speed
        nursing = 50,                -- Nurse: patient care quality
        pharmacy = 50,               -- Nurse: pharmacy efficiency
        maintenance = 50,            -- Handyman: repair speed/quality
        gardening = 50,              -- Handyman: plant care
        reception = 50,              -- Receptionist: check-in speed
        administration = 50          -- Receptionist: paperwork efficiency
    },
    
    -- State
    fatigue = 0,                     -- 0-100, increases with work
    happiness = 100,                 -- 0-100, decreases with poor conditions
    salary = 500,                    -- Monthly salary in dollars
    experience = 0,                  -- XP for level progression
    level = 1,                       -- Current level (1-10)
    
    -- Employment
    hire_date = 0,                   -- Game timestamp
    contract_type = "permanent",     -- "permanent", "temporary"
    current_room = nil,              -- Reference to assigned room
    current_task = nil,              -- Current task reference
    
    -- Training
    is_training = false,
    training_room = nil,
    training_skill = nil,
    training_progress = 0,
    
    -- Behavior
    needs_break = false,
    break_timer = 0,
    seeking_staff_room = false
}
```

### 1.3 Staff Type Specializations

#### Doctor (`doctor.lua`)
```lua
Doctor = Staff:new()
Doctor.primary_skills = {"diagnosis", "treatment", "surgery", "research"}
Doctor.required_rooms = {"office", "surgery", "research"}
Doctor.patient_interaction = true
Doctor.can_diagnose = true
Doctor.can_treat = true
Doctor.can_research = true

-- Doctor-specific behaviors
function Doctor:diagnosePatient(patient, room)
    local speed = self.skills.diagnosis * room.efficiency_factor
    local accuracy = self.skills.diagnosis / 100
    -- Diagnosis logic...
end

function Doctor:performSurgery(patient, room)
    local success_rate = self.skills.surgery / 100 * room.surgery_bonus
    -- Surgery logic...
end
```

#### Nurse (`nurse.lua`)
```lua
Nurse = Staff:new()
Nurse.primary_skills = {"treatment", "nursing", "pharmacy"}
Nurse.required_rooms = {"ward", "pharmacy", "clinic"}
Nurse.patient_interaction = true
Nurse.can_treat = true
Nurse.can_dispense = true

-- Nurse-specific behaviors
function Nurse:careForPatient(patient, room)
    local care_quality = self.skills.nursing / 100
    patient:recover(care_quality * room.ward_bonus)
end

function Nurse:dispenseMedication(patient, room)
    local efficiency = self.skills.pharmacy / 100
    -- Pharmacy logic...
end
```

#### Handyman (`handyman.lua`)
```lua
Handyman = Staff:new()
Handyman.primary_skills = {"maintenance", "gardening"}
Handyman.required_rooms = {"staff_room", "maintenance"}
Handyman.patient_interaction = false
Handyman.can_repair = true
Handyman.can_water_plants = true
Handyman.can_transport = true

-- Handyman-specific behaviors
function Handyman:repairMachine(machine, room)
    local repair_speed = self.skills.maintenance / 100
    local quality = self.skills.maintenance / 100
    machine:repair(repair_speed, quality)
end

function Handyman:waterPlants(plant_list)
    for _, plant in ipairs(plant_list) do
        if plant.needs_water then
            local care = self.skills.gardening / 100
            plant:water(care)
        end
    end
end

function Handyman:transportItem(item, from_room, to_room)
    -- Item transport logic...
end
```

#### Receptionist (`receptionist.lua`)
```lua
Receptionist = Staff:new()
Receptionist.primary_skills = {"reception", "administration"}
Receptionist.required_rooms = {"reception"}
Receptionist.patient_interaction = true
Receptionist.can_checkin = true
Receptionist.can_manage_queue = true

-- Receptionist-specific behaviors
function Receptionist:checkInPatient(patient)
    local speed = self.skills.reception / 100
    patient.status = "waiting"
    patient.queue_position = self:getQueuePosition(patient)
    -- Check-in logic...
end

function Receptionist:manageQueue(reception_room)
    -- Prioritize patients by severity, appointment time
    -- Handle walk-ins vs appointments
    -- Notify doctors of waiting patients
end

function Receptionist:handlePhoneCalls()
    -- Appointment booking, cancellations
    -- Emergency call handling
end
```

---

## 2. Fatigue & Happiness Management

### 2.1 Fatigue System (staff.lua)

```lua
-- Fatigue accumulation per game tick (typically 1 second)
function Staff:updateFatigue(dt)
    local fatigue_rate = self:getFatigueRate()
    
    -- Base fatigue from working
    if self.current_task and self.current_task.type == "work" then
        self.fatigue = math.min(100, self.fatigue + fatigue_rate * dt)
    end
    
    -- Recovery during breaks
    if self.current_task and self.current_task.type == "break" then
        self.fatigue = math.max(0, self.fatigue - FATIGUE_RECOVERY_RATE * dt)
    end
    
    -- Recovery in staff room
    if self.current_room and self.current_room.type == "staff_room" then
        local room_quality = self.current_room:getQuality()
        self.fatigue = math.max(0, self.fatigue - room_quality * STAFF_ROOM_RECOVERY_MULTIPLIER * dt)
    end
    
    -- Check break threshold
    if self.fatigue >= FATIGUE_BREAK_THRESHOLD and not self.needs_break then
        self:requestBreak()
    end
    
    -- Forced break at critical fatigue
    if self.fatigue >= FATIGUE_CRITICAL_THRESHOLD then
        self:forceBreak()
    end
end

-- Fatigue rate varies by staff type and activity
function Staff:getFatigueRate()
    local base_rates = {
        doctor = 0.8,      -- High mental load
        nurse = 0.7,       -- Physical + mental
        handyman = 0.6,    -- Physical labor
        receptionist = 0.5 -- Lower intensity
    }
    
    local rate = base_rates[self.staff_type] or 0.5
    
    -- Modifiers
    if self.current_room then
        rate = rate * self.current_room:getFatigueModifier()
    end
    
    -- Skill reduces fatigue (experienced staff work more efficiently)
    local skill_avg = self:getAverageSkill()
    rate = rate * (1 - skill_avg * 0.2)
    
    return rate
end
```

### 2.2 Happiness System (staff.lua)

```lua
-- Happiness factors and calculation
function Staff:updateHappiness(dt)
    local happiness_change = 0
    
    -- Positive factors
    happiness_change = happiness_change + self:getSalarySatisfaction() * dt
    happiness_change = happiness_change + self:getRoomQualityBonus() * dt
    happiness_change = happiness_change + self:getTrainingOpportunity() * dt
    happiness_change = happiness_change + self:getColleagueBonus() * dt
    
    -- Negative factors
    happiness_change = happiness_change - self:getFatiguePenalty() * dt
    happiness_change = happiness_change - self:getWorkloadPenalty() * dt
    happiness_change = happiness_change - self:getEnvironmentPenalty() * dt
    
    self.happiness = math.clamp(0, 100, self.happiness + happiness_change)
    
    -- Trigger resignation check
    if self.happiness <= RESIGNATION_THRESHOLD then
        self:considerResignation()
    end
end

function Staff:getSalarySatisfaction()
    local market_rate = self:getMarketSalary()
    local ratio = self.salary / market_rate
    
    if ratio >= 1.5 then return 2.0      -- Very happy
    elseif ratio >= 1.2 then return 1.0  -- Happy
    elseif ratio >= 1.0 then return 0.2  -- Neutral
    elseif ratio >= 0.8 then return -0.5 -- Unhappy
    else return -1.5                     -- Very unhappy
    end
end

function Staff:getRoomQualityBonus()
    if not self.current_room then return 0 end
    
    local quality = self.current_room:getQuality()  -- 0-100
    return (quality - 50) * 0.02  -- -1 to +1 per tick
end

function Staff:getFatiguePenalty()
    if self.fatigue > 70 then
        return (self.fatigue - 70) * 0.05
    end
    return 0
end
```

### 2.3 Staff Room Seeking Behavior

```lua
-- Staff room seeking logic (staff.lua)
function Staff:seekStaffRoom()
    if self.seeking_staff_room then return end
    
    self.seeking_staff_room = true
    self.needs_break = true
    
    -- Find best available staff room
    local best_room = nil
    local best_score = -1
    
    for _, room in ipairs(self.hospital.rooms.staff_room) do
        if room:hasCapacity() and room:isAccessible(self) then
            local score = room:getQuality() * 0.5
            score = score + (1 - room.current_occupancy / room.capacity) * 0.3
            score = score - self:distanceTo(room) * 0.2
            
            if score > best_score then
                best_score = score
                best_room = room
            end
        end
    end
    
    if best_room then
        self:navigateTo(best_room)
        self.target_staff_room = best_room
    else
        -- No staff room available - wander or wait
        self:waitForStaffRoom()
    end
end

function Staff:onEnterStaffRoom(room)
    self.seeking_staff_room = false
    self.needs_break = false
    self.current_task = {type = "break", room = room}
    
    -- Notify room
    room:staffEntered(self)
end

function Staff:onLeaveStaffRoom(room)
    self.current_task = nil
    room:staffLeft(self)
end
```

---

## 3. Salary Progression System

### 3.1 Base Salary Calculation (hospital.lua:1207-1279)

```lua
-- Hospital salary management
Hospital = {
    -- Base salaries by staff type and level
    base_salaries = {
        doctor = {
            [1] = 800, [2] = 1000, [3] = 1250, [4] = 1550, [5] = 1900,
            [6] = 2300, [7] = 2750, [8] = 3250, [9] = 3800, [10] = 4400
        },
        nurse = {
            [1] = 500, [2] = 620, [3] = 770, [4] = 950, [5] = 1150,
            [6] = 1380, [7] = 1650, [8] = 1950, [9] = 2300, [10] = 2700
        },
        handyman = {
            [1] = 400, [2] = 480, [3] = 570, [4] = 680, [5] = 800,
            [6] = 930, [7] = 1080, [8] = 1250, [9] = 1450, [10] = 1650
        },
        receptionist = {
            [1] = 450, [2] = 540, [3] = 640, [4] = 760, [5] = 900,
            [6] = 1050, [7] = 1220, [8] = 1420, [9] = 1650, [10] = 1900
        }
    },
    
    -- Salary increase triggers
    salary_increase_triggers = {
        level_up = 0.15,           -- 15% increase on level up
        skill_mastery = 0.05,      -- 5% per mastered skill (90+)
        yearly_review = 0.03,      -- 3% annual review
        performance_bonus = 0.10,  -- 10% for exceptional performance
        retention_bonus = 0.02     -- 2% per year of service
    }
}

-- Calculate current salary
function Hospital:calculateSalary(staff)
    local base = self.base_salaries[staff.staff_type][staff.level]
    
    -- Skill bonuses
    local skill_bonus = 0
    for skill, value in pairs(staff.skills) do
        if value >= 90 then
            skill_bonus = skill_bonus + base * self.salary_increase_triggers.skill_mastery
        elseif value >= 70 then
            skill_bonus = skill_bonus + base * self.salary_increase_triggers.skill_mastery * 0.5
        end
    end
    
    -- Tenure bonus
    local years_employed = (game.time - staff.hire_date) / YEAR_LENGTH
    local tenure_bonus = base * self.salary_increase_triggers.retention_bonus * years_employed
    
    -- Performance bonus
    local performance_bonus = 0
    if staff.performance_rating > 90 then
        performance_bonus = base * self.salary_increase_triggers.performance_bonus
    elseif staff.performance_rating > 75 then
        performance_bonus = base * self.salary_increase_triggers.performance_bonus * 0.5
    end
    
    return math.floor(base + skill_bonus + tenure_bonus + performance_bonus)
end

-- Annual salary review (called yearly)
function Hospital:conductSalaryReviews()
    for _, staff in ipairs(self.staff) do
        local new_salary = self:calculateSalary(staff)
        local increase = new_salary - staff.salary
        
        if increase > 0 then
            staff.salary = new_salary
            staff:notifySalaryIncrease(increase)
            
            -- Happiness boost from raise
            staff.happiness = math.min(100, staff.happiness + 10)
        end
    end
end
```

### 3.2 Salary Negotiation & Market Rates

```lua
-- Market rate calculation for salary satisfaction
function Staff:getMarketSalary()
    local base = Hospital.base_salaries[self.staff_type][self.level]
    
    -- Adjust for skills
    local skill_factor = 1.0
    for _, value in pairs(self.skills) do
        skill_factor = skill_factor + (value / 100) * 0.1
    end
    
    -- Adjust for reputation
    local reputation_factor = 1.0 + (self.hospital.reputation / 1000) * 0.2
    
    -- Regional adjustment (scenario-based)
    local regional_factor = self.hospital.scenario.salary_multiplier or 1.0
    
    return base * skill_factor * reputation_factor * regional_factor
end
```

---

## 4. Skill Training System

### 4.1 Training Mechanics (staff.lua, training.lua)

```lua
-- Training initiation
function Staff:startTraining(skill_name, training_room)
    if self.is_training then return false end
    if not self:canTrainSkill(skill_name) then return false end
    
    -- Check if skill is primary for this staff type
    local is_primary = false
    for _, primary in ipairs(self.primary_skills) do
        if primary == skill_name then is_primary = true end
    end
    
    -- Primary skills train faster
    local speed_modifier = is_primary and 1.5 or 1.0
    
    self.is_training = true
    self.training_room = training_room
    self.training_skill = skill_name
    self.training_progress = 0
    self.training_speed_modifier = speed_modifier
    
    -- Assign to training room
    training_room:assignTrainee(self, skill_name)
    
    return true
end

-- Training update (called each tick)
function Staff:updateTraining(dt)
    if not self.is_training then return end
    
    -- Get training factor from room (logarithmic scaling - see Section 6)
    local training_factor = self.training_room:getTrainingFactor(self.training_skill)
    
    -- Calculate progress
    local base_rate = TRAINING_BASE_RATE  -- e.g., 0.1 skill points per second
    local skill_level = self.skills[self.training_skill]
    
    -- Diminishing returns at higher skill levels
    local difficulty_factor = 1 / (1 + skill_level * 0.02)
    
    local progress = base_rate * training_factor * self.training_speed_modifier * difficulty_factor * dt
    
    self.training_progress = self.training_progress + progress
    self.skills[self.training_skill] = math.min(100, self.skills[self.training_skill] + progress)
    
    -- Check completion
    if self.skills[self.training_skill] >= 100 or self.training_progress >= TRAINING_SESSION_MAX then
        self:completeTraining()
    end
    
    -- Fatigue still accumulates during training (at reduced rate)
    self.fatigue = math.min(100, self.fatigue + FATIGUE_TRAINING_RATE * dt)
end

function Staff:completeTraining()
    self.is_training = false
    self.training_room:releaseTrainee(self)
    self.training_room = nil
    self.training_skill = nil
    self.training_progress = 0
    
    -- Grant experience
    self:gainExperience(EXPERIENCE_TRAINING_COMPLETE)
    
    -- Check for level up
    self:checkLevelUp()
end

function Staff:canTrainSkill(skill_name)
    -- Check prerequisites
    local prerequisites = SKILL_PREREQUISITES[skill_name] or {}
    for _, prereq in ipairs(prerequisites) do
        if self.skills[prereq] < 30 then return false end
    end
    
    -- Check if already maxed
    if self.skills[skill_name] >= 100 then return false end
    
    -- Check training room availability
    local room = self.hospital:getTrainingRoomForSkill(skill_name)
    return room ~= nil
end
```

### 4.2 Skill Prerequisites & Dependencies

```lua
SKILL_PREREQUISITES = {
    surgery = {"diagnosis", "treatment"},
    research = {"diagnosis"},
    pharmacy = {"treatment"},
    administration = {"reception"}
}

-- Skill synergy bonuses
SKILL_SYNERGIES = {
    doctor = {
        {skills = {"diagnosis", "treatment"}, bonus = 0.1},      -- 10% faster training
        {skills = {"surgery", "treatment"}, bonus = 0.15}
    },
    nurse = {
        {skills = {"nursing", "pharmacy"}, bonus = 0.1}
    },
    handyman = {
        {skills = {"maintenance", "gardening"}, bonus = 0.05}
    }
}
```

---

## 5. Handyman Tasks

### 5.1 Task Types & Priorities

```lua
-- Handyman task queue (handyman.lua)
Handyman.task_types = {
    -- Critical priority (interrupts current task)
    EMERGENCY_REPAIR = {priority = 100, max_distance = 50},
    
    -- High priority
    MACHINE_REPAIR = {priority = 80, max_distance = 40},
    RADIATOR_REPAIR = {priority = 75, max_distance = 40},
    
    -- Medium priority
    PLANT_WATERING = {priority = 50, max_distance = 60},
    ITEM_TRANSPORT = {priority = 45, max_distance = 100},
    ROOM_CLEANING = {priority = 40, max_distance = 50},
    
    -- Low priority
    ROUTINE_MAINTENANCE = {priority = 20, max_distance = 30},
    PLANT_PRUNING = {priority = 15, max_distance = 60}
}

function Handyman:selectNextTask()
    local tasks = self:hospital:getAvailableHandymanTasks()
    
    -- Sort by priority and distance
    table.sort(tasks, function(a, b)
        local score_a = a.priority - self:distanceTo(a.location) * 0.5
        local score_b = b.priority - self:distanceTo(b.location) * 0.5
        return score_a > score_b
    end)
    
    -- Check if we can interrupt current task
    if self.current_task and tasks[1] then
        if tasks[1].priority > self.current_task.priority + 20 then
            self:interruptCurrentTask()
        end
    end
    
    if tasks[1] then
        self:assignTask(tasks[1])
    end
end
```

### 5.2 Repair Mechanics

```lua
function Handyman:performRepair(target, dt)
    local repair_speed = self.skills.maintenance / 100 * REPAIR_BASE_SPEED
    local quality_factor = self.skills.maintenance / 100
    
    -- Room condition modifier
    if target.room then
        repair_speed = repair_speed * target.room:getConditionModifier()
    end
    
    -- Tool bonus (if implemented)
    if self.has_toolkit then
        repair_speed = repair_speed * 1.25
        quality_factor = quality_factor * 1.1
    end
    
    target.condition = math.min(100, target.condition + repair_speed * dt)
    
    -- Quality affects breakdown probability
    target.repair_quality = quality_factor
    
    if target.condition >= 100 then
        target:onRepairComplete(quality_factor)
        self:completeTask()
    end
end

-- Machine breakdown probability based on repair quality
function Machine:calculateBreakdownChance()
    local base_chance = 0.001  -- Per tick
    local quality_penalty = (1 - self.last_repair_quality) * 0.01
    local age_factor = self.age * 0.0001
    
    return base_chance + quality_penalty + age_factor
end
```

### 5.3 Plant Care

```lua
function Handyman:waterPlants(plant_list, dt)
    for _, plant in ipairs(plant_list) do
        if plant.needs_water and self:canReach(plant) then
            local care_quality = self.skills.gardening / 100
            
            plant.water_level = math.min(100, plant.water_level + WATER_RATE * care_quality * dt)
            plant.health = math.min(100, plant.health + care_quality * PLANT_HEALTH_GAIN * dt)
            
            -- Aesthetic bonus affects hospital reputation
            if plant.health > 80 then
                self.hospital:addReputation(REPUTATION_PLANT_BONUS)
            end
            
            if plant.water_level >= 100 then
                plant.needs_water = false
            end
        end
    end
end
```

---

## 6. Receptionist Special Behavior

### 6.1 Patient Check-In & Queue Management

```lua
-- Receptionist queue management (receptionist.lua)
function Receptionist:update(dt)
    -- Process waiting patients
    self:processQueue(dt)
    
    -- Handle phone calls
    self:handlePhoneCalls(dt)
    
    -- Manage appointments
    self:manageAppointments(dt)
    
    -- Update display boards
    self:updateDisplays()
end

function Receptionist:processQueue(dt)
    local checkin_speed = self.skills.reception / 100 * CHECKIN_BASE_SPEED
    
    for _, patient in ipairs(self.waiting_patients) do
        if patient.checkin_progress >= 100 then
            self:completeCheckIn(patient)
        else
            patient.checkin_progress = patient.checkin_progress + checkin_speed * dt
        end
    end
    
    -- Prioritize queue
    self:prioritizeQueue()
end

function Receptionist:prioritizeQueue()
    table.sort(self.waiting_patients, function(a, b)
        -- Emergency patients first
        if a.is_emergency ~= b.is_emergency then
            return a.is_emergency
        end
        
        -- Then by appointment time
        if a.appointment_time and b.appointment_time then
            return a.appointment_time < b.appointment_time
        elseif a.appointment_time then
            return true
        elseif b.appointment_time then
            return false
        end
        
        -- Then by severity
        if a.severity ~= b.severity then
            return a.severity > b.severity
        end
        
        -- Then by arrival time
        return a.arrival_time < b.arrival_time
    end)
end

function Receptionist:completeCheckIn(patient)
    patient.status = "waiting_for_doctor"
    patient.checkin_time = game.time
    
    -- Assign to appropriate department
    local dept = self:determineDepartment(patient)
    patient.assigned_department = dept
    
    -- Notify department
    dept:patientArrived(patient)
    
    -- Remove from queue
    table.remove(self.waiting_patients, 1)
    
    -- Gain experience
    self:gainExperience(EXPERIENCE_CHECKIN)
end
```

### 6.2 Phone Call Handling

```lua
function Receptionist:handlePhoneCalls(dt)
    self.phone_timer = self.phone_timer - dt
    
    if self.phone_timer <= 0 then
        -- Random chance of incoming call
        if math.random() < PHONE_CALL_CHANCE then
            local call_type = self:generateCallType()
            self:processCall(call_type)
        end
        
        self.phone_timer = PHONE_CALL_INTERVAL + math.random() * PHONE_CALL_VARIANCE
    end
end

function Receptionist:processCall(call_type)
    if call_type == "appointment" then
        self:bookAppointment()
    elseif call_type == "cancellation" then
        self:cancelAppointment()
    elseif call_type == "emergency" then
        self:handleEmergencyCall()
    elseif call_type == "enquiry" then
        self:handleEnquiry()
    end
    
    self:gainExperience(EXPERIENCE_PHONE)
end
```

---

## 7. Training Room Factor Calculation (Logarithmic Scaling)

### 7.1 Core Formula (training.lua:74-199)

```lua
-- Training room implementation
TrainingRoom = Room:new()

-- Equipment contributes to training factor with logarithmic diminishing returns
function TrainingRoom:calculateTrainingFactor(skill_name)
    local factor = 1.0  -- Base factor
    
    -- Get relevant equipment for this skill
    local equipment = self:getEquipmentForSkill(skill_name)
    
    for _, item in ipairs(equipment) do
        if item.condition > 0 then
            -- Logarithmic scaling: factor = 1 + log(1 + quality * condition/100)
            -- This provides diminishing returns for high-quality equipment
            local quality = item.training_quality or 1.0  -- 0.5 to 2.0
            local condition_factor = item.condition / 100
            
            -- Logarithmic formula: ln(1 + x) where x = quality * condition
            local equipment_factor = math.log(1 + quality * condition_factor)
            
            -- Cap individual equipment contribution
            equipment_factor = math.min(equipment_factor, MAX_EQUIPMENT_FACTOR)
            
            factor = factor + equipment_factor
        end
    end
    
    -- Room level bonus (logarithmic)
    local level_bonus = math.log(1 + self.level * 0.5)
    factor = factor + level_bonus
    
    -- Staff trainer bonus (if a skilled staff member is assigned as trainer)
    if self.assigned_trainer then
        local trainer_skill = self.assigned_trainer.skills[skill_name] or 0
        local trainer_bonus = math.log(1 + trainer_skill / 50) * TRAINER_MULTIPLIER
        factor = factor + trainer_bonus
    end
    
    -- Cap total factor
    return math.min(factor, MAX_TRAINING_FACTOR)
end

-- Example: Equipment quality impact
-- Quality 1.0, Condition 100%: ln(1 + 1.0) = 0.693
-- Quality 1.5, Condition 100%: ln(1 + 1.5) = 0.916
-- Quality 2.0, Condition 100%: ln(1 + 2.0) = 1.099
-- Quality 2.0, Condition 50%:  ln(1 + 1.0) = 0.693

-- Multiple equipment: factors add up but with diminishing returns per item
-- 3x Quality 1.0 items: 3 * 0.693 = 2.079 (before cap)
```

### 7.2 Equipment Configuration

```lua
-- Training equipment definitions (from training.lua)
TrainingRoom.equipment_types = {
    -- Doctor training
    medical_textbook = {
        skills = {"diagnosis", "treatment", "research"},
        quality = 1.0,
        cost = 5000,
        size = {1, 1}
    },
    anatomy_model = {
        skills = {"diagnosis", "surgery"},
        quality = 1.2,
        cost = 8000,
        size = {2, 1}
    },
    surgery_simulator = {
        skills = {"surgery"},
        quality = 2.0,
        cost = 50000,
        size = {3, 3}
    },
    research_terminal = {
        skills = {"research"},
        quality = 1.5,
        cost = 20000,
        size = {2, 2}
    },
    
    -- Nurse training
    nursing_manual = {
        skills = {"nursing", "treatment"},
        quality = 1.0,
        cost = 3000,
        size = {1, 1}
    },
    pharmacy_station = {
        skills = {"pharmacy"},
        quality = 1.3,
        cost = 15000,
        size = {2, 2}
    },
    
    -- Handyman training
    tool_bench = {
        skills = {"maintenance"},
        quality = 1.2,
        cost = 10000,
        size = {2, 1}
    },
    gardening_guide = {
        skills = {"gardening"},
        quality = 0.8,
        cost = 2000,
        size = {1, 1}
    },
    
    -- Receptionist training
    reception_manual = {
        skills = {"reception", "administration"},
        quality = 1.0,
        cost = 3000,
        size = {1, 1}
    },
    computer_terminal = {
        skills = {"administration"},
        quality = 1.4,
        cost = 8000,
        size = {1, 1}
    }
}
```

### 7.3 commandEnteringStaff Handler (training.lua:74-199)

```lua
-- Called when staff enters training room
function TrainingRoom:commandEnteringStaff(staff)
    if not staff.is_training then return end
    
    -- Verify this is the correct room for their training
    if staff.training_room ~= self then return end
    
    -- Find available training equipment
    local equipment = self:getAvailableEquipment(staff.training_skill)
    
    if #equipment > 0 then
        -- Assign to best available equipment
        local best = equipment[1]
        staff.training_equipment = best
        best:assignUser(staff)
        
        -- Start training animation
        staff:playAnimation("train_" .. staff.training_skill)
    else
        -- Wait for equipment
        staff:waitForEquipment()
    end
    
    -- Register in room
    self.current_trainees[staff.id] = staff
end

-- Called when staff leaves training room
function TrainingRoom:commandLeavingStaff(staff)
    if staff.training_equipment then
        staff.training_equipment:releaseUser(staff)
        staff.training_equipment = nil
    end
    
    self.current_trainees[staff.id] = nil
    
    -- If training was interrupted, save progress
    if staff.is_training then
        staff:pauseTraining()
    end
end

-- Periodic update for all trainees
function TrainingRoom:updateTraining(dt)
    for _, staff in pairs(self.current_trainees) do
        if staff.is_training then
            staff:updateTraining(dt)
        end
    end
end
```

---

## 8. Staff Profile System (staff_profile.lua:286 lines)

### 8.1 Profile Structure

```lua
-- Staff profile definitions
StaffProfile = {
    -- Unique identifier
    id = "doctor_general",
    
    -- Display
    name = "General Practitioner",
    description = "Diagnoses and treats common illnesses",
    portrait = "ui/portraits/doctor_general.png",
    
    -- Base stats
    base_skills = {
        diagnosis = 40,
        treatment = 35,
        surgery = 10,
        research = 15,
        nursing = 20,
        pharmacy = 10,
        maintenance = 5,
        gardening = 5,
        reception = 10,
        administration = 15
    },
    
    -- Skill caps by level (max skill at each level)
    skill_caps = {
        [1] = 40, [2] = 50, [3] = 60, [4] = 70, [5] = 80,
        [6] = 85, [7] = 90, [8] = 92, [9] = 95, [10] = 100
    },
    
    -- Experience curve
    experience_curve = {
        [1] = 0, [2] = 1000, [3] = 2500, [4] = 5000, [5] = 9000,
        [6] = 15000, [7] = 25000, [8] = 40000, [9] = 60000, [10] = 100000
    },
    
    -- Traits (affect behavior)
    traits = {
        "compassionate",     -- +happiness from patient recovery
        "workaholic",        -- -fatigue rate, -happiness if not working
        "perfectionist",     -- +quality, -speed
        "fast_learner",      -- +training speed
        "green_thumb"        -- +gardening (handyman only)
    },
    
    -- Hiring cost
    hire_cost = 5000,
    
    -- Availability (scenario-dependent)
    available_in_scenarios = {"all"},
    
    -- Unlock requirements
    unlock_requirements = {
        reputation = 0,
        research = nil,
        year = 1
    }
}
```

### 8.2 Profile Loading & Application

```lua
function StaffProfile:applyToStaff(staff)
    -- Set base skills
    for skill, value in pairs(self.base_skills) do
        staff.skills[skill] = value
    end
    
    -- Apply traits
    staff.traits = self.traits
    
    -- Set hire cost
    staff.hire_cost = self.hire_cost
    
    -- Initialize experience
    staff.experience = 0
    staff.level = 1
end

function StaffProfile:getMaxSkillForLevel(level)
    return self.skill_caps[level] or 100
end

function StaffProfile:getExperienceForLevel(level)
    return self.experience_curve[level] or 100000
end
```

---

## 9. Complete Code Examples

### 9.1 Creating a New Doctor

```lua
-- Example: Hiring a new doctor
function Hospital:hireDoctor(profile_id)
    local profile = StaffProfiles[profile_id]
    if not profile then return nil end
    
    -- Check budget
    if self.money < profile.hire_cost then
        return nil, "Insufficient funds"
    end
    
    -- Create doctor entity
    local doctor = Doctor:new()
    profile:applyToDoctor(doctor)
    
    -- Set initial salary
    doctor.salary = self:calculateSalary(doctor)
    
    -- Assign to hospital
    doctor.hospital = self
    doctor.hire_date = game.time
    
    -- Deduct hiring cost
    self.money = self.money - profile.hire_cost
    
    -- Add to staff list
    table.insert(self.staff, doctor)
    
    -- Find available office
    local office = self:getAvailableRoom("office")
    if office then
        doctor:assignToRoom(office)
    else
        doctor:seekStaffRoom()
    end
    
    return doctor
end
```

### 9.2 Training Workflow

```lua
-- Example: Sending doctor to training
function Hospital:sendToTraining(staff, skill_name)
    -- Find training room
    local training_room = self:getTrainingRoomForSkill(skill_name)
    if not training_room then
        return false, "No training room available for " .. skill_name
    end
    
    -- Check if staff can train
    if not staff:canTrainSkill(skill_name) then
        return false, "Cannot train " .. skill_name
    end
    
    -- Start training
    local success = staff:startTraining(skill_name, training_room)
    if not success then
        return false, "Training failed to start"
    end
    
    -- Navigate to training room
    staff:navigateTo(training_room)
    
    return true
end

-- Automatic training assignment (AI)
function Hospital:autoAssignTraining()
    for _, staff in ipairs(self.staff) do
        if not staff.is_training and not staff.needs_break then
            -- Find lowest primary skill
            local lowest_skill = nil
            local lowest_value = 100
            
            for _, skill in ipairs(staff.primary_skills) do
                if staff.skills[skill] < lowest_value then
                    lowest_value = staff.skills[skill]
                    lowest_skill = skill
                end
            end
            
            -- Train if skill is below threshold
            if lowest_skill and lowest_value < 60 then
                self:sendToTraining(staff, lowest_skill)
            end
        end
    end
end
```

### 9.3 Salary Review Process

```lua
-- Example: Monthly salary processing
function Hospital:processMonthlySalaries()
    local total_paid = 0
    
    for _, staff in ipairs(self.staff) do
        -- Pay salary
        if self.money >= staff.salary then
            self.money = self.money - staff.salary
            total_paid = total_paid + staff.salary
            
            -- Happiness from being paid on time
            staff.happiness = math.min(100, staff.happiness + 2)
        else
            -- Can't pay - severe happiness penalty
            staff.happiness = math.max(0, staff.happiness - 20)
            staff:notifyUnpaidSalary()
        end
    end
    
    -- Log expenses
    self.finances:recordExpense("salaries", total_paid)
    
    return total_paid
end

-- Annual review
function Hospital:annualReview()
    for _, staff in ipairs(self.staff) do
        -- Calculate performance
        staff.performance_rating = self:calculatePerformance(staff)
        
        -- Salary review
        local old_salary = staff.salary
        staff.salary = self:calculateSalary(staff)
        
        -- Notify
        if staff.salary > old_salary then
            staff:notifyRaise(staff.salary - old_salary)
        end
        
        -- Level up check
        staff:checkLevelUp()
    end
end
```

---

## 10. Integration Points

### 10.1 Hospital Integration (hospital.lua)

```lua
-- Staff management in Hospital class
Hospital = {
    staff = {},
    staff_rooms = {},
    training_rooms = {},
    
    -- Staff iteration
    getAllStaff = function(self) return self.staff end,
    getStaffByType = function(self, type)
        local result = {}
        for _, s in ipairs(self.staff) do
            if s.staff_type == type then table.insert(result, s) end
        end
        return result
    end,
    
    -- Room queries
    getAvailableRoom = function(self, room_type)
        for _, room in ipairs(self.rooms[room_type] or {}) do
            if room:hasCapacity() then return room end
        end
        return nil
    end,
    
    getTrainingRoomForSkill = function(self, skill)
        for _, room in ipairs(self.training_rooms) do
            if room:supportsSkill(skill) and room:hasCapacity() then
                return room
            end
        end
        return nil
    end
}
```

### 10.2 Save/Load Serialization

```lua
-- Staff serialization for save games
function Staff:serialize()
    return {
        -- Identity
        staff_type = self.staff_type,
        name = self.name,
        character = self.character,
        
        -- Skills
        skills = self.skills,
        
        -- State
        fatigue = self.fatigue,
        happiness = self.happiness,
        salary = self.salary,
        experience = self.experience,
        level = self.level,
        
        -- Employment
        hire_date = self.hire_date,
        contract_type = self.contract_type,
        
        -- Training
        is_training = self.is_training,
        training_skill = self.training_skill,
        training_progress = self.training_progress,
        
        -- Current assignment
        current_room_id = self.current_room and self.current_room.id or nil,
        current_task = self.current_task
    }
end

function Staff:deserialize(data, hospital)
    -- Restore basic properties
    for k, v in pairs(data) do
        self[k] = v
    end
    
    -- Restore room reference
    if data.current_room_id then
        self.current_room = hospital:getRoomById(data.current_room_id)
    end
    
    -- Restore training room reference
    if data.training_room_id then
        self.training_room = hospital:getRoomById(data.training_room_id)
    end
end
```

---

## 11. Key Constants & Configuration

```lua
-- Global constants (typically in constants.lua or staff.lua)
STAFF_CONSTANTS = {
    -- Fatigue
    FATIGUE_BREAK_THRESHOLD = 70,
    FATIGUE_CRITICAL_THRESHOLD = 90,
    FATIGUE_RECOVERY_RATE = 5,        -- Per second in staff room
    FATIGUE_TRAINING_RATE = 0.3,      -- Per second during training
    STAFF_ROOM_RECOVERY_MULTIPLIER = 2.0,
    
    -- Happiness
    RESIGNATION_THRESHOLD = 15,
    HAPPINESS_DECAY_BASE = 0.1,
    
    -- Training
    TRAINING_BASE_RATE = 0.1,         -- Skill points per second
    TRAINING_SESSION_MAX = 20,        -- Max skill points per session
    MAX_TRAINING_FACTOR = 5.0,
    MAX_EQUIPMENT_FACTOR = 1.5,
    TRAINER_MULTIPLIER = 0.5,
    EXPERIENCE_TRAINING_COMPLETE = 100,
    
    -- Salary
    YEAR_LENGTH = 12 * 30 * 24 * 60 * 60,  -- Game seconds per year
    
    -- Handyman
    REPAIR_BASE_SPEED = 10,           -- Condition points per second
    WATER_RATE = 5,                   -- Water level per second
    PLANT_HEALTH_GAIN = 0.5,
    
    -- Receptionist
    CHECKIN_BASE_SPEED = 20,          -- Progress per second
    PHONE_CALL_CHANCE = 0.1,
    PHONE_CALL_INTERVAL = 60,
    PHONE_CALL_VARIANCE = 30,
    
    -- Experience
    EXPERIENCE_CHECKIN = 5,
    EXPERIENCE_PHONE = 2,
    EXPERIENCE_TREATMENT = 10,
    EXPERIENCE_DIAGNOSIS = 15,
    EXPERIENCE_SURGERY = 50,
    EXPERIENCE_REPAIR = 8
}
```

---

## 12. Performance Considerations

### 12.1 Optimization Strategies

1. **Staff Update Culling**: Only update staff in loaded areas
2. **Task Queue Batching**: Process handyman tasks in batches
3. **Training Factor Caching**: Cache training factor until equipment changes
4. **Skill Lookup Tables**: Pre-compute skill caps and experience curves
5. **Distance Caching**: Cache room-to-room distances for pathfinding

### 12.2 Memory Management

```lua
-- Object pooling for staff tasks
StaffTaskPool = {
    pool = {},
    
    acquire = function(self, task_type, data)
        local task = table.remove(self.pool)
        if not task then task = {} end
        task.type = task_type
        task.data = data
        task.start_time = game.time
        return task
    end,
    
    release = function(self, task)
        task.data = nil
        table.insert(self.pool, task)
    end
}
```

---

## 13. Testing Scenarios

### 13.1 Critical Test Cases

1. **Fatigue Management**
   - Staff reaches break threshold → seeks staff room
   - Staff room at capacity → staff waits or wanders
   - Critical fatigue → forced break, happiness penalty

2. **Salary Progression**
   - Level up triggers 15% salary increase
   - Skill mastery (90+) adds 5% per skill
   - Annual review applies all bonuses
   - Unpaid salary causes happiness crash

3. **Skill Training**
   - Primary skills train 50% faster
   - Logarithmic equipment scaling verified
   - Training interrupted by emergency → progress saved
   - Max skill (100) prevents further training

4. **Handyman Tasks**
   - Emergency repair interrupts routine maintenance
   - Repair quality affects future breakdown chance
   - Plant care affects hospital reputation

5. **Receptionist Behavior**
   - Queue prioritization: emergency > appointment > severity > arrival
   - Phone calls generate appointments/cancellations
   - Check-in speed scales with reception skill

---

## 14. File Reference Map

| File | Key Functions | Lines |
|------|--------------|-------|
| `entities/humanoids/staff.lua` | Base Staff class, fatigue, happiness, training, serialization | 1-775 |
| `entities/humanoids/staff/doctor.lua` | Doctor specialization, diagnosis, surgery, research | 1-200 |
| `entities/humanoids/staff/nurse.lua` | Nurse specialization, patient care, pharmacy | 1-180 |
| `entities/humanoids/staff/handyman.lua` | Handyman tasks, repair, plants, transport | 1-250 |
| `entities/humanoids/staff/receptionist.lua` | Receptionist, check-in, queue, phone | 1-220 |
| `rooms/training.lua` | Training room, factor calculation, commandEnteringStaff | 74-199 |
| `staff_profile.lua` | Staff profiles, skill caps, experience curves | 1-286 |
| `hospital.lua` | Salary calculation, hiring, annual review | 1207-1279 |

---

*End of Summary Document*


## Related Pages

- [[05-staff-training/CHECKLIST]]
- [[05-staff-training/MAP]]
- [[05-staff-training/SCAFFOLD]]
