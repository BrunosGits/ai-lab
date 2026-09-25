# CHECKLIST — Safety gate before changing VIP/Inspector logic

- [ ] Re-read `vip.lua:245-455` — confirm which group you touch; do not
  renumber rating direction (lower = better).
- [ ] Re-read `vip.lua:420-455` — if bands move, update cash table, rep table,
  `onDestroy:228-243`, AND `player_hospital.lua:761-790` fax branches together.
- [ ] Snapshot invariant (`world.lua:480-503`): `enter_*` fields must stay in
  sync with counters used in `setVIPRating:290-352`.
- [ ] Reception invariant (`reception_desk.lua:115-160`): VIP must not trigger
  verdict; Inspector must not enter room tour. Add regression for both.
- [ ] No-desk path (`inspector.lua:75-87`): change must still deliver verdict
  when hospital has no reception desk.
- [ ] Scheduling (`world.lua:1070-1077,1327-1340`): `refuse` reschedules;
  `onDestroy` reschedules; keep `MayorLaunch` fallback (`max(...,1)`).
- [ ] Epidemic bands (`epidemic.lua:439-508`): keep 0 / <rep-min / <evac-min /
  evac aligned with `83-88` defaults and GBV overrides.
- [ ] `free_build_mode` branches (`vip.lua:229-230`) covered in tests.
- [ ] `afterLoad:458-516` untouched unless migrating a field; old saves must load.
- [ ] Strings: feature names only — do not branch logic on `languages/*`.
- [ ] Read-only repo respected: all checks via `ssh vps "cat|grep ..."`; no writes.
