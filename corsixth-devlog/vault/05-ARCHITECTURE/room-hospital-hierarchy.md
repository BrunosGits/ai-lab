# Room & Hospital Hierarchy

## Overview
CorsixTH organizes the game world through a hierarchy of Rooms within Hospitals, each with specific functions, staffing requirements, and object configurations.

## Room Types (22 types)

### Medical Rooms
| Room | Required Staff | Max Patients | Key Objects |
|------|----------------|--------------|-------------|
| GP Office | Doctor | 1 | Desk, Cabinet, Chair |
| Pharmacy | Nurse | 2 | Cabinet, Chemistry Set |
| Cardiogram | Doctor | 1 | Cardiogram Machine |
| Operating Theatre | Doctor, Nurse | 1 | Operating Table, Anaesthetic |
| Ward | Nurse | 4-6 | Bed, Nightstand |
| Fracture Clinic | Doctor | 1 | X-Ray, Casting |
| Decontamination | Nurse | 1 | Shower, Decon Unit |
| DNA Fixer | Doctor | 1 | DNA Fixer |
| Electrolysis | Nurse | 1 | Electrolysis Machine |
| General Diagnosis | Doctor | 1 | Desk, Cabinet |
| GP Office | Doctor | 1 | Desk, Computer |
| Hair Restoration | Doctor | 1 | Hair Restorer |
| Inflation | Nurse | 1 | Inflator |
| Jelly Vat | Doctor | 1 | Jelly Moulder |
| Psychiatry | Doctor | 1 | Couch, Desk |
| Research | Scientist | 2 | Research Desk, Computer |
| Scanning | Doctor | 1 | Scanner |
| Slack Tongue | Doctor | 1 | Slack Tongue Machine |
| Training | Doctor/Nurse | 2 | Bookcase, Desk |
| Ultrascan | Doctor | 1 | Ultrascan Machine |
| X-Ray | Doctor | 1 | X-Ray Viewer |
| Toilets | - | - | Toilet, Sink |

## Room Class Hierarchy
```lua
class "Room"
  ├── room_info: RoomInfo (type, build_cost, objects_needed)
  ├── hospital: Hospital
  ├── tiles: array of tile positions
  ├── door: Door
  ├── objects: array of Objects
  ├── staff: array of Staff
  ├── patients: array of Patients
  ├── humanoids_enroute: set
  └── queue: Queue

class "GP_Office" (Room)
class "Ward" (Room)
class "OperatingTheatre" (Room)
-- ... 22 subclasses
```

## Hospital Class
```lua
class "Hospital"
  ├── player_index: int
  ├── money: number
  ├── reputation: number
  ├── staff: array of Staff
  ├── rooms: array of Room
  ├── available_staff: table of categories
  ├── research_department: ResearchDepartment
  ├── value: number
  ├── win_conditions: table
  ├── parcelTileCounts: table
  ├── next_emergency_date: Date
  └── earthquake: Earthquake
```

## Room Construction Flow
```
UIBuildRoom
  → Choose room type
  → Place walls (Wall phase)
  → Place doors (Door phase)
  → Place objects (Object phase)
    → UIPlaceObjects
    → Object footprints marked unbuildable
  → Confirm → Room:onBuildComplete()
    → Room:onBuildComplete()
      → Room:updateRoomObjects()
      → Room:updateStaffRequirements()
      → Hospital:addRoom()
```

## Staff Requirements
Each room type defines:
```lua
room_info = {
  required_staff = { Doctor = 1, Nurse = 1 },
  max_staff = { Doctor = 2, Nurse = 2 },
  objects_needed = { desk = 1, cabinet = 1 },
  build_cost = 40000,
  max_patients = 1
}
```

## Staff Assignment
```lua
function Hospital:assignStaff(room)
  local available = self:getAvailableStaff(room.required_staff)
  for role, count in pairs(room.required_staff) do
    for i = 1, count do
      local staff = table.remove(available[role])
      if staff then
        room:addStaff(staff)
        staff:setRoom(room)
      end
    end
  end
end
```

## Cross-References
- [[world-entity-flow]] - How entities interact with rooms
- [[entity-action-system]] - Staff/patient actions in rooms
- [[save-load-migrations]] - Room persistence
- Area: [[01-CODEBASE/03-room-lifecycle]], [[01-CODEBASE/07-financial-system]], [[01-CODEBASE/08-reputation-system]]
