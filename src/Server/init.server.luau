-- Server entry point (ServerScriptService.Server).
-- Owns the authoritative Rodux store, builds the hub map, and runs the
-- player data layer (ProfileService + progression + world-state unlocks).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Store = require(ReplicatedStorage.Shared.Store)
local store = Store.makeStore()

local Profiles = require(script.Data.Profiles)
local WorldStateService = require(script.Data.WorldStateService)
local ProgressionService = require(script.Data.ProgressionService)

-- WorldStateChanged RemoteEvent is declared in default.project.json, so it
-- exists in ReplicatedStorage at runtime (no Instance.new needed here).

-- Start the data layer: load profiles, drive progression + world unlocks.
Profiles.start()
ProgressionService.start()
WorldStateService.start()

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

print("[server] Hub building constructed; data + progression + world-state services started.")
