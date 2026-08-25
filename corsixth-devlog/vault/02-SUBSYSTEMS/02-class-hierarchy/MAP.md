# Class Declaration Map — File:Line Index

> **Source:** CorsixTH Lua source (195 classes across 10 categories)
> **Format:** `ClassName` — `file.lua:line` — `superclass` — `category`

---

## CATEGORY 1: CORE / APPLICATION (10 classes)

| Class | File:Line | Superclass | Notes |
|-------|-----------|------------|-------|
| App | `app.lua:33` | none | Singleton, `TheApp` |
| World | `world.lua:48` | none | Game simulation root |
| Map | `map.lua:22` | none | Map data wrapper |
| Date | `date.lua:29` | none | Game date/time |
| Strings | `strings.lua:25` | none | Localization |
| Graphics | `graphics.lua:29` | none | Rendering, sprites |
| AnimationManager | `graphics.lua:858` | none | Animation lengths |
| Audio | `audio.lua:30` | none | Sound/music |
| MoviePlayer | `movie_player.lua:26` | none | Video playback |
| FileSystem | `filesystem.lua:34` | none | File I/O abstraction |

---

## CATEGORY 2: ENTITY HIERARCHY (15 classes)

### Root
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Entity | `entity.lua:22` | none |

### Humanoid Branch (Entity → Humanoid → ...)
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Humanoid | `entities/humanoid.lua:22` | Entity |
| Patient | `entities/humanoids/patient.lua:22` | Humanoid |
| Vip | `entities/humanoids/vip.lua:60` | Humanoid |
| Inspector | `entities/humanoids/inspector.lua:26` | Humanoid |
| GrimReaper | `entities/humanoids/grim_reaper.lua:21` | Humanoid |
| Staff | `entities/humanoids/staff.lua:26` | Humanoid |
| Doctor | `entities/humanoids/staff/doctor.lua:28` | Staff |
| Nurse | `entities/humanoids/staff/nurse.lua:27` | Staff |
| Handyman | `entities/humanoids/staff/handyman.lua:27` | Staff |
| Receptionist | `entities/humanoids/staff/receptionist.lua:27` | Staff |

### Object Branch (Entity → Object → ...)
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Object | `entities/object.lua:24` | Entity |
| SideObject | `entities/object.lua:1075` | Object |
| Machine | `entities/machine.lua:24` | Object |

### Direct Entity Subclass
| Class | File:Line | Superclass | Note |
|-------|-----------|------------|------|
| Litter | `objects/litter.lua:51` | Entity | NOT Object |

---

## CATEGORY 3: OBJECT SUBCLASSES (14 classes)

### Door Family
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Door | `objects/door.lua:35` | Object |
| SwingDoor | `objects/doors/swing_door_right.lua:33` | Door |
| EntranceDoor | `objects/doors/entrance_right_door.lua:34` | Object |

### Furniture & Decor
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Bench | `objects/bench.lua:146` | Object |
| Chair | `objects/chair.lua:156` | Object |
| Plant | `objects/plant.lua:91` | Object |
| ReceptionDesk | `objects/reception_desk.lua:71` | Object |
| Rathole | `objects/rathole.lua:53` | Object |

### Special Objects
| Class | File:Line | Superclass | Notes |
|-------|-----------|------------|-------|
| Helicopter | `objects/helicopter.lua:41` | Object | |
| AtomAnalyser | `objects/analyser.lua:59` | Object | |
| OperatingSink | `objects/op_sink1.lua:66` | Object | + slaveMixin |
| RadiationShield | `objects/radiation_shield.lua:73` | Object | + slaveMixin |
| SurgeonScreen | `objects/surgeon_screen.lua:103` | Object | |

### Machine Family
| Class | File:Line | Superclass | Notes |
|-------|-----------|------------|-------|
| OperatingTable | `objects/machines/operating_table.lua:123` | Machine | + slaveMixin |

---

## CATEGORY 4: ROOM HIERARCHY (24 classes)

### Root
| Class | File:Line | Superclass |
|-------|-----------|------------|
| Room | `room.lua:21` | none |

