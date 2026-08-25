# Data Formats Area MAP (area-13-data-formats)

Auto-generated index of all data file fields with file:line references.

---

## 1. DISEASE SCHEMA FIELDS (34 files)

### Common Fields (present in all diseases)
| Field | Type | Description | File:Line Examples |
|-------|------|-------------|-------------------|
| `id` | string | Unique disease identifier | bloaty_head.lua:22, kidney_beans.lua:22, ... |
| `expertise_id` | integer | Expertise level required | bloaty_head.lua:23, kidney_beans.lua:23, ... |
| `visuals_id` | integer | Visual variant ID (if applicable) | bloaty_head.lua:24, slack_tongue.lua:24, ... |
| `non_visuals_id` | integer | Non-visual variant ID (if applicable) | kidney_beans.lua:24, gut_rot.lua:24, ... |
| `name` | string | Localized name (from _S) | bloaty_head.lua:25, kidney_beans.lua:25, ... |
| `cause` | string | Localized cause description | bloaty_head.lua:26, kidney_beans.lua:26, ... |
| `symptoms` | string | Localized symptoms description | bloaty_head.lua:27, kidney_beans.lua:27, ... |
| `cure` | string | Localized cure description | bloaty_head.lua:28, kidney_beans.lua:28, ... |
| `cure_price` | integer | Price to cure the disease | bloaty_head.lua:29, kidney_beans.lua:29, ... |
| `emergency_sound` | string | Sound file for emergency | bloaty_head.lua:30, kidney_beans.lua:30, ... |
| `emergency_number` | integer | Emergency patient count | bloaty_head.lua:31, kidney_beans.lua:31, ... |
| `contagious` | boolean | Whether disease spreads | bloaty_head.lua:32, kidney_beans.lua:32, ... |
| `initPatient` | function | Patient initialization logic | bloaty_head.lua:33-40, kidney_beans.lua:33-46, ... |
| `diagnosis_rooms` | table | Array of diagnosis room IDs | bloaty_head.lua:44-49, kidney_beans.lua:50-59, ... |
| `treatment_rooms` | table | Array of treatment room IDs (ordered) | bloaty_head.lua:52-54, kidney_beans.lua:62-65, ... |
| `requires_machine` | boolean | Whether machine icon shows in casebook | bloaty_head.lua:58, slack_tongue.lua:60, ... |

### Optional Fields (present in some diseases)
| Field | Type | Description | Files |
|-------|------|-------------|-------|
| `more_loo_use` | boolean | Patient uses toilet more | the_squits.lua:33, gut_rot.lua:32 |
| `must_stand` | boolean | Force patient to stand in queues | alien_dna.lua:33 |
| `only_emergency` | boolean | Only appears via emergency | alien_dna.lua:34 |
| `yawn` | boolean | Patient yawns animation | sleeping_illness.lua:30 |
| `effect` | enum | Visual effect (AnimationEffect.Glowing/Jelly) | serious_radiation.lua:33, jellyitis.lua:33 |

### Disease File Index with Key Fields

