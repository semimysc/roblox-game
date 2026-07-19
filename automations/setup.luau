-- Lune automation: install every dependency / tool the project needs.
-- Usage: lune run setup
-- Idempotent: safe to run repeatedly on a fresh clone.
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

print("==> Rokit tools")
run("rokit install")
print("==> Wally packages")
run("wally install")
print("==> Stylua format")
run("stylua src/ automations/")
print("Setup complete. Run `lune run build` to produce a place file.")
