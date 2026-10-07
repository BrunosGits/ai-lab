require("corsixth")
require("class_test_base")
require("utility")

describe("config_spec.lua: Configuration loading", function()
  local config_finder

  before_each(function()
    config_finder = require("config_finder")
  end)

  describe("Module exports", function()
    it("exports config_filename", function()
      assert.is_not_nil(config_finder.config_filename)
      assert.is_string(config_finder.config_filename)
    end)

    it("exports config_defaults function", function()
      assert.is_function(config_finder.config_defaults)
    end)

    it("exports load_config function", function()
      assert.is_function(config_finder.load_config)
    end)

    it("exports save_config function", function()
      assert.is_function(config_finder.save_config)
    end)

    it("exports hotkeys_filename", function()
      assert.is_not_nil(config_finder.hotkeys_filename)
      assert.is_string(config_finder.hotkeys_filename)
    end)

    it("exports hotkeys_defaults function", function()
      assert.is_function(config_finder.hotkeys_defaults)
    end)

    it("exports load_hotkeys function", function()
      assert.is_function(config_finder.load_hotkeys)
    end)

    it("exports save_hotkeys function", function()
      assert.is_function(config_finder.save_hotkeys)
    end)
  end)

  describe("Config defaults function", function()
    it("config_defaults is callable", function()
      local defaults = config_finder.config_defaults()
      assert.is_table(defaults)
    end)
  end)

  describe("Hotkeys defaults function", function()
    it("hotkeys_defaults is callable", function()
      local defaults = config_finder.hotkeys_defaults()
      assert.is_table(defaults)
    end)
  end)
end)
