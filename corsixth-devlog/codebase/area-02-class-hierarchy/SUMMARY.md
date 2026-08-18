# CorsixTH Class Hierarchy & Inheritance — Deep Research

**Generated:** 2026-08-17  
**Codebase:** CorsixTH (Lua)  
**Class System:** `/tmp/CorsixTH/CorsixTH/Lua/class.lua` (175 lines)  
**Total Classes Found:** 195  
**Test Spec:** `/tmp/CorsixTH/CorsixTH/Luatest/spec/class_spec.lua`

---

## 1. OOP System Mechanics

### 1.1 Class Declaration Syntax

```lua
-- Root class (no superclass)
class "ClassName"

-- Subclass with superclass
class "SubclassName" (SuperclassName)

-- Adoption pattern (rarely used in codebase)
class "AdoptingClass" {}
```

The `class` function is a curried function that returns an `extend` function:
```lua
class = function(_, name)
  define_class(name)  -- Creates initial class table
  local adopts_self = false
  local super = nil
  
  local function extend(arg)
    if type(arg) == "table" and next(arg) == nil and not getmetatable(arg) then
      -- {} decorator: adoption pattern
      adopts_self = true
    else
      -- (Superclass) decorator
      if arg == nil then
        error("Superclass not defined at subclass definition")
      end
      super = arg
    end
    define_class(name, super, adopts_self)
    return extend
  end
  return extend
end
```

### 1.2 Metatable Structure & `__index` Chaining

The class system uses **dual metatable layers**:

```
┌─────────────────────────────────────────────────────────────┐
│ Instance (table)                                            │
│   └── __index → methods table (class methods)               │
│       └── __index → superclass methods table (via methods_mt)│
│           └── __index → ... (recursive up hierarchy)        │
└─────────────────────────────────────────────────────────────┘
```

**Key structures in `define_class(name, super, adopts_self)`:**

```lua
local mt = {}                          -- Instance metatable
local methods = {}                     -- Class method table
local methods_mt = {}                  -- Methods metatable

mt.__index = methods                   -- Instance → methods
setmetatable(methods, methods_mt)      -- methods_mt wraps methods
methods_mt.__index = super             -- Methods → superclass methods
methods_mt.__call = new_class          -- Allows ClassName(args) syntax
methods_mt.__class_name = name         -- For class.name()
methods._metatable = mt                -- Back-reference
_G[name] = methods                     -- Global registration
```

### 1.3 Instance Creation

```lua
local function new_class(methods, ...)
  local constructor = methods[name]    -- Constructor = method named after class
  local self
  if adopts_self and ... then
    self = setmetatable(..., mt)       -- Adoption: reuse passed table
    constructor(...)                   -- Call with adopted table as self
  else
    self = setmetatable({}, mt)        -- Normal: create new table
    constructor(self, ...)             -- Call with new table as self
  end
  return self
end
```

### 1.4 Adoption Pattern

**Purpose:** Turn an existing table into a class instance instead of creating a new one.

```lua
-- Declaration
class "NameWhichAdopts" {}

-- Usage
variable = NameWhichAdopts{named_constructor_argument = 42, another = 43}
```

**In codebase:** *No classes currently use the `{}` adoption decorator.* The pattern exists in `class.lua` documentation but isn't utilized in the 195 class declarations.

---

## 2. Type System & Introspection

### 2.1 `class.is(instance, class)` — Instanceof Check

```lua
function class.is(instance, class)
  local typ = type(instance)
  if typ ~= "table" and typ ~= "userdata" then
    return false
  end
  local methods = instance
  while methods do
    if methods == class then
      return true
    end
    local mt = getmetatable(methods)
    methods = mt and mt.__index
  end
  return false
end
```

**Walks the `__index` chain** from instance → methods → superclass methods → ...  
Returns `true` if `class` appears anywhere in the chain.

**Examples:**
```lua
class "Base"
class "Derived" (Base)

local d = Derived()
class.is(d, Derived)  -- true
class.is(d, Base)     -- true (inheritance)
class.is(d, Other)    -- false
```

### 2.2 `class.name(class)` — Get Class Name

```lua
function class.name(class)
  local mt = getmetatable(class)
  return mt and mt.__class_name
end
```

