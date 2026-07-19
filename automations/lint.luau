-- Lune automation: lint the codebase with Selene.
-- Usage: lune run lint
-- Requires `selene` to be installed (not currently managed by Rokit); the
-- script errors clearly if it is missing.
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

-- selene must exist on PATH
local probe = run("where selene")
if probe ~= 0 then
	error("selene is not installed. Install it (cargo install selene) or remove lint from CI.")
end

local code = run("selene src/")
if code ~= 0 then
	error("selene reported lint errors")
end
print("Lint clean.")
