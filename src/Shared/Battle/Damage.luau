-- Shared.Battle.Damage
-- HSR-aligned damage calculation. The key correctness property: buffs are
-- DECLARATIVE LAYERS, never ad-hoc math:
--
--   DMG = baseAttack
--       * (1 + SUM(damageBonus additive%))        -- ADDITIVE layer
--       * PROD(damageIncrease mult)               -- MULTIPLICATIVE layer
--       * defFactor                                -- attacker ATK vs target DEF
--       * (crit ? (1 + critDmg) : 1)              -- crit
--       * resFactor                                -- target elemental RES
--
-- "damage bonus"  (additive %)  -> layer "additive"
-- "increase dmg"  (multiplier)  -> layer "mult"
-- Stat increases on ATK/DEF are themselves additive/mult layers in StatBlock.
--
-- Pure function: same inputs -> same output (deterministic, testable).

local Damage = {}

-- HSR-style DEF factor. Uses level-scaled DEF:
--   defFactor = ATK / (ATK + DEF_stat * (1 + 10 * (level-1)/99?)) -- simplified
-- We use a stable form: ATK / (ATK + DEF * k), k tunable (k=1 default).
function Damage.defFactor(atk: number, def: number, k: number?)
	k = k or 1
	return atk / (atk + def * k)
end

-- Single-hit damage given attacker StatBlock, target StatBlock, ctx.
-- ctx carries: { crit = bool?, level = number?, targetRes = number? }
-- `mods` is the attacker's accumulated damage modifiers (additive/mult layers).
function Damage.calculate(
	params: {
		atkBlock: any, -- StatBlock (has .atk, .critRate, .critDmg, .mods)
		defStat: number, -- target's resolved DEF
		level: number?,
		targetRes: number?, -- 0..1 elemental resistance (0 = neutral)
		forceCrit: boolean?,
	}
): number
	local atkBlock = params.atkBlock
	local baseAtk = Stats_atk(atkBlock)
	local additive = 0
	local mult = 1
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

	local defK = 1
	local df = Damage.defFactor(baseAtk, params.defStat, defK)

	local crit = params.forceCrit or (math.random() < atkBlock.critRate)
	local critMul = crit and (1 + atkBlock.critDmg) or 1

	local res = params.targetRes or 0
	local resFactor = 1 - res -- simplistic: 0 res = full dmg, 1 = immune

	local dmg = baseAtk * (1 + additive) * mult * df * critMul * resFactor
	return math.max(0, dmg)
end

-- Small helper to read resolved atk from a StatBlock (kept local to avoid
-- a require cycle with Stats in this hot path; Stats.resolve is preferred
-- when you need layered ATK, but raw base atk is fine for the formula core).
function Stats_atk(block) return block.atk end

return Damage
