# CorsixTH Complete Class Mapping

> Generated: 2026-08-17 | Total: 195 classes across 10 categories

## Inheritance Hierarchy

```
Entity
  +-- Humanoid
  |     +-- Patient
  |     |     +-- Vip
  |     |     +-- Inspector
  |     |     +-- GrimReaper
  |     +-- Staff
  |     |     +-- Doctor
  |     |     +-- Nurse
  |     |     +-- Handyman
  |     |     +-- Receptionist
  +-- Object
  |     +-- SideObject
  |     +-- Machine
  |     |     +-- OperatingTable
  |     +-- Door
  |     |     +-- SwingDoor
  |     +-- EntranceDoor
  |     +-- Bench
  |     +-- Chair
  |     +-- Plant
  |     +-- ReceptionDesk
  |     +-- Rathole
  |     +-- Helicopter
  |     +-- AtomAnalyser
  |     +-- OperatingSink
  |     +-- RadiationShield
  |     +-- SurgeonScreen
  +-- Litter  (NOTE: directly extends Entity, not Object)

Room
  +-- GPRoom
  +-- OperatingTheatreRoom
  +-- WardRoom
  +-- ResearchRoom
  +-- TrainingRoom
  +-- PharmacyRoom
  +-- PsychRoom
  +-- StaffRoom
  +-- ToiletRoom
  +-- BloodMachineRoom
  +-- CardiogramRoom
  +-- DecontaminationRoom
  +-- DNAFixerRoom
  +-- ElectrolysisRoom
  +-- FractureRoom
  +-- GeneralDiagRoom
  +-- HairRestorationRoom
  +-- InflationRoom
  +-- JellyVatRoom
  +-- ScannerRoom
  +-- SlackTongueRoom
  +-- UltrascanRoom
  +-- XRayRoom

Hospital
  +-- PlayerHospital
  +-- AIHospital

Window
  +-- UI
  |     +-- GameUI
  +-- UIFullscreen
  |     +-- UIAnnualReport, UIBankManager, UICasebook, UIFax,
  |         UIGraphs, UIPolicy, UIProgressReport, UIResearch,
  |         UIStaffManagement, UITownMap
  +-- UIResizable
  |     +-- UIAdviserHistory, UICallsDispatcher, UICheats,
  |         UICustomise, UIDirectoryBrowser, UIDropdown,
  |         UIFileBrowser, UIFolder, UIHotkeyAssign,
  |         UILuaConsole, UIMachineMenu, UIMainMenu,
  |         UIMapEditor, UIMenuList, UINewGame, UIOptions,
  |         UIResolution, UIScrollSpeed, UIShiftScrollSpeed,
  |         UIZoomSpeed, UISoundSettings, UITipOfTheDay, UIUpdate
  |     +-- UIFileBrowser
  |           +-- UIChooseFont, UIChooseSoundfont, UILoadGame,
  |               UILoadMap, UISaveGame, UISaveMap
  |     +-- UIMenuList
  |           +-- UICustomCampaign, UICustomGame, UIMakeDebugPatient
  +-- UIAdviser, UIBottomPanel, UIBuildRoom, UIConfirmDialog,
      UIFurnishCorridor, UIHireStaff, UIInformation, UIJukebox,
      UIMachine, UIMenuBar, UIPatient, UIPlaceObjects, UIPlaceStaff,
      UIQueue, UIQueuePopup, UIStaff, UIStaffRise, UIWatch, Subtitles,
      UIMessage, UIHotkeyAssignKeyPane, TreeControl
  +-- UIPlaceObjects
        +-- UIEditRoom

HumanoidAction
  +-- AnswerCallAction, CallCheckPointAction, CheckWatchAction,
      DieAction, FallingAction, GetUpAction, IdleAction,
      IdleSpawnAction, KnockDoorAction, MeanderAction,
      MultiUseObjectAction, OnGroundAction, PeeAction,
      PickupAction, QueueAction, SeekReceptionAction,
      SeekRoomAction, SeekStaffRoomAction, SeekToiletsAction,
      ShakeFistAction, SpawnAction, StaffReceptionAction,
      SweepFloorAction, TapFootAction, UseObjectAction,
      UseScreenAction, UseStaffRoomAction, VaccinateAction,
      VipGoToNextRoomAction, VomitAction, WalkAction, YawnAction

TreeNode
  +-- FileTreeNode
  |     +-- DirTreeNode
  |     |     +-- InstallDirTreeNode
  |     +-- FilteredFileTreeNode
  +-- DummyRootNode

TreeControl (extends Window)
  +-- FilteredTreeControl
```

---

## CATEGORY 1: CORE / APPLICATION (10 classes)

### 1. App
- **File:** `CorsixTH/Lua/app.lua:33`
- **Superclass:** none (root)
- **Key methods:** `init()`, `onTick()`, `drawFrame()`, `dispatch()`, `loadLevel()`, `loadMainMenu()`, `loadCampaign()`, `errorHandler()`, `onKeyDown()`, `onKeyUp()`, `onMouseDown()`, `onMouseUp()`, `onMouseMove()`, `onMouseWheel()`, `onMusicOver()`, `onMovieOver()`, `onWindowResized()`, `saveConfig()`, `fixConfig()`
- **Key state fields:** `command_line`, `config`, `hotkeys`, `runtime_config`, `gfx`, `strings`, `savegame_version`, `eventHandlers`, `idle_tick`
- **Collections:** Singleton; referenced as `TheApp`

### 2. World
- **File:** `CorsixTH/Lua/world.lua:48`
- **Superclass:** none
- **Key methods:** `World()`, `onTick()`, `setUI()`, `spawnPatient()`, `spawnVIP()`, `newRoom()`, `newEntity()`, `destroyEntity()`, `initLevel()`, `speedUp()`, `previousSpeed()`, `setSpeed()`, `isPaused()`, `pauseOrUnpause()`, `getLocalPlayerHospital()`, `calculateSpawnTiles()`, `markRoomAsBuilt()`, `notifyRoomRemoved()`, `date()`
- **Key state fields:** `app`, `map`, `entities`, `objects`, `rooms`, `hospitals`, `entity_map`, `pathfinder`, `dispatcher`, `game_date`, `tick_rate`, `tick_timer`, `hours_per_tick`, `user_paused`, `available_rooms`, `floating_dollars`, `spawn_points`, `earthquake`, `next_emergency_no`, `room_built`, `idle_cache`, `delayed_map_objects`
- **Collections:** `world.entities`, `world.objects`, `world.rooms`, `world.hospitals`

### 3. Map
- **File:** `CorsixTH/Lua/map.lua:22`
- **Superclass:** none
- **Key methods:** `Map()`, `getCellFlag()`, `getRoomId()`, `setCameraTile()`, `load()`, `setTemperatureDisplayMethod()`, `getDifficulty()`, `getParcelPrice()`
- **Key state fields:** `th` (C++ THMap), `width`, `height`, `app`, `difficulty`
- **Collections:** Singleton per game; `TheApp.map`, `World.map`

### 4. Date
- **File:** `CorsixTH/Lua/date.lua:29`
- **Superclass:** none
- **Key methods:** `Date()`, `year()`, `month()`, `dayOfMonth()`, `hour()`, `dayOfYear()`, `isSameMonth()`, `isLastDayOfMonth()`, `isNextDay()`, `plusDays()`, `plusHours()`, `hoursPerDay()` (static), `daysPerMonth()` (static), `equals()`
- **Key state fields:** `_year`, `_month`, `_day`, `_hour`
- **Collections:** `World.game_date`

