# Reviewer Ticket Dashboard Documentation

## Overview

Reviewer Ticket Dashboard is a local desktop app for importing reviewer comments from CSV/XLSX, working them as tickets, and exporting manuscript response notes.

Repository model:

- `main` holds the shared app code, shared UI, and shared documentation.
- `mac` carries the macOS-specific local `.app` build utilities.
- `windows` carries the Windows-specific local app build utilities.
- `linux` carries the current Linux browser/local-web launch utilities.
Core workflow:

1. Create or select a manuscript
2. Import reviewer comments
3. Edit ticket details and write responses
4. Mark tickets complete when a response exists
5. Export the manuscript’s response notes to Markdown

## Features

- Ticket states: `OPEN` and `COMPLETED`
- Editable fields:
  - `reviewer_id`
  - `line_number`
  - `verbatim_comment`
  - `comment_category`
  - `response_text`
- Manuscript create/select/rename workflow
- Manual ticket creation
- CSV/XLSX import
- Markdown export per manuscript
- Search and filters
- Next/previous open ticket navigation
- TODO-first sort behavior
- Theme toggle

## How The App Works

- Tickets are grouped by manuscript.
- Each imported row becomes a ticket.
- A ticket cannot be marked `COMPLETED` unless `response_text` is non-empty.
- Completed tickets can still be edited.
- Completed tickets can be reopened.
- Export produces Markdown for the current manuscript.

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

## Sorting Rules

Tickets are sorted in this order:

1. `TODO` items first
2. Reviewer IDs such as `R1`, `R2`, `R10`
3. Unknown or custom IDs
4. Editor IDs such as `E1`, `E2`
5. Then by line number
6. Then by creation time

## Data Storage

Desktop mode stores the main database in the user Documents folder:

- macOS: `~/Documents/reviewer-ticket-dashboard/reviewer_dashboard.db`
- Windows: `%USERPROFILE%\Documents\reviewer-ticket-dashboard\reviewer_dashboard.db`

On Linux, the browser/local-web workflow continues to use the project-local database unless you override it with `REVIEWER_DASHBOARD_DB_PATH`.
On first launch in standalone desktop mode, the app can migrate existing data from:

1. macOS legacy path: `~/Library/Application Support/Reviewer Ticket Dashboard/reviewer_dashboard.db`
2. Windows legacy path: `%APPDATA%\Reviewer Ticket Dashboard\reviewer_dashboard.db`
3. `data/reviewer_dashboard.db`

To override the database path:

```bash
export REVIEWER_DASHBOARD_DB_PATH=/your/custom/path/reviewer_dashboard.db
```

Manual backup example:

```bash
cp ~/Documents/reviewer-ticket-dashboard/reviewer_dashboard.db reviewer_dashboard.backup.db
```

## Troubleshooting

If the desktop app opens and immediately closes, check the startup log:

- macOS: `~/Library/Logs/Reviewer Ticket Dashboard/desktop-startup.log`
- Windows: `%LOCALAPPDATA%\Reviewer Ticket Dashboard\Logs\desktop-startup.log`

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
- `scripts/build_macos_desktop_app.sh` - macOS `.app` builder
- `scripts/build_windows_desktop_app.ps1` - Windows `.exe` builder
- `run.sh` - Linux/local browser launcher
- `sample_data/sample_comments.csv` - example import file

## Platform Notes

- The shared app runtime is used by all platform branches.
- macOS and Windows package the same app into local desktop app launches.
- Linux currently uses the browser/local-web path for the same app behavior.

## Archive Notes

- Older browser-launcher assets live under `archive/`.
