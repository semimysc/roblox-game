# ComfyUI + Comfy-pilot setup

Local image-generation stack wired to Claude Code via the Comfy-pilot MCP server.

## Layout (outside this repo, to keep git clean)
- `C:\Users\baopi\ComfyUI` — ComfyUI (git clone)
- `C:\Users\baopi\ComfyUI\.venv` — Python 3.12 venv (torch CUDA 12.4)
- `C:\Users\baopi\ComfyUI\custom_nodes\comfy-pilot` — Comfy-pilot (git clone)

## Why a separate Python?
ComfyUI's `torch` CUDA wheels target Python 3.12. The repo's Rokit/Roblox tooling
doesn't need Python. A dedicated 3.12 venv avoids conflicts with the system Python 3.14.

## Start ComfyUI
```pwsh
C:\Users\baopi\ComfyUI\.venv\Scripts\python.exe C:\Users\baopi\ComfyUI\main.py
```
It serves on http://127.0.0.1:8188. Open that in a browser.

## Comfy-pilot / Claude Code wiring
- Comfy-pilot is a ComfyUI **custom node** that also runs an MCP server
  (`custom_nodes/comfy-pilot/mcp_server.py`). It talks to ComfyUI's HTTP API on port 8188.
- The MCP server is registered globally in `~/.claude.json` under `mcpServers.comfyui`,
  so Claude Code can call it from any project.
- It does NOT route through the model proxy (127.0.0.1:8899); it only needs ComfyUI
  running locally.

### Security note (important)
Comfy-pilot can **edit/run ComfyUI workflows and auto-download models with no
confirmation prompts**. Per `CLAUDE.md`, treat it as a trusted-machine power tool:
do not let automated runs wipe the models folder or change `extra_model_paths.yaml`
without an explicit request.

## One-time setup (already run)
`scripts/setup_comfyui.ps1` created the venv and installed torch + ComfyUI deps.

## Typical workflow
1. Start ComfyUI (command above).
2. In Claude Code, ask e.g. "show me the current ComfyUI workflow" — the `comfyui`
   MCP tools become available.
3. Generate textures/UI assets for the Roblox game, then bring them in via Tungsten (`tungsten sync`).
