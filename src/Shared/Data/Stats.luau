-- Shared.Data.Stats
-- The declarative stat + buff model. Everything that modifies a number goes
-- through here so buffs are DATA, not scattered math.
--
-- DESIGN (from game design):
--   * Stats are HSR/ZZZ-shaped: HP, ATK, DEF, SPD, CritRate, CritDMG, plus
--     elemental/anomaly typing (anomaly mechanics under our own name).
--   * Buffs are DECLARATIVE and LAYERED. Critically:
--       - "damage bonus"  = ADDITIVE percentage  (1 + sum of all bonuses)
--       - "increase dmg"  = MULTIPLICATIVE       (product of all increases)
--     Keeping these as separate layers is what makes HSR-style calc correct
--     and prevents the classic "additive vs multiplicative" ordering bugs.
--   * A StatBlock holds BASE values + accumulates MODIFIERS from buffs.
--     resolve() flattens base + modifiers into final combat numbers.

-- Elemental typing (HSR elements / ZZZ attributes, our own names later).
export type Element = "Physical" | "Fire" | "Ice" | "Lightning" | "Wind" | "Quantum" | "Imaginary" | "Void" -- our anomaly-equivalent placeholder

-- A modifier on a named stat. Layer decides how it combines.
export type Modifier = {
	id: string, -- source id (ability/passive/buff) for dedup/removal
	stat: string, -- stat key this touches, e.g. "damage", "atk", "spd"
	-- ADDITIVE = adds a flat or percentage to the additive layer.
	-- MULT    = multiplies the final value (product).
	layer: "additive" | "mult",
	-- Percent modifiers are expressed as fractions (0.5 = +50%).
	value: number,
	-- Optional condition gate (e.g. only vs anomaly-affected enemy).
	condition: ((ctx: any) -> boolean)?,
}

export type StatBlock = {
	-- Base (authored) values.
	hp: number,
	atk: number,
	def: number,
	spd: number,
	critRate: number, -- 0..1
	critDmg: number, -- 0..N (e.g. 0.5 = +50%)
	element: Element,
	-- Accumulated modifiers (data, not applied yet).
	mods: { [string]: Modifier },
}

local Stats = {}

function Stats.new(base: {
	hp: number,
	atk: number,
	def: number,
	spd: number,
	critRate: number?,
	critDmg: number?,
	element: Element,
}): StatBlock
	return {
		hp = base.hp,
		atk = base.atk,
		def = base.def,
		spd = base.spd,
		critRate = base.critRate or 0.05,
		critDmg = base.critDmg or 0.5,
		element = base.element,
		mods = {},
	}
end

-- Add a modifier (replaces any with same id).
function Stats.addModifier(block: StatBlock, mod: Modifier) block.mods[mod.id] = mod end

function Stats.removeModifier(block: StatBlock, id: string) block.mods[id] = nil end

-- Resolve a stat through its additive + multiplicative layers.
-- Returns base * (1 + sum(additive)) * prod(mult). Percentage mods use
-- `value` as a fraction of the base contribution they target.
function Stats.resolve(block: StatBlock, stat: string, ctx: any?): number
	local base = (block :: any)[stat]
	if base == nil then
		base = 0
	end
	local additiveSum = 0
	local multProd = 1
	for _, m in pairs(block.mods) do
		if m.stat ~= stat then
			continue
		end
		if m.condition and ctx and not m.condition(ctx) then
			continue
		end
		if m.layer == "additive" then
			additiveSum += m.value
		elseif m.layer == "mult" then
			multProd *= m.value
		end
	end
	return base * (1 + additiveSum) * multProd
end

return Stats
