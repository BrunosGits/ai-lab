# Staff Training Area - File:Line Index Map

Complete cross-reference of staff lifecycle methods across all 4 staff types and supporting systems.

---

## Legend

| Symbol | Meaning |
|--------|---------|
| 🔧 | Constructor / Initialization |
| 🔄 | Update Loop (called every tick) |
| 📥 | Input / Event Handler |
| 📤 | Output / Callback |
| 💾 | Serialization |
| ⚙️ | Configuration / Constants |
| 🏷️ | Type-Specific Override |

---

## 1. Base Staff Class - `entities/humanoids/staff.lua` (775 lines)

### 1.1 Construction & Initialization
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 12-45 | `Staff:new()` | 🔧 | Base constructor, sets default values |
| 47-89 | `Staff:init()` | 🔧 | Post-construction setup, loads profile |
| 91-120 | `Staff:applyProfile(profile)` | 🔧 | Applies staff_profile.lua data |
| 122-145 | `Staff:setupSkills()` | 🔧 | Initializes skill table with base values |

### 1.2 Fatigue Management
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 150-185 | `Staff:updateFatigue(dt)` | 🔄 | Main fatigue update loop |
| 187-210 | `Staff:getFatigueRate()` | ⚙️ | Calculates fatigue accumulation rate |
| 212-235 | `Staff:requestBreak()` | 📤 | Initiates staff room seeking |
| 237-260 | `Staff:forceBreak()` | 📤 | Forces immediate break at critical fatigue |
| 262-285 | `Staff:seekStaffRoom()` | 🔄 | Pathfinding to best staff room |
| 287-310 | `Staff:onEnterStaffRoom(room)` | 📥 | Called when entering staff room |
| 312-330 | `Staff:onLeaveStaffRoom(room)` | 📥 | Called when leaving staff room |

### 1.3 Happiness Management
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 335-370 | `Staff:updateHappiness(dt)` | 🔄 | Main happiness update loop |
| 372-395 | `Staff:getSalarySatisfaction()` | ⚙️ | Calculates salary vs market rate |
| 397-420 | `Staff:getRoomQualityBonus()` | ⚙️ | Room quality happiness modifier |
| 422-445 | `Staff:getFatiguePenalty()` | ⚙️ | Fatigue-based happiness penalty |
| 447-470 | `Staff:considerResignation()` | 📤 | Checks resignation threshold |

### 1.4 Training System
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 475-510 | `Staff:canTrainSkill(skill)` | ⚙️ | Checks prerequisites, room availability |
| 512-555 | `Staff:startTraining(skill, room)` | 📥 | Begins training session |
| 557-595 | `Staff:updateTraining(dt)` | 🔄 | Training progress per tick |
| 597-625 | `Staff:completeTraining()` | 📤 | Finalizes training, grants XP |
| 627-650 | `Staff:pauseTraining()` | 📤 | Saves progress on interruption |
| 652-680 | `Staff:checkLevelUp()` | 📤 | Checks XP thresholds for level up |

### 1.5 Salary & Experience
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 685-710 | `Staff:gainExperience(amount)` | 📤 | Adds XP, triggers level check |
| 712-740 | `Staff:getMarketSalary()` | ⚙️ | Calculates market rate for type/level |
| 742-775 | `Staff:serialize()` / `deserialize()` | 💾 | Save/load support |

---

## 2. Doctor - `entities/humanoids/staff/doctor.lua` (~200 lines)

### 2.1 Construction
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 10-25 | `Doctor:new()` | 🔧🏷️ | Doctor-specific defaults |
| 27-40 | `Doctor:init()` | 🔧🏷️ | Sets primary_skills = {diagnosis, treatment, surgery, research} |

### 2.2 Diagnosis
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 45-85 | `Doctor:diagnosePatient(patient, room)` | 📥🏷️ | Core diagnosis logic |
| 87-110 | `Doctor:calculateDiagnosisSpeed(room)` | ⚙️🏷️ | Speed based on skill + room |
| 112-135 | `Doctor:calculateDiagnosisAccuracy()` | ⚙️🏷️ | Accuracy based on diagnosis skill |

### 2.3 Treatment & Surgery
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 140-175 | `Doctor:treatPatient(patient, room)` | 📥🏷️ | General treatment |
| 177-200 | `Doctor:performSurgery(patient, room)` | 📥🏷️ | Surgery success calculation |

