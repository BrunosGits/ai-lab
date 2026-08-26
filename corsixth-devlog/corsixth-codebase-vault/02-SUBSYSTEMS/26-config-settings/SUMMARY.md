# Area 26: Config/Settings — Technical Reference

## 1. Architecture Overview

The configuration system is split across two files:

1. **`config_finder.lua`** (1010 lines) — Manages discovery, loading, saving, and serialization of `config.txt` and `hotkeys.txt`.
2. **`base_config.lua`** (598 lines) — Defines gameplay-tuning constants (`TH.config`) used by the game engine.

This separation enforces a layering violation prevention: only `config_finder.lua` should read/write config files; `base_config.lua` is pure data.

### Key Source Files

| File | Lines | Role |
|------|-------|------|
| `CorsixTH/Lua/config_finder.lua` | 1010 | Config discovery, load, save, serialization |
| `CorsixTH/Lua/base_config.lua` | 598 | Game tuning constants (TH.config) |

See [[MAP]] for the complete file:line index.

---

## 2. Config File Discovery

### 2.1 `find_config()` (lines 59-113)

Determines the path for `config.txt`:

```lua
local function find_config()
  local config_path
  if pathsep == "\\" then
    -- Windows: %AppData%/CorsixTH
    config_path = os.getenv("AppData") or ourpath
  else
    -- Linux/macOS: $XDG_CONFIG_HOME/CorsixTH or ~/.config/CorsixTH
    config_path = os.getenv("XDG_CONFIG_HOME")
           or pathconcat(os.getenv("HOME") or "~", ".config")
  end
  if config_path ~= ourpath then
    config_path = pathconcat(config_path, "CorsixTH")
  end
```

**Override via `config.path.txt`** (lines 77-89):

A file named `config.path.txt` in the application directory can redirect config storage:

```lua
local fi = io.open(pathconcat(ourpath, "config.path.txt"), "r")
if fi then
  local contents = fi:read("*a")
  contents = contents:match("^%s*(.-)%s*$")  -- trim whitespace
  if #contents ~= 0 then
    config_path = contents
    -- If path ends with .txt, extract filename separately
    if config_path:sub(-4, -1):lower() == ".txt" then
      config_name = config_path:match("([^" .. pathsep .. "]*)$")
      config_path = config_path:sub(1, -1-#config_name)
    end
  end
end
```

**Directory creation** (lines 92-112):

```lua
local function check_dir_exists(path)
  if lfs.attributes(path, "mode") == "directory" then
    return true
  else
    local subpath = path:match("^(.*)[" .. pathsep .. "]")
    if subpath then
      return check_dir_exists(subpath) and lfs.mkdir(path)
    end
  end
end
```

Recursive directory creation: checks if parent exists, creates it, then creates the target.

---

## 3. Config Defaults

### 3.1 `new_config_defaults()` (lines 115-180)

Returns a table of all configuration keys with their default values:

```lua
return {
  fullscreen = false,
  width = 800,
  height = 600,
  ui_scale = 1,
  cursor_scale = 1,
  language = [[English]],
  audio = true,
  free_build_mode = false,
  play_sounds = true,
  sound_volume = 0.5,
  play_announcements = true,
  announcement_volume = 0.5,
  play_music = true,
  music_volume = 0.5,
  prevent_edge_scrolling = false,
  capture_mouse = true,
  right_mouse_scrolling = false,
  adviser_disabled = false,
  scrolling_momentum = 0.8,
  twentyfour_hour_clock = true,
  warmth_colors_display_default = 1,
  grant_wage_increase = false,
  movies = true,
  play_intro = true,
  play_demo = true,
  allow_user_actions_while_paused = false,
  volume_opens_casebook = false,
  alien_dna_only_by_emergency = true,
  alien_dna_must_stand = true,
  alien_dna_can_knock_on_doors = false,
  disable_fractured_bones_females = true,
  enable_avg_contents = false,
  remove_destroyed_rooms = false,
  machine_menu_button = true,
  enable_screen_shake = true,
  enable_announcer_subtitles = false,
  autosave_frequency = 1,
  midi_api = nil,
  midi_port = nil,
  midi_sysex_master_volume = false,
  theme_hospital_install = [[X:\ThemeHospital\hospital]],
  debug = false,
  track_fps = false,
  zoom_speed = 80,
  scroll_speed = 2,
  shift_scroll_speed = 4,
  new_graphics_folder = nil,
  use_new_graphics = false,
  check_for_updates = true,
  room_information_dialogs = true,
  blocking_off_areas = 2,
  direct_zoom = nil,
  new_machine_extra_info = true,
  player_name = [[]],
}
```

