-- Server entry point (ServerScriptService.Server).
-- Owns the authoritative Rodux store and mirrors player join/leave into it.

local Players = game:GetService("Players")
local Store = require(script.Parent.Parent.Shared.Store)
local store = Store.makeStore()

local function onPlayerAdded(player: Player) store:dispatch({ type = "player/add", name = player.Name }) end

local function onPlayerRemoving(player: Player) store:dispatch({ type = "player/remove", name = player.Name }) end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Seed any players already present (e.g. Studio test session).
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

print("Game server started (authoritative Rodux store)")
