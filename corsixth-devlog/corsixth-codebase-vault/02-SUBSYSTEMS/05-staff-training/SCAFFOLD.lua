-- Staff Training Area - Busted Test Scaffold
-- Tests for: fatigue, salary, skill progression, training, handyman tasks, receptionist

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local setup = busted.setup
local teardown = busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local mock = require("luassert.mock")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

-- Mock Hospital
local function createMockHospital()
    local hospital = {
        money = 100000,
        reputation = 500,
        staff = {},
        rooms = {
            office = {},
            staff_room = {},
            training = {},
            reception = {},
            ward = {},
            pharmacy = {},
            surgery = {},
            research = {}
        },
        finances = {
            recordExpense = spy.new(function() end)
        },
        scenario = {
            salary_multiplier = 1.0
        },
        
        -- Methods
        getAvailableRoom = function(self, room_type)
            if #self.rooms[room_type] > 0 then
                return self.rooms[room_type][1]
            end
            return nil
        end,
        
        getTrainingRoomForSkill = function(self, skill)
            for _, room in ipairs(self.rooms.training) do
                if room:supportsSkill(skill) and room:hasCapacity() then
                    return room
                end
            end
            return nil
        end,
        
        calculateSalary = function(self, staff)
            -- Simplified for testing
            local base = 500
            return base + (staff.level - 1) * 100
        end,
        
        conductSalaryReviews = spy.new(function() end),
        processMonthlySalaries = spy.new(function() end),
        annualReview = spy.new(function() end)
    }
    return hospital
end

-- Mock Room
local function createMockRoom(room_type, overrides)
    local room = {
        id = room_type .. "_" .. math.random(1000),
        type = room_type,
        capacity = 4,
        current_occupancy = 0,
        level = 1,
        quality = 50,
        condition = 100,
        equipment = {},
        trainees = {},
        
        hasCapacity = function(self) return self.current_occupancy < self.capacity end,
        isAccessible = function(self, staff) return true end,
        getQuality = function(self) return self.quality end,
        getConditionModifier = function(self) return self.condition / 100 end,
        getFatigueModifier = function(self) return 1.0 end,
        supportsSkill = function(self, skill) return true end,
        staffEntered = spy.new(function() end),
        staffLeft = spy.new(function() end),
        assignTrainee = spy.new(function() end),
        releaseTrainee = spy.new(function() end),
        getAvailableEquipment = function(self, skill) return {} end,
        getTrainingFactor = function(self, skill) return 1.0 end,
        updateTraining = spy.new(function() end),
        navigateTo = spy.new(function() end)
    }
    
    if overrides then
        for k, v in pairs(overrides) do
            room[k] = v
        end
    end
    
    return room
end

-- Mock Staff (base)
local function createMockStaff(staff_type, overrides)
    local staff = {
        id = staff_type .. "_" .. math.random(1000),
        staff_type = staff_type,
        name = "Test " .. staff_type,
        character = staff_type .. "_1",
        hospital = createMockHospital(),
        
        -- Skills
        skills = {
            diagnosis = 50,
            treatment = 50,
            surgery = 50,
            research = 50,
            nursing = 50,
            pharmacy = 50,
            maintenance = 50,
            gardening = 50,
            reception = 50,
            administration = 50
        },
        
        -- State
        fatigue = 0,
        happiness = 100,
        salary = 500,
        experience = 0,
        level = 1,
        hire_date = 0,
        contract_type = "permanent",
        current_room = nil,
        current_task = nil,
        
        -- Training
        is_training = false,
        training_room = nil,
        training_skill = nil,
        training_progress = 0,
        training_speed_modifier = 1.0,
        training_equipment = nil,
        
        -- Behavior
        needs_break = false,
        break_timer = 0,
        seeking_staff_room = false,
        target_staff_room = nil,
        
        -- Traits
        traits = {},
        
        -- Primary skills by type
        primary_skills = {},
        required_rooms = {},
        patient_interaction = false,
        
        -- Methods (to be overridden)
        getFatigueRate = function(self) return 0.5 end,
        updateFatigue = spy.new(function(self, dt) end),
        updateHappiness = spy.new(function(self, dt) end),
        seekStaffRoom = spy.new(function(self) end),
        onEnterStaffRoom = spy.new(function(self, room) end),
        onLeaveStaffRoom = spy.new(function(self, room) end),
        canTrainSkill = function(self, skill) return true end,
        startTraining = spy.new(function(self, skill, room) 
            self.is_training = true
            self.training_skill = skill
            self.training_room = room
            return true 
        end),
        updateTraining = spy.new(function(self, dt) end),
        completeTraining = spy.new(function(self) 
            self.is_training = false 
        end),
        pauseTraining = spy.new(function(self) end),
        gainExperience = spy.new(function(self, amount) 
            self.experience = self.experience + amount 
        end),
        checkLevelUp = spy.new(function(self) end),
        notifySalaryIncrease = spy.new(function(self, amount) end),
        notifyUnpaidSalary = spy.new(function(self) end),
        notifyRaise = spy.new(function(self, amount) end),
        assignToRoom = spy.new(function(self, room) 
            self.current_room = room 
        end),
        navigateTo = spy.new(function(self, room) end),
        distanceTo = function(self, location) return 10 end,
        serialize = function(self) return {} end,
        deserialize = function(self, data) end,
        getAverageSkill = function(self) 
            local sum = 0
            local count = 0
            for _, v in pairs(self.skills) do
                sum = sum + v
                count = count + 1
            end
            return sum / count
        end,
        getMarketSalary = function(self) return self.salary * 1.1 end,
        calculatePerformance = function(self) return 75 end
    }
    
    -- Set type-specific primary skills
    if staff_type == "doctor" then
        staff.primary_skills = {"diagnosis", "treatment", "surgery", "research"}
        staff.required_rooms = {"office", "surgery", "research"}
        staff.patient_interaction = true
    elseif staff_type == "nurse" then
        staff.primary_skills = {"treatment", "nursing", "pharmacy"}
        staff.required_rooms = {"ward", "pharmacy", "clinic"}
        staff.patient_interaction = true
    elseif staff_type == "handyman" then
        staff.primary_skills = {"maintenance", "gardening"}
        staff.required_rooms = {"staff_room", "maintenance"}
        staff.patient_interaction = false
    elseif staff_type == "receptionist" then
        staff.primary_skills = {"reception", "administration"}
        staff.required_rooms = {"reception"}
        staff.patient_interaction = true
    end
    
    if overrides then
        for k, v in pairs(overrides) do
            staff[k] = v
        end
    end
    
    return staff
