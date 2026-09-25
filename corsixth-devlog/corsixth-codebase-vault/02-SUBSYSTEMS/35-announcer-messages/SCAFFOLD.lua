-- SCAFFOLD: announcer + fax core pattern (template only, not executed).
-- Mirrors CorsixTH/Lua/announcer.lua, dialogs/bottom_panel.lua,
-- dialogs/message.lua, dialogs/fullscreen/fax.lua.

local Priority = { Critical = 1, High = 2, Normal = 3, Low = 4 }
local DecayH = { [1] = -1, [2] = 31 * 24, [3] = 7 * 24, [4] = 3 * 24 }

local Queue = {}
function Queue:new()
  return setmetatable({ buckets = { {}, {}, {}, {} }, count = 0 }, { __index = self })
end
function Queue:push(p, e) table.insert(self.buckets[p], e) self.count = self.count + 1 end
function Queue:pop() -- highest priority first (announcer.lua:73)
  for _, b in ipairs(self.buckets) do
    if b[1] then self.count = self.count - 1 return table.remove(b, 1) end
  end
end
function Queue:dedup(name, date) -- refresh created_date (announcer.lua:93)
  for _, b in ipairs(self.buckets) do
    for _, e in ipairs(b) do if e.name == name then e.created = date return true end end
  end
  return false
end

local Announcer = {}
function Announcer:request(name, prio, hasDesk) -- gate (announcer.lua:178)
  prio = prio or Priority.Normal
  if self.queue:dedup(name, self:date()) then return end
  if hasDesk or prio == Priority.Critical then
    self.queue:push(prio, { name = name, prio = prio, created = self:date(), decay = DecayH[prio] })
  end
end

local FaxRouter = {} -- UIFax:choice dispatch (fax.lua:135)
FaxRouter.handlers = {
  accept_vip = function(ctx) ctx.world:spawnVIP(ctx.info.name) end,
  refuse_vip = function(ctx) ctx.world:nextVip() end,
  declare_epidemic = function(ctx) ctx.epidemic:resolveDeclaration() end,
  cover_up_epidemic = function(ctx) ctx.epidemic:startCoverUp() end,
}
function FaxRouter:choose(choice, ctx) -- always removeMessage+close after
  local h = self.handlers[choice]
  if h then h(ctx) end
  ctx.icon:removeMessage()
end

local BottomPanel = {}
function BottomPanel:queueMessage(fax) -- mutual exclusion (bottom_panel.lua:504)
  if fax.type == "epidemy" and self:hasQueued("emergency") then return self:cancel("epidemy") end
  if fax.type == "emergency" and self:hasQueued("epidemy") then return self:cancel("emergency") end
  table.insert(self.queue, fax)
end