### 5. Strings
- **File:** `CorsixTH/Lua/strings.lua:25`
- **Superclass:** none
- **Key methods:** `Strings()`, `init()`, `setLanguage()`
- **Key state fields:** `app`, `languages`, `language_chunks`, `language_to_chunk`
- **Collections:** Singleton; `TheApp.strings`

### 6. Graphics
- **File:** `CorsixTH/Lua/graphics.lua:29`
- **Superclass:** none
- **Key methods:** `Graphics()`, `init()`, `loadSpriteTable()`, `loadMainCursor()`, `loadFont()`, `loadAnimation()`, `loadPalette()`, `loadBackground()`
- **Key state fields:** `app`, `target`, `cache`, `palette_map`
- **Collections:** Singleton; `TheApp.gfx`

### 7. AnimationManager
- **File:** `CorsixTH/Lua/graphics.lua:858`
- **Superclass:** none
- **Key methods:** `AnimationManager()`, `setAnimLength()`, `getAnimLength()`, `setPatientMarker()`, `setStaffMarker()`
- **Key state fields:** `anim_length_cache`, `anims`
- **Collections:** Singleton; `TheApp.animation_manager`

### 8. Audio
- **File:** `CorsixTH/Lua/audio.lua:30`
- **Superclass:** none
- **Key methods:** `Audio()`, `init()`, `playSound()`, `playSoundAt()`, `playMusic()`, `playAnnouncement()`, `playEntitySounds()`, `stopBackgroundMusic()`, `clearCallbacks()`
- **Key state fields:** `app`, `has_bg_music`, `not_loaded`, `played_sound_callbacks`, `background_playlist`, `entities_waiting_for_sound_to_be_enabled`
- **Collections:** Singleton; `TheApp.audio`

### 9. MoviePlayer
- **File:** `CorsixTH/Lua/movie_player.lua:26`
- **Superclass:** none
- **Key methods:** `MoviePlayer()`, `playIntro()`, `playLevelWinVideo()`, `playLevelLoseVideo()`, `playVideo()`, `onMovieOver()`, `stop()`
- **Key state fields:** `app`, `moviePlayer`, `video_played_since_last_restart`
- **Collections:** Singleton; `TheApp.movie_player`

### 10. FileSystem
- **File:** `CorsixTH/Lua/filesystem.lua:34`
- **Superclass:** none
- **Key methods:** `FileSystem()`, `setPath()`, `setProvider()`, `getFileList()`, `getDirectoryList()`, `readContents()`, `isIso()`
- **Key state fields:** `files`, `sub_dirs`, `physical_path`, `provider`
- **Collections:** Used by `App` for file I/O

---

## CATEGORY 2: ENTITIES (15 classes)

### 11. Entity
- **File:** `CorsixTH/Lua/entity.lua:22`
- **Superclass:** none (root of entity hierarchy)
- **Key methods:** `Entity()`, `tick()`, `tickDay()`, `onDestroy()`, `onPickUp()`, `setAnimation()`, `setTile()`, `setPosition()`, `setSpeed()`, `setTilePositionSpeed()`, `setLayer()`, `setTimer()`, `setMoodInfo()`, `setMood()`, `setDynamicInfo()`, `getDynamicInfo()`, `clearDynamicInfo()`, `getRoom()`, `playSound()`, `playEntitySounds()`, `afterLoad()`, `resetAnimation()`, `getDrawingLayer()`, `notifyNewObject()`, `notifyNewRoom()`
- **Key state fields:** `world`, `th` (TH animation), `layers`, `tile_x`, `tile_y`, `animation_idx`, `animation_flags`, `ticks`, `mood_info`, `mood_marker`, `dynamic_info`, `timer_time`, `timer_function`, `slow_animation`
- **Collections:** `world.entities`, `world.entity_map`

### 12. Humanoid (extends Entity)
- **File:** `CorsixTH/Lua/entities/humanoid.lua:22`
- **Superclass:** Entity
- **Key methods:** `Humanoid()`, `tick()`, `tickDay()`, `onClick()`, `onDestroy()`, `afterLoad()`, `setMood()`, `setNextAction()`, `queueAction()`, `finishAction()`, `startAction()`, `walkTo()`, `despawn()`, `setHospital()`, `setType()`, `isType()`, `leaveArea()`, `tire()`, `wake()`, `updateSpeed()`, `changeAttribute()`, `getCurrentAction()`, `isLeaving()`, `findObjectsInSquare()`, `notifyNewRoom()`, `registerRoomBuildCallback()`, `unregisterCallbacks()`
- **Key state fields:** `action_queue`, `last_move_direction`, `attributes` (warmth, happiness, health, fatigue, thirst, toilet_need), `active_moods`, `speed`, `hospital`, `in_room`, `user_of`, `walk_anims`, `die_anims`, `should_knock_on_doors`, `build_callbacks`, `remove_callbacks`, `staff_change_callbacks`
- **Collections:** `world.entities`, `room.humanoids`, `world.entity_map`

### 13. Object (extends Entity)
- **File:** `CorsixTH/Lua/entities/object.lua:24`
- **Superclass:** Entity
- **Key methods:** `Object()`, `tick()`, `onClick()`, `onDestroy()`, `onPickUp()`, `afterLoad()`, `initOrientation()`, `setTile()`, `setUser()`, `removeUser()`, `addReservedUser()`, `removeReservedUser()`, `isReservedFor()`, `occupyTilesByObjectFootprintAt()`, `deoccupyTilesByObjectFootprintAt()`, `getWalkableTiles()`, `getRenderAttachTile()`, `getXYforUsePosition()`, `isMachine()`, `setInvisible()`, `incrementUsedCount()`, `updateDynamicInfo()`, `resetAnimation()`, `eraseObject()`, `resetUsageAndReservaton()`, `getState()`, `setState()`, `slaveMixinClass()` (static mixin)
- **Key state fields:** `object_type`, `hospital`, `world`, `direction`, `footprint`, `user`, `reserved_for`, `times_used`, `split_anims`, `split_anim_positions`, `ticked_since`, `dynamic_info`
- **Collections:** `world.objects`, `room.objects`, `hospital.tile_object_counts`, `world.entity_map`

### 14. SideObject (extends Object)
- **File:** `CorsixTH/Lua/entities/object.lua:1075`
- **Superclass:** Object
- **Key methods:** `SideObject()`, `getDrawingLayer()`
- **Key state fields:** inherits Object fields
- **Collections:** `world.objects`

### 15. Machine (extends Object)
- **File:** `CorsixTH/Lua/entities/machine.lua:24`
- **Superclass:** Object
- **Key methods:** `Machine()`, `notifyNewRoom()`, `machineUsed()`, `earthquakeImpact()`, `getRemainingUses()`, `isBreaking()`, `isMachine()`, `explodeMachine()`, `repairMachine()`, `setCrashedAnimation()`, `updateDynamicInfo()`, `setHandymanRepairPosition()`
- **Key state fields:** `strength`, `times_used`, `total_usage`, `smokeInfo`, `waiting_for_finalize`, `mood_marker`, `repairable`
- **Collections:** `world.objects`, `room.objects`

