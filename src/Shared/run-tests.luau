-- Jest Lua test entrypoint.
-- Built into the place under ReplicatedStorage.Shared. Run from Roblox Studio
-- (select this script in Explorer, then press Run / F8) to execute all
-- *.spec.luau tests. See automations/test.luau for the build step.
--
-- Uses the real jsdotlua/jest v3.10.0 API:
--   runCLI(cwdInstance, argv, projects) -> Promise<{ results, ... }>

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runCLI = require("@DevPackages/Jest").runCLI

local root = ReplicatedStorage.Shared

local resolved
local ok, result = pcall(function()
	runCLI(root, {
		verbose = false,
		ci = false,
	}, { root }):andThen(function(r) resolved = r end)
	while resolved == nil do
		task.wait()
	end
	return resolved
end)

if not ok or result == nil then
	print("Jest run errored:")
	print(result)
else
	local results = result.results
	if results.numFailedTestSuites == 0 and results.numFailedTests == 0 then
		print("All tests passed.")
	else
		print(
			string.format("Tests failed: %d suite(s), %d test(s)", results.numFailedTestSuites, results.numFailedTests)
		)
	end
end
