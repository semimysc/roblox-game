-- Shared.Battle.EventBus
-- The backbone of the auto-battle. A single typed event bus with a PRIORITY
-- QUEUE so handler ordering is deterministic (critical for an auto-battler —
-- no race conditions between conditions). Conditions subscribe; handlers
-- enqueue reactions; the queue resolves in priority order.
--
-- DESIGN (from game design):
--   * An "event" is data, NOT control flow. Handlers never call each other
--     directly — they enqueue. This keeps it extensible as conditions get
--     "more specific and convoluted" later.
--   * A subscription = { event, qualifier?, handler, priority }.
--   * Overrides (passives/abilities that rewrite a recall) register at a
--     HIGHER priority tier than the default clockwise handler, so they win.
--   * Handlers may enqueue buffs or subscribe to a CATEGORY of events
--     (fan-in), satisfying the "conditions churn out buffs / encapsulate
--     queue items" requirement.
--
-- Pure Lua (no Roblox APIs) so it runs server-side AND under Jest.

export type EventName =
	"onEntry"
	| "onEnemyEntry"
	| "onEnemyDeath"
	| "onAllyExit"
	| "onRecall"
	| "onDamageTaken"
	| "onDamageDealt"
	| "onUltimateReady"
	| "onTurnStart"
	| "onTurnEnd"

export type Event = {
	name: EventName,
	-- The combatant the event is about (the one entering / exiting / hit).
	source: any?,
	-- The other party, when relevant (attacker/defender).
	target: any?,
	-- Free-form payload (damage amount, etc.).
	payload: any?,
	-- Wall-clock-ish ordering tiebreaker (monotonic counter).
	seq: number,
}

export type Subscription = {
	event: EventName,
	-- Optional predicate over the Event; if it returns false, skip.
	qualifier: ((ev: Event) -> boolean)?,
	handler: (ev: Event) -> (),
	priority: number,
}

local PRIORITY = {
	default = 100,
	tokenSwap = 200, -- recall-token resolution sits above default
	override = 500, -- passives/abilities that rewrite swaps win
}

local EventBus = {}
EventBus.__index = EventBus

EventBus.PRIORITY = PRIORITY

function EventBus.new()
	local self = setmetatable({}, EventBus)
	self._subs = {} -- [EventName] = { Subscription }
	self._queue = {} -- pending events to resolve, ordered by priority then seq
	self._seq = 0
	self._log = {} -- resolved event history (for debugging / replays)
	return self
end

function EventBus:subscribe(sub: Subscription)
	self._subs[sub.event] = self._subs[sub.event] or {}
	table.insert(self._subs[sub.event], sub)
end

-- Emit an event: enqueue it, then drain the queue in priority order.
function EventBus:emit(name: EventName, source: any?, target: any?, payload: any?)
	self._seq += 1
	local ev: Event = {
		name = name,
		source = source,
		target = target,
		payload = payload,
		seq = self._seq,
	}
	table.insert(self._queue, ev)
	self:_drain()
end

-- Drain the queue: highest priority first, then lowest seq (stable order).
function EventBus:_drain()
	while #self._queue > 0 do
		-- Find the highest-priority, lowest-seq event.
		local bestIdx, best = 1, self._queue[1]
		for i = 2, #self._queue do
			local e = self._queue[i]
			local bp = self:_prio(e)
			local cp = self:_prio(best)
			if bp > cp or (bp == cp and e.seq < best.seq) then
				bestIdx, best = i, e
			end
		end
		table.remove(self._queue, bestIdx)
		self:_dispatch(best)
	end
end

function EventBus:_prio(ev: Event): number
	-- Priority is the max priority among subscriptions that will handle it.
	local subs = self._subs[ev.name]
	if not subs then
		return 0
	end
	local p = 0
	for _, s in ipairs(subs) do
		if s.priority > p then
			p = s.priority
		end
	end
	return p
end

function EventBus:_dispatch(ev: Event)
	table.insert(self._log, ev)
	local subs = self._subs[ev.name]
	if not subs then
		return
	end
	-- Copy so handlers can subscribe/unsubscribe during dispatch safely.
	local snapshot = {}
	for _, s in ipairs(subs) do
		table.insert(snapshot, s)
	end
	table.sort(snapshot, function(a, b) return a.priority > b.priority end)
	for _, s in ipairs(snapshot) do
		if s.qualifier == nil or s.qualifier(ev) then
			s.handler(ev)
		end
	end
end

-- Test/debug helper.
function EventBus:history() return self._log end

return EventBus
