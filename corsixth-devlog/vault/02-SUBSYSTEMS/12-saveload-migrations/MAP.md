# CorsixTH Save/Load Methods & Migration Hooks — File:Line Index

## Overview

This map indexes all **73 classes** with `afterLoad` methods across the CorsixTH codebase, plus the core persistence infrastructure. Organized by subsystem.

---

## Core Persistence Infrastructure

| File | Line | Symbol | Description |
|------|------|--------|-------------|
| `Lua/persistance.lua` | 50 | `permanent(name, value)` | Register permanent object |
| `Lua/persistance.lua` | 61 | `unpermanent(name)` | Unregister permanent object |
| `Lua/persistance.lua` | 74 | `MakePermanentObjectsTable(inverted)` | Build bidirectional permanent registry |
| `Lua/persistance.lua` | 236 | `SaveGame()` | Serialize game state to binary |
| `Lua/persistance.lua` | 258 | `SaveGameFile(filename)` | Save to disk |
| `Lua/persistance.lua` | 286 | `LoadGame(data)` | Deserialize and migrate game state |
| `Lua/persistance.lua` | 323 | `LoadGameFile(filename)` | Load from disk |
| `Src/persist_lua.h` | 44 | `lua_persist_writer` | C++ writer interface |
| `Src/persist_lua.h` | 107 | `lua_persist_reader` | C++ reader interface |
| `Src/persist_lua.cpp` | 163 | `lua_persist_basic_writer` | Writer implementation |
| `Src/persist_lua.cpp` | 664 | `lua_persist_basic_reader` | Reader implementation |
| `Src/persist_lua.cpp` | 1104 | `l_dump_toplevel` | `persist.dump` entry |
| `Src/persist_lua.cpp` | 1117 | `l_load_toplevel` | `persist.load` entry |

---

## App & World — Migration Orchestration

| File | Line | Class:Method | Description |
|------|------|--------------|-------------|
| `Lua/app.lua` | 1995 | `App:afterLoad()` | **Root migration entry point** — version logging, object type registration, delegates to Map/UI/World |
| `Lua/world.lua` | 2552 | `World:afterLoad(old, new)` | **Core gameplay migrations** — 50+ version gates for hospital value, object counts, dispatcher, spawn rates, etc. |
| `Lua/map.lua` | 856 | `Map:afterLoad(old, new)` | Map data migrations — parcel tiles, difficulty, expertise, cell flags, pathfinding, trophies |
| `Lua/ui.lua` | 1161 | `UI:afterLoad(old, new)` | UI migrations — delegates to Window |

---

## Entity Hierarchy (Base Classes)

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/entity.lua` | 341 | `Entity:afterLoad(old, new)` | Base entity migration |
| `Lua/entities/object.lua` | 892 | `Object:afterLoad(old, new)` | `Entity.afterLoad(self, old, new)` |
| `Lua/entities/machine.lua` | 503 | `Machine:afterLoad(old, new)` | `Object.afterLoad(self, old, new)` |
| `Lua/entities/humanoid.lua` | 361 | `Humanoid:afterLoad(old, new)` | `Entity.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/staff.lua` | 666 | `Staff:afterLoad(old, new)` | `Humanoid.afterLoad(self, old, new)` + chained |
| `Lua/humanoid_action.lua` | 112 | `HumanoidAction:afterLoad(old, new)` | Action queue migration |

---

## Humanoid Subclasses

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/entities/humanoids/patient.lua` | 1243 | `Patient:afterLoad(old, new)` | `Humanoid.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/staff/doctor.lua` | 357 | `Doctor:afterLoad(old, new)` | `Staff.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/staff/nurse.lua` | 50 | `Nurse:afterLoad(old, new)` | `Staff.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/staff/handyman.lua` | 222 | `Handyman:afterLoad(old, new)` | `Staff.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/staff/receptionist.lua` | 106 | `Receptionist:afterLoad(old, new)` | `Staff.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/vip.lua` | 458 | `Vip:afterLoad(old, new)` | `Humanoid.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/grim_reaper.lua` | 46 | `GrimReaper:afterLoad(old, new)` | `Humanoid.afterLoad(self, old, new)` |
| `Lua/entities/humanoids/inspector.lua` | 69 | `Inspector:afterLoad(old, new)` | `Humanoid.afterLoad(self, old, new)` |