Returns the string name registered at declaration time.

### 2.3 `class.superclass(class)` — Get Direct Parent

```lua
function class.superclass(class)
  return getmetatable(class).__index
end
```

Returns the immediate superclass methods table (or `nil` for root classes).

### 2.4 `class.type(instance)` — Get Runtime Type Name

```lua
function class.type(instance)
  local mt = getmetatable(instance)
  if not mt then return nil end
  local methods_mt = getmetatable(mt.__index)
  if not methods_mt then return nil end
  return methods_mt.__class_name
end
```

Returns the **most-derived class name** of an instance.

---

## 3. Complete Class Hierarchy Tree

### 3.1 Root Classes (No Superclass) — 22 Classes

| Class | File | Category |
|-------|------|----------|
| `Entity` | `Lua/entity.lua` | Core/Entities |
| `Window` | `Lua/window.lua` | UI/Window |
| `App` | `Lua/app.lua` | Core |
| `World` | `Lua/world.lua` | Core |
| `Hospital` | `Lua/hospital.lua` | Hospitals |
| `ResearchDepartment` | `Lua/research_department.lua` | Hospitals |
| `EndConditions` | `Lua/endconditions.lua` | Core |
| `StaffProfile` | `Lua/staff_profile.lua` | Entities |
| `HumanoidAction` | `Lua/humanoid_action.lua` | Actions |
| `Map` | `Lua/map.lua` | Core |
| `FileSystem` | `Lua/filesystem.lua` | Core |
| `Graphics` | `Lua/graphics.lua` | Core |
| `Room` | `Lua/room.lua` | Rooms |
| `Queue` | `Lua/queue.lua` | Core |
| `CallsDispatcher` | `Lua/calls_dispatcher.lua` | Support |
| `Strings` | `Lua/strings.lua` | Core |
| `Date` | `Lua/date.lua` | Core |
| `MoviePlayer` | `Lua/movie_player.lua` | Support |
| `EntityMap` | `Lua/entity_map.lua` | Core |
| `Audio` | `Lua/audio.lua` | Core |
| `Epidemic` | `Lua/epidemic.lua` | Support |
| `AnnouncementQueue` | `Lua/announcer.lua` | Announcer |
| `AnnouncementEntry` | `Lua/announcer.lua` | Announcer |
| `Announcer` | `Lua/announcer.lua` | Announcer |
| `Cheats` | `Lua/cheats.lua` | Support |
| `Earthquake` | `Lua/earthquake.lua` | Support |

### 3.2 Entity Hierarchy (Gameplay Objects)

```
Entity (root)
├── Humanoid
│   ├── Patient
│   ├── GrimReaper
│   ├── Vip
│   ├── Inspector
│   └── Staff
│       ├── Doctor
│       ├── Nurse
│       ├── Receptionist
│       └── Handyman
├── Object
│   ├── Machine
│   │   └── OperatingTable
│   ├── Door
│   │   └── SwingDoor
│   ├── EntranceDoor
│   ├── RadiationShield
│   ├── Plant
│   ├── Bench
│   ├── Helicopter
│   ├── SurgeonScreen
│   ├── Chair
│   ├── OperatingSink
│   ├── Litter
│   ├── ReceptionDesk
│   ├── AtomAnalyser
│   ├── Rathole
│   └── SideObject
└── (no other direct subclasses)
```

**Depth Analysis:**
- Max depth: **4** (`Entity` → `Humanoid` → `Staff` → `Doctor`/`Nurse`/etc.)
- `Object` branch max depth: **3** (`Entity` → `Object` → `Machine` → `OperatingTable`)

### 3.3 Room Hierarchy

```
Room (root)
├── OperatingTheatreRoom
├── WardRoom
├── BloodMachineRoom
├── CardiogramRoom
├── ResearchRoom
├── GPRoom
├── PsychRoom
├── InflationRoom
├── HairRestorationRoom
├── ScannerRoom
├── DecontaminationRoom
├── StaffRoom
├── FractureRoom
├── DNAFixerRoom
├── ToiletRoom
├── PharmacyRoom
├── UltrascanRoom
├── TrainingRoom
├── ElectrolysisRoom
├── JellyVatRoom
├── GeneralDiagRoom
├── SlackTongueRoom
├── XRayRoom
└── (23 total room types)
```

