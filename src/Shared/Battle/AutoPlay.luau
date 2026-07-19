-- Shared.Battle.AutoPlay
-- Drives automatic ability usage. Each card has an ABILITY POINT bar; abilities
-- cost points and are cast when:
--   * cast == "auto"  -> whenever affordable (and optional trigger true)
--   * cast == "cond"  -> only when its trigger() returns true (and affordable)
--   * cast == "manual"-> never auto (reserved for player/AI explicit control)
--
-- AutoPlay listens to battle events via the EventBus and, when a card's
-- ability is ready, spends points and enqueues its effects (declarative
-- effect descriptors resolved by the engine). This is where "conditions
-- churn out buffs / queue items" lives in practice.
--
-- Pure logic; depends on EventBus + the card's abilityBar state.

local AutoPlay = {}
AutoPlay.__index = AutoPlay

function AutoPlay.new(bus: any)
	local self = setmetatable({}, AutoPlay)
	self.bus = bus
	self._onReady = {} -- callbacks registered by Simulator per ability cast
	return self
end

-- Register a card's abilities to auto-evaluate on a given event.
-- handlers: { [EventName] = function(card, eventCtx) }
function AutoPlay:watch(card: any, eventName: string, handler: (any, any) -> ())
	self.bus:subscribe({
		event = eventName,
		priority = 150, -- below token-swap override (200), above default (100)
		qualifier = function(ev) return ev.source == card or ev.target == card end,
		handler = function(ev) handler(card, ev) end,
	})
end

-- Try to cast an ability: spend points if affordable + condition met.
-- Returns true if cast. `castFn(ability)` performs the actual effect.
function AutoPlay:tryCast(card: any, ability: any, ctx: any?, castFn: (any) -> ()): boolean
	if ability.cast == "manual" then
		return false
	end
	local bar = card.abilityBar
	if bar.points < ability.cost then
		return false
	end
	if ability.trigger and not ability.trigger(ctx or {}) then
		return false
	end
	bar.points -= ability.cost
	castFn(ability)
	return true
end

-- Regen a card's ability points at the start of its turn.
function AutoPlay:regen(card: any)
	local bar = card.abilityBar
	bar.points = math.min(bar.max, bar.points + bar.regenPerTurn)
end

return AutoPlay
