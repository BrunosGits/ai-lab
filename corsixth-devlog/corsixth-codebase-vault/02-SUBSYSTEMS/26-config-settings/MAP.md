# Area 26: Config/Settings — File:Line Index

## Lua Source

### config_finder.lua (1010 lines)

| Line(s) | Symbol / Block | Description |
|---------|---------------|-------------|
| 21-46 | Module header | Copyright, usage documentation |
| 47-49 | Imports | `pathsep`, `ourpath`, `serialize` |
| 51-57 | `pathconcat()` | Local — path joining with separator |
| 59-113 | `find_config()` | Config file discovery and directory creation |
| 62-71 | Platform detection | Windows (`AppData`) vs Linux/macOS (`XDG_CONFIG_HOME`) |
| 77-89 | `config.path.txt` override | Redirect config storage location |
| 92-112 | `check_dir_exists()` | Recursive directory creation |
| 115-180 | `new_config_defaults()` | All config keys with default values |
| 124-179 | Default values | Display, audio, gameplay, debug, etc. |
| 183-280 | `new_hotkeys_defaults()` | All hotkey bindings with defaults |
| 184-280 | Hotkey defaults | Global, scroll, zoom, panels, controls |
| 282-288 | `param()` | Config value serializer with comment support |
| 290-737 | `config_contents()` | Full config file template generator |
| 292-314 | Header comment block | Config file format documentation |
| 315-319 | Display params | `fullscreen`, `width`, `height`, `ui_scale`, `cursor_scale` |
| 322-347 | Language section | Language names and codes |
| 349-352 | Audio section | `audio` global toggle |
| 354-364 | Custom game menu | `free_build_mode` |
| 366-437 | Options menu | Sound, music, edge scrolling, adviser, clock |
| 439-537 | Customise settings | Gameplay toggles, alien DNA, autosave |
| 539-619 | Folder settings | Install path, fonts, saves, levels, music, soundfont |
| 621-652 | MIDI settings | API, port, SysEx volume |
| 654-734 | Special settings | Debug, FPS, zoom, scroll, room dialogs, blocking |
| 739-913 | `hotkeys_contents()` | Full hotkey file template generator |
| 741-771 | Global keys | Confirm, cancel, fullscreen, exit |
| 773-789 | Scroll keys | Direction keys, shift modifier |
| 781-789 | Zoom keys | In, out, reset |
| 791-858 | In-game menus | Panel keys, pause, speed, quick save/load |
| 862-911 | Position/toggle keys | Store/recall positions, toggles, dump log |
| 916-923 | `apply_config_defaults()` | Fill missing keys from defaults |
| 925-932 | `apply_hotkeys_defaults()` | Fill missing hotkeys from defaults |
| 934-939 | `open_for_write()` | Write helper with TheApp fallback |
| 942-951 | `save_config()` | Write config to disk |
| 953-962 | `save_hotkeys()` | Write hotkeys to disk |
| 964-977 | `load_config()` | Load and parse config file |
| 979-991 | `load_hotkeys()` | Load and parse hotkey file |
| 993-999 | Module-level computation | `config_filename`, `hotkeys_filename` |
| 1001-1010 | Module exports | Public API table |

### base_config.lua (598 lines)

| Line(s) | Symbol / Block | Description |
|---------|---------------|-------------|
| 23-596 | `configuration` table | Complete game tuning constants |
| 30-35 | `town` | Interest rates, starting cash, reputation |
| 43-45 | `payroll` | Maximum salary |
| 50-55 | `staff` | Per-role minimum salaries |
| 56-150 | `gbv` | Global balancing variables |
| 57-66 | `SalaryAdd` | Role-based salary additions |
| 68-70 | `SalaryAbilityDivisor` | Ability-based salary divisor |
| 72-73 | `ResearchPointsDivisor` | Research point calculation |
| 75-76 | `StartRating` / `StartCost` | Drug research defaults |
| 78-122 | Epidemic settings | Contagion, fine, compensation, limits |
| 124-147 | Training/ability | Thresholds, training rate, fatigue levels |
| 149 | `SodaPrice` | Drinks machine cost |
| 152-166 | `towns` | Per-level town parameters (12 levels) |
| 167-171 | `popn` | Population growth schedule |
| 172-219 | `expertise` | Disease research costs and difficulty |
| 220-282 | `objects` | Object costs, availability, strength |
| 286-311 | `rooms` | Room build costs (indexed from 7) |
| 312-327 | `visuals` | Visual illness values |
| 328-349 | `non_visuals` | Non-visual illness values |
| 350-365 | `visuals_available` | Illness availability months |
| 366-389 | `non_visuals_available` | Non-visual illness availability |
| 391-406 | `win_criteria` / `lose_criteria` | Level completion conditions |
| 408-411 | `staff_levels` | Initial staff allocation |
| 413-415 | `emergency_control` | Emergency parameters |
| 416-432 | `computer` | Research computer names |
| 433-595 | `awards_trophies` | Award thresholds and bonus values |
| 436-451 | Trophy win conditions | Rat kills, reputation, plants, etc. |
| 458-479 | Trophy bonuses | Money and reputation rewards |
| 482-531 | Award criteria | Cures, deaths, happiness, waiting times |
| 534-595 | Award bonuses/penalties | Money and reputation adjustments |


## Related Pages

- [[CHECKLIST]]
- [[SUMMARY]]
