-- Client.UI.OverheadHUD
-- Mihoyo-style top status strip: always-visible list of every instated
-- mode/touchpoint, each shown as locked (greyed) or available (accent-lit)
-- based on the player's WorldState unlocks. This is the "overhead UI" — a
-- persistent map of what's open, separate from the full-screen ZoneUI panel
-- that appears on proximity/enter.
--
-- Driven by Shared.Data.MapLayout (what exists) and Shared.Data.WorldState
-- (what's unlocked). Reskin via Theme. No AI art needed — procedural Fusion.

local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed
local New = Fusion.New
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup

local Theme = require(script.Parent.Theme)
local MapLayout = require(game:GetService("ReplicatedStorage").Shared.Data.MapLayout)
local WorldState = require(game:GetService("ReplicatedStorage").Shared.Data.WorldState)

local OverheadHUD = {}
OverheadHUD.__index = OverheadHUD

-- `unlocked` is a Fusion Value<{ [ModeId]: boolean }> of currently-unlocked modes.
function OverheadHUD.new(unlocked: any)
	local self = setmetatable({}, OverheadHUD)

	-- Build one chip per instated mode (from MapLayout, the single source of truth).
	local chips = {}
	for _, mode in ipairs(MapLayout.MODES) do
		local isOpen = Computed(function()
			-- WorldState.MODE_UNLOCKS[nil] => always open (e.g. Simulation).
			local req = WorldState.MODE_UNLOCKS[mode.id]
			if req == nil then
				return true
			end
			-- unlocked Value holds the computed set from the server.
			return unlocked:get()[mode.id] == true
		end)

		chips[mode.id] = New("Frame")({
			Name = mode.id .. "Chip",
			Size = UDim2.fromOffset(150, 40),
			BackgroundColor3 = Theme.bgGlass,
			BackgroundTransparency = Computed(function() return isOpen:get() and 0.25 or 0.55 end),
			BorderColor3 = Computed(function() return isOpen:get() and mode.themeColor or Theme.locked end),
			BorderSizePixel = 1,
			[Children] = {
				New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				New("TextLabel")({
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					BackgroundTransparency = 1,
					Text = Computed(function() return isOpen:get() and mode.label or "🔒 " .. mode.label end),
					TextColor3 = Computed(function() return isOpen:get() and Theme.textPrimary or Theme.locked end),
					Font = Theme.fontBody,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
			},
		})
	end

	self._gui = New("ScreenGui")({
		Name = "OverheadHUD",
		ResetOnSpawn = false,
		[Children] = {
			New("Frame")({
				Name = "Strip",
				Size = UDim2.new(1, 0, 0, 52),
				Position = UDim2.fromOffset(0, 8),
				BackgroundColor3 = Theme.bgPrimary,
				BackgroundTransparency = 0.6,
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				},
			}),
		},
	})

	-- Append chips into the strip after it's created.
	local strip = self._gui:FindFirstChild("Strip", true)
	if strip then
		for _, chip in pairs(chips) do
			chip.Parent = strip
		end
	end

	return self
end

function OverheadHUD:mount(playerGui: Instance) self._gui.Parent = playerGui end

function OverheadHUD:destroy() Cleanup(self._gui) end

return OverheadHUD
