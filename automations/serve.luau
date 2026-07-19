-- Lune automation: start a Rojo live-sync server.
-- Usage: lune run serve
-- Keeps running and syncs src/ <-> Roblox Studio in real time.
-- Requires the Rojo Studio plugin (install once from roblox.com/library).
-- Then in Studio: Plugins > Rojo > Connect, and pick the address shown here.
local process = require("@lune/process")

print("==> Starting Rojo sync server...")
print("    Open Roblox Studio, install the Rojo plugin, then Plugins > Rojo > Connect.")
print("    (Leave this terminal running — it is the live sync bridge.)")

local res = process.spawn("rojo", { "serve", "default.project.json" }, {
	cwd = ".",
	stdio = "inherit",
})

-- Keep the process alive; rojo serve blocks until interrupted.
res.wait()
print("Rojo server stopped.")