### 16. Patient (extends Humanoid)
- **File:** `CorsixTH/Lua/entities/humanoids/patient.lua:22`
- **Superclass:** Humanoid
- **Key methods:** `Patient()`, `tick()`, `tickDay()`, `onClick()`, `onDestroy()`, `setDisease()`, `changeDisease()`, `setDiagnosed()`, `completeDiagnosticStep()`, `treatDisease()`, `agreesToPay()`, `isTreatmentEffective()`, `hasMoreDiagnosisRoomsAvailable()`, `cure()`, `die()`, `falling()`, `vomit()`, `pee()`, `goHome()`, `despawn()`, `setToDying()`, `handleToiletNeed()`, `_dailyHealthChecks()`, `_dailyWaitChecks()`
- **Key state fields:** `disease`, `diagnosed`, `diagnosis_progress`, `cure_rooms_visited`, `available_diagnosis_rooms`, `treatment_history`, `going_home`, `cured`, `dead`, `set_to_die`, `going_to_die`, `infected`, `vaccinated`, `is_emergency`, `pay_amount`, `reserved_for`, `needs_redirecting`, `has_passed_reception`, `going_to_toilet`, `health_history`, `action_string`, `has_fallen`, `has_vomitted`, `litter_countdown`, `insurance_company`
- **Collections:** `world.entities`, `room.humanoids`, `hospital.patients`

### 17. Staff (extends Humanoid)
- **File:** `CorsixTH/Lua/entities/humanoids/staff.lua:26`
- **Superclass:** Humanoid
- **Key methods:** `Staff()`, `tick()`, `tickDay()`, `onClick()`, `onDestroy()`, `afterLoad()`, `setProfile()`, `fire()`, `die()`, `despawn()`, `onPickup()`, `onPlaceInCorridor()`, `setHospital()`, `goToStaffRoom()`, `checkIfNeedRest()`, `isTiring()`, `isResting()`, `isMeandering()`, `isIdle()`, `fulfillsCriterion()`, `requestRaise()`, `updateDynamicInfo()`, `setDynamicInfoText()`, `getServiceQuality()`, `isVeryTired()`, `updateSpeed()`
- **Key state fields:** `profile` (StaffProfile), `hover_cursor`, `parcelNr`, `fired`, `pickup`, `going_to_staffroom`, `task`, `on_call`, `last_room`, `timer_until_raise`, `leave_sounds`, `leave_priority`
- **Collections:** `world.entities`, `room.humanoids`, `hospital.staff`

### 18. Doctor (extends Staff)
- **File:** `CorsixTH/Lua/entities/humanoids/staff/doctor.lua:28`
- **Superclass:** Staff
- **Key methods:** `Doctor()`, `tick()`, `tickDay()`, `setProfile()`, `updateSkill()`, `trainSkills()`, `isResearching()`, `isLearning()`, `isLearningOnTheJob()`, `fulfillsCriterion()`, `updateStaffTitle()`
- **Key state fields:** inherits Staff fields; `leave_sounds` = {"sack001.wav", ...}
- **Collections:** `world.entities`, `room.humanoids`, `hospital.staff`

### 19. Nurse (extends Staff)
- **File:** `CorsixTH/Lua/entities/humanoids/staff/nurse.lua:27`
- **Superclass:** Staff
- **Key methods:** `Nurse()`, `afterLoad()`, `fulfillsCriterion()`, `adviseWrongPersonForThisRoom()`
- **Key state fields:** inherits Staff fields; `leave_sounds` = {"sack004.wav", "sack005.wav"}
- **Collections:** `world.entities`, `room.humanoids`, `hospital.staff`

### 20. Handyman (extends Staff)
- **File:** `CorsixTH/Lua/entities/humanoids/staff/handyman.lua:27`
- **Superclass:** Staff
- **Key methods:** `Handyman()`, `setProfile()`, `dump()`, `setPriority()`, `getPriority()`, `goToStaffRoom()`, `fulfillsCriterion()`, `onPickup()`, `searchForHandymanTask()`, `assignHandymanTask()`, `releaseHandymanFromTask()`
- **Key state fields:** inherits Staff fields; `attributes` include `cleaning`, `watering`, `repairing` priorities; `task`, `last_room`
- **Collections:** `world.entities`, `room.humanoids`, `hospital.staff`, `hospital.handymanTasks`

### 21. Receptionist (extends Staff)
- **File:** `CorsixTH/Lua/entities/humanoids/staff/receptionist.lua:27`
- **Superclass:** Staff
- **Key methods:** `Receptionist()`, `tickDay()`, `isTiring()` (returns false), `isResting()` (returns false), `setProfile()`, `needsWorkStation()`, `checkIfNeedRest()`, `onPlaceInCorridor()`, `fulfillsCriterion()`, `onPickup()`, `getDrawingLayer()`
- **Key state fields:** inherits Staff fields; no fatigue attribute
- **Collections:** `world.entities`, `room.humanoids`, `hospital.staff`

### 22. Vip (extends Humanoid)
- **File:** `CorsixTH/Lua/entities/humanoids/vip.lua:60`
- **Superclass:** Humanoid
- **Key methods:** `Vip()`, `tickDay()`, `getNextRoom()`, `goHome()`, `evaluateRoom()`, `calculateVipRating()`, `sendVipReport()`, `onDestroy()`, `afterLoad()`
- **Key state fields:** `vip_rating`, `cash_reward`, `rep_reward`, `enter_deaths`, `enter_visitors`, `enter_patients`, `enter_cures`, `num_vomit_noninducing`, `num_vomit_inducing`, `num_visited_rooms`, `room_eval`, `waiting`, `slow_animation`, `announced`, `going_home`
- **Collections:** `world.entities`, `world.vip_spawn`

### 23. Inspector (extends Humanoid)
- **File:** `CorsixTH/Lua/entities/humanoids/inspector.lua:26`
- **Superclass:** Humanoid
- **Key methods:** `Inspector()`, `updateDynamicInfo()`, `setIfHoverMoodsVisible()`, `goHome()`, `onDestroy()`, `announce()`, `afterLoad()`
- **Key state fields:** `has_been_announced`, `last_hospital`, `going_home`
- **Collections:** `world.entities`

### 24. GrimReaper (extends Humanoid)
- **File:** `CorsixTH/Lua/entities/humanoids/grim_reaper.lua:21`
- **Superclass:** Humanoid
- **Key methods:** `GrimReaper()`, `tickDay()` (returns false), `updateDynamicInfo()`, `afterLoad()`
- **Key state fields:** `attributes` (empty), `walk_anims` (hardcoded), `hover_cursor`
- **Collections:** `world.entities`

### 25. Litter (extends Entity)
- **File:** `CorsixTH/Lua/objects/litter.lua:51`
- **Superclass:** Entity (NOT Object -- direct Entity subclass)
- **Key methods:** `Litter()`, `setTile()`, `setLitterType()`, `remove()`, `getDrawingLayer()`, `vomitInducing()`, `anyLitter()`, `getWalkableTiles()`
- **Key state fields:** `object_type`, `hospital`, `world`, `tile_x`, `tile_y`
- **Collections:** `world.entities`, `hospital.tile_object_counts`

---

## CATEGORY 3: OBJECTS (14 classes)

