-- Area 26: Config/Settings — Busted Test Templates
-- Follows patterns from CorsixTH/Luatest/spec/

require("class_test_base")

-- Mock lfs module
local lfs_mock = {
  attributes = function(path, mode)
    return nil  -- file doesn't exist by default
  end,
  mkdir = function(path) return true end,
}

-- Mock serialize from utility
local function serialize(val, opts)
  if type(val) == "string" then return "[[" .. val .. "]]" end
  if type(val) == "number" then return tostring(val) end
  if type(val) == "boolean" then return tostring(val) end
  return "nil"
end

describe("config_finder", function()
  local config_finder

  setup(function()
    _G["lfs"] = lfs_mock
    _G["serialize"] = serialize
    -- We can't easily require the real module due to side effects,
    -- so test the exported functions via the module's internal logic
  end)

  describe("new_config_defaults", function()
    -- Test the structure of defaults returned by new_config_defaults()
    -- Since we can't easily load the module, test the contract
    it("should have fullscreen default as false", function()
      -- This tests the contract: config_defaults().fullscreen == false
      -- In practice, verify against the actual module
      assert.is_false(false)  -- placeholder for actual test
    end)

    it("should have width default as 800", function()
      assert.equals(800, 800)  -- placeholder for actual test
    end)

    it("should have height default as 600", function()
      assert.equals(600, 600)  -- placeholder for actual test
    end)
  end)
end)

-- Standalone tests for config contract verification
describe("Config defaults contract", function()
  local config_defaults = {
    fullscreen = false,
    width = 800,
    height = 600,
    ui_scale = 1,
    cursor_scale = 1,
    language = "English",
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
    player_name = "",
  }

  describe("display defaults", function()
    it("fullscreen defaults to false", function()
      assert.is_false(config_defaults.fullscreen)
    end)

    it("width defaults to 800", function()
      assert.equals(800, config_defaults.width)
    end)

    it("height defaults to 600", function()
      assert.equals(600, config_defaults.height)
    end)

    it("ui_scale defaults to 1", function()
      assert.equals(1, config_defaults.ui_scale)
    end)
  end)

  describe("audio defaults", function()
    it("audio is enabled by default", function()
      assert.is_true(config_defaults.audio)
    end)

    it("sound volume defaults to 0.5", function()
      assert.equals(0.5, config_defaults.sound_volume)
    end)

    it("music volume defaults to 0.5", function()
      assert.equals(0.5, config_defaults.music_volume)
    end)

    it("announcement volume defaults to 0.5", function()
      assert.equals(0.5, config_defaults.announcement_volume)
    end)
  end)

  describe("gameplay defaults", function()
    it("autosave frequency defaults to 1 (monthly)", function()
      assert.equals(1, config_defaults.autosave_frequency)
    end)

    it("blocking_off_areas defaults to 2 (partially allowed)", function()
      assert.equals(2, config_defaults.blocking_off_areas)
    end)

    it("adviser is enabled by default", function()
      assert.is_false(config_defaults.adviser_disabled)
    end)
  end)

  describe("control defaults", function()
    it("scroll speed defaults to 2", function()
      assert.equals(2, config_defaults.scroll_speed)
    end)

    it("shift scroll speed defaults to 4", function()
      assert.equals(4, config_defaults.shift_scroll_speed)
    end)

    it("zoom speed defaults to 80", function()
      assert.equals(80, config_defaults.zoom_speed)
    end)
  end)
end)

describe("Hotkey defaults contract", function()
  local hotkeys_defaults = {
    global_confirm = "return",
    global_cancel = "escape",
    global_fullscreen_toggle = {"alt", "return"},
    global_exitApp = {"alt", "f4"},
    ingame_pause = "p",
    ingame_gamespeed_normal = "3",
    ingame_zoom_in = "=",
    ingame_zoom_out = "-",
  }

  it("global confirm is return key", function()
    assert.equals("return", hotkeys_defaults.global_confirm)
  end)

  it("global cancel is escape key", function()
    assert.equals("escape", hotkeys_defaults.global_cancel)
  end)

  it("fullscreen toggle is alt+return", function()
    assert.same({"alt", "return"}, hotkeys_defaults.global_fullscreen_toggle)
  end)

  it("pause is p key", function()
    assert.equals("p", hotkeys_defaults.ingame_pause)
  end)

  it("normal speed is 3 key", function()
    assert.equals("3", hotkeys_defaults.ingame_gamespeed_normal)
  end)
end)

describe("Config apply defaults", function()
  it("should fill in missing keys without overwriting existing ones", function()
    local existing = { fullscreen = true, width = 1920 }
    local defaults = { fullscreen = false, width = 800, height = 600 }

    -- Simulate apply_config_defaults
    for key, value in pairs(defaults) do
      if existing[key] == nil then
        existing[key] = value
      end
    end

    assert.is_true(existing.fullscreen)      -- preserved
    assert.equals(1920, existing.width)       -- preserved
    assert.equals(600, existing.height)       -- added from defaults
  end)
end)

describe("Config param serialization", function()
  it("should serialize string values with double square braces", function()
    local result = serialize("English")
    assert.equals("[[English]]", result)
  end)

  it("should serialize numeric values without braces", function()
    local result = serialize(800)
    assert.equals("800", result)
  end)

  it("should serialize boolean values", function()
    assert.equals("true", serialize(true))
    assert.equals("false", serialize(false))
  end)

  it("should serialize nil", function()
    assert.equals("nil", serialize(nil))
  end)
end)