---

## Object Subclasses

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/objects/bench.lua` | 195 | `Bench:afterLoad(old, new)` | `Object.afterLoad(self, old, new)` |
| `Lua/objects/chair.lua` | 166 | `Chair:afterLoad(old, new)` | `Object.afterLoad(self, old, new)` |
| `Lua/objects/door.lua` | 192 | `Door:afterLoad(old, new)` | `Object.afterLoad(self, old, new)` |
| `Lua/objects/doors/swing_door_right.lua` | 190 | `SwingDoor:afterLoad(old, new)` | `Door.afterLoad(self, old, new)` |
| `Lua/objects/litter.lua` | 139 | `Litter:afterLoad(old, new)` | `Entity.afterLoad(self, old, new)` |
| `Lua/objects/plant.lua` | 317 | `Plant:afterLoad(old, new)` | `Object.afterLoad(self, old, new)` |

---

## Room Subclasses

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/room.lua` | 1058 | `Room:afterLoad(old, new)` | Base room migration |
| `Lua/rooms/training.lua` | 266 | `TrainingRoom:afterLoad(old, new)` | `Room.afterLoad(self, old, new)` |
| `Lua/rooms/research.lua` | 208 | `ResearchRoom:afterLoad(old, new)` | `Room.afterLoad(self, old, new)` |
| `Lua/rooms/ward.lua` | 208 | `WardRoom:afterLoad(old, new)` | `Room.afterLoad(self, old, new)` |
| `Lua/rooms/toilets.lua` | 170 | `ToiletRoom:afterLoad(old, new)` | `Room.afterLoad(self, old, new)` |

---

## Hospital & Research

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/hospital.lua` | 287 | `Hospital:afterLoad(old, new)` | Base hospital migration |
| `Lua/hospitals/player_hospital.lua` | 842 | `PlayerHospital:afterLoad(old, new)` | `Hospital.afterLoad(self, old, new)` |
| `Lua/hospitals/ai_hospital.lua` | 46 | `AIHospital:afterLoad(old, new)` | `Hospital.afterLoad(self, old, new)` |
| `Lua/research_department.lua` | 714 | `ResearchDepartment:afterLoad(old, new)` | Research migrations |

---

## World Systems

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/epidemic.lua` | 754 | `Epidemic:afterLoad(old, new)` | Epidemic state migrations |
| `Lua/earthquake.lua` | 220 | `Earthquake:afterLoad(old, new)` | Earthquake state (ignores params) |
| `Lua/game_ui.lua` | 1271 | `GameUI:afterLoad(old, new)` | `UI.afterLoad(self, old, new)` |

---

## UI — Window Hierarchy

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/window.lua` | 2130 | `Panel:afterLoad(old, new)` | Base panel migration |
| `Lua/window.lua` | 2140 | `Window:afterLoad(old, new)` | `Panel.afterLoad(self, old, new)` + child windows |
| `Lua/dialogs/resizable.lua` | 211 | `UIResizable:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen.lua` | 138 | `UIFullscreen:afterLoad(old, new)` | `UIResizable.afterLoad(self, old, new)` |
| `Lua/dialogs/bottom_panel.lua` | 1014 | `UIBottomPanel:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/message.lua` | 208 | `UIMessage:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |

---

## UI — Fullscreen Dialogs

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/dialogs/fullscreen/annual_report.lua` | 661 | `UIAnnualReport:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/staff_management.lua` | 688 | `UIStaffManagement:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/graphs.lua` | 488 | `UIGraphs:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/bank_manager.lua` | 111 | `UIBankManager:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/progress_report.lua` | 235 | `UIProgressReport:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/town_map.lua` | 365 | `UITownMap:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/hospital_policy.lua` | 235 | `UIPolicy:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/drug_casebook.lua` | 403 | `UICasebook:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/research_policy.lua` | 246 | `UIResearch:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |
| `Lua/dialogs/fullscreen/fax.lua` | 299 | `UIFax:afterLoad(old, new)` | `UIFullscreen.afterLoad(self, old, new)` |

