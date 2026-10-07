# Vanilla Coverage

| Object | Validated | Source |
|--------|-----------|--------|
| ultrascanner (thob 22) | validated-minimal | 3441 strict/minimal masks, save 907K, deep study room/object/diagnosis |
| scanner (thob 14) | research | Scanner-object-deep: thob/cost/room match; footprint vs EXE pending |
| x_ray (thob 27) | research | Xray-object-deep: thob/cost/room match; 5136-vs-5138 + missing 3562 open |
| blood_machine (thob 42) | research | Blood-machine-object-deep: thob/cost/room match; only_passable open |
| cardio (thob 13) | research | Cardio-object-deep: thob/cost/room match; 5-tile mask vs EXE pending |
| dna_fixer (thob 23) | research | Dna-fixer-object-deep: thob/cost match; crashed 3376 TODO in source |
| electrolyser (thob 46) | research | Electrolyser-object-deep: thob/cost/room match; strict==minimal |
| hair_restorer (thob 25) | research | Hair-restorer-object-deep: thob/cost match; 1-wide bar, strict==minimal |
| inflator (thob 9) | research | Inflator-object-deep: thob/cost/room match; 5/9 passable ring flagged |
| jelly_moulder (thob 47) | research | Jelly-moulder-object-deep: thob/cost match; handyman-outside outlier |
| analyser (thob 41) | research | Analyser-object-deep: Object-not-Machine; thob/cost match; footprint vs EXE pending |
| slicer (thob 26) | research | Slicer-object-deep: strength 8-vs-10 divergence; L-solids; handyman far offset suspect |
| operating_table (thob 30 + slave 12) | research | Operating-table-object-deep: slave mechanics mapped; east {0,0} asymmetry; strength 8-vs-12 |
| cast_remover (thob 24) | research | Cast-remover-object-deep: table-form handyman; nil-risk hypothesis; strength 10-vs-11 |
| shower (thob 54) | research | Shower-object-deep: thob/cost match; 10-tile; decon flow mapped |
| autopsy (thob 55) | research | Autopsy-object-deep: Object-not-Machine; ticks=true; multi-use 12 variants; 9+8 footprint |
| computer (thob 40) | research | Computer-object-deep: Object-not-Machine; 2-tile; use_position="passable" |
| console (thob 15) | research | Console-object-deep: Object-not-Machine; paired with 3 machines; 4-tile |
| pharmacy_cabinet (thob 39) | research | Pharmacy-cabinet-object-deep: Nurse multi-use; layer3 flask colour; L-footprint |
| projector (thob 37) | research | Projector-object-deep: Object-not-Machine; 4-tile; training required |
| op_sink1 (thob 33) + op_sink2 (thob 34) | research | Op-sinks-object-deep: master-slave mapped; locked_to_wall; empty slave footprint |
| surgeon_screen (thob 35) | research | Surgeon-screen-object-deep: Object-not-Machine; north-only; extensive markers |
| x_ray_viewer (thob 29) | research | Xray-viewer-object-deep: wall-mounted; locked_to_wall; single tile need_*_side |
| radiation_shield (thob 28) | research | Radiation-shield-object-deep: master-slave (slave file missing); console anims reused |
| desk (thob 1) | research | Desk-object-deep: Object-not-Machine; 4-orients; Doctor/Nurse anims; need_*_side all 4 |
| cabinet (thob 2) | research | Cabinet-object-deep: Object-not-Machine; 2-tile; use_animate_from_use_position |
| chair (thob 6) | research | Chair-object-deep: Object-not-Machine; 12 patient variants; walk_in_to_use; shareable |
| bench (thob 4) | research | Bench-object-deep: Object-not-Machine; corridor_object; 12 variants; shareable |
| bed (thob 8) | research | Bed-object-deep: Object-not-Machine; 5-tile; early_list north/east; render_attach array |
| screen (thob 16) | research | Screen-object-deep: Object-not-Machine; north-only; Elvis transform; M/F undress |
| bin (thob 50) | research | Bin-object-deep: SideObject; only_side; corridor_object |
| plant (thob 45) | research | Plant-object-deep: SideObject; 5-state watering; base_config MISSING |
| radiator (thob 44) | research | Radiator-object-deep: SideObject; only_side; corridor_object |
| extinguisher (thob 43) | research | Extinguisher-object-deep: SideObject; only_side; corridor_object |
| door (thob 3) | research | Door-object-deep: queue logic; dynamic info; early_list north; map flags |
| litter (thob 62) | no-parity | Litter-object-deep: Entity not Object; thob 62 CorsixTH-assigned; no base_config |
| rathole (thob 64) | no-parity | Rathole-object-deep: empty footprint; thob 64 CorsixTH-assigned; no base_config |
| helicopter (thob 63) | no-parity | Helicopter-object-deep: off-map event; thob 63 CorsixTH-assigned; no base_config |
| gates_to_hell (thob 48) | research | Gates-to-hell-object-deep: death-spawned; 3-tile; cost 0 |
| radiation_shield_b | partial | Radiation-shield-slave-object-deep: implicit slave; no separate file/thob |
| bookcase (thob 56) | research | Bookcase-object-deep: thob/cost/room match; 1+1 footprint; training value role |
| comfortable_chair (thob 61) | research | Comfortable-chair-object-deep: psych-required; axis-swapped passables vs bookcase |
| couch (thob 18) | research | Couch-object-deep: psych-required; 2x2 transposed; old<173 migration fix |
| crash_trolley (thob 20) | research | Crash-trolley-object-deep: general_diag dual-use; 1+3 footprint; markers |
| drinks_machine (thob 7) | research | Drinks-machine-object-deep: corridor+soda economy; north usage missing |
| lecture_chair (thob 36) | research | Lecture-chair-object-deep: training-required; thob-57 brief label corrected |
| loo (thob 51) | research | Loo-object-deep: toilets-required; 12-type anims; sink chain |
| pool_table (thob 10) | research | Pool-table-object-deep: 9-tile center-use; Doctor/Handyman; relax values |
| reception_desk (thob 11) | research | Reception-desk-object-deep: 5-tile cross; dual use tiles; queue class |
| sink (thob 32) | research | Sink-object-deep: 2-tile wall-hugger; M/F anim splits |
| skeleton (thob 60) | research | Skeleton-object-deep: axis-swapped vs sink; training value |
| sofa (thob 19) | research | Sofa-object-deep: 3-tile corner-use; full staff anims; W-duplicates-N |
| tv (thob 21) | research | Tv-object-deep: passive decor; no use logic; proximity happiness only |
| video_game (thob 57) | research | Video-game-object-deep: sole thob-57 owner; Doctor/Nurse; clash resolved |
| entrance_left_door (thob 58) | research | Entrance-left-door-object-deep: slave 2-tile; tall-only; map-only |
| entrance_right_door (thob 59) | research | Entrance-right-door-object-deep: master 4-tile; occupancy+sound |
| swing_door_left (thob 52) | research | Swing-door-left-object-deep: slave empty walkable; master-delegated |
| swing_door_right (thob 53) | research | Swing-door-right-object-deep: master 6-tile; swing driver; west-anim gap |
| others (2) | no | op_sink1+op_sink2 covered by Op-sinks-object-deep; count gap: 62 header vs 60 named |

Progress 1 validated + 53 research + 4 no-parity + 1 partial / 62 (all 60 named rows covered; op_sink1+2 share one note). Method: [[VANILLA_METHOD]] (05-DATA-FORMATS/objects). Count gap: CATALOG header 62 vs 60 named rows; 5 TH-only thobs (5, 12, 17, 31, 38/49) have no Lua object. Doc fix queued: lecture_chair thob 57→36 in W4/catalog lines; video_game sole thob-57 owner confirmed. Next: EXE-disassembly + screenshot overlays (V phase) for researched rows.

## Wiki vs Vault Gap (2026-09-09)

| Metric | Wiki | Vault | Delta |
|--------|------|-------|-------|
| Files | 71 | 152 | Vault +81 |
| Lines | 9880 | 42356 | Vault 4.3x |
| Subsystems | 8 topical | 27 systematic | Vault +19 |

Wiki 71 pages (14 USER, 21 DEVELOPER, 4 PACKAGER, etc.) vs Vault 152 files (27 subsystems). Only ~30% topical overlap. Absorbed Debugger-Tutorials, How-To-Compile, Coding-Conventions, Implementing-Objects as 27,28,29.

## Next

- Absorb remaining ~10 missing wiki pages if needed.
