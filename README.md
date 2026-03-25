# Reviewer Ticket Dashboard

Reviewer Ticket Dashboard is a local macOS desktop app for turning reviewer comments from CSV/XLSX into editable tickets with response tracking, manuscript separation, and Markdown export.

## macOS Only

This project currently targets macOS only.

- The supported installable output is a macOS `.app` bundled inside a `.dmg`.
- The packaging scripts rely on macOS tools such as `hdiutil` and `iconutil`.
- The current sharing/distribution path is: build the DMG on a Mac, then have coworkers drag the app into `/Applications`.

If you are looking for the older browser-first localhost workflow, treat it as legacy. The desktop app is now the primary product.

## What It Does

- Import reviewer comments from `.csv` or `.xlsx`
- Organize work by manuscript
- Track tickets in `OPEN` and `COMPLETED`
- Require non-empty `response_text` before completion
- Reopen completed tickets
- Add manual tickets
- Search and filter tickets
- Jump between open tickets with next/previous navigation
- Export manuscript responses to Markdown
- Store data locally in SQLite

## Quick Start

### Option 1: Use the packaged app

This is the recommended path for coworkers.

1. Download `Reviewer Ticket Dashboard.dmg`
2. Open the DMG
3. Drag `Reviewer Ticket Dashboard.app` into `/Applications`
4. Launch the app from Applications

### Option 2: Run from source on macOS

```bash
git clone <your-repo-url>
cd reviewer-dashboard
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make desktop
```

This starts the local backend automatically and opens the app in a native macOS window.

## Build the App

From a macOS machine:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make desktop-build
```

This creates:

- `dist/Reviewer Ticket Dashboard.app`

To build the DMG for sharing:

```bash
make desktop-dmg
```

This creates:

- `dist/Reviewer Ticket Dashboard.dmg`

## Features

- Two ticket states: `OPEN` and `COMPLETED`
- Editable fields:
  - `reviewer_id`
  - `line_number`
  - `verbatim_comment`
  - `comment_category`
  - `response_text`
- Manuscript create/select/rename workflow
- CSV/XLSX import using a fixed four-column schema
- Markdown export per manuscript
- TODO-first sort behavior
- Theme toggle

## Import Format

Import files must use this exact column order:

1. `reviewer_id`
2. `line_number`
3. `verbatim_comment`
4. `comment_category`

Example:

```csv
reviewer_id,line_number,verbatim_comment,comment_category
```

Accepted `comment_category` values:

- `editorial`
- `major`
- `minor`

`line_number` may be numeric or a range-like string such as `210-225` or `L210-225`. The first integer is used for sorting and the original value is preserved for display.

## Data Storage

Desktop mode stores the database at:

- `~/Documents/reviewer-ticket-dashboard/reviewer_dashboard.db`

On first launch in standalone desktop mode, the app can migrate existing data from:

1. `~/Library/Application Support/Reviewer Ticket Dashboard/reviewer_dashboard.db`
2. `data/reviewer_dashboard.db`

To override the database path:

```bash
export REVIEWER_DASHBOARD_DB_PATH=/your/custom/path/reviewer_dashboard.db
```

Manual backup example:

```bash
cp ~/Documents/reviewer-ticket-dashboard/reviewer_dashboard.db reviewer_dashboard.backup.db
```

## Troubleshooting

If the desktop app opens and immediately closes, check:

- `~/Library/Logs/Reviewer Ticket Dashboard/desktop-startup.log`

To override the log path:

```bash
export REVIEWER_DASHBOARD_LOG_PATH=/your/path/desktop-startup.log
```

## Repo Layout

- `app/main.py` - FastAPI app and ticket workflow logic
- `app/desktop.py` - native desktop launcher
- `app/db.py` - SQLite setup and access
- `app/templates/index.html` - main UI template
- `app/static/app.js` - client-side interactions
- `app/static/styles.css` - styling
- `scripts/build_macos_desktop_app.sh` - `.app` builder
- `scripts/package_macos_dmg.sh` - `.dmg` packager
- `sample_data/sample_comments.csv` - example import file

## Legacy Notes

- The browser/localhost workflow is no longer the primary way this project is presented.
- Older browser-launcher assets have been moved under `archive/`.
- `run.sh` is retained only as a legacy developer convenience for direct web-server use.
