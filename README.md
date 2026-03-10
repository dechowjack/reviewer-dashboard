# Reviewer Ticket Dashboard

A local FastAPI + SQLite dashboard for importing reviewer comments from CSV/XLSX and working them as Jira-like tickets on a two-column Kanban board.

## Features (v1)

- Two statuses and columns:
  - `OPEN`
  - `COMPLETED`
- Ticket cards show:
  - `reviewer_id`
  - `line_number` (display value)
  - `comment_category`
  - preview of `verbatim_comment`
- Right-side detail panel with editable fields:
  - `reviewer_id`
  - `line_number`
  - `verbatim_comment`
  - `comment_category`
  - `response_text`
  - Completed checkbox
- Completion validation:
  - A ticket cannot be marked `COMPLETED` unless `response_text` is non-empty after trim.
- Reopen flow:
  - `Reopen` action moves a completed ticket back to `OPEN`.
- Import supports `.csv` and `.xlsx` with required 4-column format.
- Markdown export per manuscript (non-CSV):
  - includes all tickets in sorted order
  - excludes `TODO` tickets by default
  - includes status, reviewer/editor/todo ID, verbatim comment
  - includes response text for completed tickets
- Manual ticket creation via `Add Ticket` button (useful for missed reviewer comments or personal to-do tickets).
- All imported fields remain editable after import (including completed tickets).
- Multiple manuscripts:
  - Select manuscript from dropdown
  - Create manuscript (name)
  - Rename manuscript
- Search/filter:
  - Search across `verbatim_comment` and `response_text`
  - Filter by `reviewer_id`, `comment_category`, `status`
- Next/previous open workflow:
  - `Next Open Ticket` button (`N`)
  - `Previous Open Ticket` button (`Shift+N` or `P`)
  - Respects current manuscript, search text, reviewer filter, and category filter.
  - Does **not** use status filter (it always navigates open tickets).
- Theme toggle:
  - Toolbar button switches light/dark themes.
  - Theme preference is saved in browser local storage.
- Local persistence in SQLite:
  - `data/reviewer_dashboard.db`

## Tech Stack

- Python 3.10+
- FastAPI
- SQLite (`sqlite3`)
- Jinja2 templates
- Minimal vanilla JavaScript
- `openpyxl` for XLSX import

## Project Structure

- `app/main.py` - FastAPI app, API routes, import parsing, sorting, validation, ticket workflow logic.
- `app/db.py` - SQLite connection and schema initialization.
- `app/templates/index.html` - Main dashboard view.
- `app/static/app.js` - UI interactions, filters, save/edit actions, next/prev open navigation.
- `app/static/styles.css` - Jira-like minimal styling.
- `sample_data/sample_comments.csv` - Example import file.
- `run.sh` - One-command local runner.

## Database Schema

### manuscripts

- `id` INTEGER PK
- `name` TEXT UNIQUE NOT NULL
- `created_at` TEXT

### tickets

- `id` INTEGER PK
- `manuscript_id` INTEGER FK -> manuscripts.id
- `reviewer_id` TEXT
- `reviewer_group_sort` INTEGER
- `reviewer_num_sort` INTEGER
- `line_number_display` TEXT
- `line_number_sort` INTEGER
- `verbatim_comment` TEXT
- `comment_category` TEXT CHECK in (`editorial`,`major`,`minor`)
- `response_text` TEXT
- `status` TEXT CHECK in (`OPEN`,`COMPLETED`)
- `created_at` TEXT
- `updated_at` TEXT

## Import Format (Required)

Import file columns must be in this exact order:

1. `reviewer_id`
2. `line_number`
3. `verbatim_comment`
4. `comment_category`

Example header:

```csv
reviewer_id,line_number,verbatim_comment,comment_category
```

Rules:

- `reviewer_id` is a short string (`R1`, `R2`, `E1`, etc.).
- `line_number` parsing:
  - Numeric (e.g., `210`) -> used directly.
  - Range/string (e.g., `210-225`, `L210-225`, `L210–225`) -> first integer is used for sorting (`line_number_sort`), original text is preserved as display.
- `comment_category` accepted values (case-insensitive on import):
  - `editorial`
  - `major`
  - `minor`

## Sorting Rules

Global ticket sort order:

1. Reviewer group:
  - `TODO`-flagged first (`reviewer_id` starts with `TODO`, case-insensitive)
  - Reviewers next: `^R\d+$`
  - Unknown/other IDs next (not matching TODO/R/E)
  - Editors last: `^E\d+$`
