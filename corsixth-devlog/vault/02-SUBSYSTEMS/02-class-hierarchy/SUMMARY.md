# Class Hierarchy — Complete Technical Reference

> **Generated:** 2026-08-24  
> **Source:** CorsixTH `Lua/class.lua` + 195 class declarations across 10 categories  
> **Purpose:** Single source of truth for OOP system mechanics, inheritance structure, and patterns

---

## 1. OOP System Mechanics (`class.lua`)

### 1.1 Class Creation Pattern

```lua
-- Typical class declaration (from entity.lua:22, humanoid.lua:22, etc.)
class "Entity" (function(_ENV)
    function Entity:__init() ... end
    function Entity:tick() ... end
    -- methods defined in _ENV become class methods
end)

-- Subclass declaration (from humanoid.lua:22)
class "Humanoid" (Entity) (function(_ENV)
    function Humanoid:__init() ... end
    function Humanoid:tick() ... end
end)
```

### 1.2 Metatable Structure & `__index` Chaining

```
Instance (e.g., patient1)
    │
    ▼ __index
Humanoid class table (methods + __init)
    │
    ▼ __index  (parent class)
Entity class table (methods + __init)
    │
    ▼ __index  (base class)
Class metatable (class.is, class.type, class.super)
    │
    ▼ __index
Global _ENV / _G
```

**Key Implementation Details:**

| Aspect | Implementation |
|--------|----------------|
| **Instance creation** | `ClassName(args)` → `class.new(ClassName, args)` |
| **Method lookup** | `instance:method()` → `__index` chain up hierarchy |
| **Superclass reference** | `ClassName.super` or `self.super` (set in `__init`) |
| **Class identity** | Stored in `ClassName.__class = ClassName` |
| **Type checking** | `class.is(instance, ClassName)` / `class.type(instance)` |

### 1.3 Adoption Pattern (Mixin-Like Composition)

```lua
-- From object.lua:1005+ (slaveMixinClass)
function Object.slaveMixinClass(klass)
    function klass:__init(...)
        self.slave = nil
        self.master = nil
        -- calls original __init
    end
    function klass:setMaster(master) ... end
    function klass:getMaster() ... end
    -- ... other mixin methods
end

-- Usage in OperatingSink, RadiationShield, OperatingTable:
class "OperatingSink" (Object) (function(_ENV)
    Object.slaveMixinClass(_ENV)  -- adopts mixin methods
    function OperatingSink:__init() ... end
end)
```

**Adoption vs Inheritance:**
- **Inheritance** (`class "Child" (Parent)`) — single parent, `__index` chain
- **Adoption** (`Parent.mixinClass(_ENV)`) — copies methods into current class table, no `__index` link to mixin
- **Multiple adoption** possible; last adoption wins on name conflicts

### 1.4 `class.is` / `class.type` Implementation

```lua
-- Pseudocode from class.lua
function class.is(obj, klass)
    if type(obj) ~= "table" then return false end
    local mt = getmetatable(obj)
    while mt do
        if mt.__class == klass then return true end
        mt = getmetatable(mt.__index)  -- walk __index chain
    end
    return false
end

function class.type(obj)
    if type(obj) ~= "table" then return nil end
    local mt = getmetatable(obj)
    if mt and mt.__class then
        return mt.__class  -- returns the class table itself
    end
    return nil
end
```

**Usage Examples:**
```lua
local patient = Patient()
class.is(patient, Patient)    -- true
class.is(patient, Humanoid)   -- true (walks up hierarchy)
class.is(patient, Entity)     -- true
class.is(patient, Staff)      -- false (sibling branch)
class.is(patient, Object)     -- false (different root)
class.type(patient)           -- returns Patient class table
class.type(patient).__name    -- "Patient"
```

---

## 2. Complete Inheritance Hierarchy (195 Classes)

### 2.1 Entity Hierarchy (15 classes, max depth 4)

```
Entity (root)
├── Humanoid
│   ├── Patient
│   │   ├── Vip
│   │   ├── Inspector
│   │   └── GrimReaper
│   └── Staff
│       ├── Doctor
│       ├── Nurse
│       ├── Handyman
│       └── Receptionist
├── Object
│   ├── SideObject
│   ├── Machine
│   │   └── OperatingTable
│   ├── Door
│   │   └── SwingDoor
│   ├── EntranceDoor
│   ├── Bench
│   ├── Chair
│   ├── Plant
│   ├── ReceptionDesk
│   ├── Rathole
│   ├── Helicopter
│   ├── AtomAnalyser
│   ├── OperatingSink  (adopts slaveMixin)
│   ├── RadiationShield (adopts slaveMixin)
│   └── SurgeonScreen
└── Litter  (direct Entity subclass — NOT Object)
```

