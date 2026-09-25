-- SCAFFOLD: VIP tour + rating and Inspector verdict (template only, not executed)
-- Mirrors: Vip:setVIPRating/goHome/onDestroy; Epidemic:handleInspectorArrival.

local VipEval = {}
VipEval.__index = VipEval

function VipEval.new()
  -- Documented fact: seed 12-rand(0,5), clamp 1..15; lower is better.
  return setmetatable({ rating = 12 - math.random(0, 5), rooms_seen = 0, room_eval = 0 }, VipEval)
end

function VipEval:observe_litter(count) -- threshold <=10 (vip.lua:259-263)
  self.rating = self.rating + (count <= 10 and -1 or 1)
end

function VipEval:observe_room(score) -- per-room decor aggregate (vip.lua:188-226)
  self.rooms_seen = self.rooms_seen + 1
  self.room_eval = self.room_eval + score
end

function VipEval:finalize() -- clamp + table lookup (vip.lua:450-454)
  local cash = { [1]=4000,[2]=2000,[3]=1500,[4]=1200,[5]=800,[6]=400,[7]=200,[8]=0 }
  self.rating = math.min(15, math.max(1, self.rating))
  return self.rating, cash[self.rating] or 0
end

local function inspector_verdict(still_infected, rep_min, evac_min)
  -- Mirrors epidemic.lua:439-508 bands (defaults 5 / 10).
  if still_infected == 0 then return "compensate" end
  if still_infected < rep_min and still_infected < evac_min then return "fine_only" end
  if still_infected < evac_min then return "fine_plus_rep" end
  return "evacuate"
end

return { VipEval = VipEval, inspector_verdict = inspector_verdict }