### All Room Subclasses (direct Room children)
| Class | File:Line | Key Override Methods |
|-------|-----------|---------------------|
| GPRoom | `rooms/gp.lua:44` | doStaffUseCycle, commandEnteringStaff, commandEnteringPatient, dealtWithPatient, sendPatientToNextDiagnosisRoom, onHumanoidLeave, roomFinished, shouldHavePatientReenter |
| OperatingTheatreRoom | `rooms/operating_theatre.lua:51` | roomFinished, commandEnteringStaff, commandEnteringPatient, onHumanoidLeave, canHumanoidEnter, setStaffMembersAttribute, queueWashHands, setXRayOn |
| WardRoom | `rooms/ward.lua:52` | roomFinished, commandEnteringStaff, commandEnteringPatient, doStaffUseCycle, updateHealingAmount, onHumanoidLeave, setStaffMember, setStaffMembersAttribute, getMaximumStaffCriteria |
| ResearchRoom | `rooms/research.lua:51` | doStaffUseCycle, roomFinished, commandEnteringStaff, commandEnteringPatient, setStaffMember, setStaffMembersAttribute, onHumanoidLeave, getMaximumStaffCriteria, afterLoad |
| TrainingRoom | `rooms/training.lua:41` | roomFinished, calculateTrainingFactor, getTrainingFactor, getStaffCount, getMaximumStaffCriteria, doStaffUseCycle, onHumanoidEnter, commandEnteringStaff, testStaffCriteria |
| PharmacyRoom | `rooms/pharmacy.lua:44` | roomFinished, commandEnteringPatient |
| PsychRoom | `rooms/psych.lua:45` | roomFinished, commandEnteringStaff, commandEnteringPatient |
| StaffRoom | `rooms/staff_room.lua:40` | onHumanoidEnter, testStaffCriteria |
| ToiletRoom | `rooms/toilets.lua:39` | roomFinished, dealtWithPatient, onHumanoidEnter, getPatientCount, afterLoad |
| BloodMachineRoom | `rooms/blood_machine_room.lua:45` | commandEnteringPatient |
| CardiogramRoom | `rooms/cardiogram.lua:45` | commandEnteringPatient, makeHumanoidLeave, onHumanoidLeave, shouldHavePatientReenter |
| DecontaminationRoom | `rooms/decontamination.lua:45` | commandEnteringStaff, commandEnteringPatient, onHumanoidLeave |
| DNAFixerRoom | `rooms/dna_fixer.lua:46` | commandEnteringPatient |
| ElectrolysisRoom | `rooms/electrolysis.lua:45` | commandEnteringPatient |
| FractureRoom | `rooms/fracture_clinic.lua:45` | commandEnteringPatient |
| GeneralDiagRoom | `rooms/general_diag.lua:44` | commandEnteringPatient, makeHumanoidLeave, shouldHavePatientReenter |
| HairRestorationRoom | `rooms/hair_restoration.lua:45` | commandEnteringPatient |
| InflationRoom | `rooms/inflation.lua:45` | commandEnteringPatient |
| JellyVatRoom | `rooms/jelly_vat.lua:45` | commandEnteringPatient |
| ScannerRoom | `rooms/scanner_room.lua:47` | commandEnteringPatient, onHumanoidLeave, makeHumanoidLeave, dealtWithPatient, shouldHavePatientReenter |
| SlackTongueRoom | `rooms/slack_tongue.lua:45` | commandEnteringPatient |
| UltrascanRoom | `rooms/ultrascan.lua:45` | commandEnteringPatient |
| XRayRoom | `rooms/x_ray_room.lua:45` | commandEnteringPatient |

---

## CATEGORY 5: HOSPITAL HIERARCHY (3 classes)

| Class | File:Line | Superclass |
|-------|-----------|------------|
| Hospital | `hospital.lua:23` | none |
| PlayerHospital | `hospitals/player_hospital.lua:25` | Hospital |
| AIHospital | `hospitals/ai_hospital.lua:21` | Hospital |

---

## CATEGORY 6: UI / WINDOW SYSTEM (32 classes)

### Core UI Classes
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

### Dialog Classes — Window-Mode (extend Window)
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

### Dialog Classes — Fullscreen (extend UIFullscreen)
| Class | File:Line |
|-------|-----------|
| UIAnnualReport | `dialogs/fullscreen/annual_report.lua:22` |
| UIBankManager | `dialogs/fullscreen/bank_manager.lua:22` |
| UICasebook | `dialogs/fullscreen/drug_casebook.lua:22` |
| UIFax | `dialogs/fullscreen/fax.lua:25` |
| UIGraphs | `dialogs/fullscreen/graphs.lua:23` |
| UIPolicy | `dialogs/fullscreen/hospital_policy.lua:22` |
| UIProgressReport | `dialogs/fullscreen/progress_report.lua:22` |
| UIResearch | `dialogs/fullscreen/research_policy.lua:21` |
| UIStaffManagement | `dialogs/fullscreen/staff_management.lua:24` |
| UITownMap | `dialogs/fullscreen/town_map.lua:24` |

### Dialog Classes — Resizable (extend UIResizable)
| Class | File:Line |
|-------|-----------|
| UIAdviserHistory | `dialogs/resizables/adviser_history.lua:22` |
| UICallsDispatcher | `dialogs/resizables/calls_dispatcher.lua:22` |
| UICheats | `dialogs/resizables/cheats_dialog.lua:24` |
| UICustomise | `dialogs/resizables/customise.lua:22` |
| UIDirectoryBrowser | `dialogs/resizables/directory_browser.lua:118` |
| UIDropdown | `dialogs/resizables/dropdown.lua:23` |
| UIFileBrowser | `dialogs/resizables/file_browser.lua:146` |
| UIFolder | `dialogs/resizables/folder_settings.lua:22` |
| UIHotkeyAssign | `dialogs/resizables/hotkey_assign.lua:22` |
| UILuaConsole | `dialogs/resizables/lua_console.lua:26` |
| UIMachineMenu | `dialogs/resizables/machine_menu.lua:22` |
| UIMainMenu | `dialogs/resizables/main_menu.lua:22` |
| UIMapEditor | `dialogs/resizables/map_editor.lua:22` |
| UIMenuList | `dialogs/resizables/menu_list_dialog.lua:22` |
| UINewGame | `dialogs/resizables/new_game.lua:22` |
| UIOptions | `dialogs/resizables/options.lua:22` |
| UIResolution | `dialogs/resizables/options.lua:637` |
| UIScrollSpeed | `dialogs/resizables/options.lua:720` |
| UIShiftScrollSpeed | `dialogs/resizables/options.lua:790` |
| UIZoomSpeed | `dialogs/resizables/options.lua:859` |
| UISoundSettings | `dialogs/resizables/sound_setting.lua:21` |
| UITipOfTheDay | `dialogs/resizables/tip_of_the_day.lua:22` |
| UIUpdate | `dialogs/resizables/update.lua:22` |

