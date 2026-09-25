-- SCAFFOLD.lua — cheats + debug-patient template (NOT executed; illustrative only).
-- Pattern: per-hospital Cheats owns menu list + active toggles; Hospital owns
-- stat quarantine via `is_debug`; fax keypad routes by literal vs range match.

local Cheats = {}
Cheats.__index = Cheats

function Cheats.new(hospital)
  local self = setmetatable({}, Cheats)
  self.hospital = hospital
  self.cheat_list = { -- cf. cheats.lua:36-57 (menu buttons)
    { name = "money", func = self.cheatMoney },
    { name = "earthquake", func = self.cheatEarthquake },
  }
  self.active_cheats = {} -- cf. cheats.lua:59; toggle state only
  return self
end

function Cheats:performCheat(num) -- cf. cheats.lua:67-71
  local ok, msg = self.cheat_list[num].func(self)
  if ok == false then return false, msg end
  return true, msg
end

function Cheats:isCheatActive(name) return self.active_cheats[name] end -- cf. :342-344

function Cheats:processCheatCode(x) -- cf. cheats.lua:349-358 (range match)
  if 185.5 < x and x < 185.6 then self:toggleCheat("no_rest_cheat") return "no_rest_cheat" end
  return nil -- miss: caller plays fax_no.wav
end

function Cheats:toggleCheat(name) -- cf. cheats.lua:363-382
  if not self:isCheatActive(name) then self.active_cheats[name] = true
  else self.active_cheats[name] = nil end
  self:announceCheat(nil)
end

function Cheats:announceCheat(speech) -- cf. cheats.lua:75-85
  self.hospital.world.ui:playAnnouncement("cheat001.wav", 1) -- Critical
  if speech then self.hospital.world.ui.adviser:say(speech) end
  self.hospital.cheated = true -- forfeits win bonus; cf. world.lua:1349
end

-- Debug-patient quarantine lives in Hospital, not Patient:die.
local function recordDeath(hospital, patient) -- cf. hospital.lua:1582-1598
  if not patient.is_debug then hospital.disease_casebook.fatalities = 1 end
  hospital.num_deaths = hospital.num_deaths + 1
end

return { Cheats = Cheats, recordDeath = recordDeath }
