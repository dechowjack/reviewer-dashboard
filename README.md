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
  - Reviewers first: `^R\d+$`
  - Unknown/other IDs next (not matching R/E)
  - Editors last: `^E\d+$`
2. Within group: numeric ID (`R1 < R2 < R10`, `E1 < E2`)
3. `line_number_sort` ascending
4. `created_at` ascending

## Run Locally (One Command)

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

## App Icon + macOS Launcher (One-Command Targets)

Generate a simple custom app icon:

```bash
make icon
```

- Primary output: `assets/icons/reviewer_dashboard_1024.png`
- If `iconutil` works in your macOS environment, it also generates `assets/icons/reviewer_dashboard.icns`.
- If `iconutil` fails, launcher build automatically falls back to the PNG icon.

Build launcher app bundle into `dist/`:

```bash
make launcher
```

Install launcher to `~/Applications` and pin to Dock:

```bash
INSTALL_TO_APPS=1 ./scripts/build_macos_launcher.sh
```

Quick local build only (no install):

```bash
INSTALL_TO_APPS=0 ./scripts/build_macos_launcher.sh
```

## Usage

1. Start app with `./run.sh`
2. (Optional) Create a new manuscript from top toolbar
3. Select manuscript
4. Import CSV/XLSX using `Import`
5. (Optional) Add manual tickets using `Add Ticket`
6. Click cards to edit ticket details in right panel
7. Add `response_text` before marking completed
8. Use `Next Open Ticket` / `Previous Open Ticket` for workflow

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

## macOS Dock Launcher Options

### Option 1: Chrome/Edge “Install app”

1. Start dashboard with `./run.sh`
2. Open [http://127.0.0.1:8000](http://127.0.0.1:8000) in Chrome or Edge
3. In browser menu, choose `Install app` (or `Create shortcut` + `Open as window`)
4. Launch it from Applications and keep it in Dock

Note: this creates an app-like launcher, but the local server still needs to be running.

### Option 2: Automator Application

1. Open Automator and create a new `Application`
2. Add `Run Shell Script` action
3. Use script like:

```bash
cd /Users/jldechow/Documents/Codex/reviewer-dashboard
./run.sh
```

4. Save as `Reviewer Ticket Dashboard.app`
5. Add to Dock

Alternative Automator script to only open URL (server must already be running):

```bash
open http://127.0.0.1:8000
```

## Verification Checklist

- Import succeeds for CSV and XLSX with exact columns
- Sorting order follows reviewer-group/numeric/line/created rules
- Completion blocked when `response_text` is blank
- Completed tickets editable and reopenable
- Next/Previous open behavior works from open/completed/no-selection cases
- Data persists after server restart
- Manuscript switching isolates tickets by manuscript

## Backups

- Primary storage is SQLite at `data/reviewer_dashboard.db`.
- This app does not currently create automatic timestamped backups.
- To back up tickets manually, copy the DB file:

```bash
cp data/reviewer_dashboard.db data/reviewer_dashboard.backup.db
```
