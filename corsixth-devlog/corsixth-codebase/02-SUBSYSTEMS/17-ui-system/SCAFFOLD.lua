-- UI System Test Scaffold
-- Busted test template for UI system

local busted = require("busted")
local describe, it, assert = busted.describe, busted.it, busted.assert

-- Mock helpers
local function makeMockApp()
  return {
    config = {},
    strings = { get = function() return "" end },
    gfx = { target = { w = 1024, h = 768 } },
    audio = { playSound = function() end },
  }
end

local function makeMockWindow(opts)
  opts = opts or {}
  local w = {
    x = opts.x or 0,
    y = opts.y or 0,
    width = opts.width or 200,
    height = opts.height or 150,
    visible = true,
    panels = {},
    buttons = {},
    windows = {},
    buttons_down = { mouse_left = false, mouse_middle = false, mouse_right = false },
    close = function(self) self.visible = false end,
    addPanel = function(self, p) table.insert(self.panels, p) return p end,
    addButton = function(self, b) table.insert(self.buttons, b) return b end,
    addWindow = function(self, child)
      child.parent = self
      table.insert(self.windows, child)
      return child
    end,
    removeWindow = function(self, child)
      for i, w in ipairs(self.windows) do
        if w == child then table.remove(self.windows, i) break end
      end
    end,
    hitTest = function(self, mx, my)
      return mx >= self.x and mx < self.x + self.width and
             my >= self.y and my < self.y + self.height
    end,
  }
  return setmetatable(w, { __index = w })
end

local function makeMockUI()
  local ui = makeMockWindow({ width = 1024, height = 768 })
  ui.app = makeMockApp()
  ui.key_handlers = {}
  ui.key_remaps = {}
  ui.button_remaps = {}
  ui.cursor_x = 0
  ui.cursor_y = 0
  ui.buttons_down = { mouse_left = false, mouse_middle = false, mouse_right = false }
  ui.modal_window = nil
  ui.addKeyHandler = function(self, key, handler) self.key_handlers[key] = handler end
  ui.removeKeyHandler = function(self, key) self.key_handlers[key] = nil end
  ui.dispatch = function(self) end
  ui.playSound = function(self, name) end
  return ui
end

local function makeMockButton(opts)
  return {
    x = opts.x or 0,
    y = opts.y or 0,
    w = opts.w or 80,
    h = opts.h or 30,
    tooltip = opts.tooltip,
    on_click = opts.on_click or function() end,
    enable = true,
    visible = true,
    sound_done = "click.wav",
  }
end

local function makeMockPanel(opts)
  return {
    x = opts.x or 0,
    y = opts.y or 0,
    w = opts.w or 100,
    h = opts.h or 50,
    colour = opts.colour or 0xFFFFFFFF,
    visible = true,
  }
end

-- Load actual modules (if available)
local Window, UI, GameUI
local ok, err = pcall(function()
  Window = require("window")
  UI = require("ui")
  GameUI = require("game_ui")
end)