end

-- Mock Doctor
local function createMockDoctor(overrides)
    local doctor = createMockStaff("doctor", overrides)
    doctor.diagnosePatient = spy.new(function(self, patient, room) end)
    doctor.performSurgery = spy.new(function(self, patient, room) end)
    return doctor
end

-- Mock Nurse
local function createMockNurse(overrides)
    local nurse = createMockStaff("nurse", overrides)
    nurse.careForPatient = spy.new(function(self, patient, room) end)
    nurse.dispenseMedication = spy.new(function(self, patient, room) end)
    return nurse
end

-- Mock Handyman
local function createMockHandyman(overrides)
    local handyman = createMockStaff("handyman", overrides)
    handyman.task_types = {
        EMERGENCY_REPAIR = {priority = 100},
        MACHINE_REPAIR = {priority = 80},
        PLANT_WATERING = {priority = 50},
        ITEM_TRANSPORT = {priority = 45}
    }
    handyman.current_task = nil
    handyman.performRepair = spy.new(function(self, target, dt) end)
    handyman.waterPlants = spy.new(function(self, plants, dt) end)
    handyman.selectNextTask = spy.new(function(self) end)
    handyman.assignTask = spy.new(function(self, task) 
        self.current_task = task 
    end)
    handyman.interruptCurrentTask = spy.new(function(self) end)
    handyman.completeTask = spy.new(function(self) 
        self.current_task = nil 
    end)
    handyman.canReach = function(self, target) return true end
    return handyman
end

-- Mock Receptionist
local function createMockReceptionist(overrides)
    local receptionist = createMockStaff("receptionist", overrides)
    receptionist.waiting_patients = {}
    receptionist.phone_timer = 0
    receptionist.processQueue = spy.new(function(self, dt) end)
    receptionist.handlePhoneCalls = spy.new(function(self, dt) end)
    receptionist.manageAppointments = spy.new(function(self, dt) end)
    receptionist.updateDisplays = spy.new(function(self) end)
    receptionist.prioritizeQueue = spy.new(function(self) end)
    receptionist.completeCheckIn = spy.new(function(self, patient) end)
    receptionist.determineDepartment = spy.new(function(self, patient) return {} end)
    receptionist.generateCallType = function(self) return "appointment" end
    receptionist.processCall = spy.new(function(self, call_type) end)
    receptionist.bookAppointment = spy.new(function(self) end)
    receptionist.cancelAppointment = spy.new(function(self) end)
    receptionist.handleEmergencyCall = spy.new(function(self) end)
    receptionist.handleEnquiry = spy.new(function(self) end)
    return receptionist
end

-- Mock Patient
local function createMockPatient(overrides)
    local patient = {
        id = "patient_" .. math.random(1000),
        name = "Patient " .. math.random(100),
        status = "arrived",
        severity = 50,
        is_emergency = false,
        appointment_time = nil,
        arrival_time = 0,
        checkin_progress = 0,
        assigned_department = nil,
        checkin_time = nil,
        queue_position = 0
    }
    if overrides then
        for k, v in pairs(overrides) do
            patient[k] = v
        end
    end
    return patient
end

-- Mock Equipment
local function createMockEquipment(overrides)
    local equipment = {
        id = "equip_" .. math.random(1000),
        condition = 100,
        training_quality = 1.0,
        assigned_user = nil,
        assignUser = spy.new(function(self, staff) 
            self.assigned_user = staff 
        end),
        releaseUser = spy.new(function(self, staff) 
            self.assigned_user = nil 
        end)
    }
    if overrides then
        for k, v in pairs(overrides) do
            equipment[k] = v
        end
    end
    return equipment
end

-- Mock Plant
local function createMockPlant(overrides)
    local plant = {
        id = "plant_" .. math.random(1000),
        water_level = 50,
        health = 80,
        needs_water = true
    }
    if overrides then
        for k, v in pairs(overrides) do
            plant[k] = v
        end
    end
    return plant
