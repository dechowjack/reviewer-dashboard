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
- Added `Makefile` targets (`make icon`, `make launcher`) for macOS app icon and launcher creation.
- Added `scripts/make_icon.sh` for custom Reviewer Ticket Dashboard icon generation.
- Added `scripts/build_macos_launcher.sh` and `startup.command` for a Dock-able macOS launcher app.
- Added manual ticket creation:
  - New `Add Ticket` button and modal form in UI
  - New backend endpoint `POST /api/manuscripts/{manuscript_id}/tickets`
  - Uses existing sort/validation rules and manuscript scoping
  - Supports creating OPEN or COMPLETED (completed still requires non-empty response_text)
- Added README backup section clarifying storage and manual DB copy command.
- Updated sorting so `TODO` reviewer IDs appear first.
- Added startup sort-key recalculation so existing tickets follow new TODO-first ordering immediately.
- Added Markdown export feature for current manuscript:
  - Endpoint: `GET /api/manuscripts/{manuscript_id}/export.md`
  - Includes all tickets with status, reviewer/editor/todo ID, verbatim comment, and response for completed tickets
  - Added `Export Markdown` toolbar button in UI.
- Updated Markdown export to exclude `TODO` tickets by default (`include_todo=true` query param can include them).
- Added desktop wrapper approach for standalone macOS usage:
  - Added `app/desktop.py` with embedded webview launcher.
  - Added `make desktop` and `make desktop-build`.
  - Added `scripts/build_macos_desktop_app.sh` to package `.app` with PyInstaller.
- Added macOS distributor workflow:
  - Added `scripts/package_macos_dmg.sh` and `make desktop-dmg` to produce a distributable `.dmg`.

## Verification Notes

- Static syntax compile check passed: `python3 -m compileall app`.
- Runtime dependency install could not be completed in this environment due restricted network access.

## 2026-03-25

- Reframed the repository documentation around the macOS desktop app as the primary product.
- Rewrote `README.md` to emphasize:
  - macOS-only support
  - DMG-based install/share workflow
  - running and building the desktop app from source
  - legacy status of the browser/localhost workflow
- Removed the legacy `make launcher` target from the top-level `Makefile`.
- Tightened `.gitignore` to exclude `.DS_Store` and `.pyinstaller-build/`.
- Prepared legacy browser-launcher assets to live under `archive/` instead of the main repo surface.
