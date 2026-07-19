-- Shared.Battle.Simulator.spec
-- Validates the core battle engine: token swap resolution, dual-tag
-- migration, and HSR-style ultimate energy. Pure-logic test (no Roblox).

local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Simulator = require(script.Parent.Simulator)
local Combatant = require(script.Parent.Combatant)

local function cardDef(id, token)
	return {
		id = id,
		name = id,
		base = { hp = 100, atk = 20, def = 10, spd = 5 },
		powerLevel = 1,
		originToken = token,
		recall = { replacesWith = nil, returnsTo = "origin" },
	}
end

describe("Battle engine", function()
	it("loads 2 active + 6 reserve across 3 tokens", function()
		local sim = Simulator.new()
		sim:setup({ cardDef("A1", 1), cardDef("A2", 1) }, {
			{ cardDef("T1a", 1), cardDef("T1b", 1) },
			{ cardDef("T2a", 2), cardDef("T2b", 2) },
			{ cardDef("T3a", 3), cardDef("T3b", 3) },
		})
		expect(sim.ring.active[1].id).toBe("A1")
		expect(sim.ring.active[2].id).toBe("A2")
		expect(sim.ring:findById("T3b").currentToken).toBe(3)
	end)

	it("default swap pulls from clockwise neighbor token", function()
		local sim = Simulator.new()
		sim:setup({ cardDef("A1", 1), cardDef("A2", 1) }, {
			{ cardDef("T1a", 1), cardDef("T1b", 1) },
			{ cardDef("T2a", 2), cardDef("T2b", 2) },
			{ cardDef("T3a", 3), cardDef("T3b", 3) },
		})
		-- A1 is active, originToken 1. On exit, default swap comes from
		-- clockwise neighbor (token 2 first), so T2a (first in token 2).
		local incoming = sim.ring:resolveSwap(sim.ring.active[1])
		expect(incoming.id).toBe("T2a")
		expect(incoming.active).toBe(true)
		-- A1 returns to its origin token 1 (reserve).
		expect(sim.ring:findById("A1").active).toBe(false)
		expect(sim.ring:findById("A1").currentToken).toBe(1)
	end)

	it("recall token overrides default swap target", function()
		local sim = Simulator.new()
		local def = cardDef("A1", 1)
		def.recall = { replacesWith = "T3b", returnsTo = "origin" }
		sim:setup({ def, cardDef("A2", 1) }, {
			{ cardDef("T1a", 1), cardDef("T1b", 1) },
			{ cardDef("T2a", 2), cardDef("T2b", 2) },
			{ cardDef("T3a", 3), cardDef("T3b", 3) },
		})
		local incoming = sim.ring:resolveSwap(sim.ring.active[1])
		-- recall.replacesWith = T3b wins over clockwise default.
		expect(incoming.id).toBe("T3b")
	end)

	it("scales combat stats by log10 of power level", function()
		local weak = Combatant.create(cardDef("W", 1))
		local strong = Combatant.create(cardDef("S", 1))
		strong.base.atk = 20
		-- re-create with higher power
		local strongDef = cardDef("S", 1)
		strongDef.powerLevel = 100
		local strong2 = Combatant.create(strongDef)
		-- A 100x power card has higher combat damage than a 1x card.
		expect(strong2.combat.damage).toBeGreaterThan(weak.combat.damage)
	end)

	it("charges ultimate energy on dealing damage", function()
		local sim = Simulator.new()
		sim:setup({ cardDef("A1", 1), cardDef("A2", 1) }, {
			{ cardDef("T1a", 1), cardDef("T1b", 1) },
			{ cardDef("T2a", 2), cardDef("T2b", 2) },
			{ cardDef("T3a", 3), cardDef("T3b", 3) },
		})
		local before = sim.ring.active[1].energy
		sim:step()
		expect(sim.ring.active[1].energy).toBeGreaterThan(before)
	end)
end)
