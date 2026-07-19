-- Shared.MapLayout
-- Data-driven description of the single-building hub map.
-- Everything here is data so the builder (Server/Map/Builder) and the
-- overhead/zone UI (Client/UI/ZoneUI) read from ONE source of truth.
-- Add future end-game modes by appending to `modes` and `rooms`.

export type ModeId = "Simulation" | "UrgentRequests" | "ComputerLab" | "Repair"

export type ModeDef = {
	id: ModeId,
	label: string,
	description: string,
	-- World position of the floating overhead indicator (above the door/interactable).
	indicatorCFrame: CFrame,
	-- World position the full-screen "zone" UI points at / centers on.
	zoneCFrame: CFrame,
	-- Accent color used by both the 3D billboard and the 2D UI (reskin hook).
	themeColor: Color3,
	-- Is this mode built out yet? Unbuilt modes show as "Coming soon".
	built: boolean,
}

export type RoomDef = {
	id: string,
	name: string,
	-- Center of the room footprint on the ground floor (y = 0).
	center: Vector3,
	size: Vector3,
	-- Floor the room sits on (0 = ground, 1 = upstairs).
	floor: number,
	-- If true, the room is an "aesthetic"/empty placeholder for now.
	placeholder: boolean,
	-- Optional mode attached to this room.
	mode: ModeId?,
}

local MapLayout = {}

-- Building envelope (single building, two stories).
MapLayout.BUILDING = {
	center = Vector3.new(0, 0, 0),
	footprint = Vector3.new(80, 36, 56), -- x, y(total height), z
	groundSize = Vector3.new(80, 1, 56),
	wallHeight = 18, -- per floor
	stairwell = {
		-- Connects ground floor to upstairs near the back-right.
		base = Vector3.new(30, 0, 18),
		width = 10,
		depth = 12,
		rise = 18, -- height gain to upstairs
	},
}

-- Ground floor rooms. (typed as {RoomDef} via the alias above)
MapLayout.ROOMS = {
	{
		id = "Lobby",
		name = "Lobby",
		center = Vector3.new(0, 0, 14),
		size = Vector3.new(80, 1, 28),
		floor = 0,
		placeholder = false,
		mode = nil,
	},
	{
		id = "CardShelf",
		name = "Card Shelf",
		center = Vector3.new(-26, 0, 0),
		size = Vector3.new(24, 1, 16),
		floor = 0,
		placeholder = false,
		mode = nil,
	},
	{
		id = "Simulation",
		name = "Simulation Room",
		center = Vector3.new(26, 0, 0),
		size = Vector3.new(24, 1, 16),
		floor = 0,
		placeholder = false,
		mode = "Simulation",
	},
	{
		id = "ComputerLab",
		name = "Computer Lab",
		center = Vector3.new(-24, 0, -18),
		size = Vector3.new(28, 1, 20),
		floor = 0,
		placeholder = false,
		mode = "ComputerLab",
	},
	{
		id = "UrgentRequests",
		name = "Urgent Requests",
		center = Vector3.new(10, 0, -18),
		size = Vector3.new(26, 1, 20),
		floor = 0,
		placeholder = false,
		mode = "UrgentRequests",
	},
	{
		id = "Repair",
		name = "Repair Room",
		center = Vector3.new(34, 0, -18),
		size = Vector3.new(20, 1, 20),
		floor = 0,
		placeholder = false,
		mode = "Repair",
	},
	{
		id = "LockedRoom",
		name = "Locked Room",
		center = Vector3.new(-2, 0, -18),
		size = Vector3.new(20, 1, 20),
		floor = 0,
		placeholder = false,
		mode = nil, -- closed door; third back room, reserved
	},
}

-- Upstairs: two aesthetic rooms + two empty placeholders (per spec Z-1).
MapLayout.UPSTAIRS = {
	{
		id = "AestheticA",
		name = "Gallery East",
		center = Vector3.new(-24, 18, 0),
		size = Vector3.new(36, 1, 24),
		floor = 1,
		placeholder = true,
		mode = nil,
	},
	{
		id = "AestheticB",
		name = "Gallery West",
		center = Vector3.new(24, 18, 0),
		size = Vector3.new(36, 1, 24),
		floor = 1,
		placeholder = true,
		mode = nil,
	},
	{
		id = "EmptyA",
		name = "Empty Wing A",
		center = Vector3.new(-24, 18, -18),
		size = Vector3.new(36, 1, 20),
		floor = 1,
		placeholder = true,
		mode = nil,
	},
	{
		id = "EmptyB",
		name = "Empty Wing B",
		center = Vector3.new(24, 18, -18),
		size = Vector3.new(36, 1, 20),
		floor = 1,
		placeholder = true,
		mode = nil,
	},
}

-- Game modes / overhead indicators. `themeColor` is the reskin hook: change it
-- (or point it at a Theme module) to restyle every UI touchpoint at once.
MapLayout.MODES = {
	{
		id = "Simulation",
		label = "Simulation",
		description = "Endless tower. Descend floors, collect cards.",
		indicatorCFrame = CFrame.new(26, 16, 8),
		zoneCFrame = CFrame.new(26, 4, 0),
		themeColor = Color3.fromRGB(120, 200, 255),
		built = true,
	},
	{
		id = "UrgentRequests",
		label = "Urgent Requests",
		description = "Radio station. Boss commissions and timed clears.",
		indicatorCFrame = CFrame.new(10, 16, -8),
		zoneCFrame = CFrame.new(10, 4, -18),
		themeColor = Color3.fromRGB(255, 140, 90),
		built = true,
	},
	{
		id = "ComputerLab",
		label = "Computer Lab",
		description = "Multiplayer hub and card-delivery upgrades.",
		indicatorCFrame = CFrame.new(-24, 16, -8),
		zoneCFrame = CFrame.new(-24, 4, -18),
		themeColor = Color3.fromRGB(150, 255, 180),
		built = true,
	},
	{
		id = "Repair",
		label = "Repair Room",
		description = "Maintain and modify your six-set artifacts.",
		indicatorCFrame = CFrame.new(34, 16, -8),
		zoneCFrame = CFrame.new(34, 4, -18),
		themeColor = Color3.fromRGB(255, 210, 120),
		built = true,
	},
}

-- Spawn / entrance.
MapLayout.SPAWN = Vector3.new(0, 3, 24)

return MapLayout
