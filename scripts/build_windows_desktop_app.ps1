$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppName = if ($env:APP_NAME) { $env:APP_NAME } else { "Reviewer Ticket Dashboard" }
$OutDir = if ($env:OUT_DIR) { $env:OUT_DIR } else { Join-Path $RootDir "dist" }
$BuildWorkDir = Join-Path $RootDir ".pyinstaller-build"
$IconPath = Join-Path $RootDir "assets\icons\reviewer_dashboard.ico"
$PythonInfoJson = python -c "import json, os, sys; print(json.dumps({'base_prefix': sys.base_prefix, 'exec_prefix': sys.exec_prefix, 'executable_dir': os.path.dirname(sys.executable)}))"
$PythonInfo = $PythonInfoJson | ConvertFrom-Json

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

$BinarySearchDirs = @(
    $PythonInfo.executable_dir,
    $PythonInfo.base_prefix,
    $PythonInfo.exec_prefix,
    (Join-Path $PythonInfo.base_prefix "DLLs"),
    (Join-Path $PythonInfo.exec_prefix "DLLs"),
    (Join-Path $PythonInfo.base_prefix "Library\bin"),
    (Join-Path $PythonInfo.exec_prefix "Library\bin")
) | Where-Object { $_ } | Select-Object -Unique

$SslBinaryPatterns = @(
    "libssl-*.dll",
    "libcrypto-*.dll",
    "libssl*.dll",
    "libcrypto*.dll"
)

$SslBinaries = @()
foreach ($Dir in $BinarySearchDirs) {
    if (-not (Test-Path $Dir)) {
        continue
    }

    foreach ($Pattern in $SslBinaryPatterns) {
        $SslBinaries += Get-ChildItem -Path $Dir -Filter $Pattern -File -ErrorAction SilentlyContinue
    }
}

$SslBinaries = $SslBinaries | Sort-Object FullName -Unique

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

if ($SslBinaries.Count -eq 0) {
    Write-Host "Warning: no OpenSSL DLLs were found in the active Python environment. If the built app fails importing _ssl, use a python.org Python install or verify OpenSSL DLLs are present."
} else {
    foreach ($Binary in $SslBinaries) {
        $PyInstallerArgs += @("--add-binary", "$($Binary.FullName);.")
    }
}

python -m PyInstaller @PyInstallerArgs

Write-Host "Built Windows desktop app: $OutDir\$AppName\$AppName.exe"