### 3.2 Setting Categories

| Category | Keys | In-Game Menu |
|----------|------|-------------|
| **Display** | `fullscreen`, `width`, `height`, `ui_scale`, `cursor_scale` | Settings Menu |
| **Language** | `language` | Settings Menu |
| **Audio** | `audio`, `play_sounds`, `sound_volume`, `play_music`, `music_volume`, `play_announcements`, `announcement_volume` | Settings/Options |
| **Controls** | `prevent_edge_scrolling`, `capture_mouse`, `right_mouse_scrolling`, `scrolling_momentum` | Options Menu |
| **UI** | `adviser_disabled`, `twentyfour_hour_clock`, `warmth_colors_display_default`, `check_for_updates` | Options Menu |
| **Gameplay** | `grant_wage_increase`, `allow_user_actions_while_paused`, `volume_opens_casebook`, `alien_dna_*`, `disable_fractured_bones_females`, `enable_avg_contents`, `remove_destroyed_rooms`, `machine_menu_button`, `enable_screen_shake`, `enable_announcer_subtitles`, `autosave_frequency` | Customise Menu |
| **Folders** | `theme_hospital_install`, `unicode_font`, `savegames`, `levels`, `campaigns`, `audio_music`, `screenshots`, `soundfont`, `new_graphics_folder` | Folders Menu |
| **Graphics** | `use_new_graphics` | — |
| **MIDI** | `midi_api`, `midi_port`, `midi_sysex_master_volume` | MIDI Settings |
| **Debug** | `debug`, `track_fps` | — (config only) |
| **Tuning** | `zoom_speed`, `scroll_speed`, `shift_scroll_speed`, `blocking_off_areas`, `direct_zoom`, `new_machine_extra_info` | — (config only) |
| **Player** | `player_name` | New Game Menu |

---

## 4. Hotkey Defaults

### 4.1 `new_hotkeys_defaults()` (lines 183-280)

Returns all hotkey bindings. Hotkeys are either strings (single key) or tables (modifier combos):

```lua
return {
  global_confirm = "return",            -- single key
  global_fullscreen_toggle = {"alt", "return"},  -- modifier combo
  global_exitApp = {"alt", "f4"},
  -- ... 80+ bindings
}
```

### 4.2 Hotkey Categories

| Category | Prefix | Examples |
|----------|--------|---------|
| Global | `global_` | `confirm`, `cancel`, `fullscreen_toggle`, `exitApp` |
| In-game scroll | `ingame_scroll_` | `up`, `down`, `left`, `right`, `shift` |
| In-game zoom | `ingame_zoom_` | `in`, `out`, `in_more`, `out_more`, `reset_zoom` |
| In-game panels | `ingame_panel_` | `bankManager`, `townMap`, `casebook`, `research` |
| In-game controls | `ingame_` | `pause`, `gamespeed_*`, `setTransparent`, `toggleTransparent` |
| Quick keys | `ingame_quick*` | `quickSave`, `quickLoad` |
| Store/recall | `ingame_storePosition_*` / `ingame_recallPosition_*` | 0-9 slots |
| Toggle | `ingame_toggle*` | `Announcements`, `Sounds`, `Music`, `Advisor` |

---

## 5. Config Loading

### 5.1 `load_config()` (lines 964-977)

```lua
local function load_config(path, res)
  res = res or {}
  if not lfs.attributes(path) then
    save_config(path, new_config_defaults())
  end
  local chunk, err = loadfile_envcall(path)
  if chunk then
    chunk(res)
  end
  apply_config_defaults(res)
  return res, err
end
```

**Flow:**

