-- Server.Map.Builder
-- Builds the single two-story hub building from Shared.Data.MapLayout.
-- Authoritative (server-created) so clients just see it. Also spawns:
--   * overhead indicator billboards for each built mode
--   * a 3D radio-station workstation for Urgent Requests
--   * ProximityPrompts on every interactable (the "enter mode" button)
-- Clients read MapLayout + Theme to mirror the same UI in 2D.

local MapLayout = require(game:GetService("ReplicatedStorage").Shared.Data.MapLayout)

local Builder = {}
Builder.__index = Builder

function Builder.new()
	local self = setmetatable({}, Builder)
	self._model = Instance.new("Model")
	self._model.Name = "HubBuilding"
	self._parts = {}
	return self
end

local function box(parent, name, size, cframe, color, material, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color or Color3.fromRGB(120, 120, 130)
	p.Material = material or Enum.Material.Concrete
	p.Anchored = anchored == nil and true or anchored
	p.Parent = parent
	return p
end

local function floorSlab(room)
	return box(
		nil,
		room.name .. " Floor",
		Vector3.new(room.size.X, 1, room.size.Z),
		CFrame.new(room.center.X, room.floor * 18 - 0.5, room.center.Z),
		room.placeholder and Color3.fromRGB(90, 92, 100) or Color3.fromRGB(110, 112, 122),
		Enum.Material.WoodPlanks
	)
end

-- Build a floating overhead indicator (BillboardGui) above a mode.
local function makeIndicator(mode)
	local adornee = Instance.new("Part")
	adornee.Name = mode.id .. "IndicatorAnchor"
	adornee.Size = Vector3.new(1, 1, 1)
	adornee.Transparency = 1
	adornee.Anchored = true
	adornee.CanCollide = false
	adornee.CFrame = mode.indicatorCFrame
	adornee.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Name = "OverheadIndicator"
	bb.Size = UDim2.fromOffset(220, 64)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = adornee
	bb.Parent = adornee

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	frame.BackgroundTransparency = 0.15
	frame.BorderColor3 = mode.themeColor
	frame.BorderSizePixel = 2
	frame.Parent = bb

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0.5, 0)
	title.Position = UDim2.fromOffset(6, 4)
	title.BackgroundTransparency = 1
	title.Text = mode.label
	title.TextColor3 = mode.themeColor
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0.45, 0)
	sub.Position = UDim2.fromOffset(6, 30)
	sub.BackgroundTransparency = 1
	sub.Text = mode.built and mode.description or "Coming soon"
	sub.TextColor3 = Color3.fromRGB(180, 185, 200)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 12
	sub.TextWrapped = true
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = frame

	return adornee
end

-- ProximityPrompt "enter mode" button. Fires an attribute the client watches,
-- or (in a full game) a RemoteEvent to the server to load the mode.
local function makePrompt(parent, mode)
	local anchor = box(
		parent,
		mode.id .. "Interact",
		Vector3.new(4, 6, 4),
		mode.zoneCFrame * CFrame.new(0, 0, 10),
		Color3.fromRGB(60, 64, 80),
		Enum.Material.Metal,
		true
	)
	anchor.CanCollide = false
	anchor.Transparency = 0.6

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterMode"
	prompt.ActionText = "Enter"
	prompt.ObjectText = mode.label
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.HoldDuration = 0.2
	-- Tag the mode id so a client/server listener can react generically.
	anchor:SetAttribute("ModeId", mode.id)
	prompt.Parent = anchor
	return anchor, prompt
end

-- Big 3D "workstation" model for the radio station (Urgent Requests).
local function makeRadioStation(room)
	local station = Instance.new("Model")
	station.Name = "RadioStationWorkstation"
	station.Parent = workspace

	local desk = box(
		station,
		"Desk",
		Vector3.new(10, 3, 5),
		CFrame.new(room.center.X, 1.5, room.center.Z + 4),
		Color3.fromRGB(45, 48, 60),
		Enum.Material.Metal
	)
	local console = box(
		station,
		"Console",
		Vector3.new(8, 2, 3),
		CFrame.new(room.center.X, 4, room.center.Z + 4),
		Color3.fromRGB(20, 24, 34),
		Enum.Material.Neon
	)
	-- Antenna mast
	box(
		station,
		"Mast",
		Vector3.new(0.6, 14, 0.6),
		CFrame.new(room.center.X + 4, 9, room.center.Z + 4),
		Color3.fromRGB(150, 150, 160),
		Enum.Material.Metal
	)
	-- Glowing screen strip
	box(
		station,
		"Screen",
		Vector3.new(7, 3, 0.4),
		CFrame.new(room.center.X, 6, room.center.Z + 5.6),
		Color3.fromRGB(90, 200, 255),
		Enum.Material.Neon
	)

	local primary = station:GetChildren()[1]
	if primary then
		station.PrimaryPart = primary
	end
	return station