**Depth Analysis:**
| Class | Depth | Path |
|-------|-------|------|
| Entity | 0 | root |
| Humanoid, Object, Litter | 1 | Entity → X |
| Patient, Staff, Machine, Door, etc. | 2 | Entity → X → Y |
| Vip, Inspector, GrimReaper, Doctor, Nurse, Handyman, Receptionist, OperatingTable, SwingDoor | 3 | Entity → X → Y → Z |

### 2.2 Room Hierarchy (24 classes, max depth 2)

```
Room (root)
├── GPRoom
├── OperatingTheatreRoom
├── WardRoom
├── ResearchRoom
├── TrainingRoom
├── PharmacyRoom
├── PsychRoom
├── StaffRoom
├── ToiletRoom
├── BloodMachineRoom
├── CardiogramRoom
├── DecontaminationRoom
├── DNAFixerRoom
├── ElectrolysisRoom
├── FractureRoom
├── GeneralDiagRoom
├── HairRestorationRoom
├── InflationRoom
├── JellyVatRoom
├── ScannerRoom
├── SlackTongueRoom
├── UltrascanRoom
└── XRayRoom
```

All 23 subclasses directly extend `Room` — flat hierarchy, no intermediate abstract classes.

### 2.3 Hospital Hierarchy (3 classes, depth 1)

```
Hospital (root)
├── PlayerHospital
└── AIHospital
```

### 2.4 UI/Window Hierarchy (32 classes, max depth 4)

```
Window (root)
├── UI
│   └── GameUI
├── UIFullscreen
│   ├── UIAnnualReport, UIBankManager, UICasebook, UIFax
│   ├── UIGraphs, UIPolicy, UIProgressReport, UIResearch
│   ├── UIStaffManagement, UITownMap
├── UIResizable
│   ├── UIAdviserHistory, UICallsDispatcher, UICheats
│   ├── UICustomise, UIDirectoryBrowser, UIDropdown
│   ├── UIFileBrowser
│   │   ├── UIChooseFont, UIChooseSoundfont
│   │   ├── UILoadGame, UILoadMap, UISaveGame, UISaveMap
│   ├── UIFolder, UIHotkeyAssign, UILuaConsole
│   ├── UIMachineMenu, UIMainMenu, UIMapEditor
│   ├── UIMenuList
│   │   ├── UICustomCampaign, UICustomGame, UIMakeDebugPatient
│   ├── UIOptions, UIResolution, UIScrollSpeed
│   ├── UIShiftScrollSpeed, UIZoomSpeed
│   ├── UISoundSettings, UITipOfTheDay, UIUpdate
│   ├── UIAdviser, UIBottomPanel, UIBuildRoom
│   ├── UIConfirmDialog, UIFurnishCorridor, UIHireStaff
│   ├── UIInformation, UIJukebox, UIMachine, UIMenuBar
│   ├── UIMessage, UIPatient, UIPlaceObjects
│   │   └── UIEditRoom
│   ├── UIPlaceStaff, UIQueue, UIQueuePopup
│   ├── UIStaff, UIStaffRise, UIWatch, Subtitles
│   ├── UIHotkeyAssignKeyPane, TreeControl
│   │   └── FilteredTreeControl
```

### 2.5 HumanoidAction Hierarchy (33 classes, depth 2)

```
HumanoidAction (root)
├── AnswerCallAction
├── CallCheckPointAction
├── CheckWatchAction
├── DieAction
├── FallingAction
├── GetUpAction
├── IdleAction
├── IdleSpawnAction
├── KnockDoorAction
├── MeanderAction
├── MultiUseObjectAction
├── OnGroundAction
├── PeeAction
├── PickupAction
├── QueueAction
├── SeekReceptionAction
├── SeekRoomAction
├── SeekStaffRoomAction
├── SeekToiletsAction
├── ShakeFistAction
├── SpawnAction
├── StaffReceptionAction
├── SweepFloorAction
├── TapFootAction
├── UseObjectAction
├── UseScreenAction
├── UseStaffRoomAction
├── VaccinateAction
├── VipGoToNextRoomAction
├── VomitAction
├── WalkAction
└── YawnAction
```

