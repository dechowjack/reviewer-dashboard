$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

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

& $PythonCommand.Executable @($PythonCommand.PrefixArgs + @("-m", "app.desktop"))
