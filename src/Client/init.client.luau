-- Client entry point (StarterPlayerScripts.Client).
-- Renders the Fusion HUD + the modular ZoneUI, and reacts to ProximityPrompts
-- so walking up to a mode shows its full-screen zone panel.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Theme = require(script.UI.Theme)
local ZoneUI = require(script.UI.ZoneUI)
local OverheadHUD = require(script.UI.OverheadHUD)
local MapLayout = require(game:GetService("ReplicatedStorage").Shared.Data.MapLayout)
local WorldState = require(game:GetService("ReplicatedStorage").Shared.Data.WorldState)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shared reactive state for which mode panel is open.
local activeMode = Value(nil)

-- ---- ZoneUI (full-screen mode panel) ----
local zoneUi = ZoneUI.new(activeMode)
zoneUi:mount(playerGui)

-- ---- OverheadHUD (Mihoyo-style always-on mode strip) ----
-- Start from WorldState's static gate table; the server pushes live unlocks
-- via the WorldStateChanged RemoteEvent (see Server/Data/WorldStateService).
local function initialUnlocks()
	local set = {}
	for modeId, req in pairs(WorldState.MODE_UNLOCKS) do
		set[modeId] = (req == nil) -- nil requirement = always open (Simulation)
	end
	return set
end
local unlocked = Value(initialUnlocks())
local overhead = OverheadHUD.new(unlocked)
overhead:mount(playerGui)

-- Server -> client unlock deltas.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local worldEvent = ReplicatedStorage:WaitForChild("WorldStateChanged", 10)
if worldEvent then
	worldEvent.OnClientEvent:Connect(function(payload)
		-- payload = { unlockModes = {modeId=true}, ... }
		if payload and payload.unlockModes then
			local cur = unlocked:get()
			for modeId in pairs(payload.unlockModes) do
				cur[modeId] = true
			end
			unlocked:set(table.clone(cur))
		end
	end)
end

-- ---- ProximityPrompt -> open the matching ZoneUI panel ----
-- The server tagged each interact anchor with Attribute "ModeId".
local function modeById(id)
	for _, m in ipairs(MapLayout.MODES) do
		if m.id == id then
			return m
		end
	end
	return nil
end

local function wirePrompt(prompt: ProximityPrompt)
	prompt.Triggered:Connect(function(who)
		if who ~= player then
			return
		end
		local id = prompt.Parent:GetAttribute("ModeId")
		if id then
			activeMode:set(modeById(id))
		end
	end)
end

-- Attach to every ProximityPrompt already in the workspace, and any added later.
for _, desc in Workspace:GetDescendants() do
	if desc:IsA("ProximityPrompt") then
		wirePrompt(desc)
	end
end
Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		wirePrompt(desc)
	end
end)

print("[client] HUD + ZoneUI mounted; proximity prompts wired.")
