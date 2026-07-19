-- Shared.Data.WorldState
-- Declarative progression rules: what unlocks, when tutorials fire, and how
-- quests advance. This is PURE DATA + PURE FUNCTIONS (no side effects, no
-- DataStore access) so it can run on client (for preview/prediction) and
-- server (authoritative) alike. The server persists results into the profile.
--
-- DESIGN:
--   * A "requirement" is a small predicate over a profile's data.
--   * Modes, tutorials and quests each declare requirements.
--   * `evaluate(profileData)` returns what SHOULD be unlocked given the data,
--     so the server can diff against what's already flagged and grant deltas.

local WorldState = {}

-- ---- Requirement predicates -------------------------------------------------
-- Each requirement is { kind = ..., ... }. Add new kinds here; keep them pure.

export type Requirement =
	{ kind: "accountLevel", level: number }
	| { kind: "modeUnlocked", modeId: string }
	| { kind: "simFloor", floor: number }
	| { kind: "questComplete", questId: string }
	| { kind: "tutorialComplete", tutorialId: string }
	| { kind: "flag", flagId: string }
	| { kind: "all", of: { Requirement } }
	| { kind: "any", of: { Requirement } }

local function meets(profile, req: Requirement): boolean
	local k = req.kind
	if k == "accountLevel" then
		return (profile.account.level or 1) >= req.level
	elseif k == "modeUnlocked" then
		return profile.world.unlockedModes[req.modeId] == true
	elseif k == "simFloor" then
		return (profile.modes.simulation.highestFloor or 0) >= req.floor
	elseif k == "questComplete" then
		return profile.world.completedQuests[req.questId] == true
	elseif k == "tutorialComplete" then
		return profile.world.completedTutorials[req.tutorialId] == true
	elseif k == "flag" then
		return profile.world.flags[req.flagId] == true
	elseif k == "all" then
		for _, r in ipairs(req.of) do
			if not meets(profile, r) then
				return false
			end
		end
		return true
	elseif k == "any" then
		for _, r in ipairs(req.of) do
			if meets(profile, r) then
				return true
			end
		end
		return false
	end
	return false
end

WorldState.meets = meets

-- ---- Mode unlock gates ------------------------------------------------------
-- modeId -> requirement to unlock it. Simulation has no gate (starts open).
WorldState.MODE_UNLOCKS = {
	Simulation = nil, -- open from the start
	UrgentRequests = { kind = "accountLevel", level = 5 },
	ComputerLab = {
		kind = "all",
		of = {
			{ kind = "accountLevel", level = 10 },
			{ kind = "simFloor", floor = 10 },
		},
	},
	Repair = { kind = "accountLevel", level = 15 },
}

-- ---- Tutorials --------------------------------------------------------------
-- tutorialId -> { trigger = Requirement, oncePerAccount = bool }
WorldState.TUTORIALS = {
	welcome = {
		trigger = { kind = "accountLevel", level = 1 },
		text = "Welcome! Draw your first pack and build a deck.",
	},
	firstSimulation = {
		trigger = { kind = "modeUnlocked", modeId = "Simulation" },
		text = "Enter the Simulation room to start an infinite run.",
	},
	tokensExplained = {
		trigger = { kind = "simFloor", floor = 1 },
		text = "Tokens decide who swaps in when a card is recalled.",
	},
	urgentUnlocked = {
		trigger = { kind = "modeUnlocked", modeId = "UrgentRequests" },
		text = "The radio station is live — take on boss commissions.",
	},
}

-- ---- Quests -----------------------------------------------------------------
-- questId -> { requirement to auto-complete, reward table, chainNext? }
WorldState.QUESTS = {
	reachFloor5 = {
		desc = "Reach Simulation floor 5.",
		complete = { kind = "simFloor", floor = 5 },
		reward = { currencies = { soft = 500 } },
		chainNext = "reachFloor10",
	},
	reachFloor10 = {
		desc = "Reach Simulation floor 10.",
		complete = { kind = "simFloor", floor = 10 },
		reward = { currencies = { soft = 1200, packTokens = 1 } },
	},
	reachLevel5 = {
		desc = "Reach account level 5 to unlock Urgent Requests.",
		complete = { kind = "accountLevel", level = 5 },
		reward = { currencies = { premium = 50 } },
	},
}

-- ---- Evaluation -------------------------------------------------------------
-- Given a profile's data, compute what SHOULD be true. The server diffs this
-- against stored flags and grants the deltas (unlocks, quest completions).
-- Returns: { unlockModes = {modeId=true}, tutorials = {id=true}, quests = {id=true} }
function WorldState.evaluate(profile)
	local result = {
		unlockModes = {},
		tutorials = {},
		quests = {},
	}

	for modeId, req in pairs(WorldState.MODE_UNLOCKS) do
		if req == nil or meets(profile, req) then
			result.unlockModes[modeId] = true
		end
	end

	for tutId, tut in pairs(WorldState.TUTORIALS) do
		if meets(profile, tut.trigger) then
			result.tutorials[tutId] = true
		end
	end

	for questId, quest in pairs(WorldState.QUESTS) do
		if meets(profile, quest.complete) then
			result.quests[questId] = true
		end
	end

	return result
end

return WorldState
