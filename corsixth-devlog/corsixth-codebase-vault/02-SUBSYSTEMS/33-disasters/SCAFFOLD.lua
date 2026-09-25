-- SCAFFOLD.lua — disaster tick template (NOT executed; illustrative only).
-- Pattern: World owns scheduler; Hospital owns victim state; UI owns feel.

local Disaster = {}
Disaster.__index = Disaster

function Disaster.new(world)
  local self = setmetatable({}, Disaster)
  self.world = world
  self.active = false
  self.warning_timer = 600 -- hours of warning before damage
  self.damage_timer = 16   -- hours between damage waves
  self.remaining = 0       -- waves left; cf. earthquake `size`
  self.disabled = false    -- cheat toggle gates tick + arming
  return self
end

function Disaster:plan(severity) -- cf. Earthquake:nextEarthquake
  self.remaining = severity
  self.damage_timer = 16
  self.warning_timer = 600
end

function Disaster:onEndDay() -- cf. Earthquake:onEndDay via World:onEndDay
  if self.disabled then return end
  -- if date matches level script: self.active = true
end

function Disaster:tick() -- cf. Earthquake:tick via World:tick (not paused)
  if not self.active or self.disabled then return end
  local hosp = self.world:getLocalPlayerHospital()
  if self.remaining == 0 then
    self.active = false
    hosp:tickEarthquake("end")
    return
  end
  if self.warning_timer > 0 then
    self.warning_timer = self.warning_timer - self.world.hours_per_tick
    return -- no damage during warning window
  end
  self.damage_timer = self.damage_timer - self.world.hours_per_tick
  if self.damage_timer > 0 then return end
  for _, room in pairs(self.world.rooms) do
    for object, _ in pairs(room.objects) do
      if object:isMachine() then object:earthquakeImpact(room) end
    end
  end
  self.remaining = self.remaining - 1
  self.damage_timer = self.damage_timer + 16
end

return Disaster