| File | id | expertise_id | visuals_id | non_visuals_id | cure_price | emergency_num | contagious | diagnosis_rooms | treatment_rooms | requires_machine |
|------|-----|--------------|------------|----------------|------------|---------------|------------|-----------------|-----------------|------------------|
| bloaty_head.lua | bloaty_head | 2 | 0 | - | 850 | 18 | false | general_diag, x_ray, cardiogram, scanner | inflation | true |
| kidney_beans.lua | kidney_beans | 19 | - | 3 | 1050 | 5 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| tv_personalities.lua | tv_personalities | 22 | - | 6 | 800 | 14 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | psych | false |
| slack_tongue.lua | slack_tongue | 7 | 5 | - | 900 | 18 | false | x_ray, scanner | slack_tongue | true |
| gut_rot.lua | gut_rot | 33 | - | 17 | 350 | 14 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| discrete_itching.lua | discrete_itching | 11 | 9 | - | 700 | 15 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| sweaty_palms.lua | sweaty_palms | 31 | - | 15 | 600 | 14 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | psych | false |
| uncommon_cold.lua | uncommon_cold | 16 | - | 0 | 300 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| alien_dna.lua | alien_dna | 8 | 6 | - | 2000 | 16 | false | (none) | dna_fixer | true |
| invisibility.lua | invisibility | 5 | 3 | - | 1400 | 18 | false | x_ray, scanner | pharmacy | false |
| king_complex.lua | king_complex | 4 | 2 | - | 1600 | 18 | false | x_ray, scanner | psych | false |
| iron_lungs.lua | iron_lungs | 30 | - | 14 | 1700 | 5 | true | x_ray, cardiogram, blood_machine | ward, operating_theatre | false |
| third_degree_sideburns.lua | third_degree_sideburns | 26 | - | 10 | 550 | 13 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | psych | false |
| hairyitis.lua | hairyitis | 3 | 1 | - | 1150 | 12 | false | x_ray, scanner | electrolysis | true |
| fractured_bones.lua | fractured_bones | 9 | 7 | - | 450 | 16 | false | scanner | fracture_clinic | true |
| chronic_nosehair.lua | chronic_nosehair | 25 | - | 9 | 800 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| golf_stones.lua | golf_stones | 34 | - | 18 | 1600 | 6 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| heaped_piles.lua | heaped_piles | 32 | - | 16 | 400 | 14 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| fake_blood.lua | fake_blood | 27 | - | 11 | 800 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | psych | false |
| the_squits.lua | the_squits | 29 | - | 13 | 400 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| corrugated_ankles.lua | corrugated_ankles | 24 | - | 8 | 800 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| unexpected_swelling.lua | unexpected_swelling | 35 | - | 19 | 500 | 5 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| ruptured_nodules.lua | ruptured_nodules | 21 | - | 5 | 1600 | 6 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| serious_radiation.lua | serious_radiation | 6 | 4 | - | 1800 | 18 | false | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | decontamination | true |
| gastric_ejections.lua | gastric_ejections | 28 | - | 12 | 650 | 15 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| broken_wind.lua | broken_wind | 17 | - | 1 | 1300 | 14 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| sleeping_illness.lua | sleeping_illness | 13 | 11 | - | 750 | 18 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | pharmacy | false |
| spare_ribs.lua | spare_ribs | 18 | - | 2 | 1100 | 4 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| jellyitis.lua | jellyitis | 12 | 10 | - | 1000 | 12 | false | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | jelly_vat | true |
| infectious_laughter.lua | infectious_laughter | 23 | - | 7 | 1500 | 18 | true | cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | psych | false |
| transparency.lua | transparency | 15 | 13 | - | 800 | 12 | false | scanner | pharmacy | false |
| broken_heart.lua | broken_heart | 20 | - | 4 | 1900 | 6 | true | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |
| baldness.lua | baldness | 10 | 8 | - | 950 | 18 | false | x_ray, blood_machine, scanner | hair_restoration | true |
| pregnant.lua | pregnant | 14 | 12 | - | 200 | 8 | false | general_diag, cardiogram, scanner, ultrascan, blood_machine, x_ray, psych, ward | ward, operating_theatre | false |

---

## 2. ROOM SCHEMA FIELDS (23 files)

### Common Fields (present in all rooms)
| Field | Type | Description | File:Line Examples |
|-------|------|-------------|-------------------|
| `id` | string | Unique room identifier | staff_room.lua:22, gp.lua:22, ... |
| `vip_must_visit` | boolean | VIP must visit this room | staff_room.lua:23, gp.lua:23, ... |
| `level_config_id` | integer | Level configuration ID | staff_room.lua:24, gp.lua:24, ... |
| `class` | string | Room class name | staff_room.lua:25, gp.lua:25, ... |
| `name` | string | Short localized name | staff_room.lua:26, gp.lua:26, ... |
| `long_name` | string | Long localized name | staff_room.lua:27, gp.lua:27, ... |
| `tooltip` | string | Tooltip text | staff_room.lua:28, gp.lua:28, ... |
| `objects_additional` | table | Optional additional objects | staff_room.lua:29, gp.lua:29, ... |
| `objects_needed` | table | Required objects with counts | staff_room.lua:30, gp.lua:30, ... |
| `build_preview_animation` | integer | Animation for build preview | staff_room.lua:31, gp.lua:31, ... |
| `categories` | table | Room categories with priority | staff_room.lua:32-34, gp.lua:32-34, ... |
| `minimum_size` | integer | Minimum room size in tiles | staff_room.lua:35, gp.lua:35, ... |
| `wall_type` | string | Wall texture type | staff_room.lua:36, gp.lua:36, ... |
| `floor_tile` | integer | Floor tile variant | staff_room.lua:37, gp.lua:37, ... |

