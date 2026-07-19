-- Shared.Data.ProfileTemplate
-- The canonical default schema for a player's saved data.
--
-- MODULARITY CONTRACT:
--   * This template is the single source of truth for persistent player data.
--   * ProfileService:Reconcile() fills in any NEW keys added here onto OLD
--     saves automatically, so you extend the game by ADDING fields — never
--     rename/remove a field in place (that orphans old data).
--   * Group related future systems under their own sub-table (see `modes`)
--     so a new game mode = one new sub-table, no migration needed.
--   * Bump SCHEMA_VERSION when you make a change that needs a migration
--     step beyond simple reconciliation (see Migrations note at bottom).

local ProfileTemplate = {}

ProfileTemplate.SCHEMA_VERSION = 1

-- The default data every new profile starts with.
ProfileTemplate.DEFAULT = {
	schemaVersion = ProfileTemplate.SCHEMA_VERSION,

	-- ---- Account-wide progression ----
	account = {
		level = 1,
		xp = 0,
		createdAtOsTime = 0, -- stamped on first load (server os.time)
		lastLoginOsTime = 0,
		totalPlaytimeSeconds = 0,
	},

	-- ---- Currencies (extend freely) ----
	currencies = {
		soft = 0, -- earned in-game
		premium = 0, -- monetized
		packTokens = 0, -- for card packs
	},

	-- ---- Card collection (the RNG core) ----
	-- cards keyed by cardId -> owned instance data. Deck is a list of cardIds.
	collection = {
		cards = {}, -- [cardId: string] = { count: number, stars: number, xp: number }
		deck = {}, -- ordered list of up to 8 cardIds
		-- Token loadout (Part A): 3 tokens, each with recall rule + 2 members.
		tokens = {}, -- [tokenIndex: number] = { members = {cardId, cardId}, recall = {...} }
	},

	-- ---- Per-character meta (artifacts, roguelite saves) ----
	characters = {}, -- [characterId: string] = { artifacts = {...}, savedRun = {...}, promotion = {...} }

	-- ---- Per-game-mode data. ONE sub-table per mode = trivial to extend. ----
	modes = {
		simulation = {
			highestFloor = 0,
			currentTier = 1,
			totalRuns = 0,
			bestRunCards = 0,
		},
		urgentRequests = {
			completed = 0,
			weeklyProgress = 0,
			lastResetOsTime = 0,
		},
		computerLab = {
			deliveriesCompleted = 0,
			upgradesUnlocked = {}, -- [upgradeId] = true
		},
		repair = {
			artifactsCrafted = 0,
		},
		-- Future modes: add `newMode = { ... }` here. Reconcile handles the rest.
	},

	-- ---- World progression: what the player has unlocked / seen. ----
	-- Mirrors Shared.Data.WorldState flags. Persisted so unlock/tutorial
	-- state survives across sessions.
	world = {
		unlockedModes = { Simulation = true }, -- Simulation open from the start
		completedTutorials = {}, -- [tutorialId] = true
		completedQuests = {}, -- [questId] = true
		activeQuests = {}, -- [questId] = { progress = number }
		flags = {}, -- [flagId] = true  (generic world-change switches)
	},

	-- ---- Settings ----
	settings = {
		musicVolume = 0.7,
		sfxVolume = 0.8,
		reducedMotion = false,
	},
}

return ProfileTemplate
