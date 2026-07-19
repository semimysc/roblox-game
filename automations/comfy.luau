-- Lune automation: start ComfyUI (so the Comfy-pilot MCP server can connect).
-- Usage: lune run comfy
-- Requires a Python 3.12 venv at C:\Users\baopi\ComfyUI\.venv with torch installed.

local process = require("@lune/process")

local COMFY_DIR = "C:\\Users\\baopi\\ComfyUI"
local PYTHON = COMFY_DIR .. "\\.venv\\Scripts\\python.exe"

local res = process.spawn(PYTHON, { COMFY_DIR .. "\\main.py", "--listen", "127.0.0.1", "--port", "8188" }, {
	cwd = COMFY_DIR,
	stdio = "inherit",
})

print("ComfyUI launched (pid " .. tostring(res.pid) .. "). Open http://127.0.0.1:8188")
print("The Comfy-pilot MCP server should now be able to connect.")
