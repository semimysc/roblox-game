-- Client entry point (StarterPlayerScripts.Client).
-- Renders a Fusion HUD that mirrors the shared Rodux store's score.
-- In a full game the server would replicate state over RemoteEvents; here we
-- keep it simple: the client holds its own store mirror and the HUD reacts to it.

local Players = game:GetService("Players")
local Fusion = require(script.Parent.Parent.Packages.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed
local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local Store = require(script.Parent.Parent.Shared.Store)
local store = Store.makeStore()

-- Fusion state object that the HUD binds to. Updated whenever the store changes.
local score = Value(store:getState().score)
local playerCount = Value(0)

store.changed:connect(function(state)
	score:set(state.score)
	playerCount:set(0)
	for _ in pairs(state.players) do
		playerCount:set(playerCount:get() + 1)
	end
end)

-- Build the HUD.
local gui = New("ScreenGui")({
	Name = "Hud",
	ResetOnSpawn = false,
	[Children] = {
		New("Frame")({
			Name = "Panel",
			Size = UDim2.fromOffset(220, 90),
			Position = UDim2.fromScale(0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(20, 20, 30),
			[Children] = {
				New("TextLabel")({
					Name = "Score",
					Size = UDim2.fromScale(1, 0.5),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					TextSize = 24,
					Text = Computed(function() return "Score: " .. tostring(score:get()) end),
				}),
				New("TextLabel")({
					Name = "Players",
					Size = UDim2.fromScale(1, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(180, 180, 200),
					Font = Enum.Font.Gotham,
					TextSize = 16,
					Text = Computed(function() return "Players online: " .. tostring(playerCount:get()) end),
				}),
				New("TextButton")({
					Name = "AddPoint",
					Size = UDim2.fromOffset(100, 28),
					Position = UDim2.fromScale(0.5, 1),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.fromRGB(70, 120, 255),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Text = "+1",
					[OnEvent("Activated")] = function() store:dispatch({ type = "score/increment" }) end,
				}),
			},
		}),
	},
})

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

print("Game client started (Fusion HUD + Rodux store)")