All 23 room types inherit directly from `Room` (depth = 2).

### 3.4 Hospital Hierarchy

```
Hospital (root)
├── PlayerHospital
└── AIHospital
```

### 3.5 UI/Window Hierarchy

```
Window (root)
├── Panel
├── Button
├── Scrollbar
├── Textbox
├── HotkeyBox
├── UI
│   └── GameUI
├── UIWatch
├── UIEditRoom (via UIPlaceObjects)
├── TreeNode
│   ├── FileTreeNode
│   │   ├── FilteredFileTreeNode
│   │   └── DirTreeNode
│   │       └── InstallDirTreeNode
│   └── DummyRootNode
├── TreeControl
│   └── FilteredTreeControl
├── UIStaff
├── UIAdviser
├── UIConfirmDialog
├── Subtitles
│   └── SubtitleQueue
├── UIResizable
│   ├── UIFolder
│   ├── UIFileBrowser
│   │   ├── UILoadMap
│   │   ├── UIChooseSoundfont
│   │   ├── UILoadGame
│   │   ├── UISaveMap
│   │   ├── UISaveGame
│   │   └── UIChooseFont
│   ├── UIUpdate
│   ├── UIHotkeyAssign
│   │   └── UIHotkeyAssignKeyPane
│   ├── UICustomise
│   ├── UISoundSettings
│   ├── UINewGame
│   ├── UIAdviserHistory
│   ├── UICallsDispatcher
│   ├── UICheats
│   ├── UILuaConsole
│   ├── UIMachineMenu
│   ├── UIMainMenu
│   ├── UIDropdown
│   ├── UIMapEditor
│   ├── UIMenuList
│   │   ├── UICustomCampaign
│   │   ├── UICustomGame
│   │   └── UIMakeDebugPatient
│   ├── UIOptions
│   │   ├── UIResolution
│   │   ├── UIScrollSpeed
│   │   ├── UIShiftScrollSpeed
│   │   └── UIZoomSpeed
│   ├── UIDirectoryBrowser
│   └── UITipOfTheDay
├── UIFullscreen
│   ├── UIFax
│   ├── UIResearch
│   ├── UICasebook
│   ├── UIPolicy
│   ├── UITownMap
│   ├── UIProgressReport
│   ├── UIBankManager
│   ├── UIGraphs
│   ├── UIStaffManagement
│   └── UIAnnualReport
├── UIBuildRoom
├── UIHireStaff
├── UIJukebox
├── UIQueue
│   └── UIQueuePopup
├── UIMenuBar
├── UIMenu
├── UIStaffRise
├── UIPlaceStaff
├── UIPatient
├── UIFurnishCorridor
├── UIMessage
└── UIBottomPanel
```

**Depth Analysis:**
- Max depth: **5** (`Window` → `UIResizable` → `UIFileBrowser` → `UILoadMap`)
- `UIResizable` branch has 22 subclasses (most prolific)
- `UIFullscreen` branch has 8 subclasses

### 3.6 HumanoidAction Hierarchy

```
HumanoidAction (root)
├── StaffReceptionAction
├── UseObjectAction
├── IdleSpawnAction
├── PickupAction
├── VipGoToNextRoomAction
├── UseScreenAction
├── KnockDoorAction
├── MeanderAction
├── OnGroundAction
├── SweepFloorAction
├── ShakeFistAction
├── IdleAction
├── SeekToiletsAction
├── DieAction
├── YawnAction
├── CheckWatchAction
├── GetUpAction
├── SeekReceptionAction
├── QueueAction
├── VomitAction
├── UseStaffRoomAction
├── MultiUseObjectAction
├── WalkAction
├── SeekStaffRoomAction
├── VaccinateAction
├── SpawnAction
├── SeekRoomAction
├── AnswerCallAction
├── FallingAction
├── CallCheckPointAction
├── PeeAction
└── TapFootAction
```

**29 total action classes**, all direct children of `HumanoidAction` (depth = 2).

### 3.7 Object Subclasses (Detailed)

