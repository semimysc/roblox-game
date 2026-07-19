-- Client entry point (StarterPlayerScripts.Client).
local Fusion = require(script.Parent.Parent.Packages.Fusion)
local Value = Fusion.Value

local count = Value(0)

-- Whenever the counter value changes, update the screen.
local function render() print("Client sees count =", count:get()) end

count:get()
render()
task.spawn(function()
	while true do
		task.wait(2)
		render()
	end
end)

print("Game client started (Fusion UI placeholder)")
