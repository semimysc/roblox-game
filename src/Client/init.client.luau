-- Client entry point (StarterPlayerScripts.Client).
-- Renders the Fusion HUD + the modular ZoneUI, and reacts to ProximityPrompts
-- so walking up to a mode shows its full-screen zone panel.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Value = Fusion.Value

local Store = require(game:GetService("ReplicatedStorage").Shared.Store)
local store = Store.makeStore()

local Theme = require(script.Parent.UI.Theme)
local ZoneUI = require(script.Parent.UI.ZoneUI)
local MapLayout = require(game:GetService("ReplicatedStorage").Shared.Data.MapLayout)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Shared reactive state for which mode panel is open.
local activeMode = Value(nil)
local score = Value(store:getState().score)
local playerCount = Value(0)

store.changed:connect(function(state)
	score:set(state.score)
	playerCount:set(0)
	for _ in pairs(state.players) do
		playerCount:set(playerCount:get() + 1)
	end
end)

-- ---- HUD (minimal; ZoneUI is the main new surface) ----
local hud = Fusion.New("ScreenGui")({
	Name = "Hud",
	ResetOnSpawn = false,
	[Fusion.Children] = {
		Fusion.New("Frame")({
			Name = "Panel",
			Size = UDim2.fromOffset(220, 90),
			Position = UDim2.fromScale(0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(20, 20, 30),
			[Fusion.Children] = {
				Fusion.New("TextLabel")({
					Name = "Score",
					Size = UDim2.fromScale(1, 0.5),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					TextSize = 24,
					Text = Fusion.Computed(function() return "Score: " .. tostring(score:get()) end),
				}),
				Fusion.New("TextLabel")({
					Name = "Players",
					Size = UDim2.fromScale(1, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(180, 180, 200),
					Font = Enum.Font.Gotham,
					TextSize = 16,
					Text = Fusion.Computed(function() return "Players online: " .. tostring(playerCount:get()) end),
				}),
				Fusion.New("TextButton")({
					Name = "AddPoint",
					Size = UDim2.fromOffset(100, 28),
					Position = UDim2.fromScale(0.5, 1),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.fromRGB(70, 120, 255),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = "+1",
					[Fusion.OnEvent("Activated")] = function() store:dispatch({ type = "score/increment" }) end,
				}),
			},
		}),
	},
})

-- ---- ZoneUI (full-screen mode panel) ----
local zoneUi = ZoneUI.new(activeMode)
zoneUi:mount(playerGui)
hud.Parent = playerGui

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
