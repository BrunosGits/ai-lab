--[[ Debugger Scaffold for CorsixTH
Usage: Copy this scaffold to test debugging setup.

1. For ZeroBrane: add MobDebug bootstrap to CorsixTH.lua as in SUMMARY.md
2. For debugger.lua: add local dbg = require('debugger') and dbg() where needed
3. For Eclipse: set debug = true in config and use debug_script.lua
4. For Live Reload: use self:reloadFile

This file is a template, not executed. Replace with your test code.
]]

-- Example debug script for Eclipse
local function doubleNumber(var)
  return var * 2
end

print("\nBefore loop.\n")

for counter_one = 1, 4, 1 do
  print("Counter = " .. counter_one)
  local doubled = doubleNumber(counter_one)
  print("Counter x 2 = " .. doubled)
  print("----------------")
end

-- Example for debugger.lua
-- local dbg = require('debugger')
-- dbg()

-- Example for Live Reload
-- function UIBottomPanel:dialogStatus()
--   self:reloadFile("dialogs/fullscreen/progress_report.lua")
--   self:addDialog(UIProgressReport(self.ui))
-- end