2. Within group: numeric ID (`R1 < R2 < R10`, `E1 < E2`)
3. `line_number_sort` ascending
4. `created_at` ascending

## Run Modes

### macOS Desktop App (Recommended)

```bash
make icon
```

Build the standalone `.app` (webview wrapper around existing FastAPI backend):

```bash
make desktop-build
```

Run from source with native window (no packaging):

```bash
make desktop
```

The desktop launcher starts the same local server automatically on a free port and opens a native window.

### Web Server (Existing)

```bash
./run.sh
```

Then open:

- [http://127.0.0.1:8000](http://127.0.0.1:8000)

`run.sh` will:

1. Create `.venv` if missing
2. Install pinned dependencies from `requirements.txt`
3. Start uvicorn on `127.0.0.1:8000`

## Git Setup (Initialize This Folder as a Repo)

If this folder is not yet a git repository, run:

```bash
cd /Users/jldechow/Documents/Codex/reviewer-dashboard
git init
git add .
git commit -m "Initial commit: reviewer ticket dashboard v1"
```

Optional remote setup:

```bash
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

## App Icon + macOS Packaging

Generate a simple custom app icon:

```bash
make icon
```

- Primary output: `assets/icons/reviewer_dashboard_1024.png`
- If `iconutil` works in your macOS environment, it also generates `assets/icons/reviewer_dashboard.icns`.
- If `iconutil` fails, build scripts fall back to the PNG icon.

Build desktop `.app` bundle into `dist/`:

```bash
make desktop-build
```

Build command example:

```bash
./scripts/build_macos_desktop_app.sh
```

Build a distributable DMG (recommended to share with coworkers):

```bash
make desktop-dmg
```

This creates `dist/Reviewer Ticket Dashboard.dmg` which is install-ready (drag app to Applications).

## Database migration for desktop mode

Desktop mode stores data in:

- `~/Library/Application Support/Reviewer Ticket Dashboard/reviewer_dashboard.db`

On first launch in desktop mode, if that file does not exist and `data/reviewer_dashboard.db` exists, the app copies it once into the app-support location.

To override the DB path (web or desktop mode):

```bash
export REVIEWER_DASHBOARD_DB_PATH=/your/custom/path/reviewer_dashboard.db
```

To explicitly keep legacy web mode DB behavior:

```bash
export REVIEWER_DASHBOARD_STANDALONE=0
```

## Usage

1. Run local:
   - Desktop: `make desktop`
   - Web: `./run.sh`
2. (Optional) Create a new manuscript from top toolbar
3. Select manuscript
4. Import CSV/XLSX using `Import`
5. Export a markdown report using `Export Markdown`
6. (Optional) Add manual tickets using `Add Ticket`
7. Click cards to edit ticket details in right panel
8. Add `response_text` before marking completed
9. Use `Next Open Ticket` / `Previous Open Ticket` for workflow

## Completion and Editing Behavior

- `response_text` is required to set `COMPLETED`.
- Validation blocks completion and shows an error.
- Completed tickets stay editable.
- Reopen is explicit via `Reopen` button or unchecking completed state and saving.

## Next Open Ticket Behavior

- If no ticket is selected: selects first matching open ticket.
- If selected is open: moves to next/previous open ticket after/before it.
- If selected is completed: finds next/previous open ticket relative to selected ticket in global sort order.
- Wraps around at the end/start.
- If no matching open ticket exists: shows `No open tickets 🎉`.

The `make launcher` and Automator/browser-install options remain in the repo as legacy references.

## Verification Checklist

- Import succeeds for CSV and XLSX with exact columns
- Sorting order follows reviewer-group/numeric/line/created rules
- Completion blocked when `response_text` is blank
- Completed tickets editable and reopenable
- Next/Previous open behavior works from open/completed/no-selection cases
- Data persists after server restart
- Manuscript switching isolates tickets by manuscript

## Backups

- Primary storage is:
  - Web mode: `data/reviewer_dashboard.db`
  - Desktop mode: `~/Library/Application Support/Reviewer Ticket Dashboard/reviewer_dashboard.db`
- This app does not currently create automatic timestamped backups.
- To back up tickets manually, copy the DB file:

```bash
cp ~/Library/Application\ Support/Reviewer\ Ticket\ Dashboard/reviewer_dashboard.db reviewer_dashboard.backup.db
```
