-- Jest test for the shared counter reducer.
-- Run with the Roblox test backend (jest-globals is built into the place file).
-- Convention: files matching *.spec.luau are picked up by the test runner.

local JestGlobals = require(script.Parent.Parent.Packages.JestGlobals)
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local Counter = require(script.Parent.Counter)

describe("Counter reducer", function()
	it("starts at 0 by default", function() expect(Counter.reducer(nil, { type = "increment" }) == 1).toBe(true) end)

	it("increments and decrements", function()
		local state = Counter.reducer(0, { type = "increment" })
		expect(state == 1).toBe(true)
		state = Counter.reducer(state, { type = "decrement" })
		expect(state == 0).toBe(true)
	end)

	it(
		"sets an explicit value",
		function() expect(Counter.reducer(0, { type = "set", value = 42 }) == 42).toBe(true) end
	)
end)
