# Reviewer Ticket Dashboard

Reviewer Ticket Dashboard is a local desktop app for managing reviewer comments as tickets, tracking responses, and exporting manuscript-ready notes. The intended setup is source-first: clone the repo, check out the branch for your platform, and build the app locally.

## 1. Choose The Right Branch

Start by cloning the repository:

```bash
git clone https://github.com/dechowjack/reviewer-dashboard.git
cd reviewer-dashboard
```

Then check out the branch that matches what you are trying to do:

- `main` for the live macOS build
- `mac-dev` for ongoing macOS development
- `windows-dev` for Windows build work

Examples:

```bash
git checkout main
```

```bash
git checkout windows-dev
```

## 2. Build And Run On macOS

Use `main` if you want the current live macOS build. `mac-dev` currently tracks the same code for macOS development work.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make desktop
```

This launches the local desktop app from source.

## 3. Build On Windows

Use `windows-dev` for the Windows build flow. The Windows build tooling does not live on `main`.

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows_desktop_app.ps1
```

This produces a local Windows desktop build from source at:

```text
dist\Reviewer Ticket Dashboard\Reviewer Ticket Dashboard.exe
```

## 4. More Documentation

Detailed app and project documentation lives in [documentation.md](/Users/jldechow/Documents/Codex/reviewer-dashboard/documentation.md).

That file covers:

- app features and workflow
- import format and sorting rules
- local data storage paths
- troubleshooting and logs
- repo layout and legacy notes
