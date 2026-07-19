-- Server entry point (ServerScriptService.Server).
-- Owns the authoritative Rodux store AND builds the hub map from data.

local Players = game:GetService("Players")
local Store = require(script.Parent.Parent.Shared.Store)
local store = Store.makeStore()

local MapBuilder = require(script.Parent.Map.Builder)

-- Build the single-building hub (rooms, stairs, indicators, radio station, prompts).
local builder = MapBuilder.new()
builder:buildBuildEnvelope()
builder:buildRooms()
builder:buildModeMarkers()
builder:finish()

local function onPlayerAdded(player: Player) store:dispatch({ type = "player/add", name = player.Name }) end
local function onPlayerRemoving(player: Player) store:dispatch({ type = "player/remove", name = player.Name }) end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

store.changed:connect(function(state)
	print(string.format(
		"[server] score=%d players=%d",
		state.score,
		(function()
			local n = 0
			for _ in pairs(state.players) do
				n += 1
			end
			return n
		end)()
	))
end)

print("[server] Hub building constructed; game server started.")
