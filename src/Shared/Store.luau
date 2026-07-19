-- Shared Rodux store factory + reducer.
-- The server is the source of truth; the client mirrors state into Fusion
-- state objects for rendering. This file is required by both sides.

local Rodux = require(script.Parent.Parent.Packages.Rodux)

export type GameAction =
	{ type: "score/increment" }
	| { type: "score/decrement" }
	| { type: "score/set", value: number }
	| { type: "player/add", name: string }
	| { type: "player/remove", name: string }

export type Player = {
	name: string,
	score: number,
}

export type GameState = {
	score: number,
	players: { [string]: Player },
}

local initial: GameState = {
	score = 0,
	players = {},
}

local function reducer(state: GameState?, action: GameAction): GameState
	state = state or initial
	if action.type == "score/increment" then
		return { score = state.score + 1, players = state.players }
	elseif action.type == "score/decrement" then
		return { score = state.score - 1, players = state.players }
	elseif action.type == "score/set" then
		return { score = action.value, players = state.players }
	elseif action.type == "player/add" then
		local players = table.clone(state.players)
		players[action.name] = { name = action.name, score = 0 }
		return { score = state.score, players = players }
	elseif action.type == "player/remove" then
		local players = table.clone(state.players)
		players[action.name] = nil
		return { score = state.score, players = players }
	end
	return state
end

return {
	initial = initial,
	reducer = reducer,
	makeStore = function() return Rodux.Store.new(reducer, initial) end,
}
