# Documentation History

## 2026-02-25

- Initialized `Reviewer Ticket Dashboard` project structure.
- Implemented FastAPI app with SQLite persistence at `data/reviewer_dashboard.db`.
- Added manuscript management (create, select, rename).
- Added ticket import endpoints for CSV and XLSX.
- Added import validation for required exact columns:
  - `reviewer_id`
  - `line_number`
  - `verbatim_comment`
  - `comment_category`
- Added line-number parsing that preserves original display and sorts by first integer for ranges.
- Implemented global sort rules:
  - Reviewers (`R#`) first
  - Unknown IDs next
  - Editors (`E#`) last
  - Numeric order inside groups, then line number, then `created_at`.
- Implemented board UI with Open/Completed columns.
- Added detail pane for editing all ticket fields, including completed tickets.
- Added completion validation requiring non-empty `response_text`.
- Added explicit `Reopen` flow.
- Added search and filters (reviewer, category, status).
- Added `Next Open Ticket` and `Previous Open Ticket` with keyboard shortcuts (`N`, `Shift+N`, `P`).
- Documented behavior that next/previous respects current manuscript plus search/reviewer/category filters.
- Added `run.sh` one-command local launch script.
- Added `sample_data/sample_comments.csv`.
- Added README setup/run/usage/import format/sorting/macOS Dock launcher instructions.
- Added light/dark theme toggle with localStorage persistence.
- Added README section for initializing this folder as a git repository and pushing to a remote.

## Verification Notes

- Static syntax compile check passed: `python3 -m compileall app`.
- Runtime dependency install could not be completed in this environment due restricted network access.
