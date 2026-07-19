# Game — Roblox project

Professional Roblox toolchain, managed entirely through [Rokit](https://github.com/rojo-rbx/rokit).

## Toolchain (all installed via Rokit — run `rokit install` on a fresh clone)
- **rojo** (`rojo-rbx/rojo`) — build/sync between filesystem and Roblox Studio.
- **wally** (`UpliftGames/wally`) — Luau dependency manager (`wally install`).
- **lune** (`lune-org/lune`) — automation scripts in `automations/` (`lune run <name>`).
- **tungsten** (`pwnwrkz/tungsten`) — cloud asset manager (`tungsten.toml`). Needs `TUNGSTEN_API_KEY` (Roblox Open Cloud). Replaces the older rojo-rbx/tarmac.
- **stylua** (`JohnnyMorganz/stylua`) — formatter (`stylua src/ automations/`).
- (selene linting config present; install `selene` separately if desired.)

## Project layout
- `default.project.json` — Rojo project tree → `src/Server`, `src/Client`, `src/Shared`, `src/StarterCharacter`, `src/Packages` (Wally output), `src/DevPackages` (Jest test deps), `src/Generated` (Tungsten output).
- `wally.toml` — package dependencies (Fusion + OnyxUI + Rodux + FusionRodux-2 bridge, Promise, Charm) and dev-deps (Jest + JestGlobals).
- `tungsten.toml` — asset sync config.
- `automations/` — Lune scripts: `build`, `test`, `lint`, `fmt`, `sync`, `setup`, `serve`, `comfy`.
- `WORKFLOW.md` — full dev-loop docs (Studio sync, Jest, Tungsten, ComfyUI).

## Common commands
```pwsh
rokit install          # install all Rokit-managed tools
wally install          # install Luau packages into src/Packages + DevPackages
lune run setup         # install tools + packages + format
lune run serve         # start Rojo live-sync server (connect from Studio plugin)
lune run build         # produce build/Game.rbxl
lune run fmt           # format
lune run lint          # lint (selene)
lune run test          # fmt check + build (tests packed into place)
lune run sync          # push assets to Roblox cloud (needs TUNGSTEN_API_KEY)
lune run comfy         # launch ComfyUI (needs up-to-date NVIDIA driver)
```

## Testing (Jest Lua / jsdotlua)
- Tests are `*.spec.luau` under `src/`; config at `src/Shared/jest.config.lua` (testMatch `**/*.spec.luau`).
- Entry point: `src/Shared/run-tests.luau` calls `require("@DevPackages/Jest").runCLI`.
- Tests `require("@DevPackages/JestGlobals")` for `describe`/`it`/`expect` (no globals injected).
- Jest runs *inside* Roblox: `lune run test` builds the place, then run `run-tests` in Studio.
- `Jest@3.10.0` + `JestGlobals@3.10.0` are the working pins (3.6.x rc lines are NOT self-consistent in the index).

## ComfyUI / Comfy-pilot guardrails
This repo is also wired to **Comfy-pilot** (ComfyUI MCP server) in `~/.claude.json`.
- Comfy-pilot can edit/run ComfyUI workflows and **auto-downloads models** with no confirmation prompts.
- Treat it as a power tool on a trusted machine only. Do NOT let automated runs delete custom nodes, wipe the ComfyUI models folder, or change `extra_model_paths.yaml` without an explicit human request.
- ComfyUI model files are large and gitignored; never commit them.

## Proxy note
Claude Code reaches the model through a local intermediary (`ANTHROPIC_BASE_URL=http://127.0.0.1:8899`) → OpenRouter. Proxy config lives in `.claude/settings.json`; do not remove it.