### Dialog Classes — FileBrowser Variants (extend UIFileBrowser)
| Class | File:Line |
|-------|-----------|
| UIChooseFont | `dialogs/resizables/file_browsers/choose_font.lua:25` |
| UIChooseSoundfont | `dialogs/resizables/file_browsers/choose_soundfont.lua:27` |
| UILoadGame | `dialogs/resizables/file_browsers/load_game.lua:22` |
| UILoadMap | `dialogs/resizables/file_browsers/load_map.lua:22` |
| UISaveGame | `dialogs/resizables/file_browsers/save_game.lua:22` |
| UISaveMap | `dialogs/resizables/file_browsers/save_map.lua:22` |

### Dialog Classes — MenuList Variants (extend UIMenuList)
| Class | File:Line |
|-------|-----------|
| UICustomCampaign | `dialogs/resizables/menu_list_dialogs/custom_campaign.lua:22` |
| UICustomGame | `dialogs/resizables/menu_list_dialogs/custom_game.lua:22` |
| UIMakeDebugPatient | `dialogs/resizables/menu_list_dialogs/make_debug_patient.lua:21` |

### TreeNode Hierarchy
| Class | File:Line | Superclass |
|-------|-----------|------------|
| TreeNode | `dialogs/tree_ctrl.lua:22` | none |
| FileTreeNode | `dialogs/tree_ctrl.lua:185` | TreeNode |
| DirTreeNode | `dialogs/resizables/directory_browser.lua:27` | FileTreeNode |
| InstallDirTreeNode | `dialogs/resizables/directory_browser.lua:61` | DirTreeNode |
| FilteredFileTreeNode | `dialogs/resizables/file_browser.lua:25` | FileTreeNode |
| DummyRootNode | `dialogs/tree_ctrl.lua:451` | TreeNode |
| FilteredTreeControl | `dialogs/resizables/file_browser.lua:70` | TreeControl |

### Non-UI Dialog Support
| Class | File:Line | Superclass |
|-------|-----------|------------|
| UIMenu | `dialogs/menu.lua:485` | none |
| SubtitleQueue | `dialogs/subtitles.lua:85` | none |

---

## CATEGORY 7: HUMANOID ACTIONS (33 classes)

### Root
| Class | File:Line | Superclass |
|-------|-----------|------------|
| HumanoidAction | `humanoid_action.lua:22` | none |

### All Action Subclasses (direct HumanoidAction children)
| Class | File:Line | Purpose |
|-------|-----------|---------|
| AnswerCallAction | `humanoid_actions/answer_call.lua:21` | Handyman responds to task |
| CallCheckPointAction | `humanoid_actions/call_checkpoint.lua:21` | Track assigned calls |
| CheckWatchAction | `humanoid_actions/check_watch.lua:21` | VIP checks watch |
| DieAction | `humanoid_actions/die.lua:21` | Patient death sequence |
| FallingAction | `humanoid_actions/falling.lua:21` | Humanoid falls down |
| GetUpAction | `humanoid_actions/get_up.lua:21` | Rise from ground |
| IdleAction | `humanoid_actions/idle.lua:21` | Standing idle |
| IdleSpawnAction | `humanoid_actions/idle_spawn.lua:21` | Idle with spawn anim |
| KnockDoorAction | `humanoid_actions/knock_door.lua:21` | Knock on room door |
| MeanderAction | `humanoid_actions/meander.lua:21` | Wander corridor |
| MultiUseObjectAction | `humanoid_actions/multi_use_object.lua:21` | Use object with another humanoid |
| OnGroundAction | `humanoid_actions/on_ground.lua:21` | Lying on ground |
| PeeAction | `humanoid_actions/pee.lua:21` | Patient urinating |
| PickupAction | `humanoid_actions/pickup.lua:21` | Player picks up humanoid |
| QueueAction | `humanoid_actions/queue.lua:21` | Stand in queue |
| SeekReceptionAction | `humanoid_actions/seek_reception.lua:21` | Walk to reception desk |
| SeekRoomAction | `humanoid_actions/seek_room.lua:21` | Walk to a room |
| SeekStaffRoomAction | `humanoid_actions/seek_staffroom.lua:21` | Walk to staff room |
| SeekToiletsAction | `humanoid_actions/seek_toilets.lua:22` | Walk to toilet |
| ShakeFistAction | `humanoid_actions/shake_fist.lua:21` | Shake fist at screen |
| SpawnAction | `humanoid_actions/spawn.lua:21` | Spawn/despawn at map edge |
| StaffReceptionAction | `humanoid_actions/staff_reception.lua:21` | Staff walks to reception |
| SweepFloorAction | `humanoid_actions/sweep_floor.lua:21` | Handyman cleans litter |
| TapFootAction | `humanoid_actions/tap_foot.lua:21` | Impatient foot tapping |
| UseObjectAction | `humanoid_actions/use_object.lua:24` | Use a machine/object |
| UseScreenAction | `humanoid_actions/use_screen.lua:21` | Use surgeon screen |
| UseStaffRoomAction | `humanoid_actions/use_staffroom.lua:21` | Rest in staff room |
| VaccinateAction | `humanoid_actions/vaccinate.lua:21` | Nurse vaccinates patient |
| VipGoToNextRoomAction | `humanoid_actions/vip_go_to_next_room.lua:21` | VIP moves to next room |
| VomitAction | `humanoid_actions/vomit.lua:21` | Patient vomits |
| WalkAction | `humanoid_actions/walk.lua:21` | Walk to tile |
| YawnAction | `humanoid_actions/yawn.lua:21` | Patient yawns |

