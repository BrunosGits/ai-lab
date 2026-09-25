-- SCAFFOLD — win/lose groups + delayed insurance (template only, not executed)
local Criteria = { BALANCE = 2, REPUTATION = 1 } -- subset of endconditions.lua:25-35

local EndConditions = {}
function EndConditions.load(win_criteria, lose_criteria)
  local goals = { win_goals = {}, lose_goals = {} }
  for _, c in ipairs(win_criteria) do -- endconditions.lua:80-104
    goals.win_goals[c.Group] = goals.win_goals[c.Group] or {}
    goals.win_goals[c.Group][c.name] = { win_value = c.Value, max_min = c.MaxMin }
  end
  for _, c in ipairs(lose_criteria) do
    goals.lose_goals[c.Group] = goals.lose_goals[c.Group] or {}
    goals.lose_goals[c.Group][c.name] = { lose_value = c.Value, max_min = c.MaxMin }
  end
  return goals
end

function EndConditions.check(hospital, goals) -- endconditions.lua:111-130
  for _, group in pairs(goals.win_goals) do
    local met, n = 0, 0
    for name, g in pairs(group) do
      n = n + 1
      local dir = (g.max_min == 1) and 1 or -1
      if (hospital[name] - g.win_value) * dir >= 0 then met = met + 1 end
    end
    if met == n and n > 0 and hospital.loan == 0 then return "win" end
  end
  for _, group in pairs(goals.lose_goals) do
    local met, n, reason, limit = 0, 0, nil, nil
    for name, g in pairs(group) do
      n = n + 1
      local dir = (g.max_min == 1) and 1 or -1
      if (hospital[name] - g.lose_value) * dir > 0 then
        met, reason, limit = met + 1, name, g.lose_value
      end
    end
    if met == n and n > 0 then return reason, limit end
  end
  return "nothing"
end

-- hospital.lua:217-222,1452-1454,994-1004: 3 insurers x 3-month queue
local insurance_balance = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } }
local function addInsuranceMoney(company, amount)
  insurance_balance[company][1] = insurance_balance[company][1] + amount
end
local function onEndMonth_payInsurers(hospital)
  for i, queue in ipairs(insurance_balance) do
    hospital.balance = hospital.balance + queue[3]
    table.remove(queue, 3); table.insert(queue, 1, 0)
  end
end
return { EndConditions = EndConditions }