end

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Staff Training Area - Fatigue Management", function()
    local staff, hospital, staff_room
    
    before_each(function()
        hospital = createMockHospital()
        staff = createMockStaff("doctor")
        staff.hospital = hospital
        staff_room = createMockRoom("staff_room", {quality = 80})
        table.insert(hospital.rooms.staff_room, staff_room)
    end)
    
    it("should accumulate fatigue while working", function()
        staff.current_task = {type = "work"}
        staff.fatigue = 0
        
        staff:updateFatigue(10) -- 10 seconds
        
        assert.is_true(staff.fatigue > 0)
        assert.is_true(staff.fatigue <= 100)
    end)
    
    it("should recover fatigue in staff room", function()
        staff.fatigue = 80
        staff.current_room = staff_room
        staff.current_task = {type = "break", room = staff_room}
        
        staff:updateFatigue(10)
        
        assert.is_true(staff.fatigue < 80)
    end)
    
    it("should request break at fatigue threshold", function()
        staff.fatigue = 75 -- Above FATIGUE_BREAK_THRESHOLD (70)
        staff.needs_break = false
        
        staff:updateFatigue(1)
        
        assert.is_true(staff.needs_break)
        assert.spy(staff.seekStaffRoom).was_called()
    end)
    
    it("should force break at critical fatigue", function()
        staff.fatigue = 95 -- Above FATIGUE_CRITICAL_THRESHOLD (90)
        
        staff:updateFatigue(1)
        
        assert.is_true(staff.needs_break)
        -- Force break logic would be triggered
    end)
    
    it("should have different fatigue rates per staff type", function()
        local doctor = createMockDoctor()
        local nurse = createMockNurse()
        local handyman = createMockHandyman()
        local receptionist = createMockReceptionist()
        
        doctor.hospital = hospital
        nurse.hospital = hospital
        handyman.hospital = hospital
        receptionist.hospital = hospital
        
        -- Doctor should have highest base fatigue rate
        assert.is_true(doctor:getFatigueRate() >= nurse:getFatigueRate())
        assert.is_true(nurse:getFatigueRate() >= handyman:getFatigueRate())
        assert.is_true(handyman:getFatigueRate() >= receptionist:getFatigueRate())
    end)
    
    it("should reduce fatigue rate with higher skills", function()
        local novice = createMockDoctor({skills = {diagnosis = 10, treatment = 10, surgery = 10, research = 10}})
        local expert = createMockDoctor({skills = {diagnosis = 90, treatment = 90, surgery = 90, research = 90}})
        
        novice.hospital = hospital
        expert.hospital = hospital
        
        assert.is_true(novice:getFatigueRate() > expert:getFatigueRate())
    end)
end)

describe("Staff Training Area - Happiness Management", function()
    local staff, hospital
    
    before_each(function()
        hospital = createMockHospital()
        staff = createMockStaff("doctor")
        staff.hospital = hospital
    end)
    
    it("should increase happiness with good salary", function()
        staff.salary = 2000
        staff.getMarketSalary = function() return 1000 end -- 2x market rate
        
        local satisfaction = staff:getSalarySatisfaction()
        assert.is_true(satisfaction > 0)
    end)
    
    it("should decrease happiness with low salary", function()
        staff.salary = 500
        staff.getMarketSalary = function() return 1000 end -- 0.5x market rate
        
        local satisfaction = staff:getSalarySatisfaction()
        assert.is_true(satisfaction < 0)
    end)
    
    it("should penalize happiness for high fatigue", function()
        staff.fatigue = 80
        local penalty = staff:getFatiguePenalty()
        assert.is_true(penalty > 0)
    end)
    
    it("should not penalize happiness for low fatigue", function()
        staff.fatigue = 50
        local penalty = staff:getFatiguePenalty()
        assert.equals(0, penalty)
    end)
    
    it("should consider resignation at very low happiness", function()
        staff.happiness = 10 -- Below RESIGNATION_THRESHOLD (15)
        staff.considerResignation = spy.new(function() end)
        
        staff:updateHappiness(1)
        
        assert.spy(staff.considerResignation).was_called()
    end)
    
    it("should boost happiness from room quality", function()
        local good_room = createMockRoom("office", {quality = 90})
        local bad_room = createMockRoom("office", {quality = 20})
        
        staff.current_room = good_room
        local good_bonus = staff:getRoomQualityBonus()
        
        staff.current_room = bad_room
        local bad_bonus = staff:getRoomQualityBonus()
        
        assert.is_true(good_bonus > bad_bonus)
    end)
end)