end

function Builder:buildBuildEnvelope()
	local B = MapLayout.BUILDING
	-- Ground slab
	box(
		self._model,
		"GroundFloor",
		Vector3.new(B.footprint.X, 1, B.footprint.Z),
		CFrame.new(B.center.X, -0.5, B.center.Z),
		Color3.fromRGB(100, 102, 112),
		Enum.Material.WoodPlanks
	)
	-- Upstairs slab
	box(
		self._model,
		"UpperFloor",
		Vector3.new(B.footprint.X, 1, B.footprint.Z),
		CFrame.new(B.center.X, 17.5, B.center.Z),
		Color3.fromRGB(100, 102, 112),
		Enum.Material.WoodPlanks
	)
	-- Perimeter walls (ground + upstairs)
	for _, f in ipairs({ 0, 18 }) do
		box(
			self._model,
			"WallFront",
			Vector3.new(B.footprint.X, B.wallHeight, 1),
			CFrame.new(B.center.X, f + B.wallHeight / 2, B.center.Z + B.footprint.Z / 2)
		)
		box(
			self._model,
			"WallBack",
			Vector3.new(B.footprint.X, B.wallHeight, 1),
			CFrame.new(B.center.X, f + B.wallHeight / 2, B.center.Z - B.footprint.Z / 2)
		)
		box(
			self._model,
			"WallLeft",
			Vector3.new(1, B.wallHeight, B.footprint.Z),
			CFrame.new(B.center.X - B.footprint.X / 2, f + B.wallHeight / 2, B.center.Z)
		)
		box(
			self._model,
			"WallRight",
			Vector3.new(1, B.wallHeight, B.footprint.Z),
			CFrame.new(B.center.X + B.footprint.X / 2, f + B.wallHeight / 2, B.center.Z)
		)
	end
	-- Stairwell: a ramp box connecting ground to upstairs.
	local S = B.stairwell
	box(
		self._model,
		"Stairs",
		Vector3.new(S.width, 2, S.depth),
		CFrame.new(S.base.X, S.rise / 2, S.base.Z) * CFrame.Angles(0, 0, math.rad(38)),
		Color3.fromRGB(80, 82, 92),
		Enum.Material.Wood
	)
	-- Locked door (third back room) — a sealed slab.
	box(
		self._model,
		"LockedDoor",
		Vector3.new(8, 14, 1),
		CFrame.new(-2, 7, -7.5),
		Color3.fromRGB(40, 42, 52),
		Enum.Material.Metal
	)
end

function Builder:buildRooms()
	-- Ground rooms
	for _, room in ipairs(MapLayout.ROOMS) do
		local slab = floorSlab(room)
		slab.Parent = self._model
		-- thin accent border so rooms read distinctly
		box(
			self._model,
			room.name .. " Trim",
			Vector3.new(room.size.X, 0.4, 0.6),
			CFrame.new(room.center.X, 0.2, room.center.Z + room.size.Z / 2),
			room.placeholder and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(120, 170, 255),
			Enum.Material.Neon
		)
	end
	-- Upstairs rooms (placeholders)
	for _, room in ipairs(MapLayout.UPSTAIRS) do
		local slab = floorSlab(room)
		slab.Parent = self._model
		box(
			self._model,
			room.name .. " Trim",
			Vector3.new(room.size.X, 0.4, 0.6),
			CFrame.new(room.center.X, room.floor * 18 + 0.2, room.center.Z + room.size.Z / 2),
			Color3.fromRGB(70, 70, 80),
			Enum.Material.Neon
		)
	end
end

function Builder:buildModeMarkers()
	self._indicators = {}
	self._prompts = {}
	for _, mode in ipairs(MapLayout.MODES) do
		local ind = makeIndicator(mode)
		ind.Parent = self._model
		table.insert(self._indicators, ind)

		local anchor, prompt = makePrompt(self._model, mode)
		-- pair for later wiring
		table.insert(self._prompts, { mode = mode, anchor = anchor, prompt = prompt })
	end
	-- The radio-station 3D model for Urgent Requests room.
	local ur = nil
	for _, r in ipairs(MapLayout.ROOMS) do
		if r.id == "UrgentRequests" then
			ur = r
			break
		end
	end
	if ur then
		makeRadioStation(ur)
	end
end

-- Returns the prompt list so the server can hook RemoteEvents later.
function Builder:getPrompts() return self._prompts end

function Builder:finish()
	self._model.Parent = workspace
	return self._model
end

return Builder
