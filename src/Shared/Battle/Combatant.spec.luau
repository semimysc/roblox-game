-- Shared.Battle.Combatant.spec
-- Validates the HSR-style exit behaviors: eject (instant % HP loss),
-- retreat (cumulative % loss), and assist (granted by assist-token membership,
-- revoked when the card moves out).

local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Combatant = require(script.Parent.Combatant)
local TokenRing = require(script.Parent.TokenRing)

local function card(id, opts)
	opts = opts or {}
	return Combatant.create({
		id = id,
		name = id,
		kind = "token",
		element = "Physical",
		stats = { hp = 1000, atk = 20, def = 10, spd = 100, critRate = 0, critDmg = 0.5 },
		powerLevel = 1,
		originToken = opts.token or 1,
		recall = { type = "clockwise", replacesWith = nil, returnsTo = "origin" },
		abilityBar = { max = 100, regenPerTurn = 10 },
		ultimate = { id = "u", cost = 100, effects = {} },
		abilities = {},
		ejectThreshold = opts.eject or 0.3,
		retreatThreshold = opts.retreat or 0.6,
	})
end

describe("Exit behaviors", function()
	it("ejects on a single hit removing >= ejectThreshold of max HP", function()
		local c = card("A", { eject = 0.3 })
		-- max HP is log10-scaled; pool is fixed by create, so use combat.hpPool.
		local max = c.combat.hpPool
		local big = max * 0.5 -- 50% in one hit -> over 30% threshold
		local reason = c:applyDamage(big)
		expect(reason).toBe("eject")
	end)

	it("retreats on cumulative loss crossing retreatThreshold", function()
		-- eject threshold high (0.5) so small hits don't eject; retreat at 0.6.
		local c = card("A", { eject = 0.5, retreat = 0.6 })
		local max = c.combat.hpPool
		-- Two 35% hits: each under eject (0.5), but cumulative 70% > retreat (0.6).
		local r1 = c:applyDamage(max * 0.35)
		expect(r1).toBe(nil) -- 35% < 50% eject, < 60% cumulative yet
		local r2 = c:applyDamage(max * 0.35)
		expect(r2).toBe("retreat")
	end)

	it("knockout when HP reaches zero", function()
		local c = card("A")
		local reason = c:applyDamage(c.combat.hpPool + 1)
		expect(reason).toBe("knockout")
		expect(c.alive).toBe(false)
	end)

	it("assist granted only while in assist token; revoked on move", function()
		local ring = TokenRing.new()
		local c = card("A", { token = 4 })
		c.currentToken = 4
		ring:assign(c, 4)
		expect(ring:isAssist(c)).toBe(true)
		-- Move the card out of the assist token -> assist revoked.
		c:setToken(1)
		expect(ring:isAssist(c)).toBe(false)
	end)
end)