### 26. Door (extends Object)
- **File:** `CorsixTH/Lua/objects/door.lua:35`
- **Superclass:** Object
- **Key methods:** `Door()`, `setupDoor()`, `getRoom()`, `updateDynamicInfo()`, `onClick()`, `setTile()`, `getWalkableTiles()`, `getUsageTile()`, `isOccupant()`, `resetAnimation()`
- **Key state fields:** `queue` (Queue), `room`, `hover_cursor`
- **Collections:** `world.objects`, `room.door`

### 27. SwingDoor (extends Door)
- **File:** `CorsixTH/Lua/objects/doors/swing_door_right.lua:33`
- **Superclass:** Door
- **Key methods:** `SwingDoor()`, `pairDoors()`, `checkPaired()`, `onClick()`, `getUsageTile()`, `getWalkableTiles()`
- **Key state fields:** `is_master`, `slave`, `master`, `paired`, `old_anim`, `old_flags`
- **Collections:** `world.objects`, `room.door2`

### 28. EntranceDoor (extends Object)
- **File:** `CorsixTH/Lua/objects/doors/entrance_right_door.lua:34`
- **Superclass:** Object
- **Key methods:** `EntranceDoor()`, `onOccupantChange()`, `tick()`, `setInvisible()`
- **Key state fields:** `is_master`, `slave`, `master`, `occupant_count`, `is_open`, `anim_frames`, `frame_index`
- **Collections:** `world.objects`

### 29. Bench (extends Object)
- **File:** `CorsixTH/Lua/objects/bench.lua:146`
- **Superclass:** Object
- **Key methods:** `Bench()`, `removeUser()`, `resetUsageAndReservaton()`, `afterLoad()`
- **Key state fields:** inherits Object fields
- **Collections:** `world.objects`, `room.objects`, `hospital.tile_object_counts.bench`

### 30. Chair (extends Object)
- **File:** `CorsixTH/Lua/objects/chair.lua:156`
- **Superclass:** Object
- **Key methods:** `Chair()`, `afterLoad()`
- **Key state fields:** inherits Object fields
- **Collections:** `world.objects`, `room.objects`

### 31. Plant (extends Object)
- **File:** `CorsixTH/Lua/objects/plant.lua:91`
- **Superclass:** Object
- **Key methods:** `Plant()`, `setNextState()`, `restoreToFullHealth()`, `tickDay()`, `isPleasingFactor()`
- **Key state fields:** `current_state`, `base_frame`, `days_left`, `unreachable`, `unreachable_counter`, `phases`
- **Collections:** `world.objects`, `room.objects`, `hospital.tile_object_counts.plant`

### 32. ReceptionDesk (extends Object)
- **File:** `CorsixTH/Lua/objects/reception_desk.lua:71`
- **Superclass:** Object
- **Key methods:** `ReceptionDesk()`, `onClick()`, `tick()`, `occupy()`, `removeStaff()`, `setDynamicInfo()`
- **Key state fields:** `queue` (Queue), `queue_advance_timer`, `hover_cursor`
- **Collections:** `world.objects`, `hospital.reception_desks`

### 33. Rathole (extends Object)
- **File:** `CorsixTH/Lua/objects/rathole.lua:53`
- **Superclass:** Object
- **Key methods:** `Rathole()`, `getDrawingLayer()`
- **Key state fields:** inherits Object fields
- **Collections:** `world.objects`

### 34. Helicopter (extends Object)
- **File:** `CorsixTH/Lua/objects/helicopter.lua:41`
- **Superclass:** Object
- **Key methods:** `Helicopter()`, `tick()`, `spawnPatient()`
- **Key state fields:** `phase`, `spawned_patients`, `hospital`
- **Collections:** `world.objects`

### 35. AtomAnalyser (extends Object)
- **File:** `CorsixTH/Lua/objects/analyser.lua:59`
- **Superclass:** Object
- **Key methods:** `AtomAnalyser()`, `getDrawingLayer()`
- **Key state fields:** inherits Object fields
- **Collections:** `world.objects`, `room.objects`

### 36. OperatingSink (extends Object)
- **File:** `CorsixTH/Lua/objects/op_sink1.lua:66`
- **Superclass:** Object
- **Key methods:** Uses `slaveMixinClass()` mixin
- **Key state fields:** inherits Object fields + slave/master from mixin
- **Collections:** `world.objects`, `room.objects`

### 37. RadiationShield (extends Object)
- **File:** `CorsixTH/Lua/objects/radiation_shield.lua:73`
- **Superclass:** Object
- **Key methods:** Uses `slaveMixinClass()` mixin
- **Key state fields:** inherits Object fields + slave/master from mixin
- **Collections:** `world.objects`, `room.objects`

### 38. SurgeonScreen (extends Object)
- **File:** `CorsixTH/Lua/objects/surgeon_screen.lua:103`
- **Superclass:** Object
- **Key methods:** `SurgeonScreen()`
- **Key state fields:** `num_green_outfits`, `num_white_outfits`
- **Collections:** `world.objects`, `room.objects`

### 39. OperatingTable (extends Machine)
- **File:** `CorsixTH/Lua/objects/machines/operating_table.lua:123`
- **Superclass:** Machine
- **Key methods:** `slaveMixinClass()` + `machineUsed()` override
- **Key state fields:** inherits Machine fields + slave/master from mixin
- **Collections:** `world.objects`, `room.objects`

---

## CATEGORY 4: ROOMS (24 classes)

### 40. Room
- **File:** `CorsixTH/Lua/room.lua:21`
- **Superclass:** none (root of room hierarchy)
- **Key methods:** `Room()`, `initRoom()`, `getEntranceXY()`, `createLeaveAction()`, `createEnterAction()`, `getPatients()`, `getPatient()`, `getPatientCount()`, `dealtWithPatient()`, `commandEnteringStaff()`, `commandEnteringPatient()`, `onHumanoidEnter()`, `onHumanoidLeave()`, `roomFinished()`, `crashRoom()`, `tryAdvanceQueue()`, `setStaffMember()`, `getStaffMember()`, `testStaffCriteria()`, `getRequiredStaffCriteria()`, `getMissingStaff()`, `canHumanoidEnter()`, `makeHumanoidLeave()`, `enterEditMode()`, `hasQueueDialog()`, `isRoomInDemand()`, `afterLoad()`, `setStaffMembersAttribute()`, `shouldHavePatientReenter()`
- **Key state fields:** `id`, `world`, `hospital`, `room_info`, `x`, `y`, `width`, `height`, `door`, `door2`, `humanoids` (set), `objects` (set), `humanoids_enroute` (set), `staff_member`, `staff_member_set`, `built`, `crashed`, `is_active`, `maximum_patients`, `maximum_staff`, `sound_played`
- **Collections:** `world.rooms`

