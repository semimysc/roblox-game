-- Client.UI.ZoneUI
-- Full-screen "zone" UI shown when a player is near / enters a mode.
-- Built with Fusion so it is reactive and reskinnable. All colors/fonts
-- come from Theme; all copy/structure comes from MapLayout. To restyle
-- for the Mihoyo look later, edit Theme + this component only.

local Fusion = require(game:GetService("ReplicatedStorage").Packages.Fusion)
local Value = Fusion.Value
local Computed = Fusion.Computed
local New = Fusion.New
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup

local Theme = require(script.Parent.Theme)
local MapLayout = require(game:GetService("ReplicatedStorage").Shared.Data.MapLayout)

local ZoneUI = {}
ZoneUI.__index = ZoneUI

-- `activeMode` is a Fusion Value holding a ModeDef | nil.
function ZoneUI.new(activeMode: any)
	local self = setmetatable({}, ZoneUI)

	-- Background dims; only visible when a mode is active.
	local visible = Computed(function() return activeMode:get() ~= nil end)

	-- Accent color: prefer the mode's themeColor (the reskin seam).
	local accent = Computed(function()
		local m = activeMode:get()
		return m and m.themeColor or Theme.accent
	end)

	local title = Computed(function()
		local m = activeMode:get()
		return m and m.label or ""
	end)

	local desc = Computed(function()
		local m = activeMode:get()
		return m and m.description or ""
	end)

	local status = Computed(function()
		local m = activeMode:get()
		if not m then
			return ""
		end
		return m.built and "Available" or "Coming soon"
	end)

	self._gui = New("ScreenGui")({
		Name = "ZoneUI",
		ResetOnSpawn = false,
		Enabled = visible,
		[Children] = {
			-- Dim backdrop
			New("Frame")({
				Name = "Backdrop",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.bgPrimary,
				BackgroundTransparency = Computed(function() return visible:get() and 0.45 or 1 end),
			}),
			-- Center card
			New("Frame")({
				Name = "Card",
				Size = UDim2.fromOffset(520, 320),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Theme.bgGlass,
				BorderColor3 = accent,
				BorderSizePixel = 2,
				[Children] = {
					New("UICorner")({ CornerRadius = Theme.cornerRadius }),
					-- Header bar (mode accent)
					New("Frame")({
						Name = "Header",
						Size = UDim2.new(1, 0, 0, 56),
						BackgroundColor3 = accent,
						BackgroundTransparency = 0.85,
						[Children] = {
							New("UICorner")({ CornerRadius = Theme.cornerRadius }),
							New("TextLabel")({
								Name = "Title",
								Size = UDim2.new(1, -24, 1, 0),
								Position = UDim2.fromOffset(16, 0),
								BackgroundTransparency = 1,
								Text = title,
								TextColor3 = Theme.textPrimary,
								Font = Theme.fontHeading,
								TextSize = 26,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						},
					}),
					-- Body
					New("TextLabel")({
						Name = "Description",
						Size = UDim2.new(1, -32, 0, 120),
						Position = UDim2.fromOffset(16, 72),
						BackgroundTransparency = 1,
						Text = desc,
						TextColor3 = Theme.textMuted,
						Font = Theme.fontBody,
						TextSize = 16,
						TextWrapped = true,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					-- Status pill
					New("Frame")({
						Name = "StatusPill",
						Size = UDim2.fromOffset(120, 28),
						Position = UDim2.fromOffset(16, 200),
						BackgroundColor3 = accent,
						BackgroundTransparency = 0.8,
						[Children] = {
							New("UICorner")({ CornerRadius = UDim.new(1, 0) }),
							New("TextLabel")({
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								Text = status,
								TextColor3 = Theme.textPrimary,
								Font = Theme.fontBody,
								TextSize = 14,
							}),
						},
					}),
					-- Enter / Close button
					New("TextButton")({
						Name = "Action",
						Size = UDim2.fromOffset(160, 40),
						Position = UDim2.fromOffset(344, 260),
						BackgroundColor3 = accent,
						TextColor3 = Theme.textPrimary,
						Font = Theme.fontHeading,
						TextSize = 18,
						Text = "Enter Zone",
						[OnEvent("Activated")] = function()
							-- In a full game this fires the mode-load RemoteEvent.
							-- For now it just clears the active mode (closes the panel).
							activeMode:set(nil)
						end,
						[Children] = { New("UICorner")({ CornerRadius = UDim.new(0, 10) }) },
					}),
				},
			}),
		},
	})

	return self
end

function ZoneUI:mount(playerGui: Instance) self._gui.Parent = playerGui end

function ZoneUI:destroy() Cleanup(self._gui) end

return ZoneUI
