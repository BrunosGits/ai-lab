# CorsixTH Data File Formats — Diseases, Rooms, Objects

> **Scope:** 34 disease files, 23 room files, 43 object files  
> **Source:** `/tmp/CorsixTH/CorsixTH/Lua/{diseases,rooms,objects}/*.lua`  
> **Generated:** 2026-08-18

---

## 1. Disease Schema (`Lua/diseases/*.lua`)

Each disease file returns a table with the following fields. All files follow the pattern `local disease = {}; ... return disease`.

### 1.1 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (matches filename). Used as key in `hospital.disease_casebook`. |
| `expertise_id` | integer | Index into expertise/research progression (1–35). |
| `visuals_id` \| `non_visuals_id` | integer | **Exactly one required.** `visuals_id` for diseases with visible patient sprites; `non_visuals_id` for diseases without unique visuals (reuses base patient sprite). |
| `name` | string | Localized string: `_S.diseases.<id>.name` |
| `cause` | string | Localized string: `_S.diseases.<id>.cause` |
| `symptoms` | string | Localized string: `_S.diseases.<id>.symptoms` |
| `cure` | string | Localized string: `_S.diseases.<id>.cure` |
| `cure_price` | integer | Cost to cure (in game currency). |
| `emergency_sound` | string | Sound file for emergency announcement (e.g., `"emerg007.wav"`). |
| `emergency_number` | integer | Number of patients spawned in emergency. |
| `contagious` | boolean | Whether disease spreads to nearby patients. |
| `initPatient` | function(patient) | Configures patient visual layers, type, and special flags. |
| `diagnosis_rooms` | table<string> | List of room IDs (excluding GP) that can be visited for diagnosis. Order not fixed. |
| `treatment_rooms` | table<string> | Ordered list of room IDs that **must** be visited to cure. |

### 1.2 Optional Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `requires_machine` | boolean | `false` | Shows machine icon in drug casebook. Used by: bloaty_head, slack_tongue, hairyitis, fractured_bones, alien_dna, serious_radiation, jellyitis, baldness. |
| `more_loo_use` | boolean | `false` | Increases toilet usage. Used by: gut_rot, the_squits. |
| `must_stand` | boolean | `false` | Forces patients to stand while queueing (missing sit anim). Used by: alien_dna. |
| `only_emergency` | boolean | `false` | Disease only appears via emergency (no GP entry). Used by: alien_dna. |
| `yawn` | boolean | `false` | Shows yawn animation. Used by: sleeping_illness. |
| `effect` | AnimationEffect | `nil` | Visual effect on patient: `AnimationEffect.Glowing` (serious_radiation), `AnimationEffect.Jelly` (jellyitis). |

### 1.3 initPatient Function

Signature: `function(patient)`

Common operations:
- `patient:setType("Standard Male Patient")` — or Female, Slack, Elvis, Chewbacca, Invisible, Transparent, Alternate, Alien
- `patient:setLayer(layer_index, value)` — Layer 0 = head/body variant, 1 = clothes, 2 = shoes/accessory, 3 = bandage1, 4 = bandage2
- `patient.cured_layers = { [0]=..., [1]=..., [2]=... }` — For invisibility/transparency cure transition
- `patient.should_knock_on_doors = false` — Disable door knock anim (baldness)
- `patient.change_into = "Standard Male Patient"` — Post-cure type (alien_dna)

### 1.4 Diagnosis & Treatment Room References

All room IDs in `diagnosis_rooms` and `treatment_rooms` **must exist** in `Lua/rooms/*.lua`. Common diagnosis rooms:
- `general_diag`, `cardiogram`, `scanner`, `ultrascan`, `blood_machine`, `x_ray`, `psych`, `ward`

Common treatment rooms:
- `pharmacy`, `inflation`, `slack_tongue`, `electrolysis`, `fracture_clinic`, `hair_restoration`, `jelly_vat`, `dna_fixer`, `decontamination`, `psych`, `ward`, `operating_theatre`

### 1.5 Code Example — Minimal Disease

```lua
local disease = {}
disease.id = "example_disease"
disease.expertise_id = 1
disease.visuals_id = 0
disease.name = _S.diseases.example_disease.name
disease.cause = _S.diseases.example_disease.cause
disease.symptoms = _S.diseases.example_disease.symptoms
disease.cure = _S.diseases.example_disease.cure
disease.cure_price = 500
disease.emergency_sound = "emerg001.wav"
disease.emergency_number = 10
disease.contagious = false
disease.initPatient = function(patient)
  patient:setType("Standard Male Patient")
  patient:setLayer(0, math.random(1, 5) * 2)
  patient:setLayer(1, math.random(0, 3) * 2)
  patient:setLayer(2, 0)
  patient:setLayer(3, 0)
  patient:setLayer(4, 0)
end
disease.diagnosis_rooms = { "general_diag", "x_ray" }
disease.treatment_rooms = { "pharmacy" }
return disease
```