### 41-63. Room Subclasses (all extend Room)
| # | Class | File:Line | Key Override Methods |
|---|-------|-----------|---------------------|
| 41 | GPRoom | `rooms/gp.lua:44` | `doStaffUseCycle`, `commandEnteringStaff`, `commandEnteringPatient`, `dealtWithPatient`, `sendPatientToNextDiagnosisRoom`, `onHumanoidLeave`, `roomFinished`, `shouldHavePatientReenter` |
| 42 | OperatingTheatreRoom | `rooms/operating_theatre.lua:51` | `roomFinished`, `commandEnteringStaff`, `commandEnteringPatient`, `onHumanoidLeave`, `canHumanoidEnter`, `setStaffMembersAttribute`, `queueWashHands`, `setXRayOn` |
| 43 | WardRoom | `rooms/ward.lua:52` | `roomFinished`, `commandEnteringStaff`, `commandEnteringPatient`, `doStaffUseCycle`, `updateHealingAmount`, `onHumanoidLeave`, `setStaffMember`, `setStaffMembersAttribute`, `getMaximumStaffCriteria` |
| 44 | ResearchRoom | `rooms/research.lua:51` | `doStaffUseCycle`, `roomFinished`, `commandEnteringStaff`, `commandEnteringPatient`, `setStaffMember`, `setStaffMembersAttribute`, `onHumanoidLeave`, `getMaximumStaffCriteria`, `afterLoad` |
| 45 | TrainingRoom | `rooms/training.lua:41` | `roomFinished`, `calculateTrainingFactor`, `getTrainingFactor`, `getStaffCount`, `getMaximumStaffCriteria`, `doStaffUseCycle`, `onHumanoidEnter`, `commandEnteringStaff`, `testStaffCriteria` |
| 46 | PharmacyRoom | `rooms/pharmacy.lua:44` | `roomFinished`, `commandEnteringPatient` |
| 47 | PsychRoom | `rooms/psych.lua:45` | `roomFinished`, `commandEnteringStaff`, `commandEnteringPatient` |
| 48 | StaffRoom | `rooms/staff_room.lua:40` | `onHumanoidEnter`, `testStaffCriteria` |
| 49 | ToiletRoom | `rooms/toilets.lua:39` | `roomFinished`, `dealtWithPatient`, `onHumanoidEnter`, `getPatientCount`, `afterLoad` |
| 50 | BloodMachineRoom | `rooms/blood_machine_room.lua:45` | `commandEnteringPatient` |
| 51 | CardiogramRoom | `rooms/cardiogram.lua:45` | `commandEnteringPatient`, `makeHumanoidLeave`, `onHumanoidLeave`, `shouldHavePatientReenter` |
| 52 | DecontaminationRoom | `rooms/decontamination.lua:45` | `commandEnteringStaff`, `commandEnteringPatient`, `onHumanoidLeave` |
| 53 | DNAFixerRoom | `rooms/dna_fixer.lua:46` | `commandEnteringPatient` |
| 54 | ElectrolysisRoom | `rooms/electrolysis.lua:45` | `commandEnteringPatient` |
| 55 | FractureRoom | `rooms/fracture_clinic.lua:45` | `commandEnteringPatient` |
| 56 | GeneralDiagRoom | `rooms/general_diag.lua:44` | `commandEnteringPatient`, `makeHumanoidLeave`, `shouldHavePatientReenter` |
| 57 | HairRestorationRoom | `rooms/hair_restoration.lua:45` | `commandEnteringPatient` |
| 58 | InflationRoom | `rooms/inflation.lua:45` | `commandEnteringPatient` |
| 59 | JellyVatRoom | `rooms/jelly_vat.lua:45` | `commandEnteringPatient` |
| 60 | ScannerRoom | `rooms/scanner_room.lua:47` | `commandEnteringPatient`, `onHumanoidLeave`, `makeHumanoidLeave`, `dealtWithPatient`, `shouldHavePatientReenter` |
| 61 | SlackTongueRoom | `rooms/slack_tongue.lua:45` | `commandEnteringPatient` |
| 62 | UltrascanRoom | `rooms/ultrascan.lua:45` | `commandEnteringPatient` |
| 63 | XRayRoom | `rooms/x_ray_room.lua:45` | `commandEnteringPatient` |

---

## CATEGORY 5: HOSPITALS (3 classes)

### 64. Hospital
- **File:** `CorsixTH/Lua/hospital.lua:23`
- **Superclass:** none
- **Key methods:** `Hospital()`, `tick()`, `onEndDay()`, `onEndMonth()`, `onEndYear()`, `afterLoad()`, `spawnPatient()`, `addStaff()`, `addPatient()`, `humanoidDeath()`, `initStaff()`, `countStaffOfCategory()`, `countRoomOfType()`, `countPatients()`, `purchasePlot()`, `isInHospital()`, `hasReceptionDesk()`, `getObjectBuildCost()`, `spendMoney()`, `receiveMoney()`, `receiveMoneyForTreatment()`, `giveAdvice()`, `manageEpidemics()`, `determineIfContagious()`, `addToEpidemic()`, `spawnContagiousPatient()`, `resolveEmergency()`, `checkEmergencyOver()`, `createEmergency()`, `isPlayerHospital()`
- **Key state fields:** `world`, `name`, `balance`, `loan`, `reputation`, `value`, `interest_rate`, `epidemic`, `future_epidemics_pool`, `num_visitors`, `num_deaths`, `num_cured`, `num_explosions`, `statistics`, `disease_casebook`, `research` (ResearchDepartment), `hosp_cheats` (Cheats), `handymanTasks`, `epidemics_disabled`, `heating`, `tile_object_counts`, `reception_desks`, `built`, `staff`, `patients`, `emergency`, `popularity`
- **Collections:** `world.hospitals`

### 65. PlayerHospital (extends Hospital)
- **File:** `CorsixTH/Lua/hospitals/player_hospital.lua:25`
- **Superclass:** Hospital
- **Key methods:** `PlayerHospital()`, `dailyAdviceChecks()`, `afterLoad()`
- **Key state fields:** `adviser_data`, `win_declined`, `announce_vip`
- **Collections:** `world.hospitals[1]` (always index 1)

### 66. AIHospital (extends Hospital)
- **File:** `CorsixTH/Lua/hospitals/ai_hospital.lua:21`
- **Superclass:** Hospital
- **Key methods:** `AIHospital()`, `spawnPatient()` (stub), `logTransaction()` (no-op), `afterLoad()`
- **Key state fields:** `is_in_world` = false
- **Collections:** `world.hospitals[2+]`

---

## CATEGORY 6: UI / WINDOW SYSTEM (32 classes)

### 67. Window
- **File:** `CorsixTH/Lua/window.lua:24`
- **Superclass:** none (root of UI hierarchy)
- **Key methods:** `Window()`, `setSize()`, `setPosition()`, `draw()`, `onMouseUp()`, `onMouseDown()`, `onMouseMove()`, `onKeyDown()`, `onKeyUp()`, `addWindow()`, `removeWindow()`, `addPanel()`, `addButton()`, `addScrollbar()`, `addTextbox()`, `addHotkeybox()`, `addColourPanel()`, `addBevelPanel()`, `setDefault()`, `setTooltip()`, `hitTest()`
- **Key state fields:** `x`, `y`, `width`, `height`, `panels`, `buttons`, `tooltip_regions`, `scrollbars`, `textboxes`, `hotkeyboxes`, `windows`, `visible`, `draggable`, `panel_sprites`, `modal_class`
- **Collections:** `ui.windows`

### 68. Panel (in window.lua)
- **File:** `CorsixTH/Lua/window.lua:168`
- **Superclass:** none
- **Key methods:** `Panel()`, `draw()`
- **Key state fields:** `x`, `y`, `w`, `h`, `colour`, `lowered`, `visible`, `sprite`, `sprite_index`
- **Collections:** `window.panels`

