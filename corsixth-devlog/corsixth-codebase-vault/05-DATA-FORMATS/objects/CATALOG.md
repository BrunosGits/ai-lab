# Objects Catalog

> Source: `CorsixTH/Lua/objects/` — 43 top-level + 15 machines + 4 doors = 62 object definitions

## Top-Level Objects

| # | ID | Name | thob | Class | is_machine | is_door | Build Cost | Research Category | Used In Rooms |
|---|-----|------|------|-------|-----------|---------|-----------|-------------------|---------------|
| 1 | [[analyser]] | Atom Analyser | 41 | AtomAnalyser | Yes | No | — | cure | [[rooms/research]] |
| 2 | [[autopsy]] | Auto Autopsy | 55 | *(default)* | Yes | No | 4000 | cure | [[rooms/research]] |
| 3 | [[bed]] | Bed | 8 | *(default)* | No | No | 200 | diagnosis | [[rooms/ward]] |
| 4 | [[bench]] | Bench | 4 | Bench | No | No | 40 | — | Corridor |
| 5 | [[bin]] | Litter Bin | 50 | SideObject | No | No | 5 | — | All rooms |
| 6 | [[bookcase]] | Bookcase | 56 | *(default)* | No | No | 350 | — | [[rooms/psych]], [[rooms/training]], [[rooms/research]] |
| 7 | [[cabinet]] | Cabinet | 2 | *(default)* | No | No | 100 | — | [[rooms/gp]], [[rooms/research]] |
| 8 | [[chair]] | Chair | 6 | *(default)* | No | No | 20 | — | [[rooms/gp]] |
| 9 | [[comfortable_chair]] | Comfortable Chair | 61 | *(default)* | No | No | 100 | — | [[rooms/psych]] |
| 10 | [[computer]] | Research Computer | 40 | *(default)* | Yes | No | 5000 | cure | [[rooms/research]] |
| 11 | [[console]] | Scanner Console | 15 | *(default)* | Yes | No | 3000 | — | [[rooms/scanner]], [[rooms/hair_restoration]], [[rooms/electrolysis]], [[rooms/dna_fixer]], [[rooms/jelly_vat]], [[rooms/decontamination]] |
| 12 | [[couch]] | Couch | 18 | *(default)* | No | No | 100 | diagnosis | [[rooms/psych]] |
| 13 | [[crash_trolley]] | Crash Trolley | 20 | *(default)* | No | No | 250 | diagnosis | [[rooms/general_diag]] |
| 14 | [[desk]] | Desk | 1 | *(default)* | No | No | 100 | — | [[rooms/gp]], [[rooms/ward]], [[rooms/research]] |
| 15 | [[door]] | Door | 3 | Door | No | Yes | 0 | — | All rooms |
| 16 | [[drinks_machine]] | Drinks Machine | 7 | *(default)* | No | No | 500 | — | Corridor |
| 17 | [[extinguisher]] | Fire Extinguisher | 43 | SideObject | No | No | 25 | — | All rooms |
| 18 | [[gates_to_hell]] | Gates to Hell | 48 | *(default)* | No | No | 0 | — | Emergency |
| 19 | [[helicopter]] | Helicopter | 63 | Helicopter | Yes | No | — | — | Emergency |
| 20 | [[lecture_chair]] | Lecture Chair | 57 | *(default)* | No | No | 50 | — | [[rooms/training]] |
| 21 | [[litter]] | Litter | — | Litter | No | No | — | — | Corridor |
| 22 | [[loo]] | Toilet | 51 | *(default)* | No | No | 300 | — | [[rooms/toilets]] |
| 23 | [[op_sink1]] | Op Sink 1 | 33 | *(default)* | No | No | 50 | — | [[rooms/operating_theatre]] |
| 24 | [[op_sink2]] | Op Sink 2 | 34 | *(default)* | No | No | 50 | — | [[rooms/operating_theatre]] |
| 25 | [[pharmacy_cabinet]] | Pharmacy Cabinet | 39 | *(default)* | Yes | No | 1000 | — | [[rooms/pharmacy]] |
| 26 | [[plant]] | Plant | 45 | SideObject | No | No | 5 | — | All rooms |
| 27 | [[pool_table]] | Snooker Table | 10 | *(default)* | No | No | 150 | — | [[rooms/staff_room]] |
| 28 | [[projector]] | Projector | 37 | *(default)* | Yes | No | 100 | — | [[rooms/training]] |
| 29 | [[radiation_shield]] | Radiation Shield | 28 | *(default)* | No | No | 2000 | — | [[rooms/x_ray]] |
| 30 | [[radiation_shield_b]] | Radiation Shield B | — | *(default)* | No | No | — | — | [[rooms/x_ray]] |
| 31 | [[radiator]] | Radiator | 44 | SideObject | No | No | 20 | — | All rooms |
| 32 | [[rathole]] | Rat Hole | — | *(default)* | No | No | — | — | Corridor |
| 33 | [[reception_desk]] | Reception Desk | 11 | ReceptionDesk | No | No | 150 | — | Reception |
| 34 | [[screen]] | Screen | 16 | *(default)* | No | No | 30 | — | [[rooms/gp]], [[rooms/cardiogram]], [[rooms/general_diag]], [[rooms/scanner]], [[rooms/psych]] |
| 35 | [[sink]] | Bathroom Sink | 32 | *(default)* | No | No | 30 | — | [[rooms/toilets]] |
| 36 | [[skeleton]] | Skeleton | 60 | *(default)* | No | No | 450 | — | [[rooms/psych]], [[rooms/training]] |
| 37 | [[sofa]] | Sofa | 19 | *(default)* | No | No | 150 | — | [[rooms/staff_room]] |
| 38 | [[surgeon_screen]] | Surgeon Screen | 35 | *(default)* | No | No | 200 | — | [[rooms/operating_theatre]] |
| 39 | [[tv]] | TV Set | 21 | *(default)* | No | No | 50 | — | [[rooms/staff_room]] |
| 40 | [[video_game]] | Video Game | 57 | *(default)* | No | No | 200 | — | [[rooms/staff_room]] |
| 41 | [[x_ray_viewer]] | X-Ray Viewer | 29 | *(default)* | No | No | 500 | — | [[rooms/operating_theatre]] |