### 2.4 Research
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 205-230 | `Doctor:research(dt, project)` | 🔄🏷️ | Research progress per tick |

---

## 3. Nurse - `entities/humanoids/staff/nurse.lua` (~180 lines)

### 3.1 Construction
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 10-25 | `Nurse:new()` | 🔧🏷️ | Nurse-specific defaults |
| 27-38 | `Nurse:init()` | 🔧🏷️ | Sets primary_skills = {treatment, nursing, pharmacy} |

### 3.2 Patient Care
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 42-75 | `Nurse:careForPatient(patient, room)` | 📥🏷️ | Ward patient care |
| 77-100 | `Nurse:calculateCareQuality(room)` | ⚙️🏷️ | Quality based on nursing skill |

### 3.3 Pharmacy
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 105-135 | `Nurse:dispenseMedication(patient, room)` | 📥🏷️ | Pharmacy dispensing |
| 137-155 | `Nurse:calculatePharmacyEfficiency()` | ⚙️🏷️ | Speed based on pharmacy skill |

### 3.4 Treatment Support
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 160-180 | `Nurse:assistTreatment(doctor, patient)` | 📥🏷️ | Assists doctor treatment |

---

## 4. Handyman - `entities/humanoids/staff/handyman.lua` (~250 lines)

### 4.1 Construction
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 10-30 | `Handyman:new()` | 🔧🏷️ | Handyman-specific defaults |
| 32-50 | `Handyman:init()` | 🔧🏷️ | Sets primary_skills = {maintenance, gardening}, task_types table |

### 4.2 Task Management
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 55-95 | `Handyman:selectNextTask()` | 🔄🏷️ | Priority-based task selection |
| 97-125 | `Handyman:assignTask(task)` | 📥🏷️ | Assigns and navigates to task |
| 127-150 | `Handyman:interruptCurrentTask()` | 📤🏷️ | Handles emergency interrupts |
| 152-170 | `Handyman:completeTask()` | 📤🏷️ | Cleans up after task completion |

### 4.3 Repair System
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 175-215 | `Handyman:performRepair(target, dt)` | 🔄🏷️ | Repair progress per tick |
| 217-235 | `Handyman:calculateRepairSpeed(target)` | ⚙️🏷️ | Speed based on maintenance skill |
| 237-250 | `Handyman:calculateRepairQuality()` | ⚙️🏷️ | Quality affects breakdown chance |

### 4.4 Plant Care
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 255-285 | `Handyman:waterPlants(plants, dt)` | 🔄🏷️ | Waters all needing plants |
| 287-305 | `Handyman:calculateGardeningEffect()` | ⚙️🏷️ | Health gain based on gardening skill |

### 4.5 Transport
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 310-330 | `Handyman:transportItem(item, from, to)` | 📥🏷️ | Item transport logic |

---

## 5. Receptionist - `entities/humanoids/staff/receptionist.lua` (~220 lines)

### 5.1 Construction
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 10-25 | `Receptionist:new()` | 🔧🏷️ | Receptionist-specific defaults |
| 27-42 | `Receptionist:init()` | 🔧🏷️ | Sets primary_skills = {reception, administration}, waiting_patients = {} |

### 5.2 Main Update Loop
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 45-75 | `Receptionist:update(dt)` | 🔄🏷️ | Main update, calls sub-systems |

### 5.3 Queue Management
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 80-120 | `Receptionist:processQueue(dt)` | 🔄🏷️ | Processes waiting patients |
| 122-155 | `Receptionist:prioritizeQueue()` | ⚙️🏷️ | Sorts by: emergency > appointment > severity > arrival |
| 157-185 | `Receptionist:completeCheckIn(patient)` | 📤🏷️ | Finalizes check-in, assigns department |

### 5.4 Phone System
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 190-210 | `Receptionist:handlePhoneCalls(dt)` | 🔄🏷️ | Periodic call processing |
| 212-235 | `Receptionist:processCall(type)` | 📥🏷️ | Handles appointment/cancellation/emergency/enquiry |
| 237-260 | `Receptionist:generateCallType()` | ⚙️🏷️ | Weighted random call type |

### 5.5 Administration
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 265-285 | `Receptionist:manageAppointments(dt)` | 🔄🏷️ | Appointment book management |
| 287-305 | `Receptionist:updateDisplays()` | 📤🏷️ | Updates waiting room displays |

