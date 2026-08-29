---
date: 2026-08-29
tags: [sprint, vanilla, 3441, 16-object-placement, 23-map-tile]
areas: [16-object-placement, 23-map-tile, 05-data-formats]
prs: [3441]
---

# Sprint Vanilla Parity I — Close

## What was done
9 pushes, 8 new files, 1 update, all 1-3 files per push, no mega push. Covers original TH Ultrascan footprint for 3441 as exemplar for bigger vanilla study.

Files: 07-STUDY-LOG research, 05-DATA-FORMATS TH_ORIGINAL_ULTRASCAN, 16-object-placement matrix and research, 23-map-tile original tiles, 06-PR-TRACKING PR-3441, 00-META tags, 08-QUERIES coverage, INDEX vanilla section, KANBAN + roadmap 3441.

Branch vault/vanilla-parity-I, 9 commits b0e694e..67ffb4e, pushed, ready for PR.

## What was learned
Vault had zero vanilla coverage before. Original mask must be measured from 3441 screenshots and save, not from code comments. Strict vs minimal both viable, save compat is the decision point.

## Next sprint
Await author reply on strict vs minimal, then code sprint fix/3441-ultrascan-footprint editing ultrascanner.lua north/east and verifying south/west mirror.

## Open questions
- Exact vanilla grid overlay of 7f209963
- TH.exe thob 22 disassembly address
- LevelEdit handling of original block IDs
