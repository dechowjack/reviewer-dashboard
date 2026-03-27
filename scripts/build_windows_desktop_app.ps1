$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$AppName = if ($env:APP_NAME) { $env:APP_NAME } else { "Reviewer Ticket Dashboard" }
$OutDir = if ($env:OUT_DIR) { $env:OUT_DIR } else { Join-Path $RootDir "dist" }
$BuildWorkDir = Join-Path $RootDir ".pyinstaller-build"
$IconPath = Join-Path $RootDir "assets\icons\reviewer_dashboard.ico"

function Resolve-PythonCommand {
    if ($env:VIRTUAL_ENV) {
        $venvPython = Join-Path $env:VIRTUAL_ENV "Scripts\python.exe"
        if (Test-Path $venvPython) {
            return @{
                Executable = $venvPython
                PrefixArgs = @()
            }
        }
    }

    $repoVenvPython = Join-Path $RootDir ".venv\Scripts\python.exe"
    if (Test-Path $repoVenvPython) {
        return @{
            Executable = $repoVenvPython
            PrefixArgs = @()
        }
    }

    if ($env:CONDA_PREFIX) {
        $condaPython = Join-Path $env:CONDA_PREFIX "python.exe"
        if (Test-Path $condaPython) {
            return @{
                Executable = $condaPython
                PrefixArgs = @()
            }
        }
    }

    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCommand -and $pythonCommand.Source -notlike "*WindowsApps*") {
        return @{
            Executable = $pythonCommand.Source
            PrefixArgs = @()
        }
    }

    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        return @{
            Executable = $pyLauncher.Source
            PrefixArgs = @("-3")
        }
    }

    return $null
}

$PythonCommand = Resolve-PythonCommand
if (-not $PythonCommand) {
    throw "Python could not be found. Activate your virtual environment or Conda environment, or create .venv and run: pip install -r requirements.txt"
}

$PythonInfoJson = & $PythonCommand.Executable @($PythonCommand.PrefixArgs + @("-c", "import json, os, sys; print(json.dumps({'base_prefix': sys.base_prefix, 'exec_prefix': sys.exec_prefix, 'executable_dir': os.path.dirname(sys.executable)}))"))
$PythonInfo = $PythonInfoJson | ConvertFrom-Json

$RequiredModules = @("PyInstaller", "openpyxl", "webview")
$MissingModules = @()

foreach ($Module in $RequiredModules) {
    & $PythonCommand.Executable @($PythonCommand.PrefixArgs + @("-c", "import importlib.util, sys; sys.exit(0 if importlib.util.find_spec('$Module') else 1)"))
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

$AdditionalRuntimeBinaryPatterns = @(
    "liblzma.dll",
    "libbz2.dll",
    "LIBBZ2.dll",
    "libmpdec-4.dll",
    "ffi.dll",
    "libexpat.dll",
    "sqlite3.dll"
)

$ExtraBinaries = @()
foreach ($Dir in $BinarySearchDirs) {
    if (-not (Test-Path $Dir)) {
        continue
    }

    foreach ($Pattern in $SslBinaryPatterns) {
        $ExtraBinaries += Get-ChildItem -Path $Dir -Filter $Pattern -File -ErrorAction SilentlyContinue
    }

    foreach ($Pattern in $AdditionalRuntimeBinaryPatterns) {
        $ExtraBinaries += Get-ChildItem -Path $Dir -Filter $Pattern -File -ErrorAction SilentlyContinue
    }
}

$ExtraBinaries = $ExtraBinaries | Sort-Object FullName -Unique

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

if ($ExtraBinaries.Count -eq 0) {
    Write-Host "Warning: no OpenSSL DLLs were found in the active Python environment. If the built app fails importing _ssl, use a python.org Python install or verify OpenSSL DLLs are present."
} else {
    foreach ($Binary in $ExtraBinaries) {
        $PyInstallerArgs += @("--add-binary", "$($Binary.FullName);.")
    }
}

& $PythonCommand.Executable @($PythonCommand.PrefixArgs + @("-m", "PyInstaller") + $PyInstallerArgs)

Write-Host "Built Windows desktop app: $OutDir\$AppName\$AppName.exe"