### 1.6 Code Example — Disease with Machine & Special Effects

```lua
local disease = {}
disease.id = "serious_radiation"
disease.expertise_id = 6
disease.visuals_id = 4
disease.name = _S.diseases.serious_radiation.name
disease.cause = _S.diseases.serious_radiation.cause
disease.symptoms = _S.diseases.serious_radiation.symptoms
disease.cure = _S.diseases.serious_radiation.cure
disease.cure_price = 1800
disease.emergency_sound = "emerg010.wav"
disease.emergency_number = 18
disease.contagious = false
disease.effect = AnimationEffect.Glowing
disease.initPatient = function(patient)
  if math.random(0, 1) == 0 then
    patient:setType("Standard Male Patient")
    patient:setLayer(0, math.random(1, 5) * 2)
    patient:setLayer(2, math.random(0, 2) * 2)
  else
    patient:setType("Standard Female Patient")
    patient:setLayer(0, math.random(1, 4) * 2)
    patient:setLayer(2, 0)
  end
  patient:setLayer(1, math.random(0, 3) * 2)
  patient:setLayer(3, 0)
  patient:setLayer(4, 0)
end
disease.diagnosis_rooms = {
  "general_diag", "cardiogram", "scanner", "ultrascan",
  "blood_machine", "x_ray", "psych", "ward"
}
disease.treatment_rooms = { "decontamination" }
disease.requires_machine = true
return disease
```

---

## 2. Room Schema (`Lua/rooms/*.lua`)

Each room file returns a table + defines a Lua class extending `Room`.

### 2.1 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (matches filename). Used in disease `treatment_rooms`/`diagnosis_rooms`. |
| `level_config_id` | integer | Index into level config (1–30). |
| `class` | string | Class name (e.g., `"GPRoom"`, `"WardRoom"`). Must match `class "ClassName" (Room)`. |
| `name` | string | Short localized name: `_S.rooms_short.<id>` |
| `long_name` | string | Full localized name: `_S.rooms_long.<id>` |
| `tooltip` | string | Tooltip text: `_S.tooltip.rooms.<id>` |
| `objects_needed` | table | Required objects with counts: `{ desk = 1, cabinet = 1, chair = 1 }` |
| `build_preview_animation` | integer | Animation ID shown in build menu. |
| `categories` | table | Category hierarchy for build menu: `{ diagnosis = 1 }`, `{ clinics = 2 }`, `{ treatment = 4 }`, `{ facilities = 3 }` |
| `minimum_size` | integer | Minimum room size in tiles. |
| `wall_type` | string | Wall texture: `"white"`, `"yellow"`, `"blue"`, `"green"` |
| `floor_tile` | integer | Floor tile ID. |
| `required_staff` | table | Required staff by role: `{ Doctor = 1 }`, `{ Nurse = 1 }`, `{ Psychiatrist = 1 }`, `{ Surgeon = 2 }`, `{ Researcher = 1 }` |
| `call_sound` | string | Sound when patient calls for staff (e.g., `"reqd008.wav"`). |

### 2.2 Optional Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `vip_must_visit` | boolean | `false` | VIPs must visit this room. Used by: ward, operating_theatre, dna_fixer, research. |
| `objects_additional` | table | `{}` | Optional decorative/functional objects: `{ "extinguisher", "radiator", "plant", "bin" }` |
| `maximum_staff` | table | `required_staff` | Max staff allowed. Can be computed dynamically in `roomFinished()`. |
| `handyman_call_sound` | string | `nil` | Sound for handyman calls (e.g., `"maint005.wav"`). |
| `has_no_queue_dialog` | boolean | `false` | Hides queue dialog. Used by: training, staff_room. |
| `swing_doors` | boolean | `false` | Uses swing doors. Used by: ward, operating_theatre, dna_fixer. |

### 2.3 Class Definition Pattern

```lua
class "RoomClassName" (Room)

---@type RoomClassName
local RoomClassName = _G["RoomClassName"]

function RoomClassName:RoomClassName(...)
  self:Room(...)
end

-- Override methods: commandEnteringPatient, commandEnteringStaff, roomFinished, etc.
```

### 2.4 Code Example — Standard Diagnosis Room