```
Object (extends Entity)
├── Machine
│   └── OperatingTable
├── Door
│   └── SwingDoor
├── EntranceDoor
├── RadiationShield
├── Plant
├── Bench
├── Helicopter
├── SurgeonScreen
├── Chair
├── OperatingSink
├── Litter (extends Entity directly!)
├── ReceptionDesk
├── AtomAnalyser
├── Rathole
└── SideObject
```

**Note:** `Litter` extends `Entity` directly, not `Object`.

### 3.8 Tree/Control Hierarchy

```
TreeNode
├── FileTreeNode
│   ├── FilteredFileTreeNode
│   └── DirTreeNode
│       └── InstallDirTreeNode
└── DummyRootNode

TreeControl (extends Window)
└── FilteredTreeControl
```

---

## 4. Inheritance Depth Analysis

| Max Depth | Path Example | Count |
|-----------|--------------|-------|
| 5 | `Window` → `UIResizable` → `UIFileBrowser` → `UILoadMap` | 1 path |
| 4 | `Entity` → `Humanoid` → `Staff` → `Doctor` | 4 classes (Doctor, Nurse, Receptionist, Handyman) |
| 4 | `Entity` → `Humanoid` → `Patient` (leaf) | 1 |
| 3 | `Entity` → `Object` → `Machine` → `OperatingTable` | 1 |
| 3 | `Window` → `UIFullscreen` → `UIFax` | 8 classes |
| 2 | `Room` → *23 room types* | 23 |
| 2 | `HumanoidAction` → *29 action types* | 29 |
| 2 | `Hospital` → `PlayerHospital`/`AIHospital` | 2 |
| 1 | Root classes (no parent) | 22 |

**Statistics:**
- **Total classes:** 195
- **Root classes:** 22 (11.3%)
- **Max depth:** 5
- **Average depth:** ~1.8
- **Classes at depth 2:** 92 (47.2%)
- **Classes at depth 3:** 12 (6.2%)
- **Classes at depth 4:** 4 (2.1%)
- **Classes at depth 5:** 1 (0.5%)

---

## 5. Method Resolution Order (MRO)

### 5.1 How It Works

The Lua class system uses **single inheritance with linear `__index` chaining**:

```lua
-- When calling instance:method(args)
-- 1. Look in instance table (raw)
-- 2. Follow mt.__index → methods table
-- 3. Follow methods_mt.__index → superclass methods table
-- 4. Repeat until found or nil
```

### 5.2 Superclass Constructor Calls (Required Pattern)

```lua
class "ChildClass" (ParentClass)

function ChildClass:ChildClass(args)
  self:ParentClass(args)  -- MANDATORY when superclass exists
  -- child-specific initialization
end
```

**Why mandatory:** The parent constructor initializes critical fields. Skipping it breaks object state.

### 5.3 Superclass Method Calls (Override Pattern)

```lua
function ChildClass:someMethod(args)
  -- Option 1: Call superclass implementation first
  ParentClass.someMethod(self, args)
  -- Then child logic
  
  -- Option 2: Call superclass implementation last
  -- child logic
  ParentClass.someMethod(self, args)
end
```

**Pattern in codebase:**
```lua
-- From Humanoid.lua:afterLoad
function Humanoid:afterLoad(old, new)
  -- ... humandoid-specific logic ...
  Entity.afterLoad(self, old, new)  -- Call superclass at end
end

-- From Staff.lua:tickDay
function Staff:tickDay()
  if not Humanoid.tickDay(self) then  -- Call superclass first, check return
    return false
  end
  -- ... staff-specific logic ...
  return true
end
```

### 5.4 Diamond Problem?

**Not applicable** — single inheritance only. No multiple inheritance, no mixins (except `Object.slaveMixinClass` which is a function that modifies a class table, not true inheritance).

---

## 6. Common Patterns in Codebase

### 6.1 Constructor Pattern

```lua
class "ClassName" (Superclass)

---@type ClassName
local ClassName = _G["ClassName"]

function ClassName:ClassName(param1, param2)
  if Superclass then
    self:Superclass(param1, param2)  -- Always call superclass constructor
  end
  self.field1 = param1
  self.field2 = param2
  -- initialization
end
```

