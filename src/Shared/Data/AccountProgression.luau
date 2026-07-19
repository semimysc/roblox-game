-- Shared.Data.AccountProgression
-- PURE data + functions for Mihoyo-style ACCOUNT progression.
--
-- Desaign note (from you): account level is NOT driven by sim floors.
-- It rises from MANY marginal XP sources — daily login, daily quests,
-- end-game clears, world quests, etc. Each grants a small amount.
-- This module defines the XP CURVE and the SOURCE table.
-- Side-effects (writing the profile) live in Server.Data.ProgressionService.
--
-- Like WorldState, this is side-effect-free so it can run on client
-- (for XP-bar preview) and server (authoritative) alike.

local AccountProgression = {}

-- ---- XP curve (Mihoyo-like: accelerating cost per level) ----
-- xpForLevel(n) = total cumulative XP needed to REACH level n.
-- Uses a quadratic-ish curve so early levels are quick, later ones slow.
-- Level 1 = 0 (starting level). Cap at MAX_LEVEL.

AccountProgression.MAX_LEVEL = 60

local function xpForLevel(level: number): number
	level = math.max(1, level)
	-- 100 * (n-1)^1.35, rounded. Tunable.
	return math.floor(100 * math.pow(level - 1, 1.35) + 0.5)
end

AccountProgression.xpForLevel = xpForLevel

-- Given total xp, return { level, xpIntoLevel, xpNeededForNext }.
function AccountProgression.computeLevel(
	totalXp: number
): { level: number, xpIntoLevel: number, xpNeededForNext: number }
	totalXp = math.max(0, totalXp)
	local level = 1
	while level < AccountProgression.MAX_LEVEL do
		local need = xpForLevel(level + 1)
		if totalXp < need then
			break
		end
		level += 1
	end
	local curBase = xpForLevel(level)
	local nextBase = xpForLevel(math.min(level + 1, AccountProgression.MAX_LEVEL))
	local into = totalXp - curBase
	local needed = nextBase - curBase
	return {
		level = level,
		xpIntoLevel = into,
		xpNeededForNext = needed,
	}
end

-- ---- XP sources (marginal, declaratively defined) ----
-- Each source = { id, xp, currencies? } and is granted via ProgressionService.
-- "Daily" sources reset on the rolling daily timer.
-- Add new sources here; no other code changes needed.

AccountProgression.XP_SOURCES = {
	-- Daily (small, repeatable)
	dailyLogin = { id = "dailyLogin", xp = 50, daily = true, desc = "Daily login" },
	dailyQuest1 = {
		id = "dailyQuest1",
		xp = 80,
		daily = true,
		desc = "Daily commission 1",
		currencies = { soft = 200 },
	},
	dailyQuest2 = {
		id = "dailyQuest2",
		xp = 80,
		daily = true,
		desc = "Daily commission 2",
		currencies = { soft = 200 },
	},
	dailyQuest3 = {
		id = "dailyQuest3",
		xp = 100,
		daily = true,
		desc = "Daily commission 3",
		currencies = { soft = 250, packTokens = 1 },
	},
	dailyClear = {
		id = "dailyClear",
		xp = 60,
		daily = true,
		desc = "Daily activity clear",
		currencies = { soft = 150 },
	},
	-- End-game / one-time clears (marginal, not daily)
	endgameUrgent = {
		id = "endgameUrgent",
		xp = 120,
		daily = false,
		desc = "Urgent Requests clear",
		currencies = { soft = 300, premium = 10 },
	},
	endgameRepair = {
		id = "endgameRepair",
		xp = 90,
		daily = false,
		desc = "Repair milestone",
		currencies = { soft = 200 },
	},
	-- World quests (also bump their own completion in WorldState)
	welcomeQuest = { id = "welcomeQuest", xp = 40, daily = false, desc = "Welcome quest" },
}

-- ---- Daily reset helper ----
-- Returns true if the player's 'lastDailyResetOsTime' is on a different
-- calendar day than `now`. Used by ProgressionService to clear daily claims.
function AccountProgression.shouldResetDaily(lastResetOsTime: number, now: number): boolean
	if lastResetOsTime == 0 then
		return true
	end
	-- Roblox os.time() is UTC seconds. Compare UTC calendar day.
	local function dayStart(t) return math.floor(t / 86400) end
	return dayStart(now) ~= dayStart(lastResetOsTime)
end

return AccountProgression