### Optional Fields (present in some rooms)
| Field | Type | Description | Files |
|-------|------|-------------|-------|
| `required_staff` | table | Required staff types and counts | gp.lua:38-40, scanner_room.lua:38-40, ... |
| `maximum_staff` | table | Maximum staff (often = required_staff) | gp.lua:41, scanner_room.lua:41, ... |
| `call_sound` | string | Sound when calling staff | gp.lua:42, scanner_room.lua:42, ... |
| `handyman_call_sound` | string | Sound for handyman call | decontamination.lua:43, scanner_room.lua:43, ... |
| `swing_doors` | boolean | Room uses swing doors | ward.lua:45, operating_theatre.lua:43, ... |
| `has_no_queue_dialog` | boolean | Hide queue dialog | staff_room.lua:38, training.lua:39, ... |

### Room File Index with Key Fields

| File | id | class | level_config_id | categories | min_size | wall_type | floor_tile | required_staff | objects_needed |
|------|-----|-------|-----------------|------------|----------|-----------|------------|----------------|----------------|
| staff_room.lua | staff_room | StaffRoom | 25 | facilities=1 | 4 | green | 17 | - | sofa=1 |
| gp.lua | gp | GPRoom | 7 | diagnosis=1 | 4 | white | 18 | Doctor=1 | desk=1, cabinet=1, chair=1 |
| decontamination.lua | decontamination | DecontaminationRoom | 30 | clinics=8 | 5 | blue | 19 | Doctor=1 | shower=1, console=1 |
| scanner_room.lua | scanner | ScannerRoom | 13 | diagnosis=4 | 5 | yellow | 19 | Doctor=1 | scanner=1, console=1, screen=1 |
| hair_restoration.lua | hair_restoration | HairRestorationRoom | 19 | clinics=4 | 4 | blue | 17 | Doctor=1 | hair_restorer=1, console=1 |
| inflation.lua | inflation | InflationRoom | 17 | clinics=1 | 4 | blue | 17 | Doctor=1 | inflator=1 |
| psych.lua | psych | PsychRoom | 8 | treatment=1, diagnosis=8 | 5 | white | 18 | Psychiatrist=1 | screen=1, couch=1, comfortable_chair=1 |
| research.lua | research | ResearchRoom | 28 | facilities=2 | 5 | green | 21 | Researcher=1 | desk=1, cabinet=1, autopsy=1 |
| cardiogram.lua | cardiogram | CardiogramRoom | 12 | diagnosis=3 | 4 | yellow | 19 | Doctor=1 | cardio=1, screen=1 |
| blood_machine_room.lua | blood_machine | BloodMachineRoom | 15 | diagnosis=6 | 4 | yellow | 19 | Doctor=1 | blood_machine=1 |
| operating_theatre.lua | operating_theatre | OperatingTheatreRoom | 10 | treatment=3 | 6 | white | 21 | Surgeon=2 | operating_table=1, surgeon_screen=1, op_sink1=1, x_ray_viewer=1 |
| x_ray_room.lua | x_ray | XRayRoom | 16 | diagnosis=7 | 6 | yellow | 19 | Doctor=1 | x_ray=1, radiation_shield=1 |
| slack_tongue.lua | slack_tongue | SlackTongueRoom | 20 | clinics=2 | 4 | blue | 17 | Doctor=1 | slicer=1 |
| general_diag.lua | general_diag | GeneralDiagRoom | 27 | diagnosis=2 | 5 | green | 21 | Doctor=1 | screen=1, crash_trolley=1 |
| jelly_vat.lua | jelly_vat | JellyVatRoom | 24 | clinics=7 | 4 | blue | 17 | Doctor=1 | jelly_moulder=1 |
| electrolysis.lua | electrolysis | ElectrolysisRoom | 23 | clinics=5 | 5 | blue | 17 | Doctor=1 | electrolyser=1, console=1 |
| training.lua | training | TrainingRoom | 22 | facilities=4 | 4 | green | 17 | - | lecture_chair=1, projector=1 |
| ultrascan.lua | ultrascan | UltrascanRoom | 14 | diagnosis=5 | 4 | yellow | 19 | Doctor=1 | ultrascanner=1 |
| pharmacy.lua | pharmacy | PharmacyRoom | 11 | treatment=4 | 4 | white | 19 | Nurse=1 | pharmacy_cabinet=1 |
| toilets.lua | toilets | ToiletRoom | 29 | facilities=3 | 4 | green | 21 | - | loo=1, sink=1 |
| dna_fixer.lua | dna_fixer | DNAFixerRoom | 23 | clinics=6 | 5 | blue | 17 | Researcher=1 | dna_fixer=1, console=1 |
| fracture_clinic.lua | fracture_clinic | FractureRoom | 21 | clinics=3 | 4 | blue | 17 | Nurse=1 | cast_remover=1 |
| ward.lua | ward | WardRoom | 9 | treatment=2, diagnosis=9 | 6 | white | 21 | Nurse=1 | desk=1, bed=1 |