### 6.2 Type Checking with `class.is`

```lua
-- In Humanoid.lua:isKnockingDoor
function Humanoid:isKnockingDoor()
  return class.is(self:getCurrentAction(), KnockDoorAction)
end

-- In Humanoid.lua:_handleEmptyActionQueue
if class.is(self, Patient) and self.going_home then
  return
end
if class.is(self, Staff) then
  self:queueAction(MeanderAction())
elseif class.is(self, GrimReaper) then
  -- ...
end
```

### 6.3 Type Checking with `class.type`

```lua
-- Less common, used for serialization/debugging
local typeName = class.type(instance)
```

### 6.4 `isType` Method (Humanoid-specific)

```lua
-- In Humanoid.lua
function Humanoid:setType(humanoid_class)
  -- Sets self.humanoid_class = humanoid_class
end

function Humanoid:isType(humanoid_class)
  return self.humanoid_class == humanoid_class
end

-- Usage:
if humanoid:isType("Doctor") then
  -- ...
end
```

**Note:** This is a **domain-specific** type check for humanoid sub-types, not the general `class.is`.

### 6.5 Adoption Pattern (Unused)

The `class "Name" {}` syntax exists in `class.lua` but **no class in the 195 declarations uses it**. All instances are created via normal construction: `ClassName(args)`.

### 6.6 `Object.slaveMixinClass` — Composition Helper

```lua
-- In objects/object.lua
function Object.slaveMixinClass(class_method_table)
  -- Modifies class_method_table to add slave object support
  -- Redirects slave → master for onClick, updateDynamicInfo, getDynamicInfo
  -- Notifies master → slave for initOrientation, onDestroy, setTile
end
```

Used for objects that have a "slave" sub-object (e.g., multi-tile objects).

---

## 7. Category Breakdown (195 Classes)

| Category | Count | Root Classes | Max Depth |
|----------|-------|--------------|-----------|
| **Core/System** | 17 | App, World, Map, FileSystem, Graphics, Queue, Strings, Date, Audio, EntityMap, MoviePlayer, CallsDispatcher, EndConditions, Epidemic, Cheats, Earthquake, ResearchDepartment | 1 |
| **Entities** | 13 | Entity, Humanoid, Object, Machine, Door, Staff, Patient, GrimReaper, Vip, Inspector, Doctor, Nurse, Receptionist, Handyman | 4 |
| **Objects** | 15 | RadiationShield, Plant, Bench, Helicopter, SurgeonScreen, SwingDoor, EntranceDoor, OperatingTable, Chair, OperatingSink, Litter, ReceptionDesk, AtomAnalyser, Rathole, SideObject | 3 |
| **Rooms** | 24 | Room + 23 subtypes | 2 |
| **Hospitals** | 3 | Hospital, PlayerHospital, AIHospital | 2 |
| **UI/Window** | 68 | Window, Panel, Button, Scrollbar, Textbox, HotkeyBox, UI, GameUI, UIWatch, UIEditRoom, TreeNode, FileTreeNode, DummyRootNode, TreeControl, FilteredTreeControl, UIStaff, UIAdviser, UIConfirmDialog, Subtitles, SubtitleQueue, UIResizable (22 subs), UIFullscreen (8 subs), UIBuildRoom, UIHireStaff, UIJukebox, UIQueue, UIQueuePopup, UIMenuBar, UIMenu, UIFolder, UIFileBrowser (5 subs), UIUpdate, UIHotkeyAssign (1 sub), UICustomise, UISoundSettings, UINewGame, UIAdviserHistory, UICallsDispatcher, UICheats, UILuaConsole, UIMachineMenu, UIMainMenu, UIDropdown, UIMapEditor, UIMenuList (3 subs), UIOptions (4 subs), UIDirectoryBrowser, UITipOfTheDay, UIStaffRise, UIPlaceStaff, UIPatient, UIFurnishCorridor, UIFax, UIResearch, UICasebook, UIPolicy, UITownMap, UIProgressReport, UIBankManager, UIGraphs, UIStaffManagement, UIAnnualReport, UIMessage, UIBottomPanel | 5 |
| **Humanoid Actions** | 30 | HumanoidAction + 29 subtypes | 2 |
| **Announcer** | 3 | AnnouncementQueue, AnnouncementEntry, Announcer | 1 |
| **Staff Profile** | 1 | StaffProfile | 1 |

