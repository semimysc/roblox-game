-- Shared.Battle.Enemy
-- PvE enemy combatant. Reuses the Combatant runtime but with enemy-specific
-- rules (from game design):
--   * NO retreat / eject (only the player side has those exit behaviors).
--   * STAGGERABLE: a stagger meter fills from big hits; at full, the enemy is
--     stunned (skips turns) for a duration.
--   * HAS attacks, passives, abilities, and ultimates (same kit shape as a card).
--   * NO anomalies: enemies neither proc nor are weak to anomalies (player
--     side procs anomalies on them; type WEAKNESS is on the enemy).
--
-- Pure data + methods; no Roblox APIs.

local Combatant = require(script.Parent.Combatant)

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Combatant })

function Enemy.create(
	def: {
		id: string,
		name: string,
		element: string, -- for RESISTANCE calc (not anomaly)
		stats: { hp: number, atk: number, def: number, spd: number, critRate: number?, critDmg: number? },
		powerLevel: number,
		weakness: string?, -- optional type the player's anomaly exploits
		ultimate: any,
		abilities: { any },
		passive: any?,
		staggerMax: number?,
	}
): any
	local c = Combatant.create({
		id = def.id,
		name = def.name,
		kind = "token", -- enemies occupy a slot-like position; no token ring
		element = def.element,
		stats = def.stats,
		powerLevel = def.powerLevel,
		originToken = nil,
		recall = { type = "knockout", replacesWith = nil, returnsTo = "origin" },
		abilityBar = { max = 0, regenPerTurn = 0 }, -- enemies use ult/abilities on cooldown, not AP
		ultimate = def.ultimate,
		abilities = def.abilities,
		passive = def.passive,
		assist = nil,
	})
	-- Enemy-only fields.
	c.faction = "enemy"
	c.weakness = def.weakness
	c.stagger = 0
	c.staggerMax = def.staggerMax or 100
	c.staggered = false
	-- Enemies do NOT use player exit behaviors.
	c.ejectThreshold = math.huge
	c.retreatThreshold = math.huge
	setmetatable(c, Enemy)
	return c
end

-- Apply a hit; fills stagger from the damage fraction. Returns the same
-- exit reason as Combatant (knockout only, since thresholds are huge).
function Enemy:applyDamage(amount: number): string?
	local reason = Combatant.applyDamage(self, amount)
	-- Stagger builds from % HP lost this hit.
	local frac = amount / self.combat.hpPool
	self.stagger = math.min(self.staggerMax, self.stagger + frac * self.staggerMax)
	if self.stagger >= self.staggerMax then
		self.staggered = true
	end
	return reason
end

function Enemy:reduceStagger(amount: number)
	self.stagger = math.max(0, self.stagger - amount)
	if self.stagger <= 0 then
		self.staggered = false
	end
end

function Enemy:isStaggered(): boolean return self.staggered end

return Enemy
