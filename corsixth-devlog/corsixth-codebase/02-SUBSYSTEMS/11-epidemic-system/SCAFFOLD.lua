--[[
Epidemic System - Busted Test Scaffold
Run with: busted SCAFFOLD.lua
]]

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local assert = require("luassert")
local spy = require("luassert.spy")
local stub = require("luassert.stub")
local match = require("luassert.match")

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockWorld()
    local world = {
        map = {
            level_config = {
                gbv = {
                    ContagiousSpreadFactor = 25,
                    EpidemicRepLossMinimum = 5,
                    EpidemicEvacMinimum = 10,
                    EpidemicFine = 2000,
                    EpidemicCompLo = 1000,
                    EpidemicCompHi = 5000,
                    VacCost = 50,
                    ReduceContMonths = 14,
                    ReduceContPeepCount = 20
                },
                expertise = {
                    [1] = { ContRate = 10 } -- Default expertise
                }
            }
        },
        entity_map = {
            getPatientsInAdjacentSquares = function(self, x, y) return {} end,
            getAdjacentFreeTiles = function(self, x, y) return {} end
        },
        spawn_points = {
            {x = 2, y = 2},
            {x = 10, y = 10}
        },
        ui = {
            bottom_panel = {
                queueMessage = function() end,
                deleteMessage = function() end
            },
            adviser = {
                say = function() end
            },
            addWindow = function() end,
            setCursor = function() end,
            app = {
                gfx = {
                    loadMainCursor = function(self, name) return name end
                }
            },
            playAnnouncement = function() end
        },
        dispatcher = {
            callNurseForVaccination = function() end,
            dropFromQueue = function() end
        },
        date = function(self)
            return {
                monthOfGame = function() return 20 end
            }
        end,
        getPathDistance = function(self, x1, y1, x2, y2) return 5 end,
        newEntity = function(self, type, x, y)
            return {
                setType = function() end,
                setNextAction = function() end,
                setHospital = function() end,
                queueAction = function() end,
                goHome = function() end,
                announce = function() end,
                tile_x = x, tile_y = y,
                has_been_announced = false
            }
        end
    }
    return world
end

local function createMockHospital(world)
    local hospital = {
        world = world,
        patients = {},
        epidemics_disabled = false,
        num_visitors = 25,
        concurrent_epidemic_limit = 3,
        epidemic = nil,
        future_epidemics_pool = {},
        reputation = 1000,
        spendMoney = function(self, amount, transaction_type) end,
        receiveMoney = function(self, amount, transaction_type) end,
        getReceptionDesks = function(self) return {} end,
        isPlayerHospital = function(self) return true end,
        isInHospital = function(self, x, y) return x > 0 and x < 100 and y > 0 and y < 100 end,
        playSound = function(self, sound) end,
        countEpidemics = function(self) return 0 end,
        addToEpidemic = function(self, patient) end,
        determineIfContagious = function(self, patient) end
    }
    world.hospital = hospital
    return hospital
end

local function createMockPatient(overrides)
    local patient = {
        tile_x = 10,
        tile_y = 10,
        disease = { 
            name = "Influenza", 
            contagious = true, 
            expertise_id = 1,
            id = "influenza"
        },
        infected = false,
        cured = false,
        vaccinated = false,
        diagnosed = false,
        marked_for_vaccination = false,
        vaccination_candidate = false,
        reserved_for = nil,
        under_infection_attempt = false,
        going_home = false,
        going_to_die = false,
        dead = false,
        is_emergency = false,
        has_passed_reception = false,
        updateDynamicInfo = function(self) end,
        setInfectedStatus = function(self) end,
        setToReadyForVaccinationStatus = function(self) end,
        giveVaccinationCandidateStatus = function(self) end,
        removeVaccinationCandidateStatus = function(self) end,
        removeAnyEpidemicStatus = function(self) end,
        changeDisease = function(self, disease) self.disease = disease end,
        getRoom = function(self) return "corridor" end,
        getCurrentAction = function(self) return { name = "idle" } end
    }
    for k, v in pairs(overrides or {}) do
        patient[k] = v
    end
    return patient
end

local function createMockNurse()
    return {
        tile_x = 10,
        tile_y = 11,
        on_call = nil,
        setCallCompleted = function(self) end,
        setNextAction = function(self, action) return self end,
        queueAction = function(self, action) return self end,
        setDynamicInfoText = function(self, text) end
    }