---

## UI — Resizable Dialogs

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/dialogs/resizables/lua_console.lua` | 133 | `UILuaConsole:afterLoad(old, new)` | `UIResizable.afterLoad(self, old, new)` |
| `Lua/dialogs/resizables/cheats_dialog.lua` | 154 | `UICheats:afterLoad(old, new)` | `UIResizable.afterLoad(self, old, new)` |
| `Lua/dialogs/resizables/machine_menu.lua` | 404 | `UIMachineMenu:afterLoad(old, new)` | `UIResizable.afterLoad(self, old, new)` |
| `Lua/dialogs/resizables/adviser_history.lua` | 193 | `UIAdviserHistory:afterLoad(old, new)` | `UIResizable.afterLoad(self, old, new)` |

---

## UI — Standard Dialogs

| File | Line | Class:Method | Parent Call |
|------|------|--------------|-------------|
| `Lua/dialogs/patient.lua` | 359 | `UIPatient:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/staff_rise.lua` | 192 | `UIStaffRise:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/hire_staff.lua` | 280 | `UIHireStaff:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/staff_dialog.lua` | 405 | `UIStaff:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/machine_dialog.lua` | 180 | `UIMachine:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/place_objects.lua` | 1118 | `UIPlaceObjects:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/furnish_corridor.lua` | 263 | `UIFurnishCorridor:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/watch.lua` | 212 | `UIWatch:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/confirm_dialog.lua` | 126 | `UIConfirmDialog:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/information.lua` | 158 | `UIInformation:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/build_room.lua` | 242 | `UIBuildRoom:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/adviser.lua` | 336 | `UIAdviser:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/edit_room.lua` | 1621 | `UIEditRoom:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/queue_dialog.lua` | 355 | `UIQueue:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/queue_dialog.lua` | 409 | `UIQueuePopup:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/jukebox.lua` | 181 | `UIJukebox:afterLoad(old, new)` | `Window.afterLoad(self, old, new)` |
| `Lua/dialogs/subtitles.lua` | 80 | `Subtitles:afterLoad(old, new)` | Base subtitles migration |

---

## Migration Call Graph (App → World → Entities)

```
App:afterLoad()
├── App migrations (v87: gates_to_hell, v114: rathole)
├── Map:afterLoad()
│   ├── v6: parcelTileCounts
│   ├── v18: difficulty
│   ├── v44: expertise MaxDiagDiff
│   ├── v57: cell buildable flags
│   ├── v120: pathfinding rebuild
│   ├── v161: trophy hotfix
│   ├── v164: non_visuals_available
│   ├── v175: payroll MaxSalary
│   └── v187: GBV Tired default
├── UI:afterLoad()
│   └── Window:afterLoad() → child windows/panels
└── World:afterLoad()
    ├── v4: room_built
    ├── v6: hospital value recalc
    ├── v10: object_counts init
    ├── v12: animation_manager
    ├── v17: radiation_shield objects
    ├── v27: CallsDispatcher
    ├── v30: nextEmergency
    ├── v31: hours_per_day = 50
    ├── v37: spawn_rate from level_config
    ├── v43: reception_desk count
    ├── v47: bench count
    ├── v52: litter cleanup
    ├── v57: user_actions_allowed
    ├── v61: room_remove_callbacks
    ├── v64: staff profile world ref
    ├── v66: staff room reservation fix
    ├── v77: has_vomitted
    ├── v83: Chewbacca patient anim
    ├── v133: (chained via Staff)
    ├── v134: staff_change_callbacks
    ├── v210: mood enum rename (sad→dying)
    └── Entity delegation:
        ├── World.entities[i]:afterLoad() → Humanoid/Object/etc.
        ├── World.epidemic:afterLoad()
        ├── World.earthquake:afterLoad()
        └── Hospital:afterLoad() → Epidemic/Research
