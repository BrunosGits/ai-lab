-- 31 Staff Management — minimal pattern template (not executed).
-- Illustrates: fair-wage check -> tiredness/rest gate -> raise/quit timer -> fire.
local StaffMgmt = {}
StaffMgmt.__index = StaffMgmt

function StaffMgmt.new(profile, policy)
  return setmetatable({
    profile = profile, -- {wage=..., skill=0..1, getFairWage=function}
    fatigue = 0, happiness = 1,
    timer_until_raise = nil, quitting_in = nil, fired = false,
    policy = policy, -- {goto_staffroom=0.6, grant_wage_increase=false}
  }, StaffMgmt)
end

function StaffMgmt:tickDay()
  -- Documented: staff.lua:42-55 wage-vs-fair happiness delta.
  local fair = self.profile:getFairWage()
  self.happiness = self.happiness + 0.05 * (self.profile.wage - fair) / (fair ~= 0 and fair or 1)
end

function StaffMgmt:tick()
  -- Documented: staff.lua:114-144 tire + raise timer; :379-425 rest gate.
  if self.fired then return end
  if self.fatigue >= self.policy.goto_staffroom then self:goToStaffRoom() end
  self.fatigue = math.min(1, self.fatigue + 0.00009)
  if self.happiness < 0.1 then
    self.timer_until_raise = (self.timer_until_raise or 200) - 1
    if self.timer_until_raise <= 0 then self:requestRaise() end
  end
  if self.quitting_in then self:checkQuit() end
end

function StaffMgmt:goToStaffRoom() self.going_to_staffroom = true end
function StaffMgmt:requestRaise()
  self.quitting_in = 25 * 30 -- staff.lua:562-587 (simplified; real: 1/5 chance + cap)
end
function StaffMgmt:checkQuit()
  self.quitting_in = self.quitting_in - 1
  if self.quitting_in < 0 then
    if self.policy.grant_wage_increase then self:increaseWage(10) else self:fire() end
  end
end
function StaffMgmt:increaseWage(a) self.profile.wage = self.profile.wage + a; self.happiness = 1 end
function StaffMgmt:fire() self.fired = true end -- staff.lua:234-263 also: severance + kicked + despawn
return StaffMgmt