### 2.6 TreeNode Hierarchy (7 classes, max depth 3)

```
TreeNode (root)
├── FileTreeNode
│   ├── DirTreeNode
│   │   └── InstallDirTreeNode
│   └── FilteredFileTreeNode
└── DummyRootNode
```

### 2.7 Standalone Classes (no inheritance)

| Category | Classes |
|----------|---------|
| Core | App, World, Map, Date, Strings, Graphics, AnimationManager, Audio, MoviePlayer, FileSystem |
| Support | StaffProfile, Queue, EntityMap, Earthquake, Epidemic, Cheats, CallsDispatcher, ResearchDepartment, EndConditions |
| Announcer | AnnouncementQueue, AnnouncementEntry, Announcer |
| UI Support | Panel, Button, Scrollbar, Textbox, HotkeyBox, UIMenu, SubtitleQueue |

---

## 3. Method Resolution Order (MRO)

### 3.1 Single Inheritance Chain Walk

```lua
-- When calling instance:method(args)
-- 1. Check instance's own table (rawget)
-- 2. Check class table (metatable.__index)
-- 3. Check superclass table (metatable.__index.__index)
-- 4. Continue up to root
-- 5. Fall back to _G
```

### 3.2 Superclass Call Pattern

```lua
-- Standard pattern (used throughout codebase)
function ChildClass:method(...)
    -- Option 1: Explicit superclass call (most common)
    ParentClass.method(self, ...)
    
    -- Option 2: Via self.super (set in __init)
    self.super.method(self, ...)
    
    -- Option 3: Dynamic (rare)
    getmetatable(self).__index.method(self, ...)
end

-- Real example from humanoid.lua:380
function Humanoid:tick()
    Entity.tick(self)  -- Superclass call FIRST
    -- ... humanoid-specific logic
end

-- Real example from patient.lua:450
function Patient:tick()
    Humanoid.tick(self)  -- Superclass call
    if self.disease then
        -- ... patient-specific logic
    end
end
```

### 3.3 Diamond Problem — Not Applicable

CorsixTH uses **single inheritance only**. No multiple inheritance, no C3 linearization needed. Adoption pattern provides composition without MRO complexity.

### 3.4 `__init` Chaining Convention

```lua
function ChildClass:__init(args)
    -- 1. Call parent __init FIRST
    ParentClass.__init(self, args)
    
    -- 2. Then child-specific initialization
    self.child_field = args.child_field
end

-- Entity:__init (entity.lua:45)
function Entity:__init()
    self.ticks = true
    self.to_destroy = false
    self.world = nil
    -- ...
end

-- Humanoid:__init (humanoid.lua:45)
function Humanoid:__init()
    Entity.__init(self)  -- Chain to parent
    self.action_queue = {}
    self.attributes = { warmth=1, happiness=1, health=1, fatigue=1, thirst=1, toilet_need=1 }
    -- ...
end
```

---

## 4. Type Checking & Runtime Introspection

### 4.1 `class.is(instance, Class)` — Hierarchy-Aware

```lua
-- Returns true if instance is Class OR any subclass
class.is(patient, Entity)      -- true
class.is(patient, Humanoid)    -- true  
class.is(patient, Patient)     -- true
class.is(patient, Staff)       -- false
class.is(doctor, Staff)        -- true
class.is(doctor, Doctor)       -- true
class.is(doctor, Humanoid)     -- true
```

### 4.2 `class.type(instance)` — Exact Class

```lua
-- Returns the concrete class table (not superclass)
local p = Patient()
class.type(p) == Patient   -- true
class.type(p) == Humanoid  -- false
```

### 4.3 Common Type-Check Patterns in Codebase

```lua
-- Pattern 1: class.is for polymorphic handling
if class.is(entity, Humanoid) then
    entity:setMood("happy")
end

-- Pattern 2: class.type for exact match (e.g., save/load)
if class.type(entity) == Patient then
    -- patient-specific serialization
end

-- Pattern 3: isType method on Humanoid (humanoid.lua:200)
function Humanoid:isType(type_name)
    return class.type(self).__name == type_name
end
-- Usage: humanoid:isType("Patient"), humanoid:isType("Doctor")
```

### 4.4 Class Identity Fields

