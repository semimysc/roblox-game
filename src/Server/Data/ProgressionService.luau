-- Server.Data.ProgressionService
-- Authoritative account-progression engine. Consumes
-- Shared.Data.AccountProgression (pure curve + sources) and writes
-- results into the player's ProfileService data:
--   * grants marginal XP from sources (daily + end-game + quests)
--   * recomputes account.level via the curve
--   * on level change -> WorldStateService.evaluate() (fires unlocks/quests)
--   * handles the rolling daily reset (dailies claimable once/day)
--   * awards source currencies
--
-- Like WorldStateService, this keeps the pure math in Shared and
-- all side-effects here.

local RunService = game:GetService("RunService")
local Profiles = require(script.Parent.Parent.Data.Profiles)
local WorldStateService = require(script.Parent.Parent.Data.WorldStateService)
local AccountProgression = require(script.Parent.Parent.Parent.Shared.Data.AccountProgression)

local ProgressionService = {}

-- Grant a single XP source to a player (idempotent for daily/one-time).
-- Returns true if something was actually granted.
local function grantSource(player: Player, profile, sourceDef)
	local data = profile.Data
	local claims = data.account.claimedSources or {}
	if sourceDef.daily then
		-- Reset claims if a new day rolled over.
		if AccountProgression.shouldResetDaily(data.account.lastDailyResetOsTime, os.time()) then
			claims = {}
			data.account.claimedSources = claims
			data.account.lastDailyResetOsTime = os.time()
		end
		if claims[sourceDef.id] then
			return false
		end
	else
		-- One-time source: skip if already claimed.
		if claims[sourceDef.id] then
			return false
		end
	end

	-- Apply
	data.account.xp = (data.account.xp or 0) + (sourceDef.xp or 0)
	if sourceDef.currencies then
		for cur, amt in pairs(sourceDef.currencies) do
			data.currencies[cur] = (data.currencies[cur] or 0) + amt
		end
	end
	claims[sourceDef.id] = true

	-- Recompute level; bump + re-eval world unlocks on change.
	local before = data.account.level
	local lvl = AccountProgression.computeLevel(data.account.xp).level
	data.account.level = lvl
	if lvl > before then
		print(string.format("[progression] %s reached level %d", player.Name, lvl))
		-- Fire unlock/quest deltas (level-based gates live in WorldState).
		WorldStateService.evaluate(player)
		-- Notify client of the level-up (reuse WorldStateChanged channel).
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("WorldStateChanged")
		if ev and ev:IsA("RemoteEvent") then
			ev:FireClient(player, { levelUp = lvl })
		end
	end
	return true
end

-- Public: grant a named source (e.g. when a daily quest completes).
function ProgressionService.grant(player: Player, sourceId: string): boolean
	local profile = Profiles.get(player)
	if not profile then
		return false
	end
	local def = AccountProgression.XP_SOURCES[sourceId]
	if not def then
		return false
	end
	return grantSource(player, profile, def)
end

-- Public: grant on first load (dailies, welcome quest, etc.).
local started = false
function ProgressionService.start()
	if started then
		return
	end
	started = true

	Profiles.onReady(function(player: Player, profile)
		local data = profile.Data
		data.account.claimedSources = data.account.claimedSources or {}
		-- On join, grant daily login + any due dailies + welcome (once).
		for _, def in pairs(AccountProgression.XP_SOURCES) do
			-- Only auto-grant the "entry" sources on load:
			if def.id == "dailyLogin" or def.id == "welcomeQuest" then
				grantSource(player, profile, def)
			end
		end
		profile:Save()
	end)
end

return ProgressionService
