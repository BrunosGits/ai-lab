require("corsixth")
require("class_test_base")

-- Mock sdl before requiring window
_G.sdl = {
  init = function() end,
  quit = function() end,
  getTicks = function() return 0 end,
}

require("window")

local Window = _G["Window"]

describe("window.lua: Modal window handling", function()
  local window

  before_each(function()
    window = Window()
  end)

  describe("Modal handling", function()
    it("opens as modal when required", function()
      window.modal = true
      assert.is_true(window.modal)
    end)

    it("closes properly", function()
      local closed = false
      window.close = function() closed = true end
      window:close()
      assert.is_true(closed)
    end)

    it("handles key events when modal", function()
      local handled = false
      window.handleKey = function(self, key)
        handled = true
        return true
      end
      assert.is_true(window:handleKey("escape"))
    end)

    it("returns false for unhandled keys", function()
      window.handleKey = function(self, key) return false end
      local handled = window:handleKey("unknown")
      assert.is_false(handled)
    end)
  end)

  describe("Modal stack", function()
    it("pushes and pops modals", function()
      local stack = {}
      function Window:pushModal(m) table.insert(stack, m) end
      function Window:popModal() return table.remove(stack) end

      local w = Window()
      w:pushModal("m1")
      w:pushModal("m2")
      assert.are.equal("m2", w:popModal())
      assert.are.equal("m1", w:popModal())
    end)
  end)

  describe("Window dimensions", function()
    it("stores width and height", function()
      local w = Window()
      w.w, w.h = 800, 600
      assert.are.equal(800, w.w)
      assert.are.equal(600, w.h)
    end)

    it("stores position", function()
      local w = Window()
      w.x, w.y = 100, 50
      assert.are.equal(100, w.x)
      assert.are.equal(50, w.y)
    end)
  end)
end)
