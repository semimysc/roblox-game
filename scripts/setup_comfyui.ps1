# setup_comfyui.ps1
# One-time setup helper for the local ComfyUI instance + Comfy-pilot.
# Run from PowerShell. Requires Python 3.12 (installed via scoop python312).
$ErrorActionPreference = "Stop"

$py312 = "$env:USERPROFILE\scoop\apps\python312\3.12.10\python.exe"

if (-not $py312) { Write-Error "Python 3.12 not found under scoop apps/python. Install with: scoop install python312" }

$comfy = "$env:USERPROFILE\ComfyUI"
$venv  = Join-Path $comfy ".venv"

Write-Host "Using Python: $py312"
Write-Host "ComfyUI dir : $comfy"
Write-Host "Venv dir    : $venv"

if (-not (Test-Path $venv)) {
    Write-Host "==> Creating venv"
    & $py312 -m venv $venv
}

$py = Join-Path $venv "Scripts\python.exe"
Write-Host "==> Upgrading pip"
& $py -m pip install --upgrade pip

Write-Host "==> Installing torch (CUDA 12.4) for RTX 2060"
& $py -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

Write-Host "==> Installing ComfyUI requirements"
& $py -m pip install -r (Join-Path $comfy "requirements.txt")

Write-Host "==> Installing Comfy-pilot (no extra deps; uses stdlib MCP server)"
# comfy-pilot needs nothing beyond ComfyUI's deps.

Write-Host "Done. Start ComfyUI with: $venv\Scripts\python.exe $comfy\main.py"
