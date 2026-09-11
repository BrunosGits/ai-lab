--[[ Lua Object Scaffold
Usage: Copy this scaffold to create a new object.

This file is a template, not executed. Replace with your object.
]]

local object = {}
object.id = "my_object"
object.thob = 99
object.name = "My Object"
object.tooltip = "A custom object"
object.ticks = false
object.orientations = {
  north = {
    footprint = {{0, 0, complete_cell = true}},
    use_position = {0, 0},
  }
}
return object
