-- Server.Data.Profiles
-- Thin, safe wrapper around ProfileService. Handles:
--   * per-player load on join / release on leave (session-locked, auto-saving)
--   * Reconcile() so new ProfileTemplate fields land on old saves
--   * Studio mock store fallback (works without published DataStores / API access)
--   * a simple accessor + "get when ready" API for other server systems
--
-- Usage (server):
--   local Profiles = require(...Server.Data.Profiles)
--   Profiles.start()                         -- hook Players join/leave
--   local profile = Profiles.get(player)     -- nil until loaded
--   Profiles.onReady(player, function(p) ... end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ProfileService = require(game:GetService("ReplicatedStorage").Packages.ProfileService)
local ProfileTemplate = require(game:GetService("ReplicatedStorage").Shared.Data.ProfileTemplate)

local Profiles = {}

-- Use the mock store in Studio (no Open Cloud / DataStore API needed to test).
local USE_MOCK = RunService:IsStudio()

local store = ProfileService.GetProfileStore("PlayerData", ProfileTemplate.DEFAULT)
if USE_MOCK then
	store = store.Mock
end

-- player -> profile
local loaded: { [Player]: any } = {}
-- player -> { fn, ... } callbacks waiting for load
local waiters: { [Player]: { (any) -> () } } = {}

local function keyFor(player: Player): string return "player_" .. player.UserId end

local function fireReady(player: Player, profile)
	local list = waiters[player]
	if list then
		waiters[player] = nil
		for _, fn in ipairs(list) do
			task.spawn(fn, profile)
		end
	end
end

local function onJoin(player: Player)
	local profile = store:LoadProfileAsync(keyFor(player))
	if profile == nil then
		-- Another server holds the lock and wouldn't release; kick to retry.
		player:Kick("Data could not be loaded. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- GDPR compliance
	profile:Reconcile() -- fill in any new template fields onto old saves

	profile:ListenToRelease(function()
		loaded[player] = nil
		-- Profile released (another server or Studio stop) — remove the player.
		player:Kick("Data session ended. Please rejoin.")
	end)

	if player:IsDescendantOf(Players) then
		loaded[player] = profile

		-- First-load stamps + login bookkeeping.
		local data = profile.Data
		local now = os.time()
		if data.account.createdAtOsTime == 0 then
			data.account.createdAtOsTime = now
		end
		data.account.lastLoginOsTime = now

		fireReady(player, profile)
	else
		-- Player left before load finished.
		profile:Release()
	end
end

local function onLeave(player: Player)
	local profile = loaded[player]
	if profile then
		profile:Release()
	end
	waiters[player] = nil
end

-- ---- Public API -------------------------------------------------------------

function Profiles.get(player: Player) return loaded[player] end

-- Calls fn(profile) now if loaded, else when it becomes ready.
function Profiles.onReady(player: Player, fn: (any) -> ())
	local existing = loaded[player]
	if existing then
		task.spawn(fn, existing)
		return
	end
	waiters[player] = waiters[player] or {}
	table.insert(waiters[player], fn)
end

local started = false
function Profiles.start()
	if started then
		return
	end
	started = true

	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	-- Handle players already in-game (Studio test / hot reload).
	for _, player in Players:GetPlayers() do
		task.spawn(onJoin, player)
	end
end

return Profiles
