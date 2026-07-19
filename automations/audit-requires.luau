-- Lune automation: statically audit every require(script...) path in src/.
-- Catches "X is not a valid member of ..." require-resolution bugs BEFORE
-- they reach Roblox Studio (rojo build / stylua cannot catch these — they
-- only fail at runtime when the script executes).
--
-- Usage: lune run audit-requires
-- Exits non-zero if any require path does not resolve to a real file/folder.

local fs = require("@lune/fs")
local path = require("@lune/path")

-- automations/audit-requires.luau -> repo root is script.Parent.Parent
local SRC = path.join(script.Parent.Parent, "src")

-- Build a set of every file path (normalized, forward slashes) under src/.
local files: { [string]: boolean } = {}
local function walk(dir: string)
	for _, entry in ipairs(fs.readDir(dir)) do
		local full = path.join(dir, entry)
		local kind = fs.exists(full)
		if kind == "Dir" then
			walk(full)
		elseif kind == "File" then
			-- Accept .luau / .lua; the require target may omit the extension.
			files[full:gsub("\\", "/")] = true
		end
	end
end
walk(SRC)

-- Resolve a require(script...) chain to an absolute path.
-- e.g. "script.Parent.Data.Profiles" from src/Server/init.server.luau
local function resolve(startFile: string, expr: string): string?
	-- expr like "script" / "script.Parent.Data.Profiles" / "script.UI.Theme"
	local parts = {}
	for seg in expr:gmatch("[^%.]+") do
		table.insert(parts, seg)
	end
	if parts[1] ~= "script" then
		return nil -- not a script-relative require; skip
	end

	local curDir = startFile:match("^(.*)/[^/]+$") -- dir containing the file
	for i = 2, #parts do
		local seg = parts[i]
		if seg == "Parent" then
			curDir = curDir:match("^(.*)/[^/]+$") or curDir
		elseif seg == "Parent.Parent" then
			curDir = (curDir:match("^(.*)/[^/]+$") or curDir):match("^(.*)/[^/]+$") or curDir
		else
			curDir = path.join(curDir, seg)
		end
	end

	-- The target may be a file (with ext) or a folder containing init.
	local candidates = {
		curDir .. ".luau",
		curDir .. ".lua",
		path.join(curDir, "init.luau"),
		path.join(curDir, "init.lua"),
	}
	for _, c in ipairs(candidates) do
		if files[c:gsub("\\", "/")] then
			return c
		end
	end
	return nil
end

local bad: { { file: string, line: number, expr: string } } = {}
for _, entry in ipairs((function()
	local out = {}
	local function w(d: string)
		for _, e in ipairs(fs.readDir(d)) do
			local full = path.join(d, e)
			if fs.exists(full) == "Dir" then
				w(full)
			else
				table.insert(out, full)
			end
		end
	end
	w(SRC)
	return out
end)()) do
	if not entry:match("%.luau$") and not entry:match("%.lua$") then
		continue
	end
	local content = fs.readFile(entry)
	local lineNo = 0
	for line in content:gmatch("[^\n]*") do
		lineNo += 1
		local expr = line:match("require%(script%.([%w%.]+)%)")
		if expr then
			local target = resolve(entry, "script." .. expr)
			if not target then
				table.insert(bad, { file = entry, line = lineNo, expr = expr })
			end
		end
	end
end

if #bad > 0 then
	print("Require audit FAILED — unresolved script-relative requires:")
	for _, b in ipairs(bad) do
		local rel = b.file:match("src[/\\].*$") or b.file
		print(string.format("  %s:%d  require(script.%s)", rel, b.line, b.expr))
	end
	os.exit(1)
else
	print("Require audit passed — all script-relative requires resolve.")
end
