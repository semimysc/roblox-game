-- Server.Data.WorldStateService
-- Authoritative progression engine. Runs WorldState.evaluate() over a
-- player's profile, then applies the DELTAS to the persisted data:
--   * newly-satisfied unlocks / tutorials / quests get flagged
--   * quest rewards are granted (currencies, etc.)
-- Keeps WorldState PURE (rules only); all side-effects live here.
--
-- Usage:
--   local WSS = require(...Server.Data.WorldStateService)
--   WSS.start()                 -- hook into Profiles.ready
--   WSS.evaluate(player)       -- manual re-eval (after XP gain, etc.)

local WorldState = require(game:GetService("ReplicatedStorage").Shared.Data.WorldState)
local Profiles = require(script.Parent.Profiles)

local WorldStateService = {}

-- Apply a reward table onto profile.Data (currencies only for now).
local function grantReward(data, reward)
	if not reward then
		return
	end
	if reward.currencies then
		for cur, amt in pairs(reward.currencies) do
			data.currencies[cur] = (data.currencies[cur] or 0) + amt
		end
	end
	-- Future: grant cards, packTokens handled elsewhere.
end

-- Diff evaluate() against stored flags; return what changed (for logging/UI).
local function apply(player: Player, profile)
	local data = profile.Data
	data.world = data.world
		or { unlockedModes = {}, completedTutorials = {}, completedQuests = {}, activeQuests = {}, flags = {} }
	local w = data.world

	local desired = WorldState.evaluate(data)
	local changes = { unlockedModes = {}, tutorials = {}, quests = {} }

	-- Mode unlocks
	for modeId, _ in pairs(desired.unlockModes) do
		if w.unlockedModes[modeId] ~= true then
			w.unlockedModes[modeId] = true
			table.insert(changes.unlockedModes, modeId)
		end
	end

	-- Tutorials (once per account)
	for tutId, _ in pairs(desired.tutorials) do
		if w.completedTutorials[tutId] ~= true then
			w.completedTutorials[tutId] = true
			table.insert(changes.tutorials, tutId)
		end
	end

	-- Quests (grant reward once)
	for questId, _ in pairs(desired.quests) do
		if w.completedQuests[questId] ~= true then
			w.completedQuests[questId] = true
			table.insert(changes.quests, questId)
			local questDef = WorldState.QUESTS[questId]
			if questDef then
				grantReward(data, questDef.reward)
			end
		end
	end

	return changes
end

-- Is a mode currently unlocked for this player? (for gating entry prompts)
function WorldStateService.isModeUnlocked(player: Player, modeId: string): boolean
	local profile = Profiles.get(player)
	if not profile then
		return false
	end
	return profile.Data.world.unlockedModes[modeId] == true
end

-- Re-evaluate a player (call after XP/level/floor changes).
function WorldStateService.evaluate(player: Player)
	local profile = Profiles.get(player)
	if not profile then
		return nil
	end
	return apply(player, profile)
end

-- Auto-eval whenever a profile finishes loading, and expose a hook
-- so other systems (XP gain) can trigger re-eval.
local started = false
function WorldStateService.start()
	if started then
		return
	end
	started = true

	Profiles.onReady(function(player: Player, profile)
		local changes = apply(player, profile)
		if #changes.unlockedModes > 0 or #changes.quests > 0 then
			profile:Save()
		end
		-- Fire a game event so the client can show unlock/tutorial toasts.
		local repEvt = game:GetService("ReplicatedStorage"):FindFirstChild("WorldStateChanged")
		if repEvt and repEvt:IsA("RemoteEvent") then
			repEvt:FireClient(player, changes)
		end
		print(
			string.format(
				"[world] %s ready: +%d modes, +%d quests, +%d tutorials",
				player.Name,
				#changes.unlockedModes,
				#changes.quests,
				#changes.tutorials
			)
		)
	end)
end

return WorldStateService
