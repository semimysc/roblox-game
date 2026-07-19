-- Shared.Battle.Combatant
-- Runtime state of one card/character in battle. Pure data + small methods;
-- no Roblox APIs. The engine (Simulator/TokenRing) reads and mutates this.
--
-- Stats model (from game design):
--   * base stats  -> auth/selection screen (Mihoyo-like sheet)
--   * combat stats -> the IN-BATTLE HP-pool and damage, SEPARATE from base,
--     and scaled by log10 of the card's power level (not linear).
--   * Ultimate energy -> HSR-style: fills by acting + taking hits.
--   * Token tags -> originToken (fixed) + currentToken (mutates on swaps).
--   * Recall token -> { replacesWith, returnsTo } declared by the card.

export type RecallToken = {
	-- Which card id swaps in when THIS card leaves.
	replacesWith: string?,
	-- Where THIS card returns to: "origin" (its natural token) or a
	-- specific token index (cross-token migration for emergent play).
	returnsTo: "origin" | number,
}

export type Combatant = {
	id: string,
	name: string,
	-- Base (selection-screen) sheet.
	base: {
		hp: number,
		atk: number,
		def: number,
		spd: number,
	},
	-- Combat-only stats (separate from base; log10-scaled by power).
	combat: {
		hpPool: number,
		hpCurrent: number,
		damage: number,
	},
	-- Ultimate energy (0..energyMax).
	energy: number,
	energyMax: number,
	-- Token identity (Part A dual-tag model).
	originToken: number, -- fixed from setup (1..3)
	currentToken: number, -- mutates as swaps happen
	-- Recall rule (every combatant has one).
	recall: RecallToken,
	-- Slot state.
	active: boolean, -- on battlefield vs reserve
	alive: boolean,
}

local Combatant = {}
Combatant.__index = Combatant

-- powerLevel: the card's "tier" strength (drives log10 combat scaling).
-- logScale: combat stat = baseStat * (1 + k * log10(1 + powerLevel)).
local function logScale(base: number, powerLevel: number, k: number): number
	return base * (1 + k * math.log10(1 + powerLevel))
end

function Combatant.create(def: {
	id: string,
	name: string,
	base: { hp: number, atk: number, def: number, spd: number },
	powerLevel: number,
	originToken: number,
	recall: RecallToken?,
	energyMax: number?,
}): Combatant
	local power = def.powerLevel or 1
	local combatHp = logScale(def.base.hp, power, 0.5)
	local combatDmg = logScale(def.base.atk, power, 0.5)

	local self: Combatant = {
		id = def.id,
		name = def.name,
		base = def.base,
		combat = {
			hpPool = combatHp,
			hpCurrent = combatHp,
			damage = combatDmg,
		},
		energy = 0,
		energyMax = def.energyMax or 100,
		originToken = def.originToken,
		currentToken = def.originToken,
		recall = def.recall or { replacesWith = nil, returnsTo = "origin" },
		active = false,
		alive = true,
	}
	setmetatable(self, Combatant)
	return self
end

-- HSR-style energy gain.
function Combatant:gainEnergy(amount: number) self.energy = math.min(self.energyMax, self.energy + amount) end

function Combatant:ultimateReady(): boolean return self.energy >= self.energyMax end

function Combatant:takeDamage(amount: number)
	self.combat.hpCurrent = math.max(0, self.combat.hpCurrent - amount)
	if self.combat.hpCurrent <= 0 then
		self.alive = false
	end
end

function Combatant:heal(amount: number)
	self.combat.hpCurrent = math.min(self.combat.hpPool, self.combat.hpCurrent + amount)
end

-- Move to a different token (mutates currentToken only; originToken fixed).
function Combatant:setToken(token: number) self.currentToken = token end

return Combatant