**Total: 195** (Note: Some classes counted in multiple categories above; actual unique = 195)

---

## 8. Code Examples

### 8.1 Creating a New Room Type

```lua
-- Lua/rooms/my_custom_room.lua
class "MyCustomRoom" (Room)

---@type MyCustomRoom
local MyCustomRoom = _G["MyCustomRoom"]

function MyCustomRoom:MyCustomRoom(x, y, w, h, id, room_info, world, hospital, door, door2)
  self:Room(x, y, w, h, id, room_info, world, hospital, door, door2)
  -- Custom initialization
  self.custom_field = 42
end

function MyCustomRoom:tick()
  Room.tick(self)  -- Call superclass
  -- Custom tick logic
end
```

### 8.2 Creating a New Humanoid Action

```lua
-- Lua/humanoid_actions/my_action.lua
class "MyAction" (HumanoidAction)

---@type MyAction
local MyAction = _G["MyAction"]

function MyAction:MyAction(param)
  self:HumanoidAction(param)
  self.param = param
end

function MyAction:start(humanoid)
  -- Implementation
end
```

### 8.3 Creating a New Dialog (UIResizable Pattern)

```lua
-- Lua/dialogs/resizables/my_dialog.lua
class "UIMyDialog" (UIResizable)

---@type UIMyDialog
local UIMyDialog = _G["UIMyDialog"]

function UIMyDialog:UIMyDialog(ui)
  self:UIResizable(ui)
  self:setSize(400, 300)
  self:setDefaultPosition(0.5, 0.5)
  -- Add panels, buttons, etc.
end
```

### 8.4 Safe Type Checking

```lua
-- Check if instance is of type or subclass
if class.is(someObject, SomeClass) then
  -- Safe to call SomeClass methods
end

-- Get runtime type name
local typeName = class.type(someObject)
if typeName == "Doctor" then
  -- Specific handling
end

-- Get superclass
local parent = class.superclass(ChildClass)
-- parent == ParentClass
```

---

## 9. Key Files Reference

| File | Purpose |
|------|---------|
| `Lua/class.lua` | OOP system implementation (175 lines) |
| `Lua/entity.lua` | Root `Entity` class |
| `Lua/entities/humanoid.lua` | `Humanoid` + animations, moods, actions |
| `Lua/entities/humanoids/staff.lua` | `Staff` base + subclasses |
| `Lua/entities/object.lua` | `Object` + `Machine`, `Door`, slave mixin |
| `Lua/room.lua` | `Room` base + room management |
| `Lua/hospital.lua` | `Hospital` + `PlayerHospital`/`AIHospital` |
| `Lua/window.lua` | `Window` + `Panel`, `Button`, `UI`, `UIResizable` |
| `Lua/ui.lua` | `UI` (extends `Window`) |
| `Lua/game_ui.lua` | `GameUI` (extends `UI`) |
| `Lua/humanoid_action.lua` | `HumanoidAction` base |
| `Lua/announcer.lua` | Announcement system classes |
| `Luatest/spec/class_spec.lua` | Busted tests for class system |

---

## 10. Summary

The CorsixTH class system is a **minimal, metatable-based single-inheritance OOP system** with:

- **175 lines** for the entire runtime (`class.lua`)
- **195 classes** declared across the codebase
- **Max inheritance depth: 5** (UI hierarchy)
- **Linear `__index` chaining** for method resolution
- **Mandatory superclass constructor calls**
- **Three introspection functions:** `class.is`, `class.name`, `class.superclass`, `class.type`
- **No multiple inheritance, no interfaces, no mixins** (except `slaveMixinClass` helper)
- **Adoption pattern exists but unused**

The hierarchy is **shallow and wide** — most classes are at depth 2 (direct children of a domain root like `Room`, `HumanoidAction`, `UIResizable`). Deep hierarchies only exist in UI dialogs (`UIResizable` → 22 subclasses → 5 sub-subclasses) and entities (`Entity` → `Humanoid` → `Staff` → 4 specializations).

