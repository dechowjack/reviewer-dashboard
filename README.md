# Reviewer Ticket Dashboard

Reviewer Ticket Dashboard is a local app for managing reviewer comments as tickets, tracking responses, and exporting manuscript-ready notes. `main` holds the shared app code and documentation, while the platform branches carry the minimum OS-specific build or launch utilities needed to run the same product locally.

## 1. Choose The Right Branch

Start by cloning the repository:

```bash
git clone https://github.com/dechowjack/reviewer-dashboard.git
cd reviewer-dashboard
```

Then check out the branch that matches what you are trying to do:

- `main` for the shared app source and documentation
- `mac` for the macOS local `.app` build path
- `windows` for the Windows local app build path
- `linux` for the Linux browser/local-web launch path

Examples:

```bash
git checkout mac
```

```bash
git checkout windows
```

```bash
git checkout linux
```

## 2. Build And Run On macOS

Use `mac` for the macOS local `.app` build path.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make desktop
```

This launches the local desktop app from source.

## 3. Build On Windows

Use `windows` for the Windows build flow.

Prerequisites:

- Python is installed and available on `PATH`
- your virtual environment is activated
- `pip install -r requirements.txt` has been run in that environment
- Windows PowerShell is available for `powershell -NoProfile -File ...`

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
powershell -NoProfile -File .\scripts\build_windows_desktop_app.ps1
```

This produces a local Windows desktop build from source at:

```text
dist\Reviewer Ticket Dashboard\Reviewer Ticket Dashboard.exe
```

If your local PowerShell policy blocks script execution in the current shell, use this least-invasive fallback and then rerun the build command:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
```

## 4. Run On Linux

Use `linux` for the current Linux path. Linux support is browser/local-web for now rather than a native desktop wrapper.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
./run.sh
```

This launches the same app locally and serves it on `127.0.0.1:8000`.

## 5. More Documentation

Detailed app and project documentation lives in [documentation.md](/Users/jldechow/Documents/Codex/reviewer-dashboard/documentation.md).

That file covers:

- app features and workflow
- import format and sorting rules
- local data storage paths
- troubleshooting and logs
- repo layout and legacy notes
