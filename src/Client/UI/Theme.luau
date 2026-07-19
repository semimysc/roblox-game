-- Client.UI.Theme
-- Central visual skin for ALL in-game UI (zone UI, prompts, overhead tags).
-- The Mihoyo-reskin requirement lives here: to restyle the whole game,
-- change values in this one module (or swap Theme for a future Theme_V2).
-- No game logic references raw colors; it reads from Theme.

export type ThemeDef = {
	-- Core palette
	bgPrimary: Color3,
	bgSecondary: Color3,
	bgGlass: Color3,
	border: Color3,
	textPrimary: Color3,
	textMuted: Color3,
	accent: Color3,
	accentSoft: Color3,
	-- Typography
	fontHeading: Enum.Font,
	fontBody: Enum.Font,
	-- Shape
	cornerRadius: UDim,
	-- Motion
	tweenIn: number, -- seconds
	-- Per-mode accent overrides (pulled from MapLayout themeColor)
	modeAccent: (modeId: string) -> Color3,
}

local Theme: ThemeDef = {
	bgPrimary = Color3.fromRGB(14, 16, 24),
	bgSecondary = Color3.fromRGB(24, 28, 40),
	bgGlass = Color3.fromRGB(30, 34, 48),
	border = Color3.fromRGB(70, 80, 110),
	textPrimary = Color3.fromRGB(240, 242, 250),
	textMuted = Color3.fromRGB(160, 168, 190),
	accent = Color3.fromRGB(120, 170, 255),
	accentSoft = Color3.fromRGB(60, 90, 160),

	fontHeading = Enum.Font.GothamBold,
	fontBody = Enum.Font.Gotham,

	cornerRadius = UDim.new(0, 14),

	tweenIn = 0.28,
}

-- Default: every mode resolves to the accent above, unless a caller
-- passes a specific modeColor (the MapLayout themeColor). This is the
-- single seam where per-mode tint enters the 2D UI.
function Theme.modeAccent(_modeId: string): Color3 return Theme.accent end

return Theme
