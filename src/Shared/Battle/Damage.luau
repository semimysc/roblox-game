-- Shared.Battle.Damage
-- HSR-aligned damage with anomaly + resistance layers. Core correctness:
--   * "damage bonus" (additive %) and "increase dmg" (multiplier) are SEPARATE
--     declarative layers (see Stats.lua) — no ad-hoc math.
--   * Anomaly procs on MASSIVE damage (ZZZ-style): if a single hit's fraction
--     of the target's max HP exceeds ANOMALY_THRESHOLD, an anomaly of the
--     attacker's element fires (player side only; enemies have no anomalies).
--   * Weakness: if attacker element == target.weakness, multiply (super-effective).
--
-- Pure + deterministic (RNG only for crit, which caller controls via forceCrit).

local Damage = {}

-- Config (data-driven; tune later).
Damage.ANOMALY_THRESHOLD = 0.25 -- a hit >= 25% of target max HP procs anomaly
Damage.WEAKNESS_MULT = 1.5

function Damage.defFactor(atk: number, defStat: number, k: number?)
	k = k or 1
	return atk / (atk + defStat * k)
end

-- Returns { amount: number, crit: bool, anomaly: string? }
function Damage.calculate(
	params: {
		atkBlock: any, -- StatBlock (atk, critRate, critDmg, mods["damage"])
		defStat: number, -- target resolved DEF
		target: any?, -- for weakness/anomaly (has .weakness, .combat.hpPool)
		forceCrit: boolean?,
	}
): { amount: number, crit: boolean, anomaly: string? }
	local atkBlock = params.atkBlock
	local baseAtk = atkBlock.atk
	local additive, mult = 0, 1
	for _, m in pairs(atkBlock.mods) do
		if m.stat ~= "damage" then
			continue
		end
		if m.layer == "additive" then
			additive += m.value
		elseif m.layer == "mult" then
			mult *= m.value
		end
	end

	local df = Damage.defFactor(baseAtk, params.defStat, 1)
	local crit = params.forceCrit or (math.random() < atkBlock.critRate)
	local critMul = crit and (1 + atkBlock.critDmg) or 1

	local amount = baseAtk * (1 + additive) * mult * df * critMul
	amount = math.max(0, amount)

	-- Weakness (super-effective vs target type).
	local target = params.target
	if target and target.weakness and target.weakness == atkBlock.element then
		amount *= Damage.WEAKNESS_MULT
	end

	-- Anomaly proc: massive single hit -> anomaly of attacker element (player only).
	local anomaly
	if target and target.combat and target.combat.hpPool > 0 then
		local frac = amount / target.combat.hpPool
		if frac >= Damage.ANOMALY_THRESHOLD and atkBlock.element ~= "Void" then
			anomaly = atkBlock.element -- player-side element procs its anomaly
		end
	end

	return { amount = amount, crit = crit, anomaly = anomaly }
end

return Damage