1. If the config file doesn't exist, create it with defaults.
2. Load the file as a Lua chunk using `loadfile_envcall`.
3. Execute the chunk with `res` as the environment — this populates `res` with user values.
4. Apply defaults for any missing keys via `apply_config_defaults`.

### 5.2 `apply_config_defaults()` (lines 916-923)

```lua
local function apply_config_defaults(res)
  local config_defaults = new_config_defaults()
  for key, value in pairs(config_defaults) do
    if res[key] == nil then
      res[key] = value
    end
  end
end
```

This ensures backward compatibility: old config files without new keys get the defaults without breaking.

### 5.3 `load_hotkeys()` (lines 979-991)

Identical pattern to `load_config`:

```lua
local function load_hotkeys(path, res)
  res = res or {}
  if not lfs.attributes(path) then
    save_hotkeys(path, new_hotkeys_defaults())
  end
  local chunk, err = loadfile_envcall(path)
  if chunk then
    chunk(res)
  end
  apply_hotkeys_defaults(res)
  return res, err
end
```

---

## 6. Config Saving

### 6.1 `save_config()` (lines 942-951)

```lua
local function save_config(path, values)
  local config_data = config_contents(values)
  local fi, err = open_for_write(path)
  if not fi then
    return nil, err
  fi
  fi:write(config_data)
  fi:close()
  return true
end
```

### 6.2 `config_contents()` (lines 290-737)

Generates the full config file text with human-readable comments:

```lua
parts[1] = [=[
------------------------- CorsixTH configuration file -------------------------
-- Lines starting with two dashes (like this one) are ignored.
-- Text settings should have their values between double square braces, e.g.
--  setting = [[value]]
-- Number settings should not have anything around their value,
--  e.g. setting = 42
--]=] .. '\n' ..
param(config_values, 'fullscreen') ..
```

The `param()` helper (line 282-288) serializes a single key-value pair:

```lua
local function param(params, param_name, nil_example)
  if nil_example then
    return param_name .. ' = ' ..
        (params[param_name] and serialize(params[param_name]) or 'nil -- ' .. nil_example) .. '\n'
  end
  return param_name .. ' = ' .. serialize(params[param_name]) .. '\n'
end
```

### 6.3 Config File Format

The config file is executable Lua with comments:

```lua
-- This is a comment (lines starting with --)
fullscreen = false
width = 800
height = 600
language = [[English]]
```

String values use double square braces `[[value]]`. Numbers are bare. Booleans are `true`/`false`.

### 6.4 Hotkey File Format

Same format as config, but with table values for modifier combos:

```lua
global_confirm = "return"
global_fullscreen_toggle = {"alt", "return"}
```

---

## 7. Module Export Interface

### 7.1 `config_finder.lua` Returns (lines 1001-1010)

```lua
return {
  config_filename = config_filename,
  config_defaults = new_config_defaults,
  load_config = load_config,
  save_config = save_config,
  hotkeys_filename = hotkeys_filename,
  hotkeys_defaults = new_hotkeys_defaults,
  load_hotkeys = load_hotkeys,
  save_hotkeys = save_hotkeys,
}
```

Note: `config_filename` and `hotkeys_filename` are computed at module load time (lines 993-999).

---

## 8. base_config.lua — Game Tuning Constants

### 8.1 Structure

`base_config.lua` returns a single `configuration` table with nested sub-tables:

```lua
local configuration = {
  town = { InterestRate, StartCash, StartRep, OverdraftDiff },
  payroll = { MaxSalary },
  staff = { [0] = {MinSalary}, ... },
  gbv = { ... },  -- Global balancing variables
  towns = { ... },  -- Per-level town settings
  popn = { ... },  -- Population growth
  expertise = { ... },  -- Disease research costs
  objects = { ... },  -- Object costs and strengths
  rooms = { ... },  -- Room build costs
  visuals = { ... },  -- Visual illness values
  non_visuals = { ... },  -- Non-visual illness values
  visuals_available = { ... },  -- Illness availability months
  non_visuals_available = { ... },
  win_criteria = { ... },
  lose_criteria = { ... },
  staff_levels = { ... },
  emergency_control = { ... },
  computer = { ... },  -- Research computer names
  awards_trophies = { ... },  -- Award thresholds and bonuses
}
```

### 8.2 Key Tuning Sections

