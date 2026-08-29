# Ultrascan Room — Deep Study

## Definition
File CorsixTH/CorsixTH/Lua/rooms/ultrascan.lua:22-43 id ultrascan, level_config_id 14, class UltrascanRoom, minimum_size 4, wall_type yellow, floor_tile 19, categories diagnosis 5.

## Staff and objects
Required Doctor 1, maximum same, single occupancy via staff_member (no staff_member_set like Ward). Objects needed ultrascanner 1, additional extinguisher/radiator/plant/bin. Build preview 5068 same as object. Call sound reqd007.wav, handyman maint016.wav.

## Economics
Room build cost 2000 at level_config 14, object StartCost 6000 StartStrength 9 via base_config.lua:242. AvailableForLevel 0, unlocked via research.

## Diagnosis
Diagnosis category 5 among yellow rooms, weight informational, routing is random via seek_room.lua:66-83. 24 of 34 diseases list ultrascan. Pseudo disease diag_ultrascan expertise 40.

## Particularities
vip_must_visit false, so VIP never forced. No dressing, no loop skill scaling, patient owned MultiUseObjectAction. Footprint via ultrascanner object, not room.

## Links
room.lua:316-430 onHumanoidEnter, 54-76 commandEnteringPatient, 192-237 dealtWithPatient, 716-741 roomFinished. See also 16-object-placement for footprint.
