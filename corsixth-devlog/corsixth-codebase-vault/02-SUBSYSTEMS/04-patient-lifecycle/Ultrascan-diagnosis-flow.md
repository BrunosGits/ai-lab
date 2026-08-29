# Ultrascan Diagnosis Flow

## Rooms
level_config_id 14, categories diagnosis 5, minimum_size 4, yellow wall, floor 19, Doctor 1.

## Flow
GP picks random available_diagnosis_rooms, removes chosen via table.remove. SeekRoom finds nearest ultrascan via World:findRoomNear, calls dispatcher if no staff. Queue at door, onHumanoidEnter checks testStaffCriteria, then commandEnteringPatient.

## Patient and staff
Patient Walk to use_position, staff Walk to secondary then Idle. MultiUseObjectAction patient primary, staff secondary, persistable ultrascan_after_use, after_use meander or finish then dealtWithPatient.

## Diagnosis
dealtWithPatient via Room:dealtWithPatient, completeDiagnosticStep with staff skill and fatigue, bonus 0.4*skill, multiplier up to 5 if skill 0.9+. Then receiveMoneyForTreatment and SeekRoom gp. GP decides diagnosed vs next diagnosis. Cure chance multiplied by diagnosis_progress.

## Links
rooms/ultrascan.lua:54-76, patient.lua:197-226, seek_room.lua:57-137, room.lua:192-237, gp.lua:112-183.