describe("Staff Training Area - Salary Progression", function()
    local hospital, doctor
    
    before_each(function()
        hospital = createMockHospital()
        doctor = createMockDoctor({level = 3, hire_date = 0})
        doctor.hospital = hospital
        table.insert(hospital.staff, doctor)
    end)
    
    it("should calculate base salary by level", function()
        local salary = hospital:calculateSalary(doctor)
        -- Level 3 doctor base should be around 1250
        assert.is_true(salary >= 1200)
    end)
    
    it("should add skill mastery bonus", function()
        doctor.skills.diagnosis = 95
        doctor.skills.treatment = 92
        
        local salary = hospital:calculateSalary(doctor)
        local base_salary = 1250 -- Approximate level 3 base
        
        assert.is_true(salary > base_salary)
    end)
    
    it("should add tenure bonus", function()
        doctor.hire_date = - (5 * 365 * 24 * 60 * 60) -- 5 years ago
        
        local salary = hospital:calculateSalary(doctor)
        local base_salary = 1250
        
        assert.is_true(salary > base_salary)
    end)
    
    it("should add performance bonus for high rating", function()
        doctor.calculatePerformance = function() return 95 end
        
        local salary = hospital:calculateSalary(doctor)
        local base_salary = 1250
        
        assert.is_true(salary > base_salary)
    end)
    
    it("should increase salary on level up", function()
        doctor.level = 3
        local old_salary = hospital:calculateSalary(doctor)
        
        doctor.level = 4
        local new_salary = hospital:calculateSalary(doctor)
        
        -- Should be at least 15% increase
        assert.is_true(new_salary >= old_salary * 1.15)
    end)
    
    it("should conduct annual salary reviews", function()
        hospital:conductSalaryReviews()
        assert.spy(hospital.conductSalaryReviews).was_called()
    end)
    
    it("should process monthly salaries", function()
        hospital.money = 10000
        hospital:processMonthlySalaries()
        assert.spy(hospital.processMonthlySalaries).was_called()
    end)
end)

describe("Staff Training Area - Skill Progression", function()
    local staff, hospital
    
    before_each(function()
        hospital = createMockHospital()
        staff = createMockStaff("doctor")
        staff.hospital = hospital
    end)
    
    it("should track experience and level up", function()
        staff.experience = 900
        staff:gainExperience(200) -- Should reach level 2 (1000 XP)
        
        assert.equals(1100, staff.experience)
        assert.spy(staff.checkLevelUp).was_called()
    end)
    
    it("should have skill caps per level", function()
        local profile = {
            skill_caps = {
                [1] = 40, [2] = 50, [3] = 60, [4] = 70, [5] = 80
            }
        }
        
        assert.equals(40, profile.skill_caps[1])
        assert.equals(80, profile.skill_caps[5])
    end)
    
    it("should apply primary skill bonus", function()
        staff.primary_skills = {"diagnosis", "treatment"}
        staff.training_speed_modifier = 1.0
        
        local is_primary = false
        for _, s in ipairs(staff.primary_skills) do
            if s == "diagnosis" then is_primary = true end
        end
        
        assert.is_true(is_primary)
        
        -- Primary skills should get 1.5x modifier
        staff.training_speed_modifier = is_primary and 1.5 or 1.0
        assert.equals(1.5, staff.training_speed_modifier)
    end)
    
    it("should enforce skill prerequisites", function()
        local prerequisites = {
            surgery = {"diagnosis", "treatment"},
            research = {"diagnosis"}
        }
        
        staff.skills.diagnosis = 20
        staff.skills.treatment = 20
        
        local can_train = true
        for _, prereq in ipairs(prerequisites.surgery) do
            if staff.skills[prereq] < 30 then can_train = false end
        end
        
        assert.is_false(can_train)
        
        staff.skills.diagnosis = 40
        staff.skills.treatment = 40
        
        can_train = true
        for _, prereq in ipairs(prerequisites.surgery) do
            if staff.skills[prereq] < 30 then can_train = false end
        end
        
        assert.is_true(can_train)
    end)
end)

describe("Staff Training Area - Training System", function()
    local staff, hospital, training_room
    
    before_each(function()
        hospital = createMockHospital()
        staff = createMockStaff("doctor")
        staff.hospital = hospital
        training_room = createMockRoom("training", {
            getTrainingFactor = function(self, skill) return 2.0 end,
            assignTrainee = spy.new(function(self, staff, skill) end),
            releaseTrainee = spy.new(function(self, staff) end)
        })
        table.insert(hospital.rooms.training, training_room)
    end)
    
    it("should start training for valid skill", function()
        staff.skills.diagnosis = 50
        
        local success = staff:startTraining("diagnosis", training_room)
        
        assert.is_true(success)
        assert.is_true(staff.is_training)
        assert.equals("diagnosis", staff.training_skill)
        assert.spy(training_room.assignTrainee).was_called_with(training_room, staff, "diagnosis")
    end)
    
    it("should not start training if already training", function()
        staff.is_training = true
        
        local success = staff:startTraining("treatment", training_room)
        
        assert.is_false(success)
    end)
    
    it("should not train skill at maximum", function()
        staff.skills.diagnosis = 100
        
        local success = staff:startTraining("diagnosis", training_room)
        
        assert.is_false(success)
    end)
    
    it("should progress training over time", function()
        staff.is_training = true
        staff.training_skill = "diagnosis"
        staff.training_room = training_room
        staff.skills.diagnosis = 50
        staff.training_progress = 0
        
        -- Simulate training update
        local initial_skill = staff.skills.diagnosis
        staff:updateTraining(10) -- 10 seconds
        
        -- Skill should have increased
        assert.is_true(staff.skills.diagnosis >= initial_skill)
    end)
    
    it("should complete training at max skill", function()
        staff.is_training = true
        staff.training_skill = "diagnosis"
        staff.skills.diagnosis = 99.5
        
        staff:updateTraining(10)
        
        -- Should complete when reaching 100
        -- Note: actual completion depends on implementation
    end)
    
    it("should apply logarithmic training factor", function()
        -- Training factor calculation with logarithmic scaling
        local function calcTrainingFactor(quality, condition)
            return math.log(1 + quality * (condition / 100))
        end
        
        -- Quality 1.0, 100% condition
        local factor1 = calcTrainingFactor(1.0, 100)
        -- Quality 2.0, 100% condition  
        local factor2 = calcTrainingFactor(2.0, 100)
        -- Quality 2.0, 50% condition
        local factor3 = calcTrainingFactor(2.0, 50)
        
        -- Logarithmic: diminishing returns
        assert.is_true(factor2 > factor1)
        assert.is_true(factor3 < factor2)
        assert.is_true(factor3 == factor1) -- Same effective quality
    end)
    
    it("should accumulate fatigue during training", function()
        staff.is_training = true
        staff.fatigue = 20
        
        staff:updateTraining(60) -- 1 minute
        
        assert.is_true(staff.fatigue > 20)
    end)
    
    it("should grant experience on training completion", function()
        staff.is_training = true
        staff.training_skill = "diagnosis"
        staff.skills.diagnosis = 100
        
        staff:completeTraining()
        
        assert.spy(staff.gainExperience).was_called()
        assert.is_false(staff.is_training)
    end)
end)