## Machines

| # | ID | Name | thob | Research Category | Used In Rooms |
|---|-----|------|------|-------------------|---------------|
| 1 | [[objects/blood_machine]] | Blood Machine | 42 | diagnosis | [[rooms/blood_machine]] |
| 2 | [[objects/cardio]] | Cardiogram Machine | 13 | diagnosis | [[rooms/cardiogram]] |
| 3 | [[objects/cast_remover]] | Cast Remover | 24 | cure | [[rooms/fracture_clinic]] |
| 4 | [[objects/dna_fixer]] | DNA Restorer | 23 | cure | [[rooms/dna_fixer]] |
| 5 | [[objects/electrolyser]] | Electrolysis Machine | 46 | cure | [[rooms/electrolysis]] |
| 6 | [[objects/hair_restorer]] | Hair Restorer | 25 | cure | [[rooms/hair_restoration]] |
| 7 | [[objects/inflator]] | Inflator Machine | 9 | cure | [[rooms/inflation]] |
| 8 | [[objects/jelly_moulder]] | Jelly Moulding Machine | 47 | cure | [[rooms/jelly_vat]] |
| 9 | [[objects/operating_table]] | Operating Table | 30 | cure | [[rooms/operating_theatre]] |
| 10 | [[objects/operating_table_b]] | Operating Table B | 12 | — | [[rooms/operating_theatre]] |
| 11 | [[objects/scanner]] | Scanner | 14 | diagnosis | [[rooms/scanner]] |
| 12 | [[objects/shower]] | Decontamination Shower | 54 | cure | [[rooms/decontamination]] |
| 13 | [[objects/slicer]] | Tongue Slicer | 26 | cure | [[rooms/slack_tongue]] |
| 14 | [[objects/ultrascanner]] | Ultrascan | 22 | diagnosis | [[rooms/ultrascan]] |
| 15 | [[objects/x_ray]] | X-Ray Machine | 27 | diagnosis | [[rooms/x_ray]] |

## Doors

| # | ID | Name | thob | Class | Used In |
|---|-----|------|------|-------|---------|
| 1 | [[objects/doors/entrance_left_door]] | Entrance Left Door | 58 | EntranceDoor | Hospital entrance |
| 2 | [[objects/doors/entrance_right_door]] | Entrance Right Door | 59 | EntranceDoor | Hospital entrance |
| 3 | [[objects/doors/swing_door_left]] | Swing Door Left | 52 | SwingDoor | Swing door rooms |
| 4 | [[objects/doors/swing_door_right]] | Swing Door Right | 53 | SwingDoor | Swing door rooms |