---

## 3. OBJECT SCHEMA FIELDS (43 files)

### Common Fields (present in all objects)
| Field | Type | Description | File:Line Examples |
|-------|------|-------------|-------------------|
| `id` | string | Unique object identifier | sink.lua:22, chair.lua:22, ... |
| `thob` | integer | THOB (texture) index | sink.lua:23, chair.lua:23, ... |
| `name` | string | Localized name | sink.lua:24, chair.lua:24, ... |
| `tooltip` | string | Tooltip text | sink.lua:25, chair.lua:25, ... |
| `ticks` | boolean | Whether object ticks each frame | sink.lua:26, chair.lua:26, ... |
| `idle_animations` | table | Idle animations per direction | sink.lua:32-34, chair.lua:28-31, ... |
| `orientations` | table | Orientation data (footprint, use_position) | sink.lua:57-68, chair.lua:137-154, ... |

### Frequent Optional Fields
| Field | Type | Description | Files |
|-------|------|-------------|-------|
| `class` | string | Custom class name | rathole.lua:25, reception_desk.lua:24, ... |
| `build_preview_animation` | integer | Build preview animation | sink.lua:27, chair.lua:27, ... |
| `usage_animations` | table | Usage animations per direction/patient | chair.lua:44-136, sink.lua:35-50, ... |
| `multi_usage_animations` | table | Multi-user animations (machine + patient) | pharmacy_cabinet.lua:54-70, crash_trolley.lua:37-82, ... |
| `show_in_town_map` | boolean | Show in town map view | chair.lua:28, scanner.lua:32, ... |
| `research_category` | string | Research category (diagnosis/cure) | scanner.lua:24, bed.lua:24, ... |
| `research_fallback` | integer | Fallback research disease ID | scanner.lua:25, bed.lua:25, ... |
| `default_strength` | integer | Machine default strength | scanner.lua:30, x_ray.lua:30, ... |
| `crashed_animation` | integer | Animation when crashed | scanner.lua:31, x_ray.lua:31, ... |
| `smoke_animation` | integer | Smoke animation | scanner.lua:33, x_ray.lua:33, ... |
| `corridor_object` | integer | Corridor object priority | fire_extinguisher.lua:27, bin.lua:27, ... |
| `walk_in_to_use` | boolean | Walk into object to use | chair.lua:32, op_sink1.lua:29, ... |
| `locked_to_wall` | table | Wall-locked orientations | op_sink1.lua:31-35, x_ray_viewer.lua:29-33, ... |
| `slave_id` | string | Slave object ID (for paired objects) | op_sink1.lua:23, operating_table.lua:23, ... |
| `dynamic_info` | boolean | Show dynamic info | bench.lua:30, loo.lua:28, ... |
| `multiple_users_allowed` | boolean | Allow multiple simultaneous users | drinks_machine.lua:29 |

### Object File Index with Key Fields