describe("Staff Training Area - Handyman Tasks", function()
    local handyman, hospital
    
    before_each(function()
        hospital = createMockHospital()
        handyman = createMockHandyman()
        handyman.hospital = hospital
    end)
    
    it("should prioritize emergency repairs", function()
        local emergency = {type = "EMERGENCY_REPAIR", priority = 100, location = {}}
        local routine = {type = "ROUTINE_MAINTENANCE", priority = 20, location = {}}
        
        hospital.getAvailableHandymanTasks = function()
            return {routine, emergency}
        end
        
        handyman:selectNextTask()
        
        -- Should pick emergency (higher priority)
        assert.spy(handyman.assignTask).was_called()
        local assigned_task = handyman.assignTask.calls[1].vals[2]
        assert.equals("EMERGENCY_REPAIR", assigned_task.type)
    end)
    
    it("should interrupt current task for higher priority", function()
        handyman.current_task = {type = "ROUTINE_MAINTENANCE", priority = 20}
        
        local emergency = {type = "EMERGENCY_REPAIR", priority = 100, location = {}}
        hospital.getAvailableHandymanTasks = function() return {emergency} end
        
        handyman:selectNextTask()
        
        assert.spy(handyman.interruptCurrentTask).was_called()
    end)
    
    it("should not interrupt for slightly higher priority", function()
        handyman.current_task = {type = "MACHINE_REPAIR", priority = 80}
        
        local routine = {type = "PLANT_WATERING", priority = 50, location = {}}
        hospital.getAvailableHandymanTasks = function() return {routine} end
        
        handyman:selectNextTask()
        
        assert.spy(handyman.interruptCurrentTask).was_not_called()
    end)
    
    it("should repair machines based on maintenance skill", function()
        local machine = {condition = 50, room = createMockRoom("clinic")}
        handyman.skills.maintenance = 80
        
        handyman:performRepair(machine, 10)
        
        assert.spy(handyman.performRepair).was_called()
        -- Condition should improve based on skill
    end)
    
    it("should water plants based on gardening skill", function()
        local plants = {
            createMockPlant({needs_water = true, water_level = 20}),
            createMockPlant({needs_water = true, water_level = 30}),
            createMockPlant({needs_water = false, water_level = 80})
        }
        handyman.skills.gardening = 70
        
        handyman:waterPlants(plants, 10)
        
        assert.spy(handyman.waterPlants).was_called()
        -- First two plants should be watered, third skipped
    end)
    
    it("should affect breakdown chance with repair quality", function()
        local machine = {
            condition = 100,
            last_repair_quality = 0.9,
            age = 1000
        }
        
        local base_chance = 0.001
        local quality_penalty = (1 - machine.last_repair_quality) * 0.01
        local age_factor = machine.age * 0.0001
        local total_chance = base_chance + quality_penalty + age_factor
        
        -- High quality repair = low breakdown chance
        assert.is_true(total_chance < 0.02)
        
        -- Poor quality repair
        machine.last_repair_quality = 0.3
        quality_penalty = (1 - machine.last_repair_quality) * 0.01
        total_chance = base_chance + quality_penalty + age_factor
        
        assert.is_true(total_chance > 0.01)
    end)
end)