---

## CATEGORY 8: SUPPORT / MANAGEMENT (11 classes)

| Class | File:Line | Superclass | Purpose |
|-------|-----------|------------|---------|
| StaffProfile | `staff_profile.lua:21` | none | Staff stats/skills |
| Queue | `queue.lua:31` | none | Room/reception queues |
| EntityMap | `entity_map.lua:21` | none | Spatial entity index |
| Earthquake | `earthquake.lua:22` | none | Disaster events |
| Epidemic | `epidemic.lua:25` | none | Disease outbreaks |
| Cheats | `cheats.lua:27` | none | Debug cheats |
| CallsDispatcher | `calls_dispatcher.lua:25` | none | Staff task dispatch |
| ResearchDepartment | `research_department.lua:32` | none | Research tree |
| EndConditions | `endconditions.lua:44` | none | Win/lose conditions |

---

## CATEGORY 9: ANNOUNCER SYSTEM (3 classes)

| Class | File:Line | Superclass | Purpose |
|-------|-----------|------------|---------|
| AnnouncementQueue | `announcer.lua:45` | none | Priority queue |
| AnnouncementEntry | `announcer.lua:107` | none | Single announcement |
| Announcer | `announcer.lua:127` | none | Playback controller |

---

## QUICK LOOKUP: Class → File:Line (Alphabetical)