### 69. Button (in window.lua)
- **File:** `CorsixTH/Lua/window.lua:594`
- **Superclass:** none
- **Key methods:** `Button()`, `draw()`, `onMouseUp()`, `onMouseDown()`
- **Key state fields:** `x`, `y`, `w`, `h`, `tooltip`, `on_click`, `enable`, `sound_done`, `visible`
- **Collections:** `window.buttons`

### 70. Scrollbar (in window.lua)
- **File:** `CorsixTH/Lua/window.lua:834`
- **Superclass:** none
- **Key methods:** `Scrollbar()`, `draw()`, `onMouseUp()`, `onMouseDown()`, `onMouseMove()`, `setRange()`, `setValue()`, `getValue()`
- **Key state fields:** `x`, `y`, `range`, `value`, `thumb_x`, `thumb_y`, `pressed`
- **Collections:** `window.scrollbars`

### 71. Textbox (in window.lua)
- **File:** `CorsixTH/Lua/window.lua:943`
- **Superclass:** none
- **Key methods:** `Textbox()`, `draw()`, `onKeyDown()`, `onMouseUp()`, `onMouseDown()`, `setText()`, `getText()`
- **Key state fields:** `x`, `y`, `text`, `font`, `caret`, `focused`, `enabled`, `panel`
- **Collections:** `window.textboxes`

### 72. HotkeyBox (in window.lua)
- **File:** `CorsixTH/Lua/window.lua:1342`
- **Superclass:** none
- **Key methods:** `HotkeyBox()`, `draw()`, `onMouseUp()`, `onMouseDown()`
- **Key state fields:** `x`, `y`, `key`, `menu_string`
- **Collections:** `window.hotkeyboxes`

### 73. UI (extends Window)
- **File:** `CorsixTH/Lua/ui.lua:24`
- **Superclass:** Window
- **Key methods:** `UI()`, `initKeyAndButtonCodes()`, `dispatch()`, `draw()`, `playSound()`, `playAnnouncement()`, `addWindow()`, `removeWindow()`, `addKeyHandler()`, `setCursorPosition()`, `getMouseXY()`, `afterLoad()`
- **Key state fields:** `app`, `key_handlers`, `key_remaps`, `button_remaps`, `gfx`, `video`, `cursor_x`, `cursor_y`, `buttons_down`, `modal_window`, `bottom_menu_visible`, `blue_filter_active`
- **Collections:** Singleton; `TheApp.ui`

### 74. GameUI (extends UI)
- **File:** `CorsixTH/Lua/game_ui.lua:25`
- **Superclass:** UI
- **Key methods:** `GameUI()`, `draw()`, `onTick()`, `onMouseMove()`, `onMouseDown()`, `onMouseUp()`, `onKeyDown()`, `onKeyUp()`, `setZoom()`, `scrollMap()`, `shakeScreen()`, `playAnnouncement()`, `afterLoad()`, `togglePlayerSpeed()`, `playWatchAnnouncement()`
- **Key state fields:** `hospital`, `tutorial`, `adviser`, `bottom_panel`, `menu_bar`, `subtitles`, `visible_diamond`, `scrolling`, `map_editor`, `announcer`, `tutorial`
- **Collections:** Singleton; `TheApp.ui` during gameplay

### 75-109. Dialog Classes (all extend Window, UIFullscreen, or UIResizable)
*(See detailed list in Category 7 below)*

---

## CATEGORY 7: DIALOGS (75 classes)

### Window-mode dialogs (extend Window):

| # | Class | File:Line |
|---|-------|-----------|
| 75 | UIAdviser | `dialogs/adviser.lua:24` |
| 76 | UIBottomPanel | `dialogs/bottom_panel.lua:22` |
| 77 | UIBuildRoom | `dialogs/build_room.lua:23` |
| 78 | UIConfirmDialog | `dialogs/confirm_dialog.lua:23` |
| 79 | UIFurnishCorridor | `dialogs/furnish_corridor.lua:27` |
| 80 | UIHireStaff | `dialogs/hire_staff.lua:21` |
| 81 | UIInformation | `dialogs/information.lua:22` |
| 82 | UIJukebox | `dialogs/jukebox.lua:24` |
| 83 | UIMachine | `dialogs/machine_dialog.lua:21` |
| 84 | UIMenuBar | `dialogs/menu.lua:26` |
| 85 | UIMessage | `dialogs/message.lua:22` |
| 86 | UIPatient | `dialogs/patient.lua:30` |
| 87 | UIPlaceObjects | `dialogs/place_objects.lua:31` |
| 88 | UIPlaceStaff | `dialogs/place_staff.lua:26` |
| 89 | UIQueue | `dialogs/queue_dialog.lua:24` |
| 90 | UIQueuePopup | `dialogs/queue_dialog.lua:362` |
| 91 | UIStaff | `dialogs/staff_dialog.lua:29` |
| 92 | UIStaffRise | `dialogs/staff_rise.lua:23` |
| 93 | UIWatch | `dialogs/watch.lua:23` |
| 94 | Subtitles | `dialogs/subtitles.lua:22` |
| 95 | UIEditRoom | `dialogs/edit_room.lua:23` |
| 96 | TreeControl | `dialogs/tree_ctrl.lua:484` |
| 97 | UIHotkeyAssignKeyPane | `dialogs/resizables/hotkey_assign.lua:568` |

### Fullscreen dialogs (extend UIFullscreen):

| # | Class | File:Line |
|---|-------|-----------|
| 98 | UIAnnualReport | `dialogs/fullscreen/annual_report.lua:22` |
| 99 | UIBankManager | `dialogs/fullscreen/bank_manager.lua:22` |
| 100 | UICasebook | `dialogs/fullscreen/drug_casebook.lua:22` |
| 101 | UIFax | `dialogs/fullscreen/fax.lua:25` |
| 102 | UIGraphs | `dialogs/fullscreen/graphs.lua:23` |
| 103 | UIPolicy | `dialogs/fullscreen/hospital_policy.lua:22` |
| 104 | UIProgressReport | `dialogs/fullscreen/progress_report.lua:22` |
| 105 | UIResearch | `dialogs/fullscreen/research_policy.lua:21` |
| 106 | UIStaffManagement | `dialogs/fullscreen/staff_management.lua:24` |
| 107 | UITownMap | `dialogs/fullscreen/town_map.lua:24` |

### Resizable dialogs (extend UIResizable):