describe("Staff Training Area - Receptionist Behavior", function()
    local receptionist, hospital
    
    before_each(function()
        hospital = createMockHospital()
        receptionist = createMockReceptionist()
        receptionist.hospital = hospital
    end)
    
    it("should prioritize emergency patients first", function()
        local emergency = createMockPatient({is_emergency = true, severity = 80, arrival_time = 100})
        local routine = createMockPatient({is_emergency = false, severity = 30, arrival_time = 50})
        
        receptionist.waiting_patients = {routine, emergency}
        receptionist:prioritizeQueue()
        
        assert.equals(emergency, receptionist.waiting_patients[1])
    end)
    
    it("should prioritize appointments over walk-ins", function()
        local appointment = createMockPatient({is_emergency = false, appointment_time = 100, arrival_time = 100})
        local walkin = createMockPatient({is_emergency = false, appointment_time = nil, arrival_time = 50})
        
        receptionist.waiting_patients = {walkin, appointment}
        receptionist:prioritizeQueue()
        
        assert.equals(appointment, receptionist.waiting_patients[1])
    end)
    
    it("should prioritize by severity for same appointment status", function()
        local severe = createMockPatient({is_emergency = false, appointment_time = nil, severity = 80, arrival_time = 100})
        local mild = createMockPatient({is_emergency = false, appointment_time = nil, severity = 20, arrival_time = 50})
        
        receptionist.waiting_patients = {mild, severe}
        receptionist:prioritizeQueue()
        
        assert.equals(severe, receptionist.waiting_patients[1])
    end)
    
    it("should process check-in over time", function()
        local patient = createMockPatient({checkin_progress = 0})
        receptionist.waiting_patients = {patient}
        receptionist.skills.reception = 80
        
        receptionist:processQueue(5) -- 5 seconds
        
        assert.is_true(patient.checkin_progress > 0)
        assert.spy(receptionist.processQueue).was_called()
    end)
    
    it("should complete check-in and assign department", function()
        local patient = createMockPatient({checkin_progress = 100})
        receptionist.waiting_patients = {patient}
        receptionist.determineDepartment = function() return {name = "cardiology"} end
        
        receptionist:completeCheckIn(patient)
        
        assert.equals("waiting_for_doctor", patient.status)
        assert.is_not_nil(patient.checkin_time)
        assert.equals("cardiology", patient.assigned_department.name)
        assert.spy(receptionist.completeCheckIn).was_called()
    end)
    
    it("should handle phone calls periodically", function()
        receptionist.phone_timer = 0
        receptionist.generateCallType = function() return "appointment" end
        
        receptionist:handlePhoneCalls(1)
        
        assert.spy(receptionist.processCall).was_called()
        assert.is_true(receptionist.phone_timer > 0)
    end)
    
    it("should process different call types", function()
        receptionist:processCall("appointment")
        assert.spy(receptionist.bookAppointment).was_called()
        
        receptionist:processCall("cancellation")
        assert.spy(receptionist.cancelAppointment).was_called()
        
        receptionist:processCall("emergency")
        assert.spy(receptionist.handleEmergencyCall).was_called()
        
        receptionist:processCall("enquiry")
        assert.spy(receptionist.handleEnquiry).was_called()
    end)
    
    it("should gain experience from check-ins and calls", function()
        local patient = createMockPatient()
        receptionist:completeCheckIn(patient)
        assert.spy(receptionist.gainExperience).was_called_with(receptionist, 5) -- EXPERIENCE_CHECKIN
        
        receptionist:processCall("appointment")
        assert.spy(receptionist.gainExperience).was_called_with(receptionist, 2) -- EXPERIENCE_PHONE
    end)
end)

describe("Staff Training Area - Training Room Factor Calculation", function()
    local training_room
    
    before_each(function()
        training_room = createMockRoom("training", {
            level = 2,
            equipment = {},
            assigned_trainer = nil
        })
    end)
    
    it("should calculate base factor of 1.0", function()
        local factor = training_room:getTrainingFactor("diagnosis")
        assert.equals(1.0, factor)
    end)
    
    it("should apply logarithmic equipment scaling", function()
        -- Simulate the logarithmic formula
        local function equipmentFactor(quality, condition)
            return math.log(1 + quality * (condition / 100))
        end
        
        -- Test various equipment configurations
        local eq1 = equipmentFactor(1.0, 100) -- ln(2) ≈ 0.693
        local eq2 = equipmentFactor(1.5, 100) -- ln(2.5) ≈ 0.916
        local eq3 = equipmentFactor(2.0, 100) -- ln(3) ≈ 1.099
        local eq4 = equipmentFactor(2.0, 50)  -- ln(2) ≈ 0.693
        
        assert.is_true(eq2 > eq1)
        assert.is_true(eq3 > eq2)
        assert.equals(eq1, eq4)
    end)
    
    it("should cap individual equipment contribution", function()
        local MAX_EQUIPMENT_FACTOR = 1.5
        local factor = math.log(1 + 5.0 * 1.0) -- Very high quality
        factor = math.min(factor, MAX_EQUIPMENT_FACTOR)
        
        assert.equals(1.5, factor)
    end)
    
    it("should add room level bonus logarithmically", function()
        local level_bonus_1 = math.log(1 + 1 * 0.5) -- ln(1.5) ≈ 0.405
        local level_bonus_5 = math.log(1 + 5 * 0.5) -- ln(3.5) ≈ 1.253
        local level_bonus_10 = math.log(1 + 10 * 0.5) -- ln(6) ≈ 1.792
        
        assert.is_true(level_bonus_5 > level_bonus_1)
        assert.is_true(level_bonus_10 > level_bonus_5)
        -- Diminishing returns
        assert.is_true((level_bonus_10 - level_bonus_5) < (level_bonus_5 - level_bonus_1))
    end)
    
    it("should add trainer bonus based on trainer skill", function()
        local TRAINER_MULTIPLIER = 0.5
        
        local trainer_skill_50 = math.log(1 + 50 / 50) * TRAINER_MULTIPLIER -- ln(2) * 0.5 ≈ 0.347
        local trainer_skill_100 = math.log(1 + 100 / 50) * TRAINER_MULTIPLIER -- ln(3) * 0.5 ≈ 0.550
        
        assert.is_true(trainer_skill_100 > trainer_skill_50)
    end)
    
    it("should cap total training factor", function()
        local MAX_TRAINING_FACTOR = 5.0
        local total = 1.0 + 2.0 + 1.5 + 1.0 -- base + equipment + level + trainer
        total = math.min(total, MAX_TRAINING_FACTOR)
        
        assert.equals(5.0, total)
    end)
    
    it("should call commandEnteringStaff when staff enters", function()
        local staff = createMockStaff("doctor")
        staff.is_training = true
        staff.training_skill = "diagnosis"
        staff.training_room = training_room
        
        training_room.commandEnteringStaff = spy.new(function(self, staff) end)
        training_room:commandEnteringStaff(staff)
        
        assert.spy(training_room.commandEnteringStaff).was_called()
    end)
    
    it("should call commandLeavingStaff when staff leaves", function()
        local staff = createMockStaff("doctor")
        staff.training_equipment = createMockEquipment()
        training_room.current_trainees = {[staff.id] = staff}
        
        training_room.commandLeavingStaff = spy.new(function(self, staff) end)
        training_room:commandLeavingStaff(staff)
        
        assert.spy(training_room.commandLeavingStaff).was_called()
        assert.is_nil(training_room.current_trainees[staff.id])
    end)
end)