| File | id | thob | class | ticks | research_category | usage_animations | multi_usage_animations | orientations |
|------|-----|------|-------|-------|-------------------|------------------|------------------------|--------------|
| sink.lua | sink | 32 | - | false | - | yes (north/south) | no | north, east |
| comfortable_chair.lua | comfortable_chair | 61 | - | false | - | yes (Doctor) | no | north, east |
| rathole.lua | rathole | 64 | Rathole | false | - | no | no | all 4 (empty footprint) |
| analyser.lua | analyser | 41 | AtomAnalyser | true | cure | yes (Doctor) | no | north, east |
| skeleton.lua | skeleton | 60 | - | false | - | yes (Doctor) | no | north, east |
| computer.lua | computer | 40 | - | false | cure | yes (Doctor) | no | north, east |
| fire_extinguisher.lua | extinguisher | 43 | SideObject | false | - | no | no | all 4 (side only) |
| reception_desk.lua | reception_desk | 11 | ReceptionDesk | true | - | no | no | all 4 |
| bin.lua | bin | 50 | SideObject | false | - | no | no | north, east |
| op_sink2.lua | op_sink2 | 34 | OperatingSink | false | - | no | no | north, east (empty) |
| litter.lua | litter | 62 | Litter | false | - | no | no | - |
| door.lua | door | 3 | Door | false | - | no | no | north, west |
| op_sink1.lua | op_sink1 | 33 | OperatingSink | false | - | yes (Surgeon) | no | north, east |
| chair.lua | chair | 6 | Chair | false | - | yes (all patients) | no | all 4 |
| radiator.lua | radiator | 44 | SideObject | false | - | no | no | all 4 (side only) |
| cabinet.lua | cabinet | 2 | - | false | - | yes (Doctor) | no | all 4 |
| helicopter.lua | helicopter | 63 | Helicopter | true | - | no | no | north (empty) |
| bench.lua | bench | 4 | Bench | false | - | yes (all patients) | no | all 4 |
| projector.lua | projector | 37 | - | false | - | yes (Doctor) | no | north, east |
| tv.lua | tv | 21 | - | false | - | no | no | all 4 |
| desk.lua | desk | 1 | - | false | - | yes (Doctor, Nurse) | no | all 4 |
| plant.lua | plant | 45 | Plant | false | - | yes (Handyman) | no | all 4 |
| lecture_chair.lua | lecture_chair | 36 | - | false | - | yes (Doctor) | no | north, east |
| radiation_shield_b.lua | radiation_shield_b | 28 | RadiationShield | false | - | no | no | north, east |
| gates_to_hell.lua | gates_to_hell | 48 | - | true | - | yes (Standard Male) | no | south, east |
| loo.lua | loo | 51 | - | false | - | yes (all patients) | no | north, east |
| radiation_shield.lua | radiation_shield | 28 | RadiationShield | true | - | yes (Doctor) | no | north, east |
| sofa.lua | sofa | 19 | - | false | - | yes (Doctor, Nurse, Handyman) | no | all 4 |
| bookcase.lua | bookcase | 56 | - | false | - | yes (Doctor) | no | north, east |
| surgeon_screen.lua | surgeon_screen | 35 | SurgeonScreen | false | - | yes (Surgeon, patients) | no | north |
| bed.lua | bed | 8 | - | false | diagnosis | yes (Standard Male/Female) | no | all 4 |
| pharmacy_cabinet.lua | pharmacy_cabinet | 39 | - | false | cure | no | yes (Nurse + patients) | north, east |
| drinks_machine.lua | drinks_machine | 7 | - | false | - | yes (all patients) | no | all 4 |
| couch.lua | couch | 18 | - | false | diagnosis | yes (Elvis, Standard) | no | north, east |
| x_ray_viewer.lua | x_ray_viewer | 29 | - | false | - | no | no | north, east |
| screen.lua | screen | 16 | - | false | - | yes (Elvis, Standard) | no | north |
| video_game.lua | video_game | 57 | - | false | - | yes (Doctor, Nurse) | no | north, east |
| autopsy.lua | autopsy | 55 | - | true | cure | yes (Handyman) | yes (Doctor + patients) | north, east |
| console.lua | console | 15 | - | true | - | yes (Doctor) | no | north, east |
| pool_table.lua | pool_table | 10 | - | false | - | yes (Doctor, Handyman) | no | north, east, south |
| crash_trolley.lua | crash_trolley | 20 | - | false | diagnosis | no | yes (Stripped + Doctor) | north, east |

### Machine Objects (in machines/ subdir)
| File | id | thob | research_category | research_fallback | default_strength | crashed_animation | smoke_animation | multi_usage_animations |
|------|-----|------|-------------------|-------------------|------------------|-------------------|-----------------|------------------------|
| machines/scanner.lua | scanner | 14 | diagnosis | 36 | 12 | 3316 | 3428 | no |
| machines/ultrascanner.lua | ultrascanner | 22 | diagnosis | 40 | 12 | 3396 | 3436 | yes (Standard + Doctor) |
| machines/slicer.lua | slicer | 26 | cure | 7 | 8 | 3400 | 3464 | yes (Slack + Doctor) |
| machines/operating_table.lua | operating_table | 30 | cure | 19 | 8 | 3392 | 3472 | yes (Surgeon + Gowned) |
| machines/x_ray.lua | x_ray | 27 | diagnosis | 39 | 12 | 3384 | 3440 | no (usage_animations) |
| machines/shower.lua | shower | 54 | cure | 6 | 10 | 3380 | 3448 | no (usage_animations) |
| machines/cardio.lua | cardio | 13 | diagnosis | 38 | 12 | 3308 | 3432 | yes (Stripped + Doctor) |
| machines/cast_remover.lua | cast_remover | 24 | cure | 9 | 10 | 3388 | 3468 | yes (Alternate/Standard + Nurse) |
| machines/hair_restorer.lua | hair_restorer | 25 | cure | 10 | 8 | 5116 | 3460 | no (usage_animations) |
| machines/inflator.lua | inflator | 9 | cure | 2 | 10 | 3362 | 3424 | yes (Standard + Doctor) |
| machines/blood_machine.lua | blood_machine | 42 | diagnosis | 37 | 12 | 3372 | 3460 | yes (Doctor + patients) |
| machines/operating_table_b.lua | operating_table_b | 12 | OperatingTable | - | - | 0 | - | no (usage_animations) |
| machines/dna_fixer.lua | dna_fixer | 23 | cure | 8 | 7 | 3376 | 3444 | no (usage_animations) |
| machines/jelly_moulder.lua | jelly_moulder | 47 | cure | 12 | 7 | 3312 | 3440 | yes (Doctor + Standard) |
| machines/electrolyser.lua | electrolyser | 46 | cure | 3 | 10 | 3300 | 3456 | no (usage_animations) |