Every class created via `class "Name"` gets:
```lua
Class.__name        -- "Patient" (string)
Class.__class       -- Class (self-reference)
Class.super         -- Parent class table (or nil for roots)
```

---

## 5. Common Patterns & Idioms

### 5.1 Superclass Call (Universal Pattern)

```lua
-- ALWAYS call superclass method first (unless intentionally overriding completely)
function Derived:tick()
    Base.tick(self)  -- or self.super.tick(self)
    -- derived logic
end

function Derived:onDestroy()
    -- derived cleanup FIRST
    self:cleanupDerived()
    -- THEN superclass
    Base.onDestroy(self)
end
```

### 5.2 Adoption / Mixin Pattern

```lua
-- Define mixin as function that modifies _ENV
function MyMixin(_ENV)
    function MyMixin:included()
        print("Mixin included in " .. _ENV.__name)
    end
    function MyMixin:sharedMethod()
        return "from mixin"
    end
end

-- Adopt in class
class "MyClass" (Base) (function(_ENV)
    MyMixin(_ENV)  -- copies methods into MyClass table
    function MyClass:__init()
        Base.__init(self)
    end
end)
```

**Used in:** `Object.slaveMixinClass()` → `OperatingSink`, `RadiationShield`, `OperatingTable`

### 5.3 Static / Class Methods

```lua
-- Defined with dot syntax (not colon)
class "MyClass" (function(_ENV)
    function MyClass.staticMethod(arg)
        return arg * 2
    end
    
    function MyClass:instanceMethod()
        return self.value
    end
end)

MyClass.staticMethod(5)  -- 10
local obj = MyClass()
obj:instanceMethod()     -- uses self
```

### 5.4 Factory / Constructor Variations

```lua
-- Standard: ClassName(args)
local patient = Patient()

-- With world reference (common for entities)
local doctor = Doctor(world, staff_profile)

-- Static factory (rare)
function Patient.createEmergency(world)
    local p = Patient(world)
    p.is_emergency = true
    return p
end
```

### 5.5 `afterLoad` for Save-Game Migration

```lua
-- Every major class implements afterLoad for version migration
function Patient:afterLoad()
    Humanoid.afterLoad(self)  -- chain
    -- migrate old fields
    if self.old_field then
        self.new_field = self.old_field
        self.old_field = nil
    end
end
```

---

## 6. File → Class Mapping Reference

### 6.1 Core Classes

| Class | File:Line | Superclass |
|-------|-----------|------------|
| App | `app.lua:33` | none |
| World | `world.lua:48` | none |
| Map | `map.lua:22` | none |
| Date | `date.lua:29` | none |
| Strings | `strings.lua:25` | none |
| Graphics | `graphics.lua:29` | none |
| AnimationManager | `graphics.lua:858` | none |
| Audio | `audio.lua:30` | none |
| MoviePlayer | `movie_player.lua:26` | none |
| FileSystem | `filesystem.lua:34` | none |

### 6.2 Entity Hierarchy

| Class | File:Line | Superclass |
|-------|-----------|------------|
| Entity | `entity.lua:22` | none |
| Humanoid | `entities/humanoid.lua:22` | Entity |
| Object | `entities/object.lua:24` | Entity |
| SideObject | `entities/object.lua:1075` | Object |
| Machine | `entities/machine.lua:24` | Object |
| Patient | `entities/humanoids/patient.lua:22` | Humanoid |
| Staff | `entities/humanoids/staff.lua:26` | Humanoid |
| Doctor | `entities/humanoids/staff/doctor.lua:28` | Staff |
| Nurse | `entities/humanoids/staff/nurse.lua:27` | Staff |
| Handyman | `entities/humanoids/staff/handyman.lua:27` | Staff |
| Receptionist | `entities/humanoids/staff/receptionist.lua:27` | Staff |
| Vip | `entities/humanoids/vip.lua:60` | Humanoid |
| Inspector | `entities/humanoids/inspector.lua:26` | Humanoid |
| GrimReaper | `entities/humanoids/grim_reaper.lua:21` | Humanoid |
| Litter | `objects/litter.lua:51` | Entity |

### 6.3 Object Subclasses