end

local function createMockInspector()
    return {
        tile_x = 5,
        tile_y = 5,
        has_been_announced = false,
        announce = function(self) self.has_been_announced = true end,
        goHome = function(self) end,
        setType = function(self, t) end,
        setNextAction = function(self, action) end,
        setHospital = function(self, h) end,
        queueAction = function(self, action) end
    }
end

local function createMockUIWatch(ui, type)
    return {
        open_timer = 100,
        close = function(self) end
    }
end

-- ============================================================================
-- TEST MODULE SETUP
-- ============================================================================

package.path = package.path .. ";/System/Volumes/Data/private/tmp/CorsixTH/CorsixTH/Lua/?.lua"

-- Mock global dependencies
_G.AnnouncementPriority = { Critical = 1 }
_G._S = {
    fax = {
        epidemic = {
            disease_name = "Disease: %s",
            declare_explanation_fine = "Fine: %d",
            cover_up_explanation_1 = "Cover up explanation 1",
            cover_up_explanation_2 = "Cover up explanation 2",
            choices = { declare = "Declare", cover_up = "Cover Up" }
        },
        epidemic_result = {
            succeeded = { part_1_name = "Success: %s", part_2 = "All cured", compensation_amount = "Compensation: %d" },
            failed = { part_1_name = "Failed: %s", part_2 = "Some infected remain", fine_amount = "Fine: %d", rep_loss_fine_amount = "Fine: %d + Rep loss", hospital_evacuated = "Hospital evacuated" },
            close_text = "Close"
        }
    },
    transactions = {
        epidemy_fine = "epidemy_fine",
        epidemy_coverup_fine = "epidemy_coverup_fine",
        compensation = "compensation"
    },
    dynamic_info = {
        staff = { actions = { vaccine = "Vaccinating" } }
    }
}
_G._A = {
    information = { epidemic_health_inspector = "Inspector arriving" },
    epidemic = { hurry_up = "Hurry up!", serious_warning = "Serious situation!" }
}

-- Mock classes
local class = function() 
    return function(name)
        local c = {}
        c.__index = c
        function c:new(...) local o = setmetatable({}, self); if o.init then o:init(...) end return o end
        return c
    end
end

_G.class = class()
_G.class.is = function(obj, cls) return getmetatable(obj) == cls end

-- Mock actions
_G.SpawnAction = function(type, point) return { name = "spawn" } end
_G.SeekReceptionAction = function() return { name = "seek_reception" } end
_G.MeanderAction = function() return { name = "meander" } end
_G.WalkAction = function(x, y) return { name = "walk", x = x, y = y, setMustHappen = function() return self end, enableWalkingToVaccinate = function() return self end } end
_G.VaccinateAction = function(patient, fee) return { name = "vaccinate", patient = patient, fee = fee } end
_G.UIWatch = function(ui, type) return createMockUIWatch(ui, type) end