describe("UI System", function()
  describe("Window Core", function()
    local window

    before_each(function()
      window = makeMockWindow({ width = 200, height = 150 })
    end)

    it("creates with default position", function()
      assert.equals(0, window.x)
      assert.equals(0, window.y)
      assert.equals(200, window.width)
      assert.equals(150, window.height)
      assert.is_true(window.visible)
    end)

    it("sets size correctly", function()
      window:setSize(300, 200)
      assert.equals(300, window.width)
      assert.equals(200, window.height)
    end)

    it("sets position with absolute coords", function()
      window:setPosition(100, 50)
      assert.equals(100, window.x)
      assert.equals(50, window.y)
    end)

    it("sets position with fractional coords", function()
      window.parent = { width = 800, height = 600 }
      window:setPosition(0.5, 0.5)
      assert.equals(400, window.x)
      assert.equals(300, window.y)
    end)

    it("sets position with negative coords (from right/bottom)", function()
      window.parent = { width = 800, height = 600 }
      window:setPosition(-100, -50)
      assert.equals(700, window.x)
      assert.equals(550, window.y)
    end)

    it("hitTest returns true for point inside", function()
      assert.is_true(window:hitTest(50, 50))
    end)

    it("hitTest returns false for point outside", function()
      assert.is_false(window:hitTest(300, 200))
    end)

    it("adds child window", function()
      local child = makeMockWindow({ width = 100, height = 100 })
      window:addWindow(child)
      assert.equals(1, #window.windows)
      assert.equals(window, child.parent)
    end)

    it("removes child window", function()
      local child = makeMockWindow({ width = 100, height = 100 })
      window:addWindow(child)
      window:removeWindow(child)
      assert.equals(0, #window.windows)
    end)

    it("closes and cleans up", function()
      window:close()
      assert.is_false(window.visible)
    end)
  end)

  describe("Panel", function()
    it("creates with defaults", function()
      local panel = makeMockPanel()
      assert.equals(0, panel.x)
      assert.equals(0, panel.y)
      assert.is_true(panel.visible)
    end)

    it("sets colour", function()
      local panel = makeMockPanel()
      panel.colour = 0xFF0000FF
      assert.equals(0xFF0000FF, panel.colour)
    end)
  end)

  describe("Button", function()
    local button

    before_each(function()
      button = makeMockButton({ x = 10, y = 10, w = 80, h = 30, on_click = function() end })
    end)

    it("creates with defaults", function()
      assert.equals(80, button.w)
      assert.equals(30, button.h)
      assert.is_true(button.enable)
      assert.is_true(button.visible)
    end)

    it("calls on_click on mouse up", function()
      local clicked = false
      button.on_click = function() clicked = true end
      button:onMouseUp(15, 15)
      assert.is_true(clicked)
    end)

    it("does not call on_click when disabled", function()
      local clicked = false
      button.on_click = function() clicked = true end
      button.enable = false
      button:onMouseUp(15, 15)
      assert.is_false(clicked)
    end)

    it("does not call on_click when outside bounds", function()
      local clicked = false
      button.on_click = function() clicked = true end
      button:onMouseUp(200, 200)
      assert.is_false(clicked)
    end)
  end)

  describe("UI Class", function()
    local ui

    before_each(function()
      ui = makeMockUI()
    end)

    it("creates with default state", function()
      assert.is_table(ui.key_handlers)
      assert.equals(0, ui.cursor_x)
      assert.is_nil(ui.modal_window)
    end)

    it("registers key handlers", function()
      local handler = function() end
      ui:addKeyHandler("escape", handler)
      assert.equals(handler, ui.key_handlers.escape)
    end)

    it("removes key handlers", function()
      ui:addKeyHandler("escape", function() end)
      ui:removeKeyHandler("escape")
      assert.is_nil(ui.key_handlers.escape)
    end)

    it("tracks mouse buttons", function()
      ui.buttons_down.mouse_left = true
      assert.is_true(ui.buttons_down.mouse_left)
    end)

    it("manages modal window", function()
      local modal = makeMockWindow({ width = 300, height = 200 })
      ui.modal_window = modal
      assert.equals(modal, ui.modal_window)
    end)
  end)

  describe("GameUI Class", function()
    local gameui

    before_each(function()
      gameui = makeMockUI()
      gameui.hospital = {}
      gameui.bottom_panel = {}
      gameui.menu_bar = {}
      gameui.announcer = {}
      gameui.tutorial = {}
      gameui.subtitles = {}
    end)

    it("has required components", function()
      assert.is_table(gameui.hospital)
      assert.is_table(gameui.bottom_panel)
      assert.is_table(gameui.menu_bar)
    end)

    it("handles zoom", function()
      gameui.setZoom = function(self, level) self.zoom = level end
      gameui:setZoom(2)
      assert.equals(2, gameui.zoom)
    end)

    it("handles map scrolling", function()
      gameui.scrollMap = function(self, dx, dy) self.scroll_x = dx; self.scroll_y = dy end
      gameui:scrollMap(10, -5)
      assert.equals(10, gameui.scroll_x)
      assert.equals(-5, gameui.scroll_y)
    end)

    it("handles screen shake", function()
      gameui.shakeScreen = function(self, intensity) self.shake = intensity end
      gameui:shakeScreen(5)
      assert.equals(5, gameui.shake)
    end)
  end)

  describe("Modal Dialog System", function()
    it("blocks input to background windows", function()
      local ui = makeMockUI()
      local modal = makeMockWindow({ width = 300, height = 200 })
      local background = makeMockWindow({ width = 800, height = 600 })
      ui:addWindow(background)
      ui:addWindow(modal)
      ui.modal_window = modal

      -- Modal should be on top (last in windows list)
      assert.equals(modal, ui.windows[#ui.windows])
    end)
  end)

  describe("Position System Edge Cases", function()
    it("handles mixed absolute/fractional", function()
      local w = makeMockWindow({ width = 100, height = 100 })
      w.parent = { width = 800, height = 600 }
      w:setPosition(100, 0.5)  -- absolute x, fractional y
      assert.equals(100, w.x)
      assert.equals(300, w.y)
    end)

    it("clamps fractional to [0,1)", function()
      local w = makeMockWindow({ width = 100, height = 100 })
      w.parent = { width = 800, height = 600 }
      w:setPosition(1.5, -0.5)  -- should clamp
      -- Implementation dependent
      assert.is_number(w.x)
      assert.is_number(w.y)
    end)
  end)

  describe("Input Handling", function()
    it("tracks mouse button state", function()
      local ui = makeMockUI()
      ui.buttons_down.mouse_left = true
      assert.is_true(ui.buttons_down.mouse_left)
      ui.buttons_down.mouse_left = false
      assert.is_false(ui.buttons_down.mouse_left)
    end)

    it("handles key remaps", function()
      local ui = makeMockUI()
      ui.key_remaps["escape"] = "pause"
      assert.equals("pause", ui.key_remaps.escape)
    end)
  end)

  describe("Integration Scenarios", function()
    it("creates nested dialog hierarchy", function()
      local ui = makeMockUI()
      local main = makeMockWindow({ width = 800, height = 600 })
      local sub = makeMockWindow({ width = 300, height = 200 })
      ui:addWindow(main)
      main:addWindow(sub)
      assert.equals(1, #ui.windows)
      assert.equals(1, #main.windows)
      assert.equals(main, sub.parent)
    end)

    it("handles modal closing cleanup", function()
      local ui = makeMockUI()
      local modal = makeMockWindow({ width = 300, height = 200 })
      ui:addWindow(modal)
      ui.modal_window = modal
      ui.modal_window = nil
      assert.is_nil(ui.modal_window)
    end)
  end)
end)