### Door Objects (in doors/ subdir)
| File | id | thob | class | idle_animations |
|------|-----|------|-------|-----------------|
| doors/entrance_right_door.lua | entrance_right_door | 59 | EntranceDoor | north, west |
| doors/swing_door_right.lua | swing_door_right | 53 | SwingDoor | north |
| doors/swing_door_left.lua | swing_door_left | 52 | SwingDoor | north, west |
| doors/entrance_left_door.lua | entrance_left_door | 58 | EntranceDoor | north, west |

---

## 4. CROSS-REFERENCES

### Disease ↔ Room References

#### Diagnosis Rooms (referenced by diseases)
| Room ID | Room File | Diseases Using As Diagnosis |
|---------|-----------|----------------------------|
| general_diag | rooms/general_diag.lua | bloaty_head, kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter (partial) |
| cardiogram | rooms/cardiogram.lua | bloaty_head, kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, iron_lungs, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter |
| scanner | rooms/scanner_room.lua | bloaty_head, kidney_beans, tv_personalities, slack_tongue, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, iron_lungs, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter, fractured_bones, transparency, baldness |
| ultrascan | rooms/ultrascan.lua | kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter |
| blood_machine | rooms/blood_machine_room.lua | kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, iron_lungs, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter, baldness |
| x_ray | rooms/x_ray_room.lua | bloaty_head, kidney_beans, tv_personalities, slack_tongue, invisibility, king_complex, hairyitis, iron_lungs, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter, baldness |
| psych | rooms/psych.lua | kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter, king_complex |
| ward | rooms/ward.lua | kidney_beans, tv_personalities, gut_rot, discrete_itching, sweaty_palms, uncommon_cold, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling, ruptured_nodules, serious_radiation, gastric_ejections, broken_wind, sleeping_illness, spare_ribs, jellyitis, broken_heart, pregnant, chronic_nosehair, golf_stones, third_degree_sideburns, infectious_laughter |

#### Treatment Rooms (referenced by diseases)
| Room ID | Room File | Diseases Using As Treatment |
|---------|-----------|----------------------------|
| inflation | rooms/inflation.lua | bloaty_head |
| ward | rooms/ward.lua | kidney_beans, iron_lungs, golf_stones, unexpected_swelling, ruptured_nodules, spare_ribs, broken_heart, pregnant |
| operating_theatre | rooms/operating_theatre.lua | kidney_beans, iron_lungs, golf_stones, unexpected_swelling, ruptured_nodules, spare_ribs, broken_heart, pregnant |
| slack_tongue | rooms/slack_tongue.lua | slack_tongue |
| pharmacy | rooms/pharmacy.lua | gut_rot, discrete_itching, sweaty_palms, uncommon_cold, corrugated_ankles, heaped_piles, fake_blood, the_squits, unexpected_swelling (no), gastric_ejections, broken_wind, sleeping_illness, spare_ribs (no), transparency, broken_heart (no) |
| psych | rooms/psych.lua | tv_personalities, sweaty_palms, third_degree_sideburns, fake_blood, king_complex, infectious_laughter |
| electrolysis | rooms/electrolysis.lua | hairyitis |
| fracture_clinic | rooms/fracture_clinic.lua | fractured_bones |
| decontamination | rooms/decontamination.lua | serious_radiation |
| dna_fixer | rooms/dna_fixer.lua | alien_dna |
| jelly_vat | rooms/jelly_vat.lua | jellyitis |
| hair_restoration | rooms/hair_restoration.lua | baldness |

### Room ↔ Object References (objects_needed)

