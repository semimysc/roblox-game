-- Lune automation: run unit tests / smoke test.
-- Usage: lune run test
-- 1. Formats/checks src + automations with stylua.
-- 2. Builds the place file (build/Game.rbxl) so Jest tests are packed in.
-- 3. Notes how to actually run the Jest tests (in Roblox Studio).
-- Jest Lua runs inside Roblox, not via Lune, so the real test execution
-- happens in Studio: open build/Game.rbxl, then run src/Shared/run-tests.luau.
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

print("==> Build place (packs Jest + tests into build/Game.rbxl)")
local b = run("rojo build default.project.json --output build/Game.rbxl")
if b ~= 0 then
	error("rojo build failed")
end
print("Build OK. To run Jest tests:")
print("  1. Open build/Game.rbxl in Roblox Studio")
print("  2. In the Explorer, find ReplicatedStorage > Shared > run-tests")
print("  3. Right-click > 'Run' (or press Play with it selected)")
print("  All *.spec.luau tests under Shared will execute.")
