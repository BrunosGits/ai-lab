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
| others (38) | no | pending per VANILLA_METHOD.md waves W4-W6 |

Progress 1 validated + 23 research / 62. Method: [[VANILLA_METHOD]] (05-DATA-FORMATS/objects). Count gap: CATALOG header 62 vs 60 named rows; 5 TH-only thobs (5, 12, 17, 31, 38/49) have no Lua object. Next: analyser (W1 remainder), then W2 slave/table cases (operating_table, cast_remover).

## Wiki vs Vault Gap (2026-09-09)

| Metric | Wiki | Vault | Delta |
|--------|------|-------|-------|
| Files | 71 | 152 | Vault +81 |
| Lines | 9880 | 42356 | Vault 4.3x |
| Subsystems | 8 topical | 27 systematic | Vault +19 |

Wiki 71 pages (14 USER, 21 DEVELOPER, 4 PACKAGER, etc.) vs Vault 152 files (27 subsystems). Only ~30% topical overlap. Absorbed Debugger-Tutorials, How-To-Compile, Coding-Conventions, Implementing-Objects as 27,28,29.

## Next

- Absorb remaining ~10 missing wiki pages if needed.