| Class | File:Line | Superclass |
|-------|-----------|------------|
| Door | `objects/door.lua:35` | Object |
| SwingDoor | `objects/doors/swing_door_right.lua:33` | Door |
| EntranceDoor | `objects/doors/entrance_right_door.lua:34` | Object |
| Bench | `objects/bench.lua:146` | Object |
| Chair | `objects/chair.lua:156` | Object |
| Plant | `objects/plant.lua:91` | Object |
| ReceptionDesk | `objects/reception_desk.lua:71` | Object |
| Rathole | `objects/rathole.lua:53` | Object |
| Helicopter | `objects/helicopter.lua:41` | Object |
| AtomAnalyser | `objects/analyser.lua:59` | Object |
| OperatingSink | `objects/op_sink1.lua:66` | Object (+ slaveMixin) |
| RadiationShield | `objects/radiation_shield.lua:73` | Object (+ slaveMixin) |
| SurgeonScreen | `objects/surgeon_screen.lua:103` | Object |
| OperatingTable | `objects/machines/operating_table.lua:123` | Machine (+ slaveMixin) |

### 6.4 Room Hierarchy (all extend Room)

| Class | File:Line |
|-------|-----------|
| Room | `room.lua:21` |
| GPRoom | `rooms/gp.lua:44` |
| OperatingTheatreRoom | `rooms/operating_theatre.lua:51` |
| WardRoom | `rooms/ward.lua:52` |
| ResearchRoom | `rooms/research.lua:51` |
| TrainingRoom | `rooms/training.lua:41` |
| PharmacyRoom | `rooms/pharmacy.lua:44` |
| PsychRoom | `rooms/psych.lua:45` |
| StaffRoom | `rooms/staff_room.lua:40` |
| ToiletRoom | `rooms/toilets.lua:39` |
| BloodMachineRoom | `rooms/blood_machine_room.lua:45` |
| CardiogramRoom | `rooms/cardiogram.lua:45` |
| DecontaminationRoom | `rooms/decontamination.lua:45` |
| DNAFixerRoom | `rooms/dna_fixer.lua:46` |
| ElectrolysisRoom | `rooms/electrolysis.lua:45` |
| FractureRoom | `rooms/fracture_clinic.lua:45` |
| GeneralDiagRoom | `rooms/general_diag.lua:44` |
| HairRestorationRoom | `rooms/hair_restoration.lua:45` |
| InflationRoom | `rooms/inflation.lua:45` |
| JellyVatRoom | `rooms/jelly_vat.lua:45` |
| ScannerRoom | `rooms/scanner_room.lua:47` |
| SlackTongueRoom | `rooms/slack_tongue.lua:45` |
| UltrascanRoom | `rooms/ultrascan.lua:45` |
| XRayRoom | `rooms/x_ray_room.lua:45` |

### 6.5 Hospital Hierarchy

| Class | File:Line | Superclass |
|-------|-----------|------------|
| Hospital | `hospital.lua:23` | none |
| PlayerHospital | `hospitals/player_hospital.lua:25` | Hospital |
| AIHospital | `hospitals/ai_hospital.lua:21` | Hospital |

### 6.6 UI/Window System

| Class | File:Line | Superclass |
|-------|-----------|------------|
| Window | `window.lua:24` | none |
| Panel | `window.lua:168` | none |
| Button | `window.lua:594` | none |
| Scrollbar | `window.lua:834` | none |
| Textbox | `window.lua:943` | none |
| HotkeyBox | `window.lua:1342` | none |
| UI | `ui.lua:24` | Window |
| GameUI | `game_ui.lua:25` | UI |
| UIFullscreen | `dialogs/fullscreen.lua:22` | Window |
| UIResizable | `dialogs/resizables/resizable.lua:22` | Window |

### 6.7 Dialog Classes (75 total)

**Window-mode (extend Window):**
| Class | File:Line |
|-------|-----------|
| UIAdviser | `dialogs/adviser.lua:24` |
| UIBottomPanel | `dialogs/bottom_panel.lua:22` |
| UIBuildRoom | `dialogs/build_room.lua:23` |
| UIConfirmDialog | `dialogs/confirm_dialog.lua:23` |
| UIFurnishCorridor | `dialogs/furnish_corridor.lua:27` |
| UIHireStaff | `dialogs/hire_staff.lua:21` |
| UIInformation | `dialogs/information.lua:22` |
| UIJukebox | `dialogs/jukebox.lua:24` |
| UIMachine | `dialogs/machine_dialog.lua:21` |
| UIMenuBar | `dialogs/menu.lua:26` |
| UIMessage | `dialogs/message.lua:22` |
| UIPatient | `dialogs/patient.lua:30` |
| UIPlaceObjects | `dialogs/place_objects.lua:31` |
| UIPlaceStaff | `dialogs/place_staff.lua:26` |
| UIQueue | `dialogs/queue_dialog.lua:24` |
| UIQueuePopup | `dialogs/queue_dialog.lua:362` |
| UIStaff | `dialogs/staff_dialog.lua:29` |
| UIStaffRise | `dialogs/staff_rise.lua:23` |
| UIWatch | `dialogs/watch.lua:23` |
| Subtitles | `dialogs/subtitles.lua:22` |
| UIEditRoom | `dialogs/edit_room.lua:23` |
| TreeControl | `dialogs/tree_ctrl.lua:484` |
| UIHotkeyAssignKeyPane | `dialogs/resizables/hotkey_assign.lua:568` |

