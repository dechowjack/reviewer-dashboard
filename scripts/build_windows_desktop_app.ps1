$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppName = if ($env:APP_NAME) { $env:APP_NAME } else { "Reviewer Ticket Dashboard" }
$OutDir = if ($env:OUT_DIR) { $env:OUT_DIR } else { Join-Path $RootDir "dist" }
$BuildWorkDir = Join-Path $RootDir ".pyinstaller-build"
$IconPath = Join-Path $RootDir "assets\icons\reviewer_dashboard.ico"

if (-not (Get-Command pyinstaller -ErrorAction SilentlyContinue)) {
    throw "pyinstaller is required. Install with: pip install pyinstaller"
}

python -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('openpyxl') and importlib.util.find_spec('webview') else 1)"
if ($LASTEXITCODE -ne 0) {
    throw "Missing runtime dependency for desktop build. Install with: pip install -r requirements.txt"
}

if (Test-Path $BuildWorkDir) {
    Remove-Item -Recurse -Force $BuildWorkDir
}

New-Item -ItemType Directory -Force -Path $BuildWorkDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$PyInstallerArgs = @(
    "--name", $AppName,
    "--distpath", $OutDir,
    "--workpath", $BuildWorkDir,
    "--add-data", "$RootDir\app\static;app/static",
    "--add-data", "$RootDir\app\templates;app/templates",
    "--collect-submodules", "app",
    "--collect-submodules", "openpyxl",
    "--collect-submodules", "webview",
    "--hidden-import", "webview",
    "--hidden-import", "openpyxl",
    "--clean",
    "--noconfirm",
    "--windowed",
    "$RootDir\app\desktop.py"
)

if (Test-Path $IconPath) {
    $PyInstallerArgs = @("--icon", $IconPath) + $PyInstallerArgs
}

& pyinstaller @PyInstallerArgs

Write-Host "Built Windows desktop app: $OutDir\$AppName\$AppName.exe"
