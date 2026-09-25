--- 39-calendar-payday SCAFFOLD (template only: never executed).
--- Core pattern: immutable clock -> day/month/year cascade ->
--- accrue-daily / settle-monthly -> snapshot stats.
local Date = require("date") -- immutable; plusHours returns a new Date

local Payday = {}
Payday.__index = Payday

function Payday:new()
  return setmetatable({
    date = Date(1, 1, 1, 0),
    acc_heating = 0, acc_interest = 0, acc_research = 0,
    money_in = 0, money_out = 0,
    insurance = { { 0, 0, 0 } }, -- [1]=this mo [3]=payable; shift monthly
    statistics = {},
  }, self)
end

function Payday:onTick(hours_per_tick)
  local next_date = self.date:plusHours(hours_per_tick)
  if self.date:dayOfMonth() ~= next_date:dayOfMonth() then
    self:onEndDay() -- accrue into acc_* (no spendMoney here)
    if self.date:isLastDayOfMonth() then
      self:onEndMonth() -- settle: spend, zero, shift, snapshot
      if self.date:isLastDayOfYear() then self:onEndYear() end
    end
  end
  self.date = next_date
end

function Payday:onEndDay()
  self.acc_heating = self.acc_heating + 10 -- daily slice of monthly cost
end

function Payday:onEndMonth()
  self:spend(self.acc_heating, "heating"); self.acc_heating = 0
  local pay = self.insurance[1][3] -- 2-month delay: pay oldest slot
  if pay > 0 then self:receive(pay, "insurance") end
  table.remove(self.insurance[1], 3)
  table.insert(self.insurance[1], 1, 0)
  self.statistics[self.date:monthOfGame() + 1] = { money_out = self.money_out }
  self.money_in, self.money_out = 0, 0
end

function Payday:onEndYear() end -- reset yearly counters AFTER report reads them
function Payday:spend(a, r) self.money_out = self.money_out + a end
function Payday:receive(a, r) self.money_in = self.money_in + a end
return Payday