## Object Cost Table (from base_config)

| thob | Object | Build Cost | Start Available | Start Strength |
|------|--------|-----------|-----------------|----------------|
| 1 | Desk | 100 | Yes | 10 |
| 2 | Cabinet | 100 | Yes | 10 |
| 3 | Door | 0 | Yes | 10 |
| 4 | Bench | 40 | Yes | 10 |
| 5 | Table | 60 | Yes | 10 |
| 6 | Chair | 20 | Yes | 10 |
| 7 | Drinks Machine | 500 | Yes | 10 |
| 8 | Bed | 200 | Yes | 10 |
| 9 | Inflator | 2500 | No | 8 |
| 10 | Snooker Table | 150 | Yes | 10 |
| 11 | Reception Desk | 150 | Yes | 10 |
| 12 | Build Room Table | 5 | Yes | 10 |
| 13 | Cardiogram | 1000 | No | 13 |
| 14 | Scanner | 5000 | No | 12 |
| 15 | Scanner Console | 3000 | Yes | 10 |
| 16 | Screen | 30 | Yes | 10 |
| 17 | Jukebox | 5000 | No | 10 |
| 18 | Couch | 100 | Yes | 10 |
| 19 | Sofa | 150 | Yes | 10 |
| 20 | Crash Trolley | 250 | Yes | 10 |
| 21 | TV Set | 50 | Yes | 10 |
| 22 | Ultrascan | 6000 | No | 9 |
| 23 | DNA Restorer | 10000 | No | 7 |
| 24 | Cast Remover | 2000 | No | 11 |
| 25 | Hair Restorer | 1000 | No | 8 |
| 26 | Slicer | 1500 | No | 10 |
| 27 | X-Ray | 4000 | No | 12 |
| 28 | Radiation Shield | 2000 | Yes | 10 |
| 29 | X-Ray Viewer | 500 | Yes | 10 |
| 30 | Operating Table | 5000 | No | 12 |
| 31 | Lamp | 2000 | Yes | 10 |
| 32 | Bathroom Sink | 30 | Yes | 10 |
| 33 | Op Sink 1 | 50 | Yes | 10 |
| 34 | Op Sink 2 | 50 | Yes | 10 |
| 35 | Surgeon Screen | 200 | Yes | 10 |
| 36 | Lecture Chair | 50 | Yes | 10 |
| 37 | Projector | 100 | No | 10 |
| 38 | Bed Screen Open | 200 | Yes | 10 |
| 39 | Pharmacy Cabinet | 1000 | Yes | 10 |
| 40 | Research Computer | 5000 | No | 10 |
| 41 | Chemical Mixer | 10000 | No | 10 |
| 42 | Blood Machine | 3000 | No | 10 |
| 43 | Fire Extinguisher | 25 | Yes | 10 |
| 44 | Radiator | 20 | Yes | 10 |
| 45 | Plant | 5 | Yes | 10 |
| 46 | Electrolyser | 3500 | No | 8 |
| 47 | Jelly Moulder | 6500 | No | 7 |
| 48 | Gates to Hell | 0 | Yes | 10 |
| 49 | Bed Screen Closed | 200 | Yes | 10 |
| 50 | Bin | 5 | Yes | 10 |
| 51 | Toilet | 300 | Yes | 10 |
| 52 | Swing Door Part 1 | 0 | Yes | 10 |
| 53 | Swing Door Part 2 | 0 | Yes | 10 |
| 54 | Decontamination Shower | 6500 | No | 10 |
| 55 | Autopsy Machine | 4000 | No | 10 |
| 56 | Bookcase | 350 | Yes | 10 |
| 57 | Video Game | 200 | No | 10 |
| 58 | Entrance Left Door | 0 | Yes | 10 |
| 59 | Entrance Right Door | 0 | Yes | 10 |
| 60 | Skeleton | 450 | Yes | 10 |
| 61 | Comfy Chair | 100 | Yes | 10 |

## Cross-Reference Matrix

See [[MASTER_CROSSREF]] for the full object-room-disease matrix.

## Related Pages

- [[diseases/CATALOG]]
- [[rooms/CATALOG]]
- [[walls/CATALOG]]
- [[level-config/CATALOG]]