-- Load the actual epidemic module
local Epidemic = dofile("/System/Volumes/Data/private/tmp/CorsixTH/CorsixTH/Lua/epidemic.lua")

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Epidemic System", function()
    local world, hospital, epidemic, patient
    
    before_each(function()
        world = createMockWorld()
        hospital = createMockHospital(world)
        patient = createMockPatient()
        hospital.epidemic = nil
        hospital.future_epidemics_pool = {}
    end)
    
    after_each(function()
        -- Cleanup
    end)
    
    -- ========================================================================
    -- INITIALIZATION TESTS
    -- ========================================================================
    
    describe("Initialization", function()
        it("should create epidemic with default config values", function()
            epidemic = Epidemic(hospital, patient)
            
            assert.are.equal(hospital, epidemic.hospital)
            assert.are.equal(world, epidemic.world)
            assert.are.equal(patient.disease, epidemic.disease)
            assert.is_false(epidemic.ready_to_reveal)
            assert.is_false(epidemic.revealed)
            assert.are.equal(0, epidemic.declare_fine)
            assert.are.equal(0, epidemic.reputation_hit)
            assert.are.equal(0, epidemic.coverup_fine)
            assert.are.equal(0, epidemic.compensation)
            assert.is_false(epidemic.will_be_evacuated)
            assert.is_false(epidemic.coverup_selected)
            assert.is_nil(epidemic.timer)
            assert.are.equal(0, epidemic.countdown_intervals)
            assert.is_false(epidemic.vaccination_mode_active)
            assert.is_false(epidemic.cheat_always_show_mood)
            assert.are.equal(0, epidemic.total_infections)
            assert.are.equal(0, epidemic.attempted_infections)
        end)
        
        it("should load config values with defaults", function()
            epidemic = Epidemic(hospital, patient)
            
            assert.are.equal(25, epidemic.spread_factor)
            assert.are.equal(5, epidemic.reputation_loss_minimum)
            assert.are.equal(10, epidemic.evacuation_minimum)
        end)
        
        it("should use custom config values when provided", function()
            world.map.level_config.gbv.ContagiousSpreadFactor = 50
            world.map.level_config.gbv.EpidemicRepLossMinimum = 3
            world.map.level_config.gbv.EpidemicEvacMinimum = 8
            
            epidemic = Epidemic(hospital, patient)
            
            assert.are.equal(50, epidemic.spread_factor)
            assert.are.equal(3, epidemic.reputation_loss_minimum)
            assert.are.equal(8, epidemic.evacuation_minimum)
        end)
        
        it("should add initial contagious patient", function()
            epidemic = Epidemic(hospital, patient)
            
            assert.are.equal(1, #epidemic.infected_patients)
            assert.are.equal(patient, epidemic.infected_patients[1])
            assert.is_true(patient.infected)
        end)
        
        it("should mark existing patients as passed reception", function()
            local p1 = createMockPatient({ tile_x = 5, tile_y = 5 })
            local p2 = createMockPatient({ tile_x = 15, tile_y = 15 })
            hospital.patients = { p1, p2 }
            
            epidemic = Epidemic(hospital, patient)
            
            assert.is_true(p1.has_passed_reception)
            assert.is_true(p2.has_passed_reception)
        end)
        
        it("should not mark queuing patients as passed reception", function()
            local desk = { queue = { patient } }
            hospital.getReceptionDesks = function() return { desk } end
            
            epidemic = Epidemic(hospital, patient)
            
            assert.is_false(patient.has_passed_reception)
        end)
    end)
    
    -- ========================================================================
    -- INFECTION SPREAD TESTS
    -- ========================================================================
    
    describe("Infection Spread", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
        end)
        
        it("should not infect if infector is cured", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10 })
            patient.cured = true
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect if infector is vaccinated", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10 })
            patient.vaccinated = true
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect outside hospital bounds", function()
            local victim = createMockPatient({ tile_x = 200, tile_y = 200 })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect already infected patient", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10, infected = true })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_true(victim.infected) -- Already infected
        end)
        
        it("should not infect cured patient", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10, cured = true })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect vaccinated patient", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10, vaccinated = true })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect patient under infection attempt", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10, under_infection_attempt = true })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect emergency patients", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10, is_emergency = true })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should not infect if different disease and victim not contagious/undiagnosed", function()
            local victim = createMockPatient({ 
                tile_x = 11, tile_y = 10,
                disease = { name = "Cold", contagious = false, diagnosed = true }
            })
            hospital.patients = { patient, victim }
            
            epidemic:infectOtherPatients()
            
            assert.is_false(victim.infected)
        end)
        
        it("should infect if same disease in same room", function()
            local victim = createMockPatient({ tile_x = 11, tile_y = 10 })
            hospital.patients = { patient, victim }
            world.entity_map.getPatientsInAdjacentSquares = function(self, x, y) return { victim } end
            
            -- Force infection by manipulating ratio
            epidemic.total_infections = 0
            epidemic.attempted_infections = 1
            
            epidemic:infectOtherPatients()
            
            assert.is_true(victim.infected)
            assert.are.equal(1, epidemic.total_infections)
            assert.are.equal(1, epidemic.attempted_infections)
        end)
        
        it("should change victim disease if different", function()
            local victim = createMockPatient({ 
                tile_x = 11, tile_y = 10,
                disease = { name = "Cold", contagious = true, diagnosed = false }
            })
            hospital.patients = { patient, victim }
            world.entity_map.getPatientsInAdjacentSquares = function(self, x, y) return { victim } end
            
            epidemic.total_infections = 0
            epidemic.attempted_infections = 1
            
            epidemic:infectOtherPatients()
            
            assert.are.equal(patient.disease, victim.disease)
            assert.is_true(victim.infected)
        end)
        
        it("should respect spread factor probability", function()
            local victims = {}
            for i = 1, 10 do
                victims[i] = createMockPatient({ tile_x = 10 + i, tile_y = 10 })
            end
            hospital.patients = { patient }
            for _, v in ipairs(victims) do table.insert(hospital.patients, v) end
            world.entity_map.getPatientsInAdjacentSquares = function(self, x, y) return victims end
            
            epidemic.total_infections = 0
            epidemic.attempted_infections = 0
            
            epidemic:infectOtherPatients()
            
            -- With spread_factor=25 and scale=200, target rate = 12.5%
            -- Actual infections depend on random but should attempt all
            assert.are.equal(10, epidemic.attempted_infections)
        end)
    end)
    
    -- ========================================================================
    -- COVER-UP FLOW TESTS
    -- ========================================================================
    
    describe("Cover-Up Flow", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
        end)
        
        it("should start cover-up with timer", function()
            epidemic:startCoverUp()
            
            assert.is_true(epidemic.coverup_selected)
            assert.is_not_nil(epidemic.timer)
            assert.are.equal(epidemic.timer.open_timer, epidemic.countdown_intervals)
        end)
        
        it("should show infected status on all patients when cover-up starts", function()
            local p2 = createMockPatient({ tile_x = 12, tile_y = 10 })
            epidemic.infected_patients[2] = p2
            
            local setInfectedStatusSpy = spy.on(patient, "setInfectedStatus")
            local setInfectedStatusSpy2 = spy.on(p2, "setInfectedStatus")
            
            epidemic:startCoverUp()
            
            assert.spy(setInfectedStatusSpy).was_called()
            assert.spy(setInfectedStatusSpy2).was_called()
        end)
        
        it("should toggle vaccination mode", function()
            epidemic:startCoverUp()
            
            assert.is_false(epidemic.vaccination_mode_active)
            epidemic:toggleVaccinationMode()
            assert.is_true(epidemic.vaccination_mode_active)
            epidemic:toggleVaccinationMode()
            assert.is_false(epidemic.vaccination_mode_active)
        end)
        
        it("should update cursor when vaccination mode toggled", function()
            epidemic:startCoverUp()
            local setCursorSpy = spy.on(world.ui, "setCursor")
            
            epidemic:toggleVaccinationMode()
            assert.spy(setCursorSpy).was_called_with("epidemic_hover")
            
            epidemic:toggleVaccinationMode()
            assert.spy(setCursorSpy).was_called_with("default")
        end)
        
        it("should mark patient for vaccination", function()
            epidemic:startCoverUp()
            local playSoundSpy = spy.on(hospital, "playSound")
            local setReadySpy = spy.on(patient, "setToReadyForVaccinationStatus")
            
            epidemic:markForVaccination(patient)
            
            assert.is_true(patient.marked_for_vaccination)
            assert.spy(playSoundSpy).was_called_with("vaccin.wav")
            assert.spy(setReadySpy).was_called()
        end)
        
        it("should not mark already vaccinated patient", function()
            epidemic:startCoverUp()
            patient.vaccinated = true
            
            epidemic:markForVaccination(patient)
            
            assert.is_false(patient.marked_for_vaccination)
        end)
        
        it("should not mark already marked patient", function()
            epidemic:startCoverUp()
            patient.marked_for_vaccination = true
            
            epidemic:markForVaccination(patient)
            
            assert.is_true(patient.marked_for_vaccination) -- Still true, no double-mark
        end)
        
        it("should call nurse for vaccination for static marked patients", function()
            epidemic:startCoverUp()
            patient.marked_for_vaccination = true
            local callNurseSpy = spy.on(world.dispatcher, "callNurseForVaccination")
            
            epidemic:markedPatientsCallForVaccination()
            
            assert.spy(callNurseSpy).was_called_with(patient)
        end)
        
        it("should not call nurse for non-static patients", function()
            epidemic:startCoverUp()
            patient.marked_for_vaccination = true
            patient.getCurrentAction = function() return { name = "walk" } end
            local callNurseSpy = spy.on(world.dispatcher, "callNurseForVaccination")
            
            epidemic:markedPatientsCallForVaccination()
            
            assert.spy(callNurseSpy).was_not_called()
        end)
        
        it("should not call nurse if patient already reserved", function()
            epidemic:startCoverUp()
            patient.marked_for_vaccination = true
            patient.reserved_for = createMockNurse()
            local callNurseSpy = spy.on(world.dispatcher, "callNurseForVaccination")
            
            epidemic:markedPatientsCallForVaccination()
            
            assert.spy(callNurseSpy).was_not_called()
        end)
    end)
    
    -- ========================================================================
    -- VACCINATION TESTS
    -- ========================================================================
    
    describe("Vaccination Process", function()
        local nurse
        
        before_each(function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
            nurse = createMockNurse()
        end)
        
        it("should create vaccination actions for reachable patient", function()
            world.entity_map.getAdjacentFreeTiles = function(self, x, y) 
                return {{x = 10, y = 9}} 
            end
            
            epidemic:createVaccinationActions(patient, nurse)
            
            assert.are.equal(nurse, patient.reserved_for)
            assert.is_true(patient.vaccination_candidate)
        end)
        
        it("should handle unreachable patient", function()
            world.entity_map.getAdjacentFreeTiles = function(self, x, y) 
                return {} 
            end
            world.getPathDistance = function() return nil end
            
            local removeCandidateSpy = spy.on(patient, "removeVaccinationCandidateStatus")
            local meanderSpy = spy.on(nurse, "setNextAction")
            
            epidemic:createVaccinationActions(patient, nurse)
            
            assert.is_nil(patient.reserved_for)
            assert.spy(removeCandidateSpy).was_called()
        end)
        
        it("should use bench-front tile for bench patients", function()
            local bench = { object_type = { id = "bench" }, direction = "north" }
            patient.getCurrentAction = function() 
                return { name = "use_object", object = bench } 
            end
            world.entity_map.getAdjacentFreeTiles = function(self, x, y) 
                return {{x = 10, y = 9}} 
            end
            
            local x, y = epidemic:getBestVaccinationTile(nurse, patient)
            
            assert.are.equal(10, x)
            assert.are.equal(9, y) -- North of patient (10,10)
        end)
        
        it("should calculate closest reachable tile for non-bench patients", function()
            world.entity_map.getAdjacentFreeTiles = function(self, x, y) 
                return {{x = 10, y = 9}, {x = 11, y = 10}, {x = 9, y = 10}} 
            end
            world.getPathDistance = function(self, nx, ny, x, y) 
                return math.abs(nx - x) + math.abs(ny - y) 
            end
            
            local x, y = epidemic:getBestVaccinationTile(nurse, patient)
            
            -- Nurse at (10,11), patient at (10,10), adjacent tiles: (10,9), (11,10), (9,10)
            -- Distances: 2, 1, 2 -> closest is (11,10)
            assert.are.equal(11, x)
            assert.are.equal(10, y)
        end)
        
        it("should interrupt vaccination actions", function()
            epidemic:startCoverUp()
            patient.marked_for_vaccination = true
            patient.vaccination_candidate = true
            nurse.on_call = { object = patient, assigned = true }
            
            epidemic:interruptVaccinationActions(nurse)
            
            assert.is_false(patient.vaccination_candidate)
            assert.is_nil(patient.reserved_for)
            assert.is_nil(nurse.on_call)
        end)
    end)
    
    -- ========================================================================
    -- OUTCOME TESTS
    -- ========================================================================
    
    describe("Outcomes", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
        end)
        
        it("should give compensation for 0 infected", function()
            patient.cured = true
            patient.vaccinated = true
            
            epidemic:handleInspectorArrival()
            
            assert.are.equal(0, epidemic.coverup_fine)
            assert.is_true(epidemic.compensation >= 1000 and epidemic.compensation <= 5000)
            assert.is_false(epidemic.will_be_evacuated)
        end)
        
        it("should give fine only for < reputation_loss_minimum infected", function()
            -- 3 infected (less than default 5)
            local p2 = createMockPatient({ cured = false })
            local p3 = createMockPatient({ cured = false })
            epidemic.infected_patients[2] = p2
            epidemic.infected_patients[3] = p3
            
            epidemic:handleInspectorArrival()
            
            assert.are.equal(0, epidemic.compensation)
            assert.are.equal(6000, epidemic.coverup_fine) -- 3 * 2000
            assert.is_false(epidemic.will_be_evacuated)
        end)
        
        it("should give fine + reputation hit for >= reputation_loss_minimum but < evacuation_minimum", function()
            -- 7 infected (between 5 and 10)
            for i = 2, 7 do
                epidemic.infected_patients[i] = createMockPatient({ cured = false })
            end
            
            epidemic:handleInspectorArrival()
            
            assert.are.equal(0, epidemic.compensation)
            assert.are.equal(14000, epidemic.coverup_fine) -- 7 * 2000
            assert.is_false(epidemic.will_be_evacuated)
        end)
        
        it("should trigger evacuation for >= evacuation_minimum infected", function()
            -- 12 infected (>= 10)
            for i = 2, 12 do
                epidemic.infected_patients[i] = createMockPatient({ cured = false })
            end
            
            epidemic:handleInspectorArrival()
            
            assert.is_true(epidemic.will_be_evacuated)
            assert.are.equal(24000, epidemic.coverup_fine) -- 12 * 2000
        end)
        
        it("should apply compensation on successful cover-up", function()
            patient.cured = true
            patient.vaccinated = true
            local receiveMoneySpy = spy.on(hospital, "receiveMoney")
            
            epidemic:handleInspectorArrival()
            
            assert.spy(receiveMoneySpy).was_called()
        end)
        
        it("should apply fine and reputation hit on failed cover-up", function()
            local p2 = createMockPatient({ cured = false })
            epidemic.infected_patients[2] = p2
            
            local spendMoneySpy = spy.on(hospital, "spendMoney")
            
            epidemic:handleInspectorArrival()
            
            assert.spy(spendMoneySpy).was_called()
            assert.is_true(hospital.reputation < 1000)
        end)
        
        it("should evacuate hospital on catastrophic failure", function()
            for i = 2, 12 do
                local p = createMockPatient({ cured = false, has_passed_reception = true })
                epidemic.infected_patients[i] = p
                hospital.patients[i] = p
            end
            local goHomeSpy = spy.new(function() end)
            for _, p in ipairs(epidemic.infected_patients) do
                p.goHome = goHomeSpy
            end
            
            epidemic:handleInspectorArrival()
            
            assert.is_true(epidemic.will_be_evacuated)
        end)
    end)
    
    -- ========================================================================
    -- FINE CALCULATION TESTS
    -- ========================================================================
    
    describe("Fine Calculation", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
        end)
        
        it("should calculate fine with default EpidemicFine", function()
            local fine = epidemic:calculateInfectedFine(5)
            assert.are.equal(10000, fine) -- 5 * 2000
        end)
        
        it("should enforce minimum fine of 2000", function()
            local fine = epidemic:calculateInfectedFine(0)
            assert.are.equal(2000, fine)
            
            fine = epidemic:calculateInfectedFine(1)
            assert.are.equal(2000, fine) -- max(2000, 1*2000)
        end)
        
        it("should use custom EpidemicFine from config", function()
            world.map.level_config.gbv.EpidemicFine = 5000
            
            local fine = epidemic:calculateInfectedFine(3)
            assert.are.equal(15000, fine)
        end)
        
        it("should calculate base reputation from fine", function()
            local rep = math.round(5000 / 100)
            assert.are.equal(50, rep)
        end)
    end)
    
    -- ========================================================================
    -- DECLARATION PATH TESTS
    -- ========================================================================
    
    describe("Declaration Path", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
        end)
        
        it("should apply declare fine and reputation hit", function()
            local spendMoneySpy = spy.on(hospital, "spendMoney")
            epidemic.declare_fine = 8000
            
            epidemic:resolveDeclaration()
            
            assert.spy(spendMoneySpy).was_called_with(8000, "epidemy_fine")
            assert.are.equal(920, hospital.reputation) -- 1000 - 80
            assert.is_nil(hospital.epidemic)
        end)
        
        it("should clear all infected patients on declaration", function()
            local p2 = createMockPatient({})
            epidemic.infected_patients[2] = p2
            local removeStatusSpy = spy.on(patient, "removeAnyEpidemicStatus")
            local removeStatusSpy2 = spy.on(p2, "removeAnyEpidemicStatus")
            local dropQueueSpy = spy.on(world.dispatcher, "dropFromQueue")
            
            epidemic:resolveDeclaration()
            
            assert.is_true(patient.vaccinated)
            assert.is_true(p2.vaccinated)
            assert.spy(removeStatusSpy).was_called()
            assert.spy(removeStatusSpy2).was_called()
            assert.spy(dropQueueSpy).was_called(2)
        end)
    end)
    
    -- ========================================================================
    -- EDGE CASES & INTEGRATION TESTS
    -- ========================================================================
    
    describe("Edge Cases", function()
        it("should handle early cover-up termination when infected leaves", function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
            
            patient.going_home = true
            patient.cured = false
            patient.tile_x = 200
            patient.tile_y = 200
            hospital.isInHospital = function(self, x, y) return false end
            
            local finishCoverUpSpy = spy.on(epidemic, "finishCoverUp")
            
            epidemic:checkInfectedLeftHospital()
            
            assert.spy(finishCoverUpSpy).was_called()
        end)
        
        it("should handle early cover-up termination when no infected remain", function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
            
            patient.cured = true
            patient.vaccinated = true
            
            local finishCoverUpSpy = spy.on(epidemic, "finishCoverUp")
            
            epidemic:checkNoInfectedPatients()
            
            assert.spy(finishCoverUpSpy).was_called()
        end)
        
        it("should remove patients going home before epidemic revealed", function()
            patient.going_home = true
            epidemic = Epidemic(hospital, patient)
            
            assert.are.equal(0, #epidemic.infected_patients)
        end)
        
        it("should not add new patients to epidemic during cover-up", function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
            
            local newPatient = createMockPatient({ disease = patient.disease })
            hospital:addToEpidemic(newPatient)
            
            -- Should not be added because coverup_selected is true
            assert.are.equal(1, #epidemic.infected_patients)
        end)
        
        it("should add same-disease patients to active epidemic when not covering up", function()
            epidemic = Epidemic(hospital, patient)
            -- No cover-up started
            
            local newPatient = createMockPatient({ disease = patient.disease })
            hospital:addToEpidemic(newPatient)
            
            assert.are.equal(2, #epidemic.infected_patients)
        end)
        
        it("should create new epidemic in pool for different disease", function()
            epidemic = Epidemic(hospital, patient)
            
            local newPatient = createMockPatient({ 
                disease = { name = "Cold", contagious = true, expertise_id = 1, id = "cold" }
            })
            hospital:addToEpidemic(newPatient)
            
            assert.are.equal(1, #hospital.future_epidemics_pool)
            assert.are.equal(newPatient.disease, hospital.future_epidemics_pool[1].disease)
        end)
        
        it("should respect concurrent epidemic limit", function()
            hospital.concurrent_epidemic_limit = 1
            epidemic = Epidemic(hospital, patient)
            
            local newPatient = createMockPatient({ 
                disease = { name = "Cold", contagious = true, expertise_id = 1, id = "cold" }
            })
            hospital:addToEpidemic(newPatient)
            
            assert.are.equal(0, #hospital.future_epidemics_pool) -- At limit
        end)
    end)
    
    -- ========================================================================
    -- CONTAGIOUS DETECTION TESTS
    -- ========================================================================
    
    describe("Contagious Detection", function()
        it("should not trigger if epidemics disabled", function()
            hospital.epidemics_disabled = true
            patient = createMockPatient()
            
            hospital:determineIfContagious(patient)
            
            assert.is_nil(hospital.epidemic)
            assert.are.equal(0, #hospital.future_epidemics_pool)
        end)
        
        it("should not trigger for emergency patients", function()
            patient = createMockPatient({ is_emergency = true })
            
            hospital:determineIfContagious(patient)
            
            assert.is_nil(hospital.epidemic)
        end)
        
        it("should not trigger for non-contagious disease", function()
            patient = createMockPatient({ disease = { contagious = false } })
            
            hospital:determineIfContagious(patient)
            
            assert.is_nil(hospital.epidemic)
        end)
        
        it("should use ContRate for contagion chance", function()
            world.map.level_config.expertise[1].ContRate = 1 -- 100% chance
            patient = createMockPatient()
            
            hospital:determineIfContagious(patient)
            
            -- With ContRate=1, math.random(1,1) == 1 always true
            assert.is_not_nil(hospital.epidemic)
        end)
        
        it("should reduce contagion after ReduceContMonths", function()
            world.map.level_config.ReduceContMonths = 10
            world.map.level_config.ReduceContPeepCount = 10
            world.date = function() return { monthOfGame = function() return 5 end } end -- Before reduction
            hospital.num_visitors = 15
            
            patient = createMockPatient()
            world.map.level_config.expertise[1].ContRate = 1
            
            hospital:determineIfContagious(patient)
            
            -- Before month 10, should still trigger
            assert.is_not_nil(hospital.epidemic)
        end)
        
        it("should reduce contagion when both month and visitor thresholds met", function()
            world.map.level_config.ReduceContMonths = 10
            world.map.level_config.ReduceContPeepCount = 10
            world.date = function() return { monthOfGame = function() return 15 end } end -- After reduction
            hospital.num_visitors = 15
            
            patient = createMockPatient()
            world.map.level_config.expertise[1].ContRate = 1
            
            hospital:determineIfContagious(patient)
            
            -- After month 10 AND visitors > 10, should NOT trigger
            assert.is_nil(hospital.epidemic)
        end)
    end)
    
    -- ========================================================================
    -- TIMER & ADVISOR TESTS
    -- ========================================================================
    
    describe("Timer and Advisor", function()
        before_each(function()
            epidemic = Epidemic(hospital, patient)
            epidemic.ready_to_reveal = true
            epidemic:revealEpidemic()
            epidemic:startCoverUp()
        end)
        
        it("should show hurry up message at 25% timer remaining", function()
            epidemic.countdown_intervals = 100
            epidemic.timer.open_timer = 25 -- 25% remaining
            epidemic.has_said_hurry_up = false
            
            local saySpy = spy.on(world.ui.adviser, "say")
            
            epidemic:showAppropriateAdviceMessages()
            
            assert.spy(saySpy).was_called_with("Hurry up!")
            assert.is_true(epidemic.has_said_hurry_up)
        end)
        
        it("should show serious warning at 75% elapsed with >10 infected", function()
            epidemic.countdown_intervals = 100
            epidemic.timer.open_timer = 25 -- 75% elapsed
            epidemic.has_said_serious = false
            
            -- Add 11 infected patients
            for i = 2, 12 do
                epidemic.infected_patients[i] = createMockPatient({ cured = false })
            end
            
            local saySpy = spy.on(world.ui.adviser, "say")
            
            epidemic:showAppropriateAdviceMessages()
            
            assert.spy(saySpy).was_called_with("Serious situation!")
            assert.is_true(epidemic.has_said_serious)
        end)
        
        it("should not repeat advisor messages", function()
            epidemic.countdown_intervals = 100
            epidemic.timer.open_timer = 25
            epidemic.has_said_hurry_up = true -- Already said
            
            local saySpy = spy.on(world.ui.adviser, "say")
            
            epidemic:showAppropriateAdviceMessages()
            
            assert.spy(saySpy).was_not_called()
        end)
    end)
    
    -- ========================================================================
    -- CHEAT & CANCEL TESTS
    -- ========================================================================
    
    describe("Cheat and Cancel", function()
        it("should cancel epidemic and clean up", function()
            epidemic = Epidemic(hospital, patient)
            epidemic.timer = createMockUIWatch(world.ui, "epidemic")
            epidemic.inspector = createMockInspector()
            
            local deleteMsgSpy = spy.on(world.ui.bottom_panel, "deleteMessage")
            local closeTimerSpy = spy.on(epidemic.timer, "close")
            local goHomeSpy = spy.on(epidemic.inspector, "goHome")
            local clearSpy = spy.on(epidemic, "clearAllInfectedPatients")
            
            epidemic:cancelEpidemic()
            
            assert.spy(deleteMsgSpy).was_called_with(epidemic)
            assert.spy(closeTimerSpy).was_called()
            assert.spy(goHomeSpy).was_called()
            assert.spy(clearSpy).was_called()
            assert.are.equal(0, #epidemic.infected_patients)
        end)
    end)
end)

-- ============================================================================
-- RUNNER
-- ============================================================================

print("Epidemic System Test Scaffold Loaded")
print("Run with: busted SCAFFOLD.lua")