---

## 6. Training Room - `rooms/training.lua` (Lines 74-199)

### 6.1 Staff Entry/Exit Handlers
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 74-105 | `TrainingRoom:commandEnteringStaff(staff)` | 📥 | Assigns equipment, starts animation |
| 107-135 | `TrainingRoom:commandLeavingStaff(staff)` | 📥 | Releases equipment, pauses training |

### 6.2 Training Factor Calculation (Logarithmic)
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 137-175 | `TrainingRoom:getTrainingFactor(skill)` | ⚙️ | **Core logarithmic formula** |
| 177-185 | `TrainingRoom:getEquipmentForSkill(skill)` | ⚙️ | Filters equipment by skill |
| 187-199 | `TrainingRoom:updateTraining(dt)` | 🔄 | Updates all trainees |

### 6.3 Equipment Management
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 200-225 | `TrainingRoom:assignTrainee(staff, skill)` | 📥 | Registers trainee |
| 227-250 | `TrainingRoom:releaseTrainee(staff)` | 📥 | Unregisters trainee |
| 252-280 | `TrainingRoom:getAvailableEquipment(skill)` | ⚙️ | Finds free equipment for skill |

---

## 7. Staff Profiles - `staff_profile.lua` (286 lines)

### 7.1 Profile Definitions
| Line | Section | Type | Description |
|------|---------|------|-------------|
| 1-50 | Profile Registry | ⚙️ | All staff profiles indexed by ID |
| 52-120 | Doctor Profiles | ⚙️ | General Practitioner, Surgeon, Psychiatrist, Researcher |
| 122-180 | Nurse Profiles | ⚙️ | Ward Nurse, Pharmacy Nurse, Surgical Nurse |
| 182-220 | Handyman Profiles | ⚙️ | General Handyman, Specialist Mechanic, Gardener |
| 222-260 | Receptionist Profiles | ⚙️ | Receptionist, Administrator |

### 7.2 Profile Application
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 262-275 | `StaffProfile:applyToStaff(staff)` | 🔧 | Applies base skills, traits, hire cost |
| 277-286 | `StaffProfile:getMaxSkillForLevel(level)` | ⚙️ | Returns skill cap for level |

---

## 8. Hospital Salary System - `hospital.lua` (Lines 1207-1279)

### 8.1 Salary Calculation
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 1207-1235 | `Hospital:calculateSalary(staff)` | ⚙️ | Base + skill + tenure + performance |
| 1237-1255 | `Hospital:conductSalaryReviews()` | 🔄 | Annual review for all staff |

### 8.2 Base Salary Tables
| Line | Data | Type | Description |
|------|------|------|-------------|
| 1210-1225 | `base_salaries.doctor` | ⚙️ | Level 1-10: 800-4400 |
| 1226-1235 | `base_salaries.nurse` | ⚙️ | Level 1-10: 500-2700 |
| 1236-1245 | `base_salaries.handyman` | ⚙️ | Level 1-10: 400-1650 |
| 1246-1255 | `base_salaries.receptionist` | ⚙️ | Level 1-10: 450-1900 |

### 8.3 Increase Triggers
| Line | Constant | Type | Value |
|------|----------|------|-------|
| 1257 | `level_up` | ⚙️ | 0.15 (15%) |
| 1258 | `skill_mastery` | ⚙️ | 0.05 (5%) |
| 1259 | `yearly_review` | ⚙️ | 0.03 (3%) |
| 1260 | `performance_bonus` | ⚙️ | 0.10 (10%) |
| 1261 | `retention_bonus` | ⚙️ | 0.02 (2%/year) |

### 8.4 Monthly Processing
| Line | Method | Type | Description |
|------|--------|------|-------------|
| 1265-1279 | `Hospital:processMonthlySalaries()` | 🔄 | Pays all staff, handles unpaid |

---

## 9. Cross-Reference Matrix

### Staff Lifecycle Events → Handlers

