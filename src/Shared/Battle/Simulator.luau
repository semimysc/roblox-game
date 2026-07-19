-- Shared.Battle.Simulator
-- Drives an infinite-mode run: a tick loop that advances the auto-battle,
-- emits events through the EventBus, fills ultimate energy, and resolves
-- token swaps when a card exits/recalls. Pure (no Roblox APIs) so it runs
-- server-side and under Jest.
--
-- The Simulator owns the EventBus + TokenRing and wires the DEFAULT swap
-- handler (clockwise) at tokenSwap priority. Override handlers (passives/
-- abilities) are registered by card logic at override priority and win.

local EventBus = require(script.Parent.EventBus)
local TokenRing = require(script.Parent.TokenRing)
local Combatant = require(script.Parent.Combatant)

local Simulator = {}
Simulator.__index = Simulator

function Simulator.new()
	local self = setmetatable({}, Simulator)
	self.bus = EventBus.new()
	self.ring = TokenRing.new()
	self.tick = 0
	self._wireDefaults()
	return self
end

-- Wire the default clockwise swap handler at tokenSwap priority.
function Simulator:_wireDefaults()
	self.bus:subscribe({
		event = "onAllyExit",
		priority = EventBus.PRIORITY.tokenSwap,
		handler = function(ev)
			local leaving = ev.source
			local incoming = self.ring:resolveSwap(leaving)
			if incoming then
				self.bus:emit("onEntry", incoming, nil, { swappedIn = true })
			end
		end,
	})
	-- Taking a hit charges ultimate energy (HSR-style).
	self.bus:subscribe({
		event = "onDamageTaken",
		priority = EventBus.PRIORITY.default,
		handler = function(ev)
			local c = ev.target
			if c and c.gainEnergy then
				c:gainEnergy(8)
			end
		end,
	})
	-- Acting (dealing damage) charges ultimate energy.
	self.bus:subscribe({
		event = "onDamageDealt",
		priority = EventBus.PRIORITY.default,
		handler = function(ev)
			local c = ev.source
			if c and c.gainEnergy then
				c:gainEnergy(12)
			end
		end,
	})
end

-- Set up a run from a deck: 2 active + 6 reserve across 3 tokens.
-- active = { def, def }; tokens = { {def,def}, {def,def}, {def,def} }
-- Each def is a Combatant.create arg table.
function Simulator:setup(active: { any }, tokens: { any })
	local a = Combatant.create(active[1])
	local b = Combatant.create(active[2])
	self.ring:setActive(a, b)
	for t = 1, 3 do
		for _, d in ipairs(tokens[t]) do
			local c = Combatant.create(d)
			self.ring:assign(c, t)
		end
	end
end

-- Advance one tick: pick an active attacker, deal damage to a target,
-- emit events, resolve any exits (death/recall).
function Simulator:step()
	self.tick += 1
	self.bus:emit("onTurnStart", nil, nil, { tick = self.tick })

	-- Find first alive active combatant as the actor.
	local actor = self.ring.active[1]
	if not (actor and actor.alive) then
		actor = self.ring.active[2]
	end
	if actor and actor.alive then
		-- Deal damage to the "enemy" (simulated target hp handled by caller).
		self.bus:emit("onDamageDealt", actor, nil, { amount = actor.combat.damage })
		if actor:ultimateReady() then
			self.bus:emit("onUltimateReady", actor)
		end
	end

	self.bus:emit("onTurnEnd", nil, nil, { tick = self.tick })
end

function Simulator:history() return self.bus:history() end

return Simulator