describe("Staff Training Area - Staff Profile System", function()
    local profile
    
    before_each(function()
        profile = {
            id = "doctor_general",
            name = "General Practitioner",
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
            skill_caps = {
                [1] = 40, [2] = 50, [3] = 60, [4] = 70, [5] = 80,
                [6] = 85, [7] = 90, [8] = 92, [9] = 95, [10] = 100
            },
            experience_curve = {
                [1] = 0, [2] = 1000, [3] = 2500, [4] = 5000, [5] = 9000,
                [6] = 15000, [7] = 25000, [8] = 40000, [9] = 60000, [10] = 100000
            },
            traits = {"compassionate", "workaholic"},
            hire_cost = 5000
        }
    end)
    
    it("should apply base skills to staff", function()
        local staff = createMockStaff("doctor")
        profile.applyToStaff = function(self, staff)
            for skill, value in pairs(self.base_skills) do
                staff.skills[skill] = value
            end
        end
        
        profile:applyToStaff(staff)
        
        assert.equals(40, staff.skills.diagnosis)
        assert.equals(10, staff.skills.surgery)
        assert.equals(5, staff.skills.maintenance)
    end)
    
    it("should apply traits", function()
        local staff = createMockStaff("doctor")
        profile.applyToStaff = function(self, staff)
            staff.traits = self.traits
        end
        
        profile:applyToStaff(staff)
        
        assert.same({"compassionate", "workaholic"}, staff.traits)
    end)
    
    it("should return correct max skill for level", function()
        profile.getMaxSkillForLevel = function(self, level)
            return self.skill_caps[level] or 100
        end
        
        assert.equals(40, profile:getMaxSkillForLevel(1))
        assert.equals(70, profile:getMaxSkillForLevel(4))
        assert.equals(100, profile:getMaxSkillForLevel(10))
    end)
    
    it("should return correct experience for level", function()
        profile.getExperienceForLevel = function(self, level)
            return self.experience_curve[level] or 100000
        end
        
        assert.equals(0, profile:getExperienceForLevel(1))
        assert.equals(5000, profile:getExperienceForLevel(4))
        assert.equals(100000, profile:getExperienceForLevel(10))
    end)
    
    it("should have increasing experience curve", function()
        for i = 2, 10 do
            assert.is_true(profile.experience_curve[i] > profile.experience_curve[i-1])
        end
    end)
    
    it("should have increasing skill caps", function()
        for i = 2, 10 do
            assert.is_true(profile.skill_caps[i] >= profile.skill_caps[i-1])
        end
    end)
end)