```

---

## Version Gate Summary (Key Milestones)

| Version | Scope | Description |
|---------|-------|-------------|
| 0 | All | Pre-versioning saves |
| 4 | World | room_built table |
| 6 | World/Map | Hospital value, parcel tiles |
| 10 | World | object_counts categories |
| 12 | World | animation_manager |
| 15 | Machine | Cardio THOB fix |
| 17 | World | Radiation shield objects |
| 18 | Map | Difficulty field |
| 27 | World | CallsDispatcher |
| 30 | World | nextEmergency |
| 31 | World | hours_per_day = 50 |
| 37 | World | Spawn rate from level config |
| 38 | Humanoid | Health attribute |
| 42 | Humanoid | Slack Female Patient anim |
| 43 | World | Reception desk count |
| 44 | Map | Expertise MaxDiagDiff |
| 47 | World | Bench count |
| 49 | Humanoid | has_fallen |
| 52 | World | Litter cleanup |
| 54 | Machine | Repair task fix |
| 57 | World/Map | user_actions_allowed, cell flags |
| 61 | World/Humanoid | room_remove_callbacks, callback restructure |
| 64 | World | Staff profile world ref |
| 66 | World | Staff room reservation |
| 77 | Humanoid | has_vomitted |
| 83 | Humanoid | Chewbacca patient anim |
| 87 | App | Gates to Hell object |
| 106 | Epidemic | level_config removed |
| 114 | App | Rathole object |
| 120 | Map | Pathfinding rebuild |
| 133 | Staff | Chained migration |
| 134 | Humanoid | staff_change_callbacks |
| 161 | Map | Trophy hotfix |
| 164 | Map | Non-visual illness availability |
| 166 | Persistence | Graphics set type (compat gate) |
| 175 | Map | MaxSalary config |
| 187 | Map | GBV Tired default |
| 210 | Humanoid | Mood enum rename (sad→dying) |
| 212 | Epidemic | coverup field rename |

**Current version**: 212 (see `App.savegame_version` in `app.lua`)

---

## Permanent Object Registration Points

| Module | Permanent Names Registered |
|--------|---------------------------|
| `objects/*.lua` | `objects.<id>` (e.g., `objects.radiator`, `objects.bench`) |
| `humanoid_action.lua` | `humanoid_actions.<id>` |
| `diseases.lua` | `diseases.<id>` |
| `rooms/*.lua` | `rooms.<id>` |
| `C++ bindings` | `TH.<class>`, `TH.<class>.<mt>` |
| `App subsystems` | `TheApp.config`, `TheApp.modes`, `TheApp.video`, etc. |
| `Graphics` | `TheApp.gfx.load_info[obj]` (weak keys) |
| `User code` | Via `permanent("custom.name", obj)` |

---

## File Count Summary

| Category | Count |
|----------|-------|
| Core persistence | 2 files |
| App/World/Map/UI orchestration | 4 files |
| Entity base classes | 5 files |
| Humanoid subclasses | 8 files |
| Object subclasses | 6 files |
| Room subclasses | 5 files |
| Hospital/Research | 4 files |
| World systems | 3 files |
| UI Window hierarchy | 5 files |
| UI Fullscreen dialogs | 10 files |
| UI Resizable dialogs | 4 files |
| UI Standard dialogs | 15 files |
| **Total afterLoad implementations** | **73** |

---

## Quick Navigation

### Search Patterns
```bash
# All afterLoad definitions
grep -rn "function.*:afterLoad" Lua/

# All afterLoad calls
grep -rn "afterLoad(" Lua/

# Version gates
grep -rn "if old <" Lua/

# Parent calls
grep -rn "\.afterLoad(self, old, new)" Lua/

# Permanent registration
grep -rn "permanent(" Lua/
```

### Key Files to Remember
- `Lua/persistance.lua` — Save/Load entry, permanent system
- `Lua/app.lua:1995` — App:afterLoad (migration root)
- `Lua/world.lua:2552` — World:afterLoad (gameplay migrations)
- `Lua/map.lua:856` — Map:afterLoad (map data migrations)
- `Src/persist_lua.cpp` — C++ binary serializer

---

*Generated from CorsixTH source tree. Line numbers may shift with edits.*