| # | Class | File:Line |
|---|-------|-----------|
| 108 | UIAdviserHistory | `dialogs/resizables/adviser_history.lua:22` |
| 109 | UICallsDispatcher | `dialogs/resizables/calls_dispatcher.lua:22` |
| 110 | UICheats | `dialogs/resizables/cheats_dialog.lua:24` |
| 111 | UICustomise | `dialogs/resizables/customise.lua:22` |
| 112 | UIDirectoryBrowser | `dialogs/resizables/directory_browser.lua:118` |
| 113 | UIDropdown | `dialogs/resizables/dropdown.lua:23` |
| 114 | UIFileBrowser | `dialogs/resizables/file_browser.lua:146` |
| 115 | UIFolder | `dialogs/resizables/folder_settings.lua:22` |
| 116 | UIHotkeyAssign | `dialogs/resizables/hotkey_assign.lua:22` |
| 117 | UILuaConsole | `dialogs/resizables/lua_console.lua:26` |
| 118 | UIMachineMenu | `dialogs/resizables/machine_menu.lua:22` |
| 119 | UIMainMenu | `dialogs/resizables/main_menu.lua:22` |
| 120 | UIMapEditor | `dialogs/resizables/map_editor.lua:22` |
| 121 | UIMenuList | `dialogs/resizables/menu_list_dialog.lua:22` |
| 122 | UINewGame | `dialogs/resizables/new_game.lua:22` |
| 123 | UIOptions | `dialogs/resizables/options.lua:22` |
| 124 | UIResolution | `dialogs/resizables/options.lua:637` |
| 125 | UIScrollSpeed | `dialogs/resizables/options.lua:720` |
| 126 | UIShiftScrollSpeed | `dialogs/resizables/options.lua:790` |
| 127 | UIZoomSpeed | `dialogs/resizables/options.lua:859` |
| 128 | UISoundSettings | `dialogs/resizables/sound_setting.lua:21` |
| 129 | UITipOfTheDay | `dialogs/resizables/tip_of_the_day.lua:22` |
| 130 | UIUpdate | `dialogs/resizables/update.lua:22` |

### File browser variants (extend UIFileBrowser):

| # | Class | File:Line |
|---|-------|-----------|
| 131 | UIChooseFont | `dialogs/resizables/file_browsers/choose_font.lua:25` |
| 132 | UIChooseSoundfont | `dialogs/resizables/file_browsers/choose_soundfont.lua:27` |
| 133 | UILoadGame | `dialogs/resizables/file_browsers/load_game.lua:22` |
| 134 | UILoadMap | `dialogs/resizables/file_browsers/load_map.lua:22` |
| 135 | UISaveGame | `dialogs/resizables/file_browsers/save_game.lua:22` |
| 136 | UISaveMap | `dialogs/resizables/file_browsers/save_map.lua:22` |

### Menu list variants (extend UIMenuList):

| # | Class | File:Line |
|---|-------|-----------|
| 137 | UICustomCampaign | `dialogs/resizables/menu_list_dialogs/custom_campaign.lua:22` |
| 138 | UICustomGame | `dialogs/resizables/menu_list_dialogs/custom_game.lua:22` |
| 139 | UIMakeDebugPatient | `dialogs/resizables/menu_list_dialogs/make_debug_patient.lua:21` |

### Tree control nodes:

| # | Class | File:Line | Superclass |
|---|-------|-----------|------------|
| 140 | TreeNode | `dialogs/tree_ctrl.lua:22` | none |
| 141 | FileTreeNode | `dialogs/tree_ctrl.lua:185` | TreeNode |
| 142 | DummyRootNode | `dialogs/tree_ctrl.lua:451` | TreeNode |
| 143 | DirTreeNode | `dialogs/resizables/directory_browser.lua:27` | FileTreeNode |
| 144 | InstallDirTreeNode | `dialogs/resizables/directory_browser.lua:61` | DirTreeNode |
| 145 | FilteredFileTreeNode | `dialogs/resizables/file_browser.lua:25` | FileTreeNode |
| 146 | FilteredTreeControl | `dialogs/resizables/file_browser.lua:70` | TreeControl |

### Non-UI dialog support classes:

| # | Class | File:Line | Superclass |
|---|-------|-----------|------------|
| 147 | UIMenu | `dialogs/menu.lua:485` | none |
| 148 | SubtitleQueue | `dialogs/subtitles.lua:85` | none |

---

## CATEGORY 8: HUMANOID ACTIONS (33 classes)

### 149. HumanoidAction
- **File:** `CorsixTH/Lua/humanoid_action.lua:22`
- **Superclass:** none (root of action hierarchy)
- **Key methods:** `HumanoidAction()`, `setCount()`, `setMustHappen()`, `setUninterruptible()`, `setLoopCallback()`, `setAfterUse()`, `setIsLeaving()`, `setNoTruncate()`, `afterLoad()`, `setName()`
- **Key state fields:** `name`, `count`, `must_happen`, `loop_callback`, `after_use`, `is_leaving`, `no_truncate`, `uninterruptible`
- **Collections:** `humanoid.action_queue`

### Action subclasses (all extend HumanoidAction):

| # | Class | File:Line | Key Purpose |
|---|-------|-----------|-------------|
| 150 | AnswerCallAction | `humanoid_actions/answer_call.lua:21` | Handyman responds to task |
| 151 | CallCheckPointAction | `humanoid_actions/call_checkpoint.lua:21` | Track assigned calls |
| 152 | CheckWatchAction | `humanoid_actions/check_watch.lua:21` | VIP checks watch |
| 153 | DieAction | `humanoid_actions/die.lua:21` | Patient death sequence |
| 154 | FallingAction | `humanoid_actions/falling.lua:21` | Humanoid falls down |
| 155 | GetUpAction | `humanoid_actions/get_up.lua:21` | Rise from ground |
| 156 | IdleAction | `humanoid_actions/idle.lua:21` | Standing idle |
| 157 | IdleSpawnAction | `humanoid_actions/idle_spawn.lua:21` | Idle with spawn anim |
| 158 | KnockDoorAction | `humanoid_actions/knock_door.lua:21` | Knock on room door |
| 159 | MeanderAction | `humanoid_actions/meander.lua:21` | Wander corridor |
| 160 | MultiUseObjectAction | `humanoid_actions/multi_use_object.lua:21` | Use object with another humanoid |
| 161 | OnGroundAction | `humanoid_actions/on_ground.lua:21` | Lying on ground |
| 162 | PeeAction | `humanoid_actions/pee.lua:21` | Patient urinating |
| 163 | PickupAction | `humanoid_actions/pickup.lua:21` | Player picks up humanoid |
| 164 | QueueAction | `humanoid_actions/queue.lua:21` | Stand in queue |
| 165 | SeekReceptionAction | `humanoid_actions/seek_reception.lua:21` | Walk to reception desk |
| 166 | SeekRoomAction | `humanoid_actions/seek_room.lua:21` | Walk to a room |
| 167 | SeekStaffRoomAction | `humanoid_actions/seek_staffroom.lua:21` | Walk to staff room |
| 168 | SeekToiletsAction | `humanoid_actions/seek_toilets.lua:22` | Walk to toilet |
| 169 | ShakeFistAction | `humanoid_actions/shake_fist.lua:21` | Shake fist at screen |
| 170 | SpawnAction | `humanoid_actions/spawn.lua:21` | Spawn/despawn at map edge |
| 171 | StaffReceptionAction | `humanoid_actions/staff_reception.lua:21` | Staff walks to reception |
| 172 | SweepFloorAction | `humanoid_actions/sweep_floor.lua:21` | Handyman cleans litter |
| 173 | TapFootAction | `humanoid_actions/tap_foot.lua:21` | Impatient foot tapping |
| 174 | UseObjectAction | `humanoid_actions/use_object.lua:24` | Use a machine/object |
| 175 | UseScreenAction | `humanoid_actions/use_screen.lua:21` | Use surgeon screen |
| 176 | UseStaffRoomAction | `humanoid_actions/use_staffroom.lua:21` | Rest in staff room |
| 177 | VaccinateAction | `humanoid_actions/vaccinate.lua:21` | Nurse vaccinates patient |
| 178 | VipGoToNextRoomAction | `humanoid_actions/vip_go_to_next_room.lua:21` | VIP moves to next room |
| 179 | VomitAction | `humanoid_actions/vomit.lua:21` | Patient vomits |
| 180 | WalkAction | `humanoid_actions/walk.lua:21` | Walk to tile |
| 181 | YawnAction | `humanoid_actions/yawn.lua:21` | Patient yawns |