| Class | File:Line |
|-------|-----------|
| AIHospital | `hospitals/ai_hospital.lua:21` |
| AnimationManager | `graphics.lua:858` |
| Announcer | `announcer.lua:127` |
| AnnouncementEntry | `announcer.lua:107` |
| AnnouncementQueue | `announcer.lua:45` |
| AnswerCallAction | `humanoid_actions/answer_call.lua:21` |
| App | `app.lua:33` |
| AtomAnalyser | `objects/analyser.lua:59` |
| Audio | `audio.lua:30` |
| Bench | `objects/bench.lua:146` |
| BloodMachineRoom | `rooms/blood_machine_room.lua:45` |
| Button | `window.lua:594` |
| CallCheckPointAction | `humanoid_actions/call_checkpoint.lua:21` |
| CallsDispatcher | `calls_dispatcher.lua:25` |
| CardiogramRoom | `rooms/cardiogram.lua:45` |
| Chair | `objects/chair.lua:156` |
| CheckWatchAction | `humanoid_actions/check_watch.lua:21` |
| Cheats | `cheats.lua:27` |
| Date | `date.lua:29` |
| DecontaminationRoom | `rooms/decontamination.lua:45` |
| DieAction | `humanoid_actions/die.lua:21` |
| DNAFixerRoom | `rooms/dna_fixer.lua:46` |
| Doctor | `entities/humanoids/staff/doctor.lua:28` |
| Door | `objects/door.lua:35` |
| DummyRootNode | `dialogs/tree_ctrl.lua:451` |
| Earthquake | `earthquake.lua:22` |
| ElectrolysisRoom | `rooms/electrolysis.lua:45` |
| EndConditions | `endconditions.lua:44` |
| Entity | `entity.lua:22` |
| EntityMap | `entity_map.lua:21` |
| EntranceDoor | `objects/doors/entrance_right_door.lua:34` |
| Epidemic | `epidemic.lua:25` |
| FallingAction | `humanoid_actions/falling.lua:21` |
| FileSystem | `filesystem.lua:34` |
| FilteredFileTreeNode | `dialogs/resizables/file_browser.lua:25` |
| FilteredTreeControl | `dialogs/resizables/file_browser.lua:70` |
| FractureRoom | `rooms/fracture_clinic.lua:45` |
| GameUI | `game_ui.lua:25` |
| GetUpAction | `humanoid_actions/get_up.lua:21` |
| GPRoom | `rooms/gp.lua:44` |
| Graphics | `graphics.lua:29` |
| GrimReaper | `entities/humanoids/grim_reaper.lua:21` |
| HairRestorationRoom | `rooms/hair_restoration.lua:45` |
| Handyman | `entities/humanoids/staff/handyman.lua:27` |
| Helicopter | `objects/helicopter.lua:41` |
| Hospital | `hospital.lua:23` |
| HotkeyBox | `window.lua:1342` |
| Humanoid | `entities/humanoid.lua:22` |
| HumanoidAction | `humanoid_action.lua:22` |
| IdleAction | `humanoid_actions/idle.lua:21` |
| IdleSpawnAction | `humanoid_actions/idle_spawn.lua:21` |
| InflationRoom | `rooms/inflation.lua:45` |
| Inspector | `entities/humanoids/inspector.lua:26` |
| InstallDirTreeNode | `dialogs/resizables/directory_browser.lua:61` |
| JellyVatRoom | `rooms/jelly_vat.lua:45` |
| KnockDoorAction | `humanoid_actions/knock_door.lua:21` |
| Litter | `objects/litter.lua:51` |
| Machine | `entities/machine.lua:24` |
| Map | `map.lua:22` |
| MeanderAction | `humanoid_actions/meander.lua:21` |
| MoviePlayer | `movie_player.lua:26` |
| MultiUseObjectAction | `humanoid_actions/multi_use_object.lua:21` |
| Nurse | `entities/humanoids/staff/nurse.lua:27` |
| Object | `entities/object.lua:24` |
| OnGroundAction | `humanoid_actions/on_ground.lua:21` |
| OperatingSink | `objects/op_sink1.lua:66` |
| OperatingTable | `objects/machines/operating_table.lua:123` |
| OperatingTheatreRoom | `rooms/operating_theatre.lua:51` |
| Patient | `entities/humanoids/patient.lua:22` |
| PeeAction | `humanoid_actions/pee.lua:21` |
| PharmacyRoom | `rooms/pharmacy.lua:44` |
| PickupAction | `humanoid_actions/pickup.lua:21` |
| Plant | `objects/plant.lua:91` |
| PlayerHospital | `hospitals/player_hospital.lua:25` |
| PsychRoom | `rooms/psych.lua:45` |
| Queue | `queue.lua:31` |
| QueueAction | `humanoid_actions/queue.lua:21` |
| RadiationShield | `objects/radiation_shield.lua:73` |
| Rathole | `objects/rathole.lua:53` |
| ReceptionDesk | `objects/reception_desk.lua:71` |
| Receptionist | `entities/humanoids/staff/receptionist.lua:27` |
| ResearchDepartment | `research_department.lua:32` |
| ResearchRoom | `rooms/research.lua:51` |
| Room | `room.lua:21` |
| ScannerRoom | `rooms/scanner_room.lua:47` |
| Scrollbar | `window.lua:834` |
| SeekReceptionAction | `humanoid_actions/seek_reception.lua:21` |
| SeekRoomAction | `humanoid_actions/seek_room.lua:21` |
| SeekStaffRoomAction | `humanoid_actions/seek_staffroom.lua:21` |
| SeekToiletsAction | `humanoid_actions/seek_toilets.lua:22` |
| ShakeFistAction | `humanoid_actions/shake_fist.lua:21` |
| SideObject | `entities/object.lua:1075` |
| SlackTongueRoom | `rooms/slack_tongue.lua:45` |
| SpawnAction | `humanoid_actions/spawn.lua:21` |
| Staff | `entities/humanoids/staff.lua:26` |
| StaffProfile | `staff_profile.lua:21` |
| StaffReceptionAction | `humanoid_actions/staff_reception.lua:21` |
| Strings | `strings.lua:25` |
| SubtitleQueue | `dialogs/subtitles.lua:85` |
| Subtitles | `dialogs/subtitles.lua:22` |
| SurgeonScreen | `objects/surgeon_screen.lua:103` |
| SwingDoor | `objects/doors/swing_door_right.lua:33` |
| Textbox | `window.lua:943` |
| ToiletRoom | `rooms/toilets.lua:39` |
| TreeControl | `dialogs/tree_ctrl.lua:484` |
| TreeNode | `dialogs/tree_ctrl.lua:22` |
| UltrascanRoom | `rooms/ultrascan.lua:45` |
| UI | `ui.lua:24` |
| UIAdviser | `dialogs/adviser.lua:24` |
| UIAdviserHistory | `dialogs/resizables/adviser_history.lua:22` |
| UIAnnualReport | `dialogs/fullscreen/annual_report.lua:22` |
| UIBankManager | `dialogs/fullscreen/bank_manager.lua:22` |
| UIBottomPanel | `dialogs/bottom_panel.lua:22` |
| UIBuildRoom | `dialogs/build_room.lua:23` |
| UICallsDispatcher | `dialogs/resizables/calls_dispatcher.lua:22` |
| UICasebook | `dialogs/fullscreen/drug_casebook.lua:22` |
| UICheats | `dialogs/resizables/cheats_dialog.lua:24` |
| UIChooseFont | `dialogs/resizables/file_browsers/choose_font.lua:25` |
| UIChooseSoundfont | `dialogs/resizables/file_browsers/choose_soundfont.lua:27` |
| UIConfirmDialog | `dialogs/confirm_dialog.lua:23` |
| UICustomCampaign | `dialogs/resizables/menu_list_dialogs/custom_campaign.lua:22` |
| UICustomGame | `dialogs/resizables/menu_list_dialogs/custom_game.lua:22` |
| UICustomise | `dialogs/resizables/customise.lua:22` |
| UIDirectoryBrowser | `dialogs/resizables/directory_browser.lua:118` |
| UIDropdown | `dialogs/resizables/dropdown.lua:23` |
| UIEditRoom | `dialogs/edit_room.lua:23` |
| UIFax | `dialogs/fullscreen/fax.lua:25` |
| UIFileBrowser | `dialogs/resizables/file_browser.lua:146` |
| UIFolder | `dialogs/resizables/folder_settings.lua:22` |
| UIFullscreen | `dialogs/fullscreen.lua:22` |
| UIFurnishCorridor | `dialogs/furnish_corridor.lua:27` |
| UIGraphs | `dialogs/fullscreen/graphs.lua:23` |
| UIHireStaff | `dialogs/hire_staff.lua:21` |
| UIHotkeyAssign | `dialogs/resizables/hotkey_assign.lua:22` |
| UIHotkeyAssignKeyPane | `dialogs/resizables/hotkey_assign.lua:568` |
| UIInformation | `dialogs/information.lua:22` |
| UIJukebox | `dialogs/jukebox.lua:24` |
| UILuaConsole | `dialogs/resizables/lua_console.lua:26` |
| UIMachine | `dialogs/machine_dialog.lua:21` |
| UIMachineMenu | `dialogs/resizables/machine_menu.lua:22` |
| UIMainMenu | `dialogs/resizables/main_menu.lua:22` |
| UIMakeDebugPatient | `dialogs/resizables/menu_list_dialogs/make_debug_patient.lua:21` |
| UIMapEditor | `dialogs/resizables/map_editor.lua:22` |
| UIMenu | `dialogs/menu.lua:485` |
| UIMenuBar | `dialogs/menu.lua:26` |
| UIMenuList | `dialogs/resizables/menu_list_dialog.lua:22` |
| UIMessage | `dialogs/message.lua:22` |
| UINewGame | `dialogs/resizables/new_game.lua:22` |
| UIOptions | `dialogs/resizables/options.lua:22` |
| UIPatient | `dialogs/patient.lua:30` |
| UIPlaceObjects | `dialogs/place_objects.lua:31` |
| UIPlaceStaff | `dialogs/place_staff.lua:26` |
| UIPolicy | `dialogs/fullscreen/hospital_policy.lua:22` |
| UIProgressReport | `dialogs/fullscreen/progress_report.lua:22` |
| UIQueue | `dialogs/queue_dialog.lua:24` |
| UIQueuePopup | `dialogs/queue_dialog.lua:362` |
| UIResearch | `dialogs/fullscreen/research_policy.lua:21` |
| UIResolution | `dialogs/resizables/options.lua:637` |
| UIResizable | `dialogs/resizables/resizable.lua:22` |
| UIScrollSpeed | `dialogs/resizables/options.lua:720` |
| UIShiftScrollSpeed | `dialogs/resizables/options.lua:790` |
| UISaveGame | `dialogs/resizables/file_browsers/save_game.lua:22` |
| UISaveMap | `dialogs/resizables/file_browsers/save_map.lua:22` |
| UIStaff | `dialogs/staff_dialog.lua:29` |
| UIStaffManagement | `dialogs/fullscreen/staff_management.lua:24` |
| UIStaffRise | `dialogs/staff_rise.lua:23` |
| UISoundSettings | `dialogs/resizables/sound_setting.lua:21` |
| UITipOfTheDay | `dialogs/resizables/tip_of_the_day.lua:22` |
| UITownMap | `dialogs/fullscreen/town_map.lua:24` |
| UIUpdate | `dialogs/resizables/update.lua:22` |
| UIWatch | `dialogs/watch.lua:23` |
| UIZoomSpeed | `dialogs/resizables/options.lua:859` |
| UseObjectAction | `humanoid_actions/use_object.lua:24` |
| UseScreenAction | `humanoid_actions/use_screen.lua:21` |
| UseStaffRoomAction | `humanoid_actions/use_staffroom.lua:21` |
| VaccinateAction | `humanoid_actions/vaccinate.lua:21` |
| Vip | `entities/humanoids/vip.lua:60` |
| VipGoToNextRoomAction | `humanoid_actions/vip_go_to_next_room.lua:21` |
| VomitAction | `humanoid_actions/vomit.lua:21` |
| WalkAction | `humanoid_actions/walk.lua:21` |
| WardRoom | `rooms/ward.lua:52` |
| Window | `window.lua:24` |
| World | `world.lua:48` |
| XRayRoom | `rooms/x_ray_room.lua:45` |
| YawnAction | `humanoid_actions/yawn.lua:21` |

