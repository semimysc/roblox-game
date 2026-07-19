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
local SpeedQueue = require(script.Parent.SpeedQueue)
local AutoPlay = require(script.Parent.AutoPlay)

local Simulator = {}
Simulator.__index = Simulator

function Simulator.new()
	local self = setmetatable({}, Simulator)
	self.bus = EventBus.new()
	self.ring = TokenRing.new()
	self.speed = SpeedQueue.new() -- HSR action-value turn order
	self.autoPlay = AutoPlay.new(self.bus) -- ability auto-cast on conditions
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
	-- Taking a hit: apply damage, charge ultimate energy, and emit an exit
	-- event if the hit triggers knockout / eject / retreat. The exit REASON
	-- drives which condition/passive resolves the swap (all via token recall).
	self.bus:subscribe({
		event = "onDamageTaken",
		priority = EventBus.PRIORITY.default,
		handler = function(ev)
			local c = ev.target
			if not (c and c.applyDamage) then
				return
			end
			local reason = c:applyDamage(ev.payload and ev.payload.amount or 0)
			c:gainEnergy(8) -- HSR-style: taking a hit charges ult
			if reason ~= nil then
				-- onAllyExit with reason; token-swap handler resolves the
				-- incoming card via this card's chosen recall behavior.
				self.bus:emit("onAllyExit", c, ev.source, {
					reason = reason, -- "knockout" | "eject" | "retreat"
					forced = reason ~= "knockout", -- eject/retreat are involuntary
				})
				if not c.alive and reason == "knockout" then
					self.bus:emit("onEnemyDeath", c)
				end
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

-- Set up a run: 2 active + 6 reserve in tokens 1-3 (token 4 = empty assist
-- token). active = { def, def }; tokens = { {def,def}, {def,def}, {def,def} }.
-- Each def is a Combatant.create arg table (minus originToken, assigned here).
function Simulator:setup(active: { any }, tokens: { any })
	local a = Combatant.create(active[1])
	local b = Combatant.create(active[2])
	self.ring:setActive(a, b)
	self.speed:add(a, a.stats.spd)
	self.speed:add(b, b.stats.spd)
	for t = 1, 3 do
		for _, d in ipairs(tokens[t]) do
			local c = Combatant.create(d)
			c.originToken = t
			c.currentToken = t
			self.ring:assign(c, t)
			self.speed:add(c, c.stats.spd)
		end
	end
	-- Token 4 (assist) starts empty by design.
end

-- Advance one tick: the speed-ordered actor deals damage, emits events,
-- resolves any exits (eject/retreat/knockout) via the token-recall handler.
function Simulator:step()
	self.tick += 1
	self.bus:emit("onTurnStart", nil, nil, { tick = self.tick })

	-- Pop the next actor by action value (HSR speed order).
	local actor = self.speed:popNext()
	-- Fall back to any alive active if the queue is empty (no enemies queued).
	if actor == nil then
		actor = self.ring.active[1]
		if not (actor and actor.alive) then
			actor = self.ring.active[2]
		end
	end
	if actor and actor.alive then
		self.speed:add(actor, actor.stats.spd) -- re-queue for next turn
		-- Deal damage (simulated enemy target; caller applies to real target).
		self.bus:emit("onDamageDealt", actor, nil, { amount = actor.combat.damage })
		if actor:ultimateReady() then
			self.bus:emit("onUltimateReady", actor)
		end
		-- AutoPlay: try abilities on this card's turn.
		self.autoPlay = self.autoPlay
	end

	self.bus:emit("onTurnEnd", nil, nil, { tick = self.tick })
end

function Simulator:history() return self.bus:history() end

return Simulator
