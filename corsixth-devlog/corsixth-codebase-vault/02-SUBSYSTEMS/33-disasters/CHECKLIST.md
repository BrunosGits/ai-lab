# 33 — Disasters safety gate (run before changing quake/boiler code)

- [ ] Re-read `earthquake.lua:73-156` tick order: end → warning edges →
      shake/sound → damage gate. Confirm your change preserves the
      `warning_timer > 0` early-return before damage.
- [ ] If touching scheduling: `nextEarthquake` index base matches level
      data (`quake_control[current_map_earthquake]`, `Severity ~= 0`
      guard at `earthquake.lua:174-175`); test maps with zero quakes left.
- [ ] If touching damage: quake wear must still skip `total_usage`
      (`machine.lua:158-167`) and route through `machineUsed` so repair
      escalation (`170-194`) and explosion odds (`197-228`) stay shared.
- [ ] If touching shake/sound: keep `"pause"` path (`world.lua:781-782`
      → `game_ui.lua:1032-1034`) and the `announceRepair` spam guard
      (`player_hospital.lua:488`).
- [ ] If touching boiler: keep all four `boilerBreakdown` early-returns
      (`hospital.lua:650-657`) and the `_fixBoiler` −3/−2/−1 staffing
      ladder (`hospital.lua:677-683`); restore `saved_radiator_heat`.
- [ ] Finance: heating still accrues daily (`hospital.lua:940`) and bills
      monthly (`959-962`); quakes add no direct transaction — confirm any
      new cost uses `spendMoney` with a `transactions.*` reason.
- [ ] Cheats/saves: `disabled` gates both `tick` and `onEndDay`;
      `afterLoad` (`earthquake.lua:220-248`, `world.lua:2949`) loads old
      saves without residual `quake_points`.
- [ ] Cross-check [[32-machine-maintenance/MAP]] for explosion/repair changes and
      [[07-financial-system/MAP]] for transaction label changes.