```lua
local room = {}
room.id = "cardiogram"
room.vip_must_visit = false
room.level_config_id = 12
room.class = "CardiogramRoom"
room.name = _S.rooms_short.cardiogram
room.long_name = _S.rooms_long.cardiogram
room.tooltip = _S.tooltip.rooms.cardiogram
room.objects_additional = { "extinguisher", "radiator", "plant", "bin" }
room.objects_needed = { cardio = 1, screen = 1 }
room.build_preview_animation = 918
room.categories = { diagnosis = 3 }
room.minimum_size = 4
room.wall_type = "yellow"
room.floor_tile = 19
room.required_staff = { Doctor = 1 }
room.maximum_staff = room.required_staff
room.call_sound = "reqd001.wav"
room.handyman_call_sound = "maint010.wav"

class "CardiogramRoom" (Room)
-- ... class methods ...
return room
```

### 2.5 Code Example — Dynamic Staff/Capacity (Ward)

```lua
function WardRoom:roomFinished()
  local fx, fy = self:getEntranceXY(true)
  local objects = self.world:findAllObjectsNear(fx, fy)
  local beds = 0
  local desks = 0
  for object, _ in pairs(objects) do
    if object.object_type.id == "bed" then beds = beds + 1 end
    if object.object_type.id == "desk" then desks = desks + 1 end
  end
  self.maximum_staff = { Nurse = desks }
  self.maximum_patients = beds
  Room.roomFinished(self)
end

function WardRoom:getMaximumStaffCriteria()
  return self.maximum_staff
end
```

---

## 3. Object Schema (`Lua/objects/*.lua`)

Each object file returns a table + optionally defines a Lua class extending `Object`.

### 3.1 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (matches filename). Referenced in room `objects_needed`/`objects_additional`. |
| `thob` | integer | THOB (Thing Object) animation bank index. |
| `name` | string | Localized name: `_S.object.<id>` |
| `tooltip` | string | Tooltip: `_S.tooltip.objects.<id>` |
| `ticks` | boolean | Whether object receives `tick()` calls. |
| `build_preview_animation` | integer | Animation shown in build menu. |
| `orientations` | table | Orientation definitions (north, east, south, west). |

### 3.2 Optional Fields

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `research_category` | string | `nil` | `"diagnosis"` or `"cure"` — unlocks via research. |
| `research_fallback` | integer | `nil` | Disease expertise_id fallback if research not implemented. |
| `class` | string | `nil` | Custom class name (e.g., `"ReceptionDesk"`, `"Plant"`, `"Door"`). |
| `show_in_town_map` | boolean | `false` | Shows on town map. |
| `idle_animations` | table | `{}` | Animation IDs per direction. |
| `usage_animations` | table | `{}` | Per-direction, per-humanoid-type animations for `UseObjectAction`. |
| `multi_usage_animations` | table | `{}` | For `MultiUseObjectAction` (two humanoids). Key: `"StaffType - PatientType"`. |
| `crashed_animation` | integer | `nil` | Animation when object crashes (autopsy). |
| `corridor_object` | integer | `nil` | Priority for corridor placement (1–7). |
| `walk_in_to_use` | boolean | `false` | Humanoid walks into object tile to use. |
| `locked_to_wall` | table | `nil` | `{ north = "east", west = "north" }` — auto-orient to wall. |
| `slave_id` | string | `nil` | ID of slave object (e.g., `op_sink2` for `op_sink1`). |
| `multiple_users_allowed` | boolean | `false` | Allow multiple simultaneous users (drinks_machine). |
| `dynamic_info` | boolean | `false` | Shows dynamic info on hover. |

### 3.3 Orientation Structure

Each orientation (north, east, south, west) contains:

```lua
north = {
  footprint = {
    {0, 0, complete_cell = true},
    {0, 1, only_passable = true},
    -- flags: complete_cell, only_passable, only_side, invisible, shareable, need_north_side, etc.
  },
  use_position = {x, y} | "passable",
  use_position_secondary = {x, y},  -- for second user (MultiUseObjectAction)
  render_attach_position = {x, y} | {{x1,y1},{x2,y2}},
  early_list = boolean,  -- rendering order
  use_animate_from_use_position = boolean,
  handyman_position = {x, y},  -- for plant watering
  slave_position = {x, y},  -- for slave objects
}
```

### 3.4 Usage Animations Structure

```lua
usage_animations = {
  north = {
    begin_use = { ["Standard Male Patient"] = 1234, ["Doctor"] = 5678 },
    begin_use_2 = { ["Doctor"] = 5679 },
    in_use = { ["Doctor"] = { 5680, 5681 } },  -- list = random choice
    finish_use = { ["Standard Male Patient"] = 1235 },
  },
  east = { ... },
  south = { ... },
  west = { ... },
}
```

### 3.5 Code Example — Simple Object (Radiator)

