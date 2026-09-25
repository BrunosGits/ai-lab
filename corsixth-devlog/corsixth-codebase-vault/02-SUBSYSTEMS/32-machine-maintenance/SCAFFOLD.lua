-- SCAFFOLD: machine wear -> service -> breakdown -> replace (template, not executed)
-- Mirrors entities/machine.lua core pattern in minimal form.

local MachineScaffold = {}
MachineScaffold.__index = MachineScaffold

function MachineScaffold.new(research_strength)
  return setmetatable({ strength = research_strength, times_used = 0, total = 0 }, MachineScaffold)
end

function MachineScaffold:remaining() return self.strength - self.times_used end
function MachineScaffold:needsService() return self:remaining() < 4 end -- cf. isBreaking

-- Priority mirrors callHandymanForRepairIfNecessary: <6 low, <4 high.
function MachineScaffold:servicePriority()
  if self:remaining() < 4 then return 2 end
  if self:remaining() < 6 then return 1 end
  return 0
end

function MachineScaffold:use()
  self.times_used = self.times_used + 1
  self.total = self.total + 1
  if self:remaining() < 1 then return self:rollExplosion(0) end -- extinguisher count injected
  return false
end

function MachineScaffold:rollExplosion(extinguishers)
  if extinguishers == 0 or self:remaining() < -3 then return true end
  local chance = (2 / self.strength) + (self:remaining() * -0.2)
    - (extinguishers * 0.05) + 0.05
  chance = math.min(0.95, math.max(0.05, chance))
  return math.random() < chance
end

function MachineScaffold:repair() -- cf. machineRepaired + reduceStrengthOnRepair
  if self.strength > 2 and math.random() < self.times_used / self.strength then
    self.strength = self.strength - 1
  end
  self.times_used = 0
end

function MachineScaffold:replace(cost, balance, new_strength) -- cf. replaceMachine
  assert(balance >= cost, "cannot afford replacement")
  self.total, self.times_used, self.strength = 0, 0, new_strength
end

return MachineScaffold