#### `town` (lines 30-35)

```lua
town = {
  InterestRate = 100,     -- Divided by 10,000 for actual rate
  StartCash = 40000,
  StartRep = 500,
  OverdraftDiff = 200,    -- Differential for overdraft interest
}
```

#### `gbv` (Global Balancing Variables, lines 56-150)

Critical gameplay parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ResearchPointsDivisor` | 5 | Divides research input for points |
| `StartRating` | 100 | Initial drug research rating |
| `StartCost` | 100 | Initial drug research cost |
| `MinDrugCost` | 50 | Minimum drug cost |
| `HowContagious` | 25 | Contagious illness spread rate |
| `EpidemicFine` | 2000 | Coverup failure fine per person |
| `VacCost` | 50 | Vaccination cost |
| `MaxObjectStrength` | 20 | Maximum researchable object strength |
| `TrainingRate` | 40 | Student doctor learning rate |
| `DoctorThreshold` | 250 | Skill threshold for doctor title |
| `ConsultantThreshold` | 750 | Skill threshold for consultant |

#### `expertise` (lines 172-219)

Each disease has:

```lua
{StartPrice = 850, Known = 0, RschReqd = 40000, MaxDiagDiff = 700}
--         ^cost    ^initially    ^research        ^diagnostic
--                   known?        points needed    difficulty
```

#### `objects` (lines 220-282)

Each object has:

```lua
{StartCost = 500, StartAvail = 1, WhenAvail = 0, StartStrength = 10, AvailableForLevel = 1}
```

#### `rooms` (lines 286-311)

Room costs indexed by room ID (starting at 7):

```lua
rooms = {
  [7] = {Cost = 2280},   -- GP_OFFICE
  [8] = {Cost = 2270},   -- PSYCHO
  -- ... 24 rooms total
}
```

---

## 9. Version Migration Strategy

### 9.1 Adding New Config Keys

When adding a new config property:

1. Add the default value to `new_config_defaults()` (line 115).
2. Add the parameter line to `config_contents()` (line 290) under the appropriate section heading.
3. Add a `param()` call with description comment.

The `apply_config_defaults()` function (line 916) ensures old configs without the new key get the default value — no migration code needed.

### 9.2 Removing Deprecated Keys

Deprecated keys are simply removed from `new_config_defaults()`. They are silently ignored when loading old config files because `loadfile_envcall` executes the file in the provided environment — undefined keys simply don't set anything.

### 9.3 Windows Installer Template

After changing config.txt, regenerate the Windows installer template:

```bash
lua scripts/generate_windows_config.lua
```

This is documented in the module header (config_finder.lua:39-41).

---

## 10. Error Handling

### 10.1 Missing Config File

If `config.txt` doesn't exist, it is created with defaults (lines 967-969):

```lua
if not lfs.attributes(path) then
  save_config(path, new_config_defaults())
end
```

### 10.2 Corrupt Config File

If `loadfile_envcall` returns an error, `load_config` returns it to the caller (line 976). The caller decides how to handle it — typically logging and using defaults.

### 10.3 Write Failures

`open_for_write` uses `TheApp:writeToFileOrTmp` if available (line 935-939), falling back to `io.open`. If writing fails, the error is returned to the caller.

### 10.4 Directory Creation Failure

If `check_dir_exists` cannot create the target directory, `config_path` falls back to `ourpath` (the application directory) at line 109.

---

## 11. Relationship Between Config Files

| File | Location | Purpose |
|------|----------|---------|
| `config.txt` | User config dir | Main configuration |
| `hotkeys.txt` | Same dir as config.txt | Hotkey bindings |
| `config.path.txt` | Application dir | Redirects config storage |
| `config.txt.debug` | — | Debug config variant |
| `config.txt.mp` | — | Multiplayer config variant |

The `config.txt.debug` and `config.txt.mp` variants are not managed by `config_finder.lua` — they are loaded by `App` directly when specific launch flags are set.

---

## Related Pages

- [[MAP]] — File:line index for rapid navigation across all config source files
- [[SCAFFOLD]] — Busted test templates for config loading and defaults
- [[CHECKLIST]] — Pre-fix verification checklist with priority-ordered items