```lua
local object = {}
object.id = "radiator"
object.thob = 44
object.name = _S.object.radiator
object.tooltip = _S.tooltip.objects.radiator
object.ticks = false
object.class = "SideObject"
object.corridor_object = 5
object.build_preview_animation = 914
object.idle_animations = {
  north = 750,
  east = 752,
}
object.orientations = {
  north = { footprint = { {0, 0, only_side = true} } },
  east  = { footprint = { {0, 0, only_side = true} } },
  south = { footprint = { {0, 0, only_side = true} } },
  west  = { footprint = { {0, 0, only_side = true} } },
}
return object
```

### 3.6 Code Example — Complex Object with Multi-Use (Pharmacy Cabinet)

```lua
local object = {}
object.id = "pharmacy_cabinet"
object.thob = 39
object.research_category = "cure"
object.research_fallback = 13
object.name = _S.object.pharmacy_cabinet
object.tooltip = _S.tooltip.objects.pharmacy_cabinet
object.ticks = false
object.build_preview_animation = 5088
object.show_in_town_map = true

local function anim_set(begin, finish, idle, in_use, idle2)
  return {
    begin_use    = 1590,
    begin_use_2  = 1594,
    begin_use_3  = begin,
    in_use       = 1666,
    finish_use   = finish,
    finish_use_2 = 1598,
    secondary = {
      begin_use    = idle,
      begin_use_2  = idle,
      in_use       = in_use,
      finish_use_2 = idle2 or idle,
    },
  }
end

object.multi_usage_animations = {
  ["Nurse - Standard Male Patient"] = copy_north_to_south {
    north = anim_set(1630, 1638, 26, 1662),
  },
  ["Nurse - Standard Female Patient"] = copy_north_to_south {
    north = anim_set(3104, 3112, 10, 3108),
  },
  -- ... more patient types ...
}

object.orientations = {
  north = {
    footprint = { {0, 0, complete_cell = true}, {0, 1, only_passable = true}, {0, 2, only_passable = true}, {-1, 1, only_passable = true} },
    use_position = {0, 1},
    use_position_secondary = {-1, 1},
    use_animate_from_use_position = true,
  },
  east = { ... },
}
return object
```

### 3.7 Code Example — Object with Custom Class (Plant)

```lua
local object = {}
object.id = "plant"
object.thob = 45
object.name = _S.object.plant
object.class = "Plant"
object.tooltip = _S.tooltip.objects.plant
object.ticks = false
object.corridor_object = 7
object.build_preview_animation = 934
object.idle_animations = { north = 1950, south = 1950, east = 1950, west = 1950 }
object.usage_animations = {
  north = {
    begin_use = { ["Handyman"] = {1972, object_visible = true} },
    in_use = { ["Handyman"] = {1980, object_visible = true} },
  },
  east = { ... },
}
object.orientations = {
  north = { footprint = { {0, 0, complete_cell = true} }, use_animate_from_use_position = true },
  -- ... all 4 directions ...
}

class "Plant" (Object)
-- ... custom methods: setNextState, restoreToFullHealth, tick, tickDay, callForWatering, etc.
return object
```

---

## 4. Cross-Reference Summary

### 4.1 Disease → Room References
- 34 diseases × avg 8 diagnosis rooms = ~272 references
- 34 diseases × avg 1.5 treatment rooms = ~51 references
- All referenced rooms exist in 23 room files

### 4.2 Room → Object References
- 23 rooms × avg 5 needed objects = ~115 `objects_needed` references
- 23 rooms × avg 4 additional objects = ~92 `objects_additional` references
- All referenced objects exist in 43 object files

### 4.3 Object Classes with Custom Logic
| Object ID | Class | Key Methods |
|-----------|-------|-------------|
| `reception_desk` | ReceptionDesk | tick, checkForNearbyStaff, occupy, resetUsageAndReservaton |
| `door` | Door | setupDoor, setTile, closeDoor, checkForDeadlock |
| `plant` | Plant | setNextState, restoreToFullHealth, tick, tickDay, callForWatering |
| `bench` | Bench | removeUser, resetUsageAndReservaton |
| `radiation_shield` | RadiationShield | slaveMixinClass |
| `op_sink1` | OperatingSink | slaveMixinClass |
| `autopsy` | (none) | multi_usage_animations only |
| `chair` | Chair | afterLoad |
| `lecture_chair` | (none) | — |
| `surgeon_screen` | SurgeonScreen | constructor (num_green_outfits) |
| `helicopter` | Helicopter | tick, spawnPatient |
| `litter` | Litter (Entity) | setLitterType, remove, vomitInducing, isCleanable |
| `rathole` | Rathole | getDrawingLayer |

---

## 5. Validation Checklist for New Data Files

See `CHECKLIST.md` for pre-fix checklist and `SCAFFOLD.lua` for Busted test template.