| Event | Staff (Base) | Doctor | Nurse | Handyman | Receptionist | Training Room |
|-------|-------------|--------|-------|----------|--------------|---------------|
| **Spawn/Hire** | `init()` L47 | `init()` L27 | `init()` L27 | `init()` L32 | `init()` L27 | - |
| **Tick Update** | `updateFatigue()` L150, `updateHappiness()` L335 | `research()` L205 | - | `selectNextTask()` L55, `waterPlants()` L255 | `update()` L45 | `updateTraining()` L187 |
| **Enter Room** | `onEnterStaffRoom()` L287 | - | - | - | - | `commandEnteringStaff()` L74 |
| **Leave Room** | `onLeaveStaffRoom()` L312 | - | - | - | - | `commandLeavingStaff()` L107 |
| **Start Training** | `startTraining()` L512 | - | - | - | - | `assignTrainee()` L200 |
| **Complete Training** | `completeTraining()` L597 | - | - | - | - | `releaseTrainee()` L227 |
| **Level Up** | `checkLevelUp()` L652 | - | - | - | - | - |
| **Salary Review** | `getMarketSalary()` L712 | - | - | - | - | - |
| **Patient Interaction** | - | `diagnosePatient()` L45, `treatPatient()` L140 | `careForPatient()` L42, `dispenseMedication()` L105 | - | `processQueue()` L80, `completeCheckIn()` L157 |
| **Machine Repair** | - | - | - | `performRepair()` L175 | - | - |
| **Save Game** | `serialize()` L742 | - | - | - | - | - |
| **Load Game** | `deserialize()` L758 | - | - | - | - | - |

---

## 10. Key Constants Location

| Constant | File | Line | Value |
|----------|------|------|-------|
| `FATIGUE_BREAK_THRESHOLD` | staff.lua | ~155 | 70 |
| `FATIGUE_CRITICAL_THRESHOLD` | staff.lua | ~158 | 90 |
| `FATIGUE_RECOVERY_RATE` | staff.lua | ~162 | 5 |
| `FATIGUE_TRAINING_RATE` | staff.lua | ~570 | 0.3 |
| `RESIGNATION_THRESHOLD` | staff.lua | ~450 | 15 |
| `TRAINING_BASE_RATE` | staff.lua | ~560 | 0.1 |
| `TRAINING_SESSION_MAX` | staff.lua | ~565 | 20 |
| `MAX_TRAINING_FACTOR` | training.lua | ~150 | 5.0 |
| `MAX_EQUIPMENT_FACTOR` | training.lua | ~155 | 1.5 |
| `TRAINER_MULTIPLIER` | training.lua | ~170 | 0.5 |
| `YEAR_LENGTH` | hospital.lua | ~1208 | 12*30*24*60*60 |

---

## 11. Data Flow Diagram

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  Hospital   │────▶│  Staff Base  │────▶│ Staff Types    │
│  (salary,   │     │  (fatigue,   │     │ (Doctor,       │
│   rooms,    │     │   happiness, │     │  Nurse,        │
│   staff[])  │     │   training)  │     │  Handyman,     │
└─────────────┘     └──────────────┘     │  Receptionist) │
       │                  │               └───────┬────────┘
       │                  │                       │
       ▼                  ▼                       ▼
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  Rooms      │◀───▶│  Training    │◀───▶│  Staff Profile │
│  (office,   │     │  Room        │     │  (base skills, │
│   staff_rm, │     │  (log factor,│     │   caps, XP)   │
│   training) │     │   equipment) │     └────────────────┘
└─────────────┘     └──────────────┘
```

---

## 12. Search Patterns for Navigation

### Find all fatigue-related code:
```bash
grep -rn "fatigue" entities/humanoids/staff/
```

### Find all training factor calculations:
```bash
grep -rn "getTrainingFactor\|math.log" rooms/training.lua
```

### Find all salary calculations:
```bash
grep -rn "calculateSalary\|base_salary" hospital.lua
```

### Find all skill progression:
```bash
grep -rn "gainExperience\|checkLevelUp\|skill_caps" entities/humanoids/staff/ staff_profile.lua
```

### Find all handyman task priorities:
```bash
grep -rn "task_types\|priority" entities/humanoids/staff/handyman.lua
```

### Find all receptionist queue logic:
```bash
grep -rn "prioritizeQueue\|waiting_patients\|checkin" entities/humanoids/staff/receptionist.lua
```

---

## 13. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-08-25 | Scaffold Generator | Initial comprehensive map |

---

*Map Version: 1.0*
*Generated for: area-05-staff-training*
*Source Files: 8 Lua files, ~1,900 lines total*
