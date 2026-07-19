-- Lune automation: sync local assets to the Roblox cloud via Tungsten.
-- Usage: lune run sync
-- Requires TUNGSTEN_API_KEY (Roblox Open Cloud API key) in env.
local process = require("@lune/process")

local function run(cmd)
	local res = process.exec("powershell", {
		"-NoProfile",
		"-Command",
		cmd,
	})
	if not res.ok then
		error("failed to launch: " .. tostring(res.stdout))
	end
	if res.stdout and res.stdout ~= "" then
		print(res.stdout)
	end
	if res.stderr and res.stderr ~= "" then
		print(res.stderr)
	end
	return res.code or 1
end

local key = process.env["TUNGSTEN_API_KEY"]
if not key or key == "" then
	error("TUNGSTEN_API_KEY is not set; cannot sync assets. See tungsten.toml.")
end

local code = run("tungsten sync --target cloud")
if code ~= 0 then
	error("tungsten sync failed")
end
print("Assets synced to Roblox cloud.")
