-- Shared.Battle.TokenRing
-- The Part A token system, made executable.
--
-- MODEL (from design):
--   * 4 tokens, 2 slots each. Tokens 1-3 hold 2 cards (6 reserve); token 4 is
--     the ASSIST TOKEN (initially empty). 2 cards active on field.
--   * Normal flow: tokens advance CLOCKWISE. When a slot opens, the next card
--     comes from the clockwise-neighbor token.
--   * A recall token declares { replacesWith, returnsTo }.
--   * Every card has originToken (fixed) + currentToken (mutates).
--   * ASSIST: a card in the assist token (currentToken == assistToken) gains
--     its assist passive (HSR-style off-field). Moving out REVOKES it, so
--     assist is tied to CURRENT membership, not origin.
--   * On recall a card chooses return: cross-token (token of the card it
--     swapped with) or preserve origin. This divergence = emergent play.
--
-- This module resolves WHO swaps in when a card leaves, and WHERE it goes.
-- It is pure (operates on Combatant tables); the Simulator drives it and
-- emits events through the EventBus.

local TokenRing = {}
TokenRing.__index = TokenRing

local TOKEN_COUNT = 4
local ASSIST_TOKEN = 4 -- token 4: the (initially empty) assist token

function TokenRing.new()
	local self = setmetatable({}, TokenRing)
	-- tokens[t] = { combatantA, combatantB }  (nil if empty)
	self.tokens = {}
	for t = 1, TOKEN_COUNT do
		self.tokens[t] = { nil, nil }
	end
	self.active = { nil, nil } -- 2 active slots
	return self
end

function TokenRing:clockwiseNext(from: number): number return (from % TOKEN_COUNT) + 1 end

-- Is this card currently in the assist token? (grants assist passive)
function TokenRing:isAssist(c: any): boolean return c.currentToken == ASSIST_TOKEN end

-- Fire a card's assist passive (off-field, HSR-style). No swap occurs.
function TokenRing:assist(c: any)
	if not self:isAssist(c) then
		return nil
	end
	if c.assist and c.assist.effects then
		return c.assist.effects -- engine applies these as a passive
	end
	return nil
end

-- Place a combatant into a token slot (fills first empty slot).
function TokenRing:assign(combatant, token: number)
	local slot = self.tokens[token]
	if slot[1] == nil then
		slot[1] = combatant
	elseif slot[2] == nil then
		slot[2] = combatant
	else
		-- token full; overwrite slot 2 (rare; design keeps 2 per token)
		slot[2] = combatant
	end
	combatant.currentToken = token
end

-- Set the 2 active combatants (the starters; they start OUTSIDE a token
-- but still carry a recall token, per design).
function TokenRing:setActive(a: any, b: any)
	self.active[1] = a
	self.active[2] = b
	a.active = true
	b.active = true
end

-- Find the first available reserve card, preferring the clockwise neighbor
-- of the leaving card's current token (default behavior).
function TokenRing:defaultSwapIn(leaving: any): any?
	local start = self:clockwiseNext(leaving.currentToken)
	for step = 1, TOKEN_COUNT do
		local t = (start - 1 + step) % TOKEN_COUNT + 1
		for _, c in ipairs(self.tokens[t]) do
			if c and c.alive and not c.active then
				return c, t
			end
		end
	end
	return nil
end

-- Resolve a swap when `leaving` exits/recalls.
-- Returns the incoming combatant and updates token membership.
-- `override` (optional) is a table { replacesWith = id } set by a higher-
-- priority condition handler (passive/ability), which wins over the card's
-- own recall token.
function TokenRing:resolveSwap(leaving: any, override: { replacesWith: string? }?)
	local incomingId = (override and override.replacesWith) or leaving.recall.replacesWith

	local incoming
	if incomingId then
		incoming = self:findById(incomingId)
	end
	local incomingToken
	if incoming then
		-- locate its current token
		incomingToken = incoming.currentToken
	else
		incoming, incomingToken = self:defaultSwapIn(leaving)
	end

	-- Move leaving card to its return destination.
	local dest = leaving.recall.returnsTo
	if dest == "origin" then
		dest = leaving.originToken
	end
	-- Free its old reserve slot, then place at dest (cross-token if chosen).
	self:_removeFromTokens(leaving)
	self:assign(leaving, dest)
	leaving.active = false

	-- Bring incoming onto the field.
	if incoming then
		self:_removeFromTokens(incoming)
		incoming.active = true
		-- incoming's currentToken already reflects where it sat.
	end

	return incoming
end

function TokenRing:_removeFromTokens(c: any)
	for t = 1, TOKEN_COUNT do
		local slot = self.tokens[t]
		if slot[1] == c then
			slot[1] = nil
		elseif slot[2] == c then
			slot[2] = nil
		end
	end
end

function TokenRing:findById(id: string): any?
	for t = 1, TOKEN_COUNT do
		for _, c in ipairs(self.tokens[t]) do
			if c and c.id == id then
				return c
			end
		end
	end
	for _, c in ipairs(self.active) do
		if c and c.id == id then
			return c
		end
	end
	return nil
end

return TokenRing
