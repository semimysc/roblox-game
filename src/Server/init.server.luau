-- Server entry point (ServerScriptService.Server).
local Counter = require(script.Parent.Parent.Shared.Counter)

local store = Counter.makeStore()
print("Game server started; counter =", store:getState())

-- Example: increment once per second so you can see state changing.
task.spawn(function()
	while true do
		task.wait(1)
		store:dispatch({ type = "increment" })
	end
end)
