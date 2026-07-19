-- Shared.Battle.SpeedQueue
-- HSR-aligned turn order via ACTION VALUE. Each unit has an action value
-- (AV); when AV reaches <= 0 it acts, then its AV is reset to
-- BASE_AV / speed (BASE_AV = 10000). Higher speed -> smaller AV -> acts
-- sooner. A shared "timeline" advances by the smallest positive AV each
-- step, so the queue yields actors in correct speed order.
--
-- Pure + deterministic (no randomness). The Simulator drives it.

local BASE_AV = 10000

local SpeedQueue = {}
SpeedQueue.__index = SpeedQueue

function SpeedQueue.new()
	local self = setmetatable({}, SpeedQueue)
	self.units = {} -- [combatant] = { av = number }
	self._order = {} -- recent action order (debug/replay)
	return self
end

function SpeedQueue:add(c: any, spd: number) self.units[c] = { av = BASE_AV / math.max(1, spd) } end

function SpeedQueue:remove(c: any) self.units[c] = nil end

-- Advance the timeline by the smallest AV and return the acting unit.
-- Returns nil if no units. Advances ALL units' AV down by that step.
function SpeedQueue:popNext(): any?
	local minAV = math.huge
	local actor = nil
	for c, u in pairs(self.units) do
		if u.av < minAV then
			minAV = u.av
			actor = c
		end
	end
	if actor == nil then
		return nil
	end
	-- Advance everyone by minAV (the actor reaches 0 first).
	for _, u in pairs(self.units) do
		u.av -= minAV
	end
	-- Reset actor's AV for its next turn.
	local spd = actor.spd or actor.base and actor.base.spd or 100
	self.units[actor].av = BASE_AV / math.max(1, spd)
	table.insert(self._order, actor)
	return actor
end

-- Peek the next N actors in order without consuming (for UI preview).
function SpeedQueue:peek(n: number): { any }
	local order = {}
	for c, u in pairs(self.units) do
		table.insert(order, { c = c, av = u.av })
	end
	table.sort(order, function(a, b) return a.av < b.av end)
	local out = {}
	for i = 1, math.min(n, #order) do
		table.insert(out, order[i].c)
	end
	return out
end

return SpeedQueue
