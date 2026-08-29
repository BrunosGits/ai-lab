# Ultrascan Lifecycle Sequence

## Entry
1. patient WalkAction to use_position {-1,0} via findObjectNear ultrascanner
2. staff WalkAction to secondary {1,-1} then Idle west/north
3. patient MultiUseObjectAction(ultrascanner, staff) with after_use scan
4. after_use: if staff queue ==1 meander else finishAction, then dealtWithPatient
5. Room commandEnteringPatient delegates to base for visitor_count and wait toggle

## Staff and queue
- Inherits canHumanoidEnter, tryAdvanceQueue, getUsageScore single patient
- No roomFinished override, no onHumanoidLeave override
- Diagnosis via completeDiagnosticStep, then SeekRoom gp

## Gaps
- No dressing, no loop skill, patient owned MultiUse, persistable ultrascan_after_use
