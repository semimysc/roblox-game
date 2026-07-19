-- Jest Lua test entrypoint.
-- Built into the place under ReplicatedStorage.Shared. Run from Roblox Studio
-- (or a headless runner) to execute all *.spec.luau tests.
-- Run with: select this script in Studio and press Play/Run, or trigger via the
-- test runner. See automations/test.luau for the build step.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runCLI = require("@DevPackages/Jest").runCLI

local root = ReplicatedStorage.Shared

local status, result = runCLI(root, {
	verbose = false,
	ci = false,
}, { root }):awaitStatus()

if status == "Rejected" then
	print("Jest run errored:")
	print(result)
elseif status == "Resolved" then
	local results = result.results
	if results.numFailedTestSuites == 0 and results.numFailedTests == 0 then
		print("All tests passed.")
	else
		print(
			string.format("Tests failed: %d suite(s), %d test(s)", results.numFailedTestSuites, results.numFailedTests)
		)
	end
end