**Fullscreen (extend UIFullscreen):**
UIAnnualReport, UIBankManager, UICasebook, UIFax, UIGraphs, UIPolicy, UIProgressReport, UIResearch, UIStaffManagement, UITownMap

**Resizable (extend UIResizable):**
UIAdviserHistory, UICallsDispatcher, UICheats, UICustomise, UIDirectoryBrowser, UIDropdown, UIFileBrowser, UIFolder, UIHotkeyAssign, UILuaConsole, UIMachineMenu, UIMainMenu, UIMapEditor, UIMenuList, UINewGame, UIOptions, UIResolution, UIScrollSpeed, UIShiftScrollSpeed, UIZoomSpeed, UISoundSettings, UITipOfTheDay, UIUpdate

**FileBrowser variants (extend UIFileBrowser):**
UIChooseFont, UIChooseSoundfont, UILoadGame, UILoadMap, UISaveGame, UISaveMap

**MenuList variants (extend UIMenuList):**
UICustomCampaign, UICustomGame, UIMakeDebugPatient

**TreeNode hierarchy:**
TreeNode (`tree_ctrl.lua:22`), FileTreeNode (`tree_ctrl.lua:185`), DirTreeNode (`directory_browser.lua:27`), InstallDirTreeNode (`directory_browser.lua:61`), FilteredFileTreeNode (`file_browser.lua:25`), DummyRootNode (`tree_ctrl.lua:451`), FilteredTreeControl (`file_browser.lua:70`)

### 6.8 Humanoid Actions (all extend HumanoidAction)

| Class | File:Line |
|-------|-----------|
| HumanoidAction | `humanoid_action.lua:22` |
| AnswerCallAction | `humanoid_actions/answer_call.lua:21` |
| CallCheckPointAction | `humanoid_actions/call_checkpoint.lua:21` |
| CheckWatchAction | `humanoid_actions/check_watch.lua:21` |
| DieAction | `humanoid_actions/die.lua:21` |
| FallingAction | `humanoid_actions/falling.lua:21` |
| GetUpAction | `humanoid_actions/get_up.lua:21` |
| IdleAction | `humanoid_actions/idle.lua:21` |
| IdleSpawnAction | `humanoid_actions/idle_spawn.lua:21` |
| KnockDoorAction | `humanoid_actions/knock_door.lua:21` |
| MeanderAction | `humanoid_actions/meander.lua:21` |
| MultiUseObjectAction | `humanoid_actions/multi_use_object.lua:21` |
| OnGroundAction | `humanoid_actions/on_ground.lua:21` |
| PeeAction | `humanoid_actions/pee.lua:21` |
| PickupAction | `humanoid_actions/pickup.lua:21` |
| QueueAction | `humanoid_actions/queue.lua:21` |
| SeekReceptionAction | `humanoid_actions/seek_reception.lua:21` |
| SeekRoomAction | `humanoid_actions/seek_room.lua:21` |
| SeekStaffRoomAction | `humanoid_actions/seek_staffroom.lua:21` |
| SeekToiletsAction | `humanoid_actions/seek_toilets.lua:22` |
| ShakeFistAction | `humanoid_actions/shake_fist.lua:21` |
| SpawnAction | `humanoid_actions/spawn.lua:21` |
| StaffReceptionAction | `humanoid_actions/staff_reception.lua:21` |
| SweepFloorAction | `humanoid_actions/sweep_floor.lua:21` |
| TapFootAction | `humanoid_actions/tap_foot.lua:21` |
| UseObjectAction | `humanoid_actions/use_object.lua:24` |
| UseScreenAction | `humanoid_actions/use_screen.lua:21` |
| UseStaffRoomAction | `humanoid_actions/use_staffroom.lua:21` |
| VaccinateAction | `humanoid_actions/vaccinate.lua:21` |
| VipGoToNextRoomAction | `humanoid_actions/vip_go_to_next_room.lua:21` |
| VomitAction | `humanoid_actions/vomit.lua:21` |
| WalkAction | `humanoid_actions/walk.lua:21` |
| YawnAction | `humanoid_actions/yawn.lua:21` |

