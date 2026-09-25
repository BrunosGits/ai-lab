# 38 — Cheats + Debug Tooling

> Scope: `cheats.lua` menu + fax-toggle cheats, fax keypad backdoor,
> debug console/script/menu hooks, `is_debug` patient flags.
> Map: [[38-cheats-debug/MAP]] · Gate: [[38-cheats-debug/CHECKLIST]]
> Template: [[38-cheats-debug/SCAFFOLD]]
> Legend: **[Fact]** = read in source · **[Inference]** = implied by code
> **[Hypothesis]** = needs runtime confirm

## 1. Overview

- **[Fact]** One `Cheats` instance per `Hospital` (`hospital.lua:179-180`);
  owns `cheat_list` (20 menu cheats), `active_cheats` (toggle state),
  plus a file-local `toggle_cheats` table (4 fax-only pairs).
  See [[38-cheats-debug/MAP#cheats-core]].
- **[Fact]** Two entry paths: `UICheats` dialog buttons
  → `performCheat(num)`; fax keypad → `24328` (dialog) or obfuscated
  `processCheatCode(x)` (toggles). See [[38-cheats-debug/MAP#entries]].
- **[Fact]** Every successful cheat sets `hospital.cheated = true` and
  plays a random `cheat00*.wav` at `Critical`; win bonus is forfeited.
- **[Fact]** Debug tooling is separate from cheats: `UILuaConsole`,
  `debug_script.lua` (`_` + `TheApp`), `config.debug`-gated menu/hotkeys,
  `is_debug` patients. See [[38-cheats-debug/MAP#debug]].
- **[Inference]** Design intent: menu cheats are discoverable + labelled;
  fax toggles are hidden/powerful (need adviser strings, not persisted);
  debug patients are stat-neutral test dummies.

## 2. Lifecycle / flow

### A. Menu-cheat path

1. **[Fact]** `UICheats:buttonClicked(num)` → pause gate
   (`isUserActionProhibited` unless a `UIFax` is open) → `performCheat`.
2. **[Fact]** `performCheat` calls `cheat_list[num].func`; `false` return =
   failure + feedback message; `lose_level` never reports success
   (so no cheated-banner update on that path).
3. **[Fact]** On success dialog calls `announceCheat` → Critical
   announcement + `cheated = true` + green→red banner refresh.

### B. Fax-keypad backdoor

1. **[Fact]** `UIFax:validate`: `24328` opens `UICheats` + adviser line;
   `112` plays Critical `rand*.wav`; else obfuscated `x` → `processCheatCode`.
2. **[Fact]** `x = |(code/1e5)^5.00001 − (code/1e5)^5|·1e5 − (code/1e5)^5`;
   range match (`lower < x < upper`) → `toggleCheat(name)`.
   Miss → `fax_no.wav`; hit/`24328`/`112` → `fax_yes.wav`.

### C. Toggle-cheat path

1. **[Fact]** `toggleCheat` enables (was inactive) or disables (was active),
   plays the paired `_A.cheats.*` adviser line via `announceCheat(speech)`,
   refreshes open cheats window.
2. **[Fact]** Four pairs: spawn-rate (27868.3–4), no-rest (185.5–6),
   queue-jump (200.5–6), super-doctor (301.5–6); plus menu-listed
   `invulnerable_machines` flip-flop. Consumers in world/staff/queue/machine
   read `isCheatActive`. See [[33-disasters/MAP]] for quake side.

### D. Debug tooling path

1. **[Fact]** Whole Debug menu gated on `app.config.debug`; cheat-window
   hotkey (F11) additionally gated on non-`MAP EDITOR` world.
2. **[Fact]** `global_showLuaConsole` (F12) / `global_runDebugScript`
   (Shift+D) handlers are added/removed by `addOrRemoveDebugModeKeyHandlers`.
3. **[Fact]** Console and debug script both expose clicked entity as `_`
   (`debug_cursor_entity`) and must clear `_ = nil` after use (save safety).
   Script file is `loadfile`d fresh each run; default body is comments only
   (`_:die()` example).

### E. `is_debug` patient path

1. **[Fact]** Created only via `UIMakeDebugPatient` (disease picker):
   `is_debug = true`, pushed to `hospital.debug_patients`, pre-diagnosed,
   `idea1` mood badge; no `SeekReception` on `setHospital`.
2. **[Fact]** Right-click drives debug patient (`UIPatient` window patient
   else round-robin `getDebugPatient`); `goHome`/`removePatient` detach
   from `debug_patients` so despawn works.
3. **[Fact]** Stat quarantine is at `Hospital` level, not `Patient:die`:
   `humanoidDeath` skips casebook fatalities; `updateCuredCounts` skips
   reputation (counts still bump); `updateNotCuredCounts` returns early.
   Guess-cure button/logic refuses debug patients.
4. **[Fact]** `epidemic.lua` contains zero `is_debug` references (grep) —
   "epidemic fatality skip" is the shared `humanoidDeath` guard above.

## 3. Key mechanics

- **Gating:** **[Fact]** pause gate, `createEarthquake` active/disabled
  guard, `epidemics_disabled` + `cancelEpidemics`, quake `disabled` flag,
  per-cheat failure messages (emergency/epidemic-icon cases).
- **Persistence:** **[Fact]** `active_cheats` migrated at `hospital afterLoad
  old<169`; toggle table notes adviser strings "cannot be persisted".
  **[Inference]** menu `cheated` flag persists with hospital; toggle states
  partially migrate (spawn-rate only).
- **Announce:** **[Fact]** `cheat_announcements = cheat001..003.wav`,
  `AnnouncementPriority.Critical` (bypasses staffed-desk gate).
  See [[35-announcer-messages/MAP]].
- **Cheat effects:** **[Fact]** money +10000; research drains policy queues;
  prices ±0.5 clamped [0.5, 2.0]; reputation → max; machines repaired in
  place; month/year forced; win/lose direct.

## 4. Related subsystems

- [[35-announcer-messages/MAP]] — fax keypad ownership, Critical play,
  adviser `say` contract; fax pauses game.
- [[33-disasters/MAP]] — `cheatEarthquake`/`cheatToggleEarthquake` vs
  `Earthquake:tick/onEndDay/disabled`; wear path shared with machines.
- [[32-machine-maintenance/MAP]] — `invulnerable_machines` gate in
  `machineUsed`; quake wear still routes through it.
- [[11-epidemic-system/MAP]] — `cheatEpidemic/Toggle/ShowInfected` producers;
  no `is_debug` inside epidemic itself.
- [[04-patient-lifecycle/MAP]] + [[37-death-handling/MAP]] — die/goHome/cure
  counters that `is_debug` suppresses.

## 5. Open questions

- **[Hypothesis]** `UICheats:buttonClicked:140` passes `self.ui` as `speech`;
  `announceCheat` then calls `adviser:say(UI-object)` — assert passes
  (tables) but queues `text=nil`. Likely bug; menu path should pass nil or a
  real `_A.cheats` line like the fax path does. Verify before touching.
- **[Hypothesis]** `cheatShowInfected` flips mood icons for *all* pooled
  future epidemics with no per-epidemic targeting — intended (comment says
  so) but irreversible per-epidemic. Confirm UX before extending.
