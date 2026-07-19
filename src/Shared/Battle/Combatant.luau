-- Shared.Battle.Combatant
-- Runtime state of one card/character in battle. Pure data + small methods;
-- no Roblox APIs. Built FROM a CardDef (see Data.CardDef).
--
-- Stats model (from game design):
--   * StatBlock (declarative, HSR/ZZZ-shaped) holds base + accumulated mods.
--     resolve() flattens base + modifiers into final combat numbers.
--   * Combat HP-pool/damage are SEPARATE from base selection-screen stats and
--     scaled by log10 of powerLevel.
--   * Ultimate energy (HSR-style): fills by acting + taking hits.
--   * Ability points: per-character bar, spent by AutoPlay on abilities.
--   * Token identity (Part A dual-tag): originToken (fixed) + currentToken
--     (mutable). Leaders have NO token.
--   * Recall: a recall TYPE (clockwise/specified/conditional) + returnsTo.
--   * Exit behaviors: eject (instant % HP loss), retreat (cumulative % HP
--     lost). Both resolved via the recall behavior.
--   * Assist: a card in the assist token (currentToken == assistToken) gains
--     its assist passive (HSR-style off-field). Moving out REVOKES it.

local Stats = require(script.Parent.Parent.Data.Stats)

local Combatant = {}
Combatant.__index = Combatant

-- log10 combat scaling: combatStat = baseStat * (1 + k*log10(1+power)).
local function logScale(base: number, power: number, k: number): number return base * (1 + k * math.log10(1 + power)) end

function Combatant.create(def: {
	id: string,
	name: string,
	kind: "leader" | "token",
	element: string,
	stats: { hp: number, atk: number, def: number, spd: number, critRate: number?, critDmg: number? },
	powerLevel: number,
	originToken: number?,
	recall: { type: string, replacesWith: string?, returnsTo: any },
	abilityBar: { max: number, regenPerTurn: number },
	ultimate: any,
	abilities: { any },
	passive: any?,
	assist: any?,
}): Combatant
	local power = def.powerLevel or 1
	local block = Stats.new({
		hp = def.stats.hp,
		atk = def.stats.atk,
		def = def.stats.def,
		spd = def.stats.spd,
		critRate = def.stats.critRate,
		critDmg = def.stats.critDmg,
		element = def.element,
	})
	local combatHp = logScale(def.stats.hp, power, 0.5)
	local combatDmg = logScale(def.stats.atk, power, 0.5)

	local self: Combatant = {
		id = def.id,
		name = def.name,
		kind = def.kind,
		element = def.element,
		stats = block,
		combat = {
			hpPool = combatHp,
			hpCurrent = combatHp,
			damage = combatDmg,
		},
		energy = 0,
		energyMax = 100,
		abilityBar = {
			max = def.abilityBar.max,
			points = def.abilityBar.max, -- start full
			regenPerTurn = def.abilityBar.regenPerTurn,
		},
		originToken = def.originToken,
		currentToken = def.originToken,
		recall = def.recall,
		ejectThreshold = def.ejectThreshold or 0.3, -- instant % HP loss -> eject
		retreatThreshold = def.retreatThreshold or 0.6, -- cumulative % HP lost -> retreat
		cumulativeLost = 0,
		active = false,
		alive = true,
		ultimate = def.ultimate,
		abilities = def.abilities,
		passive = def.passive,
		assist = def.assist,
	}
	setmetatable(self, Combatant)
	return self
end

-- HSR-style ultimate energy gain.
function Combatant:gainEnergy(amount: number) self.energy = math.min(self.energyMax, self.energy + amount) end

function Combatant:ultimateReady(): boolean return self.energy >= self.energyMax end

-- Apply damage and return the exit REASON (if any), as conditions use it.
-- Returns nil | "knockout" | "eject" | "retreat".
function Combatant:applyDamage(amount: number): string?
	local before = self.combat.hpCurrent
	self.combat.hpCurrent = math.max(0, self.combat.hpCurrent - amount)
	self.cumulativeLost += amount
	local maxHp = self.combat.hpPool

	local instantFrac = amount / maxHp
	local cumulativeFrac = self.cumulativeLost / maxHp

	if self.combat.hpCurrent <= 0 then
		self.alive = false
		return "knockout"
	elseif instantFrac >= self.ejectThreshold then
		return "eject"
	elseif cumulativeFrac >= self.retreatThreshold then
		return "retreat"
	end
	return nil
end

function Combatant:heal(amount: number)
	self.combat.hpCurrent = math.min(self.combat.hpPool, self.combat.hpCurrent + amount)
end

-- Move to a different token (mutates currentToken only; originToken fixed).
function Combatant:setToken(token: number) self.currentToken = token end

return Combatant