### 6.9 Support Classes

| Class | File:Line | Superclass |
|-------|-----------|------------|
| StaffProfile | `staff_profile.lua:21` | none |
| Queue | `queue.lua:31` | none |
| EntityMap | `entity_map.lua:21` | none |
| Earthquake | `earthquake.lua:22` | none |
| Epidemic | `epidemic.lua:25` | none |
| Cheats | `cheats.lua:27` | none |
| CallsDispatcher | `calls_dispatcher.lua:25` | none |
| ResearchDepartment | `research_department.lua:32` | none |
| EndConditions | `endconditions.lua:44` | none |

### 6.10 Announcer System

| Class | File:Line | Superclass |
|-------|-----------|------------|
| AnnouncementQueue | `announcer.lua:45` | none |
| AnnouncementEntry | `announcer.lua:107` | none |
| Announcer | `announcer.lua:127` | none |

---

## 7. Inheritance Depth Statistics

| Hierarchy Root | Total Classes | Max Depth | Avg Depth | Branching Factor |
|----------------|---------------|-----------|-----------|------------------|
| Entity | 15 | 4 | 1.9 | 2.3 |
| Room | 24 | 2 | 1.0 | 23.0 |
| Hospital | 3 | 1 | 0.7 | 2.0 |
| Window | 32 | 4 | 2.1 | 2.8 |
| HumanoidAction | 33 | 2 | 1.0 | 32.0 |
| TreeNode | 7 | 3 | 1.7 | 1.8 |
| Standalone | 21 | 0 | 0.0 | N/A |
| **TOTAL** | **195** | **4** | **1.2** | — |

---

## 8. Critical Design Rules

### 8.1 DO
- ✅ Call `Parent.__init(self)` first in `__init`
- ✅ Call `Parent.method(self)` first in overridden methods (usually)
- ✅ Use `class.is(obj, Class)` for polymorphic checks
- ✅ Use `class.type(obj)` for exact-type serialization
- ✅ Use adoption (`Mixin(_ENV)`) for cross-cutting concerns
- ✅ Implement `afterLoad()` for save-game compatibility

### 8.2 DON'T
- ❌ Don't use multiple inheritance (not supported)
- ❌ Don't forget `__init` chaining — breaks object state
- ❌ Don't override `__index` or `__newindex` on class tables
- ❌ Don't modify parent class tables at runtime (affects all children)
- ❌ Don't use `class.is` with non-class tables (returns false)

### 8.3 Common Bugs

| Bug | Cause | Fix |
|-----|-------|-----|
| "attempt to call nil value" | Forgot `Parent.__init(self)` | Add superclass init call |
| Method not found | Typo in method name or wrong superclass | Check spelling, verify hierarchy |
| Infinite recursion | `self:method()` instead of `Parent.method(self)` | Use explicit superclass call |
| Type check fails | Using `class.type` instead of `class.is` | Use `class.is` for hierarchy checks |
| Mixin methods missing | Adoption order overwrites | Adopt mixins before defining overrides |

---

## 9. Quick Reference Card

```lua
-- DECLARE CLASS
class "ClassName" (function(_ENV) ... end)

-- DECLARE SUBCLASS
class "ChildName" (ParentClass) (function(_ENV) ... end)

-- INSTANCE CREATION
local instance = ClassName(args)

-- SUPERCLASS CALL
ParentClass.method(self, args)
-- or
self.super.method(self, args)

-- TYPE CHECKS
class.is(instance, ClassName)      -- hierarchy-aware
class.type(instance) == ClassName  -- exact match
instance:isType("ClassName")       -- Humanoid helper

-- ADOPTION (MIXIN)
MixinFunction(_ENV)

-- CLASS METADATA
Class.__name      -- "ClassName"
Class.super       -- ParentClass or nil
Class.__class     -- Class (self-ref)
```

---

*End of SUMMARY.md — 195 classes documented across 10 categories*