describe("Staff Training Area - Integration & Serialization", function()
    local hospital, doctor
    
    before_each(function()
        hospital = createMockHospital()
        doctor = createMockDoctor({level = 2, salary = 1200})
        doctor.hospital = hospital
        table.insert(hospital.staff, doctor)
    end)
    
    it("should serialize staff correctly", function()
        doctor.current_room = createMockRoom("office")
        doctor.current_room.id = "office_1"
        
        local data = doctor:serialize()
        
        assert.equals("doctor", data.staff_type)
        assert.equals(2, data.level)
        assert.equals(1200, data.salary)
        assert.equals("office_1", data.current_room_id)
    end)
    
    it("should deserialize staff correctly", function()
        local data = {
            staff_type = "doctor",
            name = "Dr. Test",
            level = 3,
            salary = 1500,
            skills = {diagnosis = 60, treatment = 55},
            current_room_id = "office_2"
        }
        
        local new_doctor = createMockDoctor()
        new_doctor.hospital = hospital
        hospital.getRoomById = function(self, id) 
            return createMockRoom("office", {id = id}) 
        end
        
        new_doctor:deserialize(data, hospital)
        
        assert.equals(3, new_doctor.level)
        assert.equals(1500, new_doctor.salary)
        assert.equals(60, new_doctor.skills.diagnosis)
        assert.is_not_nil(new_doctor.current_room)
    end)
    
    it("should get staff by type", function()
        local nurse = createMockNurse()
        local handyman = createMockHandyman()
        table.insert(hospital.staff, nurse)
        table.insert(hospital.staff, handyman)
        
        local doctors = hospital:getStaffByType("doctor")
        local nurses = hospital:getStaffByType("nurse")
        
        assert.equals(1, #doctors)
        assert.equals(1, #nurses)
    end)
    
    it("should find available rooms", function()
        local room1 = createMockRoom("office", {capacity = 1, current_occupancy = 1})
        local room2 = createMockRoom("office", {capacity = 2, current_occupancy = 1})
        hospital.rooms.office = {room1, room2}
        
        local available = hospital:getAvailableRoom("office")
        
        assert.equals(room2, available)
    end)
end)

describe("Staff Training Area - Edge Cases & Error Handling", function()
    local staff, hospital
    
    before_each(function()
        hospital = createMockHospital()
        staff = createMockStaff("doctor")
        staff.hospital = hospital
    end)
    
    it("should handle nil current_room gracefully", function()
        staff.current_room = nil
        
        -- Should not crash
        local bonus = staff:getRoomQualityBonus()
        assert.equals(0, bonus)
    end)
    
    it("should handle missing training room", function()
        hospital.getTrainingRoomForSkill = function() return nil end
        
        local success = staff:startTraining("diagnosis", nil)
        assert.is_false(success)
    end)
    
    it("should clamp fatigue to 0-100", function()
        staff.fatigue = 95
        staff:updateFatigue(10) -- Would exceed 100
        assert.is_true(staff.fatigue <= 100)
        
        staff.fatigue = 5
        staff.current_room = createMockRoom("staff_room", {quality = 100})
        staff.current_task = {type = "break"}
        staff:updateFatigue(100) -- Would go below 0
        assert.is_true(staff.fatigue >= 0)
    end)
    
    it("should clamp happiness to 0-100", function()
        staff.happiness = 95
        staff:updateHappiness(10)
        assert.is_true(staff.happiness <= 100)
        
        staff.happiness = 5
        staff.salary = 0
        staff.getMarketSalary = function() return 1000 end
        staff:updateHappiness(10)
        assert.is_true(staff.happiness >= 0)
    end)
    
    it("should clamp skills to 0-100", function()
        staff.skills.diagnosis = 95
        staff.is_training = true
        staff.training_skill = "diagnosis"
        staff.training_room = createMockRoom("training", {getTrainingFactor = function() return 10 end})
        
        staff:updateTraining(100)
        
        assert.is_true(staff.skills.diagnosis <= 100)
    end)
    
    it("should handle empty equipment list in training room", function()
        local room = createMockRoom("training", {equipment = {}})
        room.getAvailableEquipment = function() return {} end
        
        local staff = createMockStaff("doctor")
        staff.is_training = true
        staff.training_skill = "diagnosis"
        
        room:commandEnteringStaff(staff)
        
        -- Should handle gracefully (staff waits for equipment)
        assert.is_nil(staff.training_equipment)
    end)
end)

-- ============================================================================
-- CONSTANTS FOR TESTING
-- ============================================================================

FATIGUE_BREAK_THRESHOLD = 70
FATIGUE_CRITICAL_THRESHOLD = 90
FATIGUE_RECOVERY_RATE = 5
FATIGUE_TRAINING_RATE = 0.3
STAFF_ROOM_RECOVERY_MULTIPLIER = 2.0
RESIGNATION_THRESHOLD = 15
TRAINING_BASE_RATE = 0.1
TRAINING_SESSION_MAX = 20
MAX_TRAINING_FACTOR = 5.0
MAX_EQUIPMENT_FACTOR = 1.5
TRAINER_MULTIPLIER = 0.5
EXPERIENCE_TRAINING_COMPLETE = 100
YEAR_LENGTH = 12 * 30 * 24 * 60 * 60
REPAIR_BASE_SPEED = 10
WATER_RATE = 5
PLANT_HEALTH_GAIN = 0.5
CHECKIN_BASE_SPEED = 20
PHONE_CALL_CHANCE = 0.1
PHONE_CALL_INTERVAL = 60
PHONE_CALL_VARIANCE = 30
EXPERIENCE_CHECKIN = 5
EXPERIENCE_PHONE = 2
EXPERIENCE_TREATMENT = 10
EXPERIENCE_DIAGNOSIS = 15
EXPERIENCE_SURGERY = 50
EXPERIENCE_REPAIR = 8

SKILL_PREREQUISITES = {
    surgery = {"diagnosis", "treatment"},
    research = {"diagnosis"},
    pharmacy = {"treatment"},
    administration = {"reception"}
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function math.clamp(min, max, value)
    return math.max(min, math.min(max, value))
end

-- Run tests
print("Running Staff Training Area Tests...")
print("Test suites: Fatigue, Happiness, Salary, Skills, Training, Handyman, Receptionist, Training Room, Profile, Integration, Edge Cases")
