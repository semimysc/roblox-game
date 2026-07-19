# Development workflow

Everything is driven through Rokit-managed tools and Lune automations. On a fresh
clone run `rokit install` then `wally install` first.

## 1. Live-sync with Roblox Studio (the core loop)

One-time setup:
1. Install the **Rojo** plugin in Studio (Studio → Toolbox → Plugins, search "Rojo",
   or get it from https://create.roblox.com/store/asset/13916111004/Rojo).
2. Open a place in Studio (a blank baseplate is fine).

Every session:
1. In a terminal: `lune run serve` (starts the Rojo server; leave it running).
2. In Studio: **Plugins → Rojo → Connect** (default address `localhost:34872`).
3. Now edit files under `src/` in VS Code — changes appear in Studio instantly.

> The tree mapping (what goes where in the DataModel) is in `default.project.json`.

## 2. Build a place file (no Studio needed)

```pwsh
lune run build          # -> build/Game.rbxl
```

## 3. Run tests (Jest Lua)

Jest runs *inside* Roblox, so:
1. `lune run test` — formats, then builds `build/Game.rbxl` with the tests packed in.
2. Open `build/Game.rbxl` in Studio.
3. In Explorer: **ReplicatedStorage → Shared → run-tests**, right-click → **Run**.
4. Test results print to the Output window.

Test files are any `*.spec.luau` under `src/` (see `src/Shared/Counter.spec.luau`).
Config is `src/Shared/jest.config.lua`.

## 4. Format & lint

```pwsh
lune run fmt            # stylua auto-format
lune run lint           # selene (install selene separately if you want this)
```

## 5. Assets (Tungsten)

1. Drop files in `assets/images`, `assets/audio`, or `assets/models`.
2. Set your key in the shell (permanent env var recommended):
   `$env:TUNGSTEN_API_KEY = "<roblox open cloud key>"`
3. Confirm your creator id in `tungsten.toml` (currently `type = "user"`, `id = 1032387470`).
4. Dry run: `tungsten sync cloud --dry-run`
5. Real upload: `lune run sync` (or `tungsten sync cloud`).
   Generated Luau id modules land in `src/Generated/` (gitignored).

## 6. ComfyUI (asset generation, optional)

- Start it: `lune run comfy` (needs an up-to-date NVIDIA driver — see README note).
- The Comfy-pilot MCP server (in `~/.claude.json`) connects on port 8188.

## Updating tools & packages

```pwsh
rokit update            # bump toolchain tools (rojo, wally, lune, ...) -> commit rokit.toml
wally update            # bump Luau packages -> commit wally.lock
rokit self-update       # update Rokit itself
```
