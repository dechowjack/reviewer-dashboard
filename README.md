# Reviewer Ticket Dashboard

Reviewer Ticket Dashboard is a local desktop app for managing reviewer comments as tickets, tracking responses, and exporting manuscript-ready notes.

## 1. Platform Setup

This project now has platform-specific setup paths.

- macOS is the current stable desktop path.
- Windows packaging is being developed on `windows-dev`.
- If you only want to use the app, prefer downloading the packaged app for your platform instead of building from source.

## 2. Clone The Right Branch

Choose the branch that matches what you are doing:

- `main` for the current stable repo state
- `mac-dev` for ongoing macOS desktop development
- `windows-dev` for Windows executable work

Example:

```bash
git clone https://github.com/dechowjack/reviewer-dashboard.git
cd reviewer-dashboard
git checkout windows-dev
```

If you are not developing, you may not need to clone the repo at all.

## 3. Install And Run

### 3a. macOS

Recommended for most users:

1. Download `Reviewer Ticket Dashboard.dmg`
2. Open the DMG
3. Drag `Reviewer Ticket Dashboard.app` into `/Applications`
4. Launch the app

If you need to build from source on macOS:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make desktop
```

To build the packaged app:

```bash
make desktop-build
make desktop-dmg
```

### 3b. Windows

Target end-state:

1. Download `Reviewer Ticket Dashboard.exe`
2. Run the `.exe`

Current status:

- Windows packaging is still in progress.
- On this branch, the expected build output is `dist\Reviewer Ticket Dashboard\Reviewer Ticket Dashboard.exe`.
- The Windows build flow still needs real-machine verification.

If you are testing the Windows build from source:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_windows_desktop_app.ps1
```

## 4. More Documentation

The detailed documentation has been moved to [documentation.md](/Users/jldechow/Documents/Codex/reviewer-dashboard/documentation.md).

That file covers:

- app features and workflow
- import format and sorting rules
- local data storage paths
- troubleshooting and logs
- repo layout and legacy notes
