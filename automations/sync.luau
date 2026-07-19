-- Lune automation: sync local assets to the Roblox cloud via Tarmac.
-- Usage: lune run sync
-- Requires OPEN_CLOUD_API_KEY (+ optionally PLACE_ID/UNIVERSE_ID) in env.
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

local key = process.env["OPEN_CLOUD_API_KEY"]
if not key or key == "" then
	error("OPEN_CLOUD_API_KEY is not set; cannot sync assets. See tarmac.toml.")
end

local code = run("tarmac sync --target roblox")
if code ~= 0 then
	error("tarmac sync failed")
end
print("Assets synced to Roblox cloud.")
