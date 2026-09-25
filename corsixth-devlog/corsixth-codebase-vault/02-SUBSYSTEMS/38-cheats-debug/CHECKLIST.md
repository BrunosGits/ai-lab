# 38 — Cheats + Debug safety gate (run before changing cheat/debug code)

- [ ] Re-read `cheats.lua:67-85`: `false` = fail, `lose_level` excluded
      from success, `announceCheat` always sets `cheated=true`. Keep the
      win-bonus forfeit at `world.lua:1349-1350`.
- [ ] If touching fax codes: keep `24328` dialog, `112` Critical,
      obfuscated range scan (`cheats.lua:349-358`), and
      `fax_yes/no.wav` feedback (`fax.lua:258-287`).
- [ ] If touching toggles: keep On/Off symmetry + `isCheatActive` reads in
      world/staff/queue/machine/profile; keep `disabled` guards for quake
      (`earthquake.lua:198`) and epidemics (`cheats.lua:138-148`).
- [ ] If touching the dialog: keep the pause gate
      (`cheats_dialog.lua:134`), fail-message fallback (`:143`), banner
      refresh (`:124-128`), and close-on-load (`:154-158`).
- [ ] Do NOT pass UI objects to `announceCheat` (see `:140` suspect);
      new callers must pass nil or a `_A.cheats.*` table per `say` contract
      (`adviser.lua:200-207`).
- [ ] If touching debug tools: keep `config.debug` gates (`menu.lua:843`,
      `ui.lua:1167-1173`, `game_ui.lua:182-184`) and the `_ = nil` cleanup
      in both console (`lua_console.lua:126`) and script (`ui.lua:208`).
- [ ] If touching `is_debug`: keep all four hospital quarantines
      (`hospital.lua:1585`, `:1868`, `:1891`, `patient.lua:549-551`) plus
      `SeekReception` skip (`patient.lua:237`) and guess-cure guards
      (`dialogs/patient.lua:302`, `:341`).
- [ ] Cross-check [[33-disasters/MAP]] (quake cheat/disabled),
      [[35-announcer-messages/MAP]] (fax + Critical), [[37-death-handling/MAP]]
      (death counters) for shared-path changes.
