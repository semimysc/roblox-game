-- Lune automation: run unit tests / smoke test.
-- Usage: lune run test
-- Typechecks formatting with stylua, then runs rojo build as a smoke test.
-- Expand with realmin / testez-runner when desired.
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

print("==> Format check")
local fmt = run("stylua --check src/ automations/")
if fmt ~= 0 then
	print("WARNING: stylua --check found formatting issues (run `lune run fmt`).")
end

print("==> Build smoke test")
local b = run("rojo build default.project.json --output build/Game.rbxl")
if b ~= 0 then
	error("rojo build failed")
end
print("Tests passed (build smoke test).")