| Room | Required Objects |
|------|------------------|
| gp | desk, cabinet, chair |
| scanner | scanner, console, screen |
| decontamination | shower, console |
| hair_restoration | hair_restorer, console |
| inflation | inflator |
| psych | screen, couch, comfortable_chair |
| research | desk, cabinet, autopsy |
| cardiogram | cardio, screen |
| blood_machine | blood_machine |
| operating_theatre | operating_table, surgeon_screen, op_sink1, x_ray_viewer |
| x_ray | x_ray, radiation_shield |
| slack_tongue | slicer |
| general_diag | screen, crash_trolley |
| jelly_vat | jelly_moulder |
| electrolysis | electrolyser, console |
| training | lecture_chair, projector |
| ultrascan | ultrascanner |
| pharmacy | pharmacy_cabinet |
| toilets | loo, sink |
| dna_fixer | dna_fixer, console |
| fracture_clinic | cast_remover |
| ward | desk, bed |
| staff_room | sofa |

### Object ↔ Room Cross-Reference (machines used in rooms)

| Machine Object | Used In Room(s) | Room File |
|----------------|-----------------|-----------|
| scanner | scanner | rooms/scanner_room.lua |
| console | scanner, decontamination, hair_restoration, electrolysis, x_ray, dna_fixer | multiple |
| screen | scanner, cardiogram, general_diag, psych, operating_theatre | multiple |
| shower | decontamination | rooms/decontamination.lua |
| hair_restorer | hair_restoration | rooms/hair_restoration.lua |
| inflator | inflation | rooms/inflation.lua |
| couch | psych | rooms/psych.lua |
| comfortable_chair | psych | rooms/psych.lua |
| autopsy | research | rooms/research.lua |
| cardio | cardiogram | rooms/cardiogram.lua |
| blood_machine | blood_machine | rooms/blood_machine_room.lua |
| operating_table | operating_theatre | rooms/operating_theatre.lua |
| surgeon_screen | operating_theatre | rooms/operating_theatre.lua |
| op_sink1 | operating_theatre | rooms/operating_theatre.lua |
| x_ray_viewer | operating_theatre | rooms/operating_theatre.lua |
| x_ray | x_ray | rooms/x_ray_room.lua |
| radiation_shield | x_ray | rooms/x_ray_room.lua |
| slicer | slack_tongue | rooms/slack_tongue.lua |
| crash_trolley | general_diag | rooms/general_diag.lua |
| jelly_moulder | jelly_vat | rooms/jelly_vat.lua |
| electrolyser | electrolysis | rooms/electrolysis.lua |
| lecture_chair | training | rooms/training.lua |
| projector | training | rooms/training.lua |
| ultrascanner | ultrascan | rooms/ultrascan.lua |
| pharmacy_cabinet | pharmacy | rooms/pharmacy.lua |
| loo | toilets | rooms/toilets.lua |
| sink | toilets | rooms/toilets.lua |
| dna_fixer | dna_fixer | rooms/dna_fixer.lua |
| cast_remover | fracture_clinic | rooms/fracture_clinic.lua |
| bed | ward | rooms/ward.lua |
| desk | gp, research, ward | multiple |
| cabinet | gp, research | gp.lua, research.lua |
| chair | gp | rooms/gp.lua |
| radiator | most rooms | common additional |
| plant | most rooms | common additional |
| extinguisher | most rooms | common additional |
| bin | most rooms | common additional |
| sofa | staff_room | rooms/staff_room.lua |
| bench | corridors, staff_room | bench.lua, staff_room.lua |
| tv | staff_room | rooms/staff_room.lua |
| video_game | staff_room | rooms/staff_room.lua |
| pool_table | staff_room | rooms/staff_room.lua |
| bookcase | psych, training | rooms/psych.lua, training.lua |
| skeleton | training | rooms/training.lua |

### Disease → Machine Requirements (requires_machine = true)

| Disease | Machine Required | Treatment Room | Machine Object |
|---------|------------------|----------------|----------------|
| bloaty_head | inflation machine | inflation | machines/inflator.lua |
| slack_tongue | slicer | slack_tongue | machines/slicer.lua |
| fractured_bones | cast remover | fracture_clinic | machines/cast_remover.lua |
| hairyitis | electrolysis | electrolysis | machines/electrolyser.lua |
| alien_dna | dna fixer | dna_fixer | machines/dna_fixer.lua |
| serious_radiation | decontamination shower | decontamination | machines/shower.lua |
| jellyitis | jelly moulder | jelly_vat | machines/jelly_moulder.lua |
| baldness | hair restorer | hair_restoration | machines/hair_restorer.lua |

### Staff Category ↔ Room Requirements

| Staff Category | Required In Rooms |
|----------------|-------------------|
| Doctor | gp, scanner, decontamination, hair_restoration, inflation, cardiogram, blood_machine, x_ray, slack_tongue, general_diag, jelly_vat, electrolysis, ultrascan, operating_theatre (as Surgeon) |
| Surgeon | operating_theatre (2 required) |
| Nurse | ward, pharmacy, fracture_clinic |
| Psychiatrist | psych |
| Researcher | research, dna_fixer |
| Receptionist | reception_desk (object) |
| Handyman | all rooms (maintenance) |