---

## CATEGORY 9: SUPPORT / MANAGEMENT (11 classes)

### 182. StaffProfile
- **File:** `CorsixTH/Lua/staff_profile.lua:21`
- **Superclass:** none
- **Key methods:** `StaffProfile()`, `setDoctorAbilities()`, `initDoctor()`, `init()`, `setSkill()`, `randomise()`, `randomiseOrganical()`, `parseSkillLevel()`, `getFairWage()`, `afterLoad()`
- **Key state fields:** `world`, `humanoid_class`, `name`, `initial`, `skill`, `wage`, `layer5`, `attention_to_detail`, `profession`, `is_psychiatrist`, `is_surgeon`, `is_researcher`, `is_junior`, `is_consultant`
- **Collections:** `Staff.profile`

### 183. Queue
- **File:** `CorsixTH/Lua/queue.lua:31`
- **Superclass:** none
- **Key methods:** `Queue()`, `expect()`, `unexpect()`, `decreaseMaxSize()`, `increaseMaxSize()`, `setMaxQueue()`, `setBenchThreshold()`, `size()`, `isFull()`, `reportedSize()`, `expectedSize()`, `hasEmergencyPatient()`, `patientSize()`, `reportedHumanoid()`, `push()`, `remove()`, `dropFromQueue()`, `afterLoad()`
- **Key state fields:** `reported_size`, `expected`, `callbacks`, `expected_count`, `visitor_count`, `max_size`, `bench_threshold`
- **Collections:** `Door.queue`, `ReceptionDesk.queue`

### 184. EntityMap
- **File:** `CorsixTH/Lua/entity_map.lua:21`
- **Superclass:** none
- **Key methods:** `EntityMap()`, `addEntity()`, `removeEntity()`, `getHumanoidsAtCoordinate()`, `getObjectsAtCoordinate()`
- **Key state fields:** `width`, `height`, `entity_map` (2D array of `{humanoids={}, objects={}}`)
- **Collections:** `World.entity_map`

### 185. Earthquake
- **File:** `CorsixTH/Lua/earthquake.lua:22`
- **Superclass:** none
- **Key methods:** `Earthquake()`, `tick()`, `nextEarthquake()`, `afterLoad()`
- **Key state fields:** `world`, `active`, `next_planned`, `start_month`, `start_day`, `size`, `remaining_damage`, `damage_timer`, `warning_timer`, `current_map_earthquake`, `disabled`
- **Collections:** `World.earthquake`

### 186. Epidemic
- **File:** `CorsixTH/Lua/epidemic.lua:25`
- **Superclass:** none
- **Key methods:** `Epidemic()`, `tick()`, `addContagiousPatient()`, `infectOtherPatients()`, `checkIfReadyToReveal()`, `markedPatientsCallForVaccination()`, `markForVaccination()`, `vaccinatePatient()`, `checkInfectedLeftHospital()`, `checkNoInfectedPatients()`, `reveal()`, `afterLoad()`
- **Key state fields:** `hospital`, `world`, `infected_patients`, `disease`, `ready_to_reveal`, `revealed`, `declare_fine`, `reputation_hit`, `coverup_fine`, `compensation`, `will_be_evacuated`, `coverup_selected`, `timer`, `vaccination_mode_active`, `total_infections`, `attempted_infections`, `spread_factor`, `inspector`
- **Collections:** `Hospital.epidemic`, `Hospital.future_epidemics_pool`

### 187. Cheats
- **File:** `CorsixTH/Lua/cheats.lua:27`
- **Superclass:** none
- **Key methods:** `Cheats()`, `performCheat()`, `announceCheat()`, `isCheatActive()`, `cheatMoney()`, `cheatResearch()`, `cheatEmergency()`, `cheatVip()`, etc.
- **Key state fields:** `hospital`, `cheat_list`, `active_cheats`
- **Collections:** `Hospital.hosp_cheats`

### 188. CallsDispatcher
- **File:** `CorsixTH/Lua/calls_dispatcher.lua:25`
- **Superclass:** none
- **Key methods:** `CallsDispatcher()`, `onTick()`, `callForStaff()`, `callForRepair()`, `callForWatering()`, `callForCleaning()`, `dropFromQueue()`, `enqueue()`, `onChange()`, `addChangeCallback()`, `removeChangeCallback()`
- **Key state fields:** `world`, `call_queue`, `change_callback`, `tick`
- **Collections:** `World.dispatcher`

### 189. ResearchDepartment
- **File:** `CorsixTH/Lua/research_department.lua:32`
- **Superclass:** none
- **Key methods:** `ResearchDepartment()`, `initResearch()`, `setResearchConcentration()`, `addResearchPoints()`, `discoverObject()`, `improveObject()`, `improveDrug()`, `afterLoad()`
- **Key state fields:** `hospital`, `world`, `research_progress`, `research_policy` (cure, diagnosis, drugs, improvements), `drain`
- **Collections:** `Hospital.research`

### 190. EndConditions
- **File:** `CorsixTH/Lua/endconditions.lua:44`
- **Superclass:** none
- **Key methods:** `EndConditions()`, `checkEndGame()`, `generateReportTable()`, `_loadGoals()`, `_checkWinGroup()`, `_checkLoseGroup()`
- **Key state fields:** `win_goals`, `lose_goals`, `highest_group`
- **Collections:** `World.end_conditions`

---

## CATEGORY 10: ANNOUNCER SYSTEM (3 classes)

### 191. AnnouncementQueue
- **File:** `CorsixTH/Lua/announcer.lua:45`
- **Superclass:** none
- **Key methods:** `AnnouncementQueue()`, `push()`, `pop()`, `isEmpty()`, `checkForDuplicates()`
- **Key state fields:** `priorities` (4-level priority queues), `count`
- **Collections:** `Announcer.entries`

### 192. AnnouncementEntry
- **File:** `CorsixTH/Lua/announcer.lua:107`
- **Superclass:** none
- **Key methods:** `AnnouncementEntry()`
- **Key state fields:** `name`, `priority`, `created_date`, `decay_hours`, `played_callback`, `played_callback_delay`
- **Collections:** `AnnouncementQueue.priorities`

### 193. Announcer
- **File:** `CorsixTH/Lua/announcer.lua:127`
- **Superclass:** none
- **Key methods:** `Announcer()`, `playAnnouncement()`, `onTick()`
- **Key state fields:** `app`, `entries` (AnnouncementQueue), `playing`, `ticks_since_last_announcement`
- **Collections:** `GameUI.announcer`

---

## Statistics

| Category | Count |
|----------|-------|
| Core/Application classes | 10 |
| Entity hierarchy | 15 |
| Object subclasses | 14 |
| Room hierarchy | 24 |
| Hospital hierarchy | 3 |
| UI/Window system | 32 |
| Dialog classes | 75 |
| HumanoidAction hierarchy | 33 |
| Support/Management classes | 11 |
| Announcer system | 3 |
| **Grand Total** | **~195 classes** |
