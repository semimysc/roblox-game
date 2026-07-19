-- Shared.Battle.Damage.spec
-- Validates HSR-aligned damage: declarative ADDITIVE vs MULTIPLICATIVE
-- layers must combine in the correct order, plus def/crit/res factors.

local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local Damage = require(script.Parent.Damage)
local Stats = require(script.Parent.Parent.Data.Stats)

local function atkBlock()
	local b = Stats.new({ hp = 1, atk = 100, def = 1, spd = 1, critRate = 0, critDmg = 0.5, element = "Physical" })
	return b
end

describe("Damage calculation", function()
	it("applies additive damage bonus as (1 + sum)", function()
		local b = atkBlock()
		Stats.addModifier(b, { id = "db1", stat = "damage", layer = "additive", value = 0.5 })
		local d = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0 })
		-- 100 * (1 + 0.5) * defFactor(100,0)=1 * crit(1) * res(1) = 150
		expect(d).toBeCloseTo(150, 3)
	end)

	it("applies multiplicative increase as product", function()
		local b = atkBlock()
		Stats.addModifier(b, { id = "di1", stat = "damage", layer = "mult", value = 2.0 })
		local d = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0 })
		-- 100 * 1 * 2.0 = 200
		expect(d).toBeCloseTo(200, 3)
	end)

	it("combines additive THEN multiplicative (correct HSR order)", function()
		local b = atkBlock()
		Stats.addModifier(b, { id = "db1", stat = "damage", layer = "additive", value = 0.5 })
		Stats.addModifier(b, { id = "di1", stat = "damage", layer = "mult", value = 2.0 })
		local d = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0 })
		-- 100 * (1 + 0.5) * 2.0 = 300  (NOT 100*1.5 + 100*2)
		expect(d).toBeCloseTo(300, 3)
	end)

	it("reduces damage via def factor (higher def -> less)", function()
		local b = atkBlock()
		local noDef = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0 })
		local withDef = Damage.calculate({ atkBlock = b, defStat = 100, targetRes = 0 })
		expect(withDef).toBeLessThan(noDef)
	end)

	it("applies crit multiplier", function()
		local b = atkBlock()
		b.critRate = 1 -- always crit
		local d = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0, forceCrit = true })
		-- 100 * 1 * 1 * (1 + 0.5) = 150
		expect(d).toBeCloseTo(150, 3)
	end)

	it("reduces by elemental resistance", function()
		local b = atkBlock()
		local neutral = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0 })
		local resisted = Damage.calculate({ atkBlock = b, defStat = 0, targetRes = 0.5 })
		expect(resisted).toBeCloseTo(neutral * 0.5, 3)
	end)
end)
