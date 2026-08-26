# Area 26: Config/Settings — Pre-Fix Verification Checklist

## Critical

- [ ] **1.1** `config_finder.lua` is the ONLY module that reads/writes config files — verify no other module directly parses `config.txt` (config_finder.lua:45-46 comment)
- [ ] **1.2** `load_config` uses `loadfile_envcall` — verify the environment parameter is the `res` table, not `_G` (config_finder.lua:970-972)
- [ ] **1.3** `apply_config_defaults` only fills `nil` keys — verify it never overwrites user-set values (config_finder.lua:918-920)
- [ ] **1.4** Config file creation: if `config.txt` doesn't exist, `save_config` is called with defaults before loading — verify this doesn't race with concurrent access (config_finder.lua:967-969)

## High

- [ ] **2.1** `find_config` checks `config.path.txt` override — verify the path trimming logic handles trailing path separators correctly (config_finder.lua:77-89)
- [ ] **2.2** `check_dir_exists` is recursive — verify it handles deeply nested paths without stack overflow (config_finder.lua:93-107)
- [ ] **2.3** `param()` helper: verify it correctly handles `nil` values with the `nil_example` fallback (config_finder.lua:282-288)
- [ ] **2.4** `config_contents()` generates the full file text — verify all config keys have corresponding `param()` calls (config_finder.lua:290-737)
- [ ] **2.5** `hotkeys_contents()` generates the full hotkey text — verify all hotkey keys have corresponding `param()` calls (config_finder.lua:739-913)
- [ ] **2.6** Hotkey values: verify modifier combos are serialized as tables (e.g., `{"alt", "return"}`) not strings (config_finder.lua:746-750)

## Medium

- [ ] **3.1** `open_for_write` uses `TheApp:writeToFileOrTmp` when available — verify fallback to `io.open` works when `TheApp` is nil (config_finder.lua:934-939)
- [ ] **3.2** Config file path: verify `config_filename` and `hotkeys_filename` are computed at module load time and cached (config_finder.lua:993-999)
- [ ] **3.3** Windows path separator: verify `pathconcat` handles both `\` and `/` correctly (config_finder.lua:51-57)
- [ ] **3.4** `config.txt.debug` and `config.txt.mp` are not managed by this module — verify no code path in config_finder loads them (config_finder.lua:45-46)
- [ ] **3.5** New config keys: verify the version migration strategy (add to defaults + add param line) doesn't require explicit migration code (config_finder.lua:916-923)
- [ ] **3.6** `base_config.lua` tables start at index 0 — verify iteration uses `ipairs` awareness (base_config.lua:21-22)

## Low

- [ ] **4.1** `config.path.txt` with empty contents should fall back to default path — verify the `#contents ~= 0` check (config_finder.lua:82)
- [ ] **4.2** `config.path.txt` ending with `.txt` should extract filename separately — verify the sub-path logic (config_finder.lua:84-87)
- [ ] **4.3** `serialize()` is imported from `utility` module — verify it's available at module scope (config_finder.lua:49)
- [ ] **4.4** `base_config.lua` `awards_trophies` section: verify all bonus/penalty values are within documented MIN/MAX ranges (base_config.lua:433-595)


## Related Pages

- [[MAP]]
- [[SUMMARY]]
