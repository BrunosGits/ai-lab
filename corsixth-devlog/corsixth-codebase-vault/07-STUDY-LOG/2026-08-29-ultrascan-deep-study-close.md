---
date: 2026-08-29
tags: [deep-study, ultrascan, 3441, 03-room-lifecycle, 16-object-placement]
areas: [03-room-lifecycle, 16-object-placement, 04-patient-lifecycle, 05-data-formats, 03-CPP-ENGINE]
prs: [3441]
---

# Ultrascan Deep Study — Close

## What was done
Deep study sprint vault/ultrascan-deep-1, 8 pushes, no mega push, covering all angles before fix.

- Room deep: definition, staff, economics, diagnosis weight, particularities, MAP fix, lifecycle sequence, SCAFFOLD tests
- Object deep: thob 22, animations, orientations, footprints, use positions, processTypeDefinition, smoke, render_attach
- Diagnosis flow: GP random routing, SeekRoom, MultiUse, after_use, dealtWithPatient, cure chance
- Original TH: footprint matrix strict vs minimal, TH_ORIGINAL_ULTRASCAN, TH_ORIGINAL_TILES, block LUT, save 907K
- Merged vault/vanilla-parity-I (10 pushes) into deep study, bringing vanilla coverage 1/62

Branch vault/ultrascan-deep-1, 14 commits total, pushed, ready for PR. No code yet, study only.

## Next
Await ARGAMX reply on 3441 strict vs minimal, then code sprint fix/3441-ultrascan-footprint.

## Open questions
- Grid overlay 7f209963 pixel measure
- TH.exe disassembly for thob 22
- LevelEdit block validation
