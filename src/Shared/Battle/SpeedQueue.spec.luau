-- Shared.Battle.SpeedQueue.spec
-- Validates HSR action-value turn order: higher speed acts sooner, and the
-- queue yields actors in correct speed order across multiple turns.

local JestGlobals = require("@DevPackages/JestGlobals")
local describe = JestGlobals.describe
local it = JestGlobals.it
local expect = JestGlobals.expect

local SpeedQueue = require(script.Parent.SpeedQueue)

local function card(id, spd) return { id = id, spd = spd } end

describe("Speed queue", function()
	it("yields the fastest unit first", function()
		local q = SpeedQueue.new()
		q:add(card("slow", 100), 100)
		q:add(card("fast", 200), 200)
		local first = q:popNext()
		expect(first.id).toBe("fast")
	end)

	it("cycles through all units in speed order across turns", function()
		local q = SpeedQueue.new()
		q:add(card("A", 100), 100)
		q:add(card("B", 150), 150)
		q:add(card("C", 300), 300)
		local order = {}
		for _ = 1, 3 do
			local u = q:popNext()
			table.insert(order, u.id)
		end
		-- C (300) -> B (150) -> A (100)
		expect(order[1]).toBe("C")
		expect(order[2]).toBe("B")
		expect(order[3]).toBe("A")
	end)

	it("peek returns upcoming actors without consuming", function()
		local q = SpeedQueue.new()
		q:add(card("A", 100), 100)
		q:add(card("B", 300), 300)
		local peeked = q:peek(2)
		expect(peeked[1].id).toBe("B")
		expect(peeked[2].id).toBe("A")
		-- still there after peek
		expect(q:popNext().id).toBe("B")
	end)
end)