---

## STATISTICS

| Category | Classes | Files |
|----------|---------|-------|
| Core/Application | 10 | 10 |
| Entity Hierarchy | 15 | 13 |
| Object Subclasses | 14 | 14 |
| Room Hierarchy | 24 | 24 |
| Hospital Hierarchy | 3 | 3 |
| UI/Window System | 32 | 28 |
| Humanoid Actions | 33 | 33 |
| Support/Management | 11 | 9 |
| Announcer System | 3 | 1 |
| **TOTAL** | **195** | **~135** |

---

## FILE ORGANIZATION BY DIRECTORY

```
CorsixTH/Lua/
├── app.lua                    → App
├── world.lua                  → World
├── map.lua                    → Map
├── date.lua                   → Date
├── strings.lua                → Strings
├── graphics.lua               → Graphics, AnimationManager
├── audio.lua                  → Audio
├── movie_player.lua           → MoviePlayer
├── filesystem.lua             → FileSystem
├── class.lua                  → (class system)
├── entity.lua                 → Entity
├── entity_map.lua             → EntityMap
├── hospital.lua               → Hospital
├── ui.lua                     → UI
├── game_ui.lua                → GameUI
├── window.lua                 → Window, Panel, Button, Scrollbar, Textbox, HotkeyBox
├── room.lua                   → Room
├── staff_profile.lua          → StaffProfile
├── queue.lua                  → Queue
├── earthquake.lua             → Earthquake
├── epidemic.lua               → Epidemic
├── cheats.lua                 → Cheats
├── calls_dispatcher.lua       → CallsDispatcher
├── research_department.lua    → ResearchDepartment
├── endconditions.lua          → EndConditions
├── announcer.lua              → AnnouncementQueue, AnnouncementEntry, Announcer
├── humanoid_action.lua        → HumanoidAction
│
├── entities/
│   ├── humanoid.lua           → Humanoid
│   ├── object.lua             → Object, SideObject
│   ├── machine.lua            → Machine
│   └── humanoids/
│       ├── patient.lua        → Patient
│       ├── vip.lua            → Vip
│       ├── inspector.lua      → Inspector
│       ├── grim_reaper.lua    → GrimReaper
│       └── staff/
│           ├── staff.lua      → Staff
│           ├── doctor.lua     → Doctor
│           ├── nurse.lua      → Nurse
│           ├── handyman.lua   → Handyman
│           └── receptionist.lua → Receptionist
│
├── objects/
│   ├── litter.lua             → Litter
│   ├── door.lua               → Door
│   ├── bench.lua              → Bench
│   ├── chair.lua              → Chair
│   ├── plant.lua              → Plant
│   ├── reception_desk.lua     → ReceptionDesk
│   ├── rathole.lua            → Rathole
│   ├── helicopter.lua         → Helicopter
│   ├── analyser.lua           → AtomAnalyser
│   ├── op_sink1.lua           → OperatingSink
│   ├── radiation_shield.lua   → RadiationShield
│   ├── surgeon_screen.lua     → SurgeonScreen
│   ├── doors/
│   │   ├── swing_door_right.lua    → SwingDoor
│   │   └── entrance_right_door.lua → EntranceDoor
│   └── machines/
│       └── operating_table.lua     → OperatingTable
│
├── rooms/
│   ├── gp.lua                 → GPRoom
│   ├── operating_theatre.lua  → OperatingTheatreRoom
│   ├── ward.lua               → WardRoom
│   ├── research.lua           → ResearchRoom
│   ├── training.lua           → TrainingRoom
│   ├── pharmacy.lua           → PharmacyRoom
│   ├── psych.lua              → PsychRoom
│   ├── staff_room.lua         → StaffRoom
│   ├── toilets.lua            → ToiletRoom
│   ├── blood_machine_room.lua → BloodMachineRoom
│   ├── cardiogram.lua         → CardiogramRoom
│   ├── decontamination.lua    → DecontaminationRoom
│   ├── dna_fixer.lua          → DNAFixerRoom
│   ├── electrolysis.lua       → ElectrolysisRoom
│   ├── fracture_clinic.lua    → FractureRoom
│   ├── general_diag.lua       → GeneralDiagRoom
│   ├── hair_restoration.lua   → HairRestorationRoom
│   ├── inflation.lua          → InflationRoom
│   ├── jelly_vat.lua          → JellyVatRoom
│   ├── scanner_room.lua       → ScannerRoom
│   ├── slack_tongue.lua       → SlackTongueRoom
│   ├── ultrascan.lua          → UltrascanRoom
│   └── x_ray_room.lua         → XRayRoom
│
├── hospitals/
│   ├── player_hospital.lua    → PlayerHospital
│   └── ai_hospital.lua        → AIHospital
│
├── dialogs/
│   ├── adviser.lua            → UIAdviser
│   ├── bottom_panel.lua       → UIBottomPanel
│   ├── build_room.lua         → UIBuildRoom
│   ├── confirm_dialog.lua     → UIConfirmDialog
│   ├── furnish_corridor.lua   → UIFurnishCorridor
│   ├── hire_staff.lua         → UIHireStaff
│   ├── information.lua        → UIInformation
│   ├── jukebox.lua            → UIJukebox
│   ├── machine_dialog.lua     → UIMachine
│   ├── menu.lua               → UIMenuBar, UIMenu
│   ├── message.lua            → UIMessage
│   ├── patient.lua            → UIPatient
│   ├── place_objects.lua      → UIPlaceObjects
│   ├── place_staff.lua        → UIPlaceStaff
│   ├── queue_dialog.lua       → UIQueue, UIQueuePopup
│   ├── staff_dialog.lua       → UIStaff
│   ├── staff_rise.lua         → UIStaffRise
│   ├── watch.lua              → UIWatch
│   ├── subtitles.lua          → Subtitles, SubtitleQueue
│   ├── edit_room.lua          → UIEditRoom
│   ├── tree_ctrl.lua          → TreeControl, TreeNode, FileTreeNode, DummyRootNode
│   ├── fullscreen.lua         → UIFullscreen
│   ├── fullscreen/
│   │   ├── annual_report.lua  → UIAnnualReport
│   │   ├── bank_manager.lua   → UIBankManager
│   │   ├── drug_casebook.lua  → UICasebook
│   │   ├── fax.lua            → UIFax
│   │   ├── graphs.lua         → UIGraphs
│   │   ├── hospital_policy.lua→ UIPolicy
│   │   ├── progress_report.lua→ UIProgressReport
│   │   ├── research_policy.lua→ UIResearch
│   │   ├── staff_management.lua → UIStaffManagement
│   │   └── town_map.lua       → UITownMap
│   └── resizables/
│       ├── resizable.lua      → UIResizable
│       ├── adviser_history.lua→ UIAdviserHistory
│       ├── calls_dispatcher.lua → UICallsDispatcher
│       ├── cheats_dialog.lua  → UICheats
│       ├── customise.lua      → UICustomise
│       ├── directory_browser.lua → UIDirectoryBrowser, DirTreeNode, InstallDirTreeNode
│       ├── dropdown.lua       → UIDropdown
│       ├── file_browser.lua   → UIFileBrowser, FilteredFileTreeNode, FilteredTreeControl
│       ├── folder_settings.lua→ UIFolder
│       ├── hotkey_assign.lua  → UIHotkeyAssign, UIHotkeyAssignKeyPane
│       ├── lua_console.lua    → UILuaConsole
│       ├── machine_menu.lua   → UIMachineMenu
│       ├── main_menu.lua      → UIMainMenu
│       ├── map_editor.lua     → UIMapEditor
│       ├── menu_list_dialog.lua → UIMenuList
│       ├── new_game.lua       → UINewGame
│       ├── options.lua        → UIOptions, UIResolution, UIScrollSpeed, UIShiftScrollSpeed, UIZoomSpeed
│       ├── sound_setting.lua  → UISoundSettings
│       ├── tip_of_the_day.lua → UITipOfTheDay
│       ├── update.lua         → UIUpdate
│       ├── file_browsers/
│       │   ├── choose_font.lua → UIChooseFont
│       │   ├── choose_soundfont.lua → UIChooseSoundfont
│       │   ├── load_game.lua  → UILoadGame
│       │   ├── load_map.lua   → UILoadMap
│       │   ├── save_game.lua  → UISaveGame
│       │   └── save_map.lua   → UISaveMap
│       └── menu_list_dialogs/
│           ├── custom_campaign.lua → UICustomCampaign
│           ├── custom_game.lua → UICustomGame
│           └── make_debug_patient.lua → UIMakeDebugPatient
│
└── humanoid_actions/
    ├── answer_call.lua        → AnswerCallAction
    ├── call_checkpoint.lua    → CallCheckPointAction
    ├── check_watch.lua        → CheckWatchAction
    ├── die.lua                → DieAction
    ├── falling.lua            → FallingAction
    ├── get_up.lua             → GetUpAction
    ├── idle.lua               → IdleAction
    ├── idle_spawn.lua         → IdleSpawnAction
    ├── knock_door.lua         → KnockDoorAction
    ├── meander.lua            → MeanderAction
    ├── multi_use_object.lua   → MultiUseObjectAction
    ├── on_ground.lua          → OnGroundAction
    ├── pee.lua                → PeeAction
    ├── pickup.lua             → PickupAction
    ├── queue.lua              → QueueAction
    ├── seek_reception.lua     → SeekReceptionAction
    ├── seek_room.lua          → SeekRoomAction
    ├── seek_staffroom.lua     → SeekStaffRoomAction
    ├── seek_toilets.lua       → SeekToiletsAction
    ├── shake_fist.lua         → ShakeFistAction
    ├── spawn.lua              → SpawnAction
    ├── staff_reception.lua    → StaffReceptionAction
    ├── sweep_floor.lua        → SweepFloorAction
    ├── tap_foot.lua           → TapFootAction
    ├── use_object.lua         → UseObjectAction
    ├── use_screen.lua         → UseScreenAction
    ├── use_staffroom.lua      → UseStaffRoomAction
    ├── vaccinate.lua          → VaccinateAction
    ├── vip_go_to_next_room.lua→ VipGoToNextRoomAction
    ├── vomit.lua              → VomitAction
    ├── walk.lua               → WalkAction
    └── yawn.lua               → YawnAction
```

---

*End of MAP.md — 195 classes indexed by file:line and category*


## Related Pages

- [[02-class-hierarchy/SUMMARY]]
- [[02-class-hierarchy/CHECKLIST]]
- [[02-class-hierarchy/SCAFFOLD]]
