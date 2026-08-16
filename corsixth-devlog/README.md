# CorsixTH Contributions

A record of my journey contributing to CorsixTH, the open source reimplementation
of the 1997 Bullfrog game Theme Hospital: understanding a codebase with Lua game
logic on a C++ engine, finding issues, sending patches and learning how a large
open source project actually works.

## What's here

- `roadmap.md`: master plan of open tasks
- `README.md`: this file

The personal journal, per-project time tracker summary and the story of the
project live in the unified journal at the repo root (`journal.md`).

## Progress

- **#1793** (broken Lua docs links): fixed, PR #3494 merged by the maintainers
- **#1467** (entities table modified inside an `ipairs` loop): fixed and validated
  on full game data, PR #3501 open with CI green, awaiting maintainer review
- **#3372** (properly destroy entities on pickup again): active. Snapshot-and-destroy
  with tile reservation is designed; reuses the #1467 deferred-destruction machinery.
  Implementation in progress, nothing pushed yet
- **#2469** (right-mouse panning glitches) and **#1738** (handymen watering plants
  in benches): queued after #3372

## Environment

Building, unit tests and smoke runs happen on the VPS with the legal Theme
Hospital demo data. The VPS address, login name and key are private and never
appear in this repo.

## License

MIT
