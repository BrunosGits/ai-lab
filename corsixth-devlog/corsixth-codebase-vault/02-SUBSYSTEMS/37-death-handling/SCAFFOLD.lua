-- 37-death-handling SCAFFOLD (template only — not executed)
-- Pattern: synchronous accounting in Patient:die() + async cosmetic DieAction branch.
-- See [[37-death-handling/SUMMARY]] and M9/M11/M14-M19 in [[37-death-handling/MAP]].

local DeathHandling = {}

-- Mirrors Patient:treatDisease() → die() ordering: money first, then the roll.
function DeathHandling.onTreatmentFinished(hospital, patient, is_effective)
  hospital:receiveMoneyForTreatment(patient) -- kept even on death (M24)
  if is_effective then
    patient:cure()
    patient:goHome("cured")
  else
    DeathHandling.die(patient) -- M9/M11
  end
  hospital:paySupplierForDrug(patient.disease.id)
end

-- Mirrors Patient:die() + Hospital:humanoidDeath(): sync books, async animation.
function DeathHandling.die(patient)
  if patient.cured then return end
  patient.set_to_die = false
  patient.hospital:humanoidDeath(patient) -- counters + rep(-4) + % (M20-M22)
  patient.going_to_die = true
  patient:queueAction({ name = "meander", count = 1 })
  if DeathHandling.eligibleForReaper(patient) then
    DeathHandling.playHellDeath(patient) -- spawn hole+reaper, consume patient (M16-M18)
  else
    DeathHandling.playHeavenDeath(patient) -- rise/wings/hands/fly, then destroy (M14)
  end
end

function DeathHandling.eligibleForReaper(patient)
  -- M19: males only, no bloaty_head, 65% roll, plus map spawn-tile checks.
  return patient:isMale() and patient.disease.id ~= "bloaty_head" and math.random(1, 100) <= 65
end

function DeathHandling.playHeavenDeath(patient) end -- phase timers → despawn+destroy
function DeathHandling.playHellDeath(patient) end -- use-tile walk → UseObject(destroy_user_after_use)

return DeathHandling
