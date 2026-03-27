$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppName = if ($env:APP_NAME) { $env:APP_NAME } else { "Reviewer Ticket Dashboard" }
$OutDir = if ($env:OUT_DIR) { $env:OUT_DIR } else { Join-Path $RootDir "dist" }
$BuildWorkDir = Join-Path $RootDir ".pyinstaller-build"
$IconPath = Join-Path $RootDir "assets\icons\reviewer_dashboard.ico"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python is required on PATH. Install Python, activate your virtual environment, and run: pip install -r requirements.txt"
}

$RequiredModules = @("PyInstaller", "openpyxl", "webview")
$MissingModules = @()

foreach ($Module in $RequiredModules) {
    python -c "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('$Module') else 1)"
    if ($LASTEXITCODE -ne 0) {
        $MissingModules += $Module
    }
}

if ($MissingModules.Count -gt 0) {
    $MissingModuleList = $MissingModules -join ", "
    throw "Missing required Python packages: $MissingModuleList. Activate your virtual environment and run: pip install -r requirements.txt"
}

$null = python -m PyInstaller --version 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller is installed incorrectly or unavailable in this Python environment. Activate your virtual environment and run: pip install -r requirements.txt"
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
} else {
    Write-Host "Windows icon not found at $IconPath. Building without a custom icon."
}

python -m PyInstaller @PyInstallerArgs

Write-Host "Built Windows desktop app: $OutDir\$AppName\$AppName.exe"
