-- Lune automation: format the codebase with Stylua.
-- Usage: lune run fmt
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

local code = run("stylua src/ automations/")
if code ~= 0 then
	error("stylua failed")
end
print("Formatted src/ and automations/.")
