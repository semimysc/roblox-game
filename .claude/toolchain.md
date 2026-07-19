---
name: toolchain
description: Roblox project toolchain versions, working dependency pins, and known blockers for the c:/Desktop/Game project
---

# Roblox toolchain (c:/Desktop/Game)

Professional Roblox setup managed entirely via Rokit. Repo: `semimysc/roblox-game` on GitHub (master branch).

## Toolchain versions (rokit.toml)
- rojo 7.7.0, wally 0.3.2, lune 0.10.5, tungsten 3.0.0, stylua 2.5.2
- `.rokit/bin` is on the Windows **User** PATH. VS Code terminals need a restart to see it.
- Rokit bin path is `C:\Users\baopi\.rokit\bin`.

## Working dependency pins (wally.toml)
- Fusion = elttob/fusion@0.2.0 (pinned because FusionRodux-2 bridge only supports >=0.2.0,<0.3.0)
- OnyxUI = imavafe/onyx-ui@1.0.4, ColourUtils = csqrl/colour-utils@1.4.1
- Rodux = roblox/rodux@3.0.0
- FusionRodux = vflour/fusionrodux-2@0.1.32
- Promise = evaera/promise@4.0.0, Charm = littlensy/charm@0.7.6
- Jest = jsdotlua/jest@3.10.0, JestGlobals = jsdotlua/jest-globals@3.10.0 (DEV deps)

## Jest Lua (jsdotlua) — critical gotchas
- Jest runs ONLY inside Roblox (Studio). It is NOT a Lune/CLI runner.
- Test files: `*.spec.luau`, matched by `src/Shared/jest.config.lua` (testMatch `**/*.spec.luau`).
- Tests MUST `require("@DevPackages/JestGlobals")` for describe/it/expect — Jest injects nothing into globals.
- `jest-globals` ERRORS if required outside the Jest environment (by design).
- Entry point `src/Shared/run-tests.luau` calls `require("@DevPackages/Jest").runCLI(...)`.
- DevPackages is mounted in `default.project.json` under ReplicatedStorage so `@DevPackages/...` resolves.
- **DO NOT use jsdotlua/jest@3.6.x-rc lines** — they are internally inconsistent in the Wally index (request luau-polyfill >=3.10.0 which doesn't exist). 3.10.0 works.

## ComfyUI / Comfy-pilot
- ComfyUI at `C:\Users\baopi\ComfyUI`, venv at `.venv` (NOT `venv`), Python 3.12.10 via scoop `python312`.
- torch 2.6.0+cu124 installed. MCP server in `~/.claude.json` points comfyui -> `.venv/Scripts/python.exe` + `custom_nodes/comfy-pilot/mcp_server.py` on port 8188.
- **BLOCKER: NVIDIA driver is ancient (25.21.14.1749, CUDA 10.0 era). ComfyUI crashes at torch.cuda init.** Needs driver update (>=551 for cu124) before GPU works. User chose to do this later. CPU-only torch is a possible fallback.

## Known false-positive IDE diagnostics
- The Luau language-server in VS Code does NOT load `selene.toml` (std=roblox), so it falsely flags `script`, `task`, `game`, `Players`, `Enum`, type annotations (e.g. `player: Player`) as errors. These are VALID Roblox Luau. Trust `stylua --check` + `rojo build` instead.

## Proxy / env
- Claude Code uses `ANTHROPIC_BASE_URL=http://127.0.0.1:8899` -> OpenRouter. Config in `.claude/settings.json` (gitignored, contains OpenRouter key).
- TUNGSTEN_API_KEY is a permanent Windows User env var (not in any file). Creator id in tungsten.toml is user 1032387470 (user, not group — no group purchased).

## Update rules
- `rokit update` / `wally update` then commit rokit.toml + wally.lock. Never hand-edit versions.
- ComfyUI: `.venv/Scripts/python.exe -m pip install --upgrade -r requirements.txt`
