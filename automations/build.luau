-- Lune automation: build the place file with Rojo.
-- Usage: lune run build
local fs = require("@lune/fs")
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

fs.writeDir("build")
local code = run("rojo build default.project.json --output build/Game.rbxl")
if code ~= 0 then
	error("rojo build failed with exit code " .. tostring(code))
end
print("Built build/Game.rbxl")
