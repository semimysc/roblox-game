-- Shared counter store built on Rodux.
-- This is a tiny example of shared state the client and server can both reference.

local Rodux = require(game:GetService("ReplicatedStorage").Packages.Rodux)

export type CounterAction = { type: "increment" } | { type: "decrement" } | { type: "set", value: number }

local function reducer(state: number?, action: CounterAction): number
	state = state or 0
	if action.type == "increment" then
		return state + 1
	elseif action.type == "decrement" then
		return state - 1
	elseif action.type == "set" then
		return action.value
	end
	return state
end

return {
	reducer = reducer,
	makeStore = function() return Rodux.Store.new(reducer, 0) end,
}