### Object Class Hierarchy

```
Object (base)
├── SideObject (fire_extinguisher, bin, radiator)
├── Door
│   ├── EntranceDoor (entrance_right_door, entrance_left_door)
│   └── SwingDoor (swing_door_right, swing_door_left)
├── Machine (operating_table, operating_table_b, radiation_shield)
├── Chair
├── Bench
├── Plant
├── Rathole
├── Litter (extends Entity, not Object)
├── ReceptionDesk
├── SurgeonScreen
└── AtomAnalyser (analyser)
```

---

## 5. FILE LOCATIONS SUMMARY

### Diseases (34 files)
```
/tmp/CorsixTH/CorsixTH/Lua/diseases/
├── alien_dna.lua
├── baldness.lua
├── bloaty_head.lua
├── broken_heart.lua
├── broken_wind.lua
├── chronic_nosehair.lua
├── corrugated_ankles.lua
├── discrete_itching.lua
├── fake_blood.lua
├── fractured_bones.lua
├── gastric_ejections.lua
├── golf_stones.lua
├── gut_rot.lua
├── hairyitis.lua
├── heaped_piles.lua
├── infectious_laughter.lua
├── invisibility.lua
├── iron_lungs.lua
├── jellyitis.lua
├── kidney_beans.lua
├── king_complex.lua
├── pregnant.lua
├── ruptured_nodules.lua
├── serious_radiation.lua
├── slack_tongue.lua
├── sleeping_illness.lua
├── spare_ribs.lua
├── sweaty_palms.lua
├── the_squits.lua
├── third_degree_sideburns.lua
├── transparency.lua
├── tv_personalities.lua
├── unexpected_swelling.lua
```

### Rooms (23 files)
```
/tmp/CorsixTH/CorsixTH/Lua/rooms/
├── blood_machine_room.lua
├── cardiogram.lua
├── decontamination.lua
├── dna_fixer.lua
├── electrolysis.lua
├── fracture_clinic.lua
├── general_diag.lua
├── gp.lua
├── hair_restoration.lua
├── inflation.lua
├── jelly_vat.lua
├── operating_theatre.lua
├── pharmacy.lua
├── psych.lua
├── research.lua
├── scanner_room.lua
├── slack_tongue.lua
├── staff_room.lua
├── training.lua
├── toilets.lua
├── ultrascan.lua
├── ward.lua
├── x_ray_room.lua
```

### Objects (43 files)
```
/tmp/CorsixTH/CorsixTH/Lua/objects/
├── analyser.lua
├── autopsy.lua
├── bed.lua
├── bench.lua
├── bin.lua
├── bookcase.lua
├── cabinet.lua
├── chair.lua
├── comfortable_chair.lua
├── console.lua
├── couch.lua
├── crash_trolley.lua
├── desk.lua
├── door.lua
├── drinks_machine.lua
├── fire_extinguisher.lua
├── gates_to_hell.lua
├── helicopter.lua
├── litter.lua
├── loo.lua
├── op_sink1.lua
├── op_sink2.lua
├── pharmacy_cabinet.lua
├── plant.lua
├── pool_table.lua
├── projector.lua
├── radiation_shield.lua
├── radiation_shield_b.lua
├── rathole.lua
├── reception_desk.lua
├── screen.lua
├── skeleton.lua
├── sink.lua
├── sofa.lua
├── surgeon_screen.lua
├── tv.lua
├── video_game.lua
├── x_ray_viewer.lua
├── doors/
│   ├── entrance_left_door.lua
│   ├── entrance_right_door.lua
│   ├── swing_door_left.lua
│   └── swing_door_right.lua
└── machines/
    ├── blood_machine.lua
    ├── cardio.lua
    ├── cast_remover.lua
    ├── dna_fixer.lua
    ├── electrolyser.lua
    ├── hair_restorer.lua
    ├── inflator.lua
    ├── jelly_moulder.lua
    ├── operating_table.lua
    ├── operating_table_b.lua
    ├── scanner.lua
    ├── shower.lua
    ├── slicer.lua
    ├── ultrascanner.lua
    └── x_ray.lua
```

---

*Generated: 2026-08-25*
*Total: 34 diseases + 23 rooms + 43 objects = 100 data files indexed*


## Related Pages

- [[13-data-formats/SUMMARY]]
- [[13-data-formats/CHECKLIST]]
- [[13-data-formats/SCAFFOLD]]
