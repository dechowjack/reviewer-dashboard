from __future__ import annotations

import os
import sqlite3
import shutil
import sys
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _legacy_db_path() -> Path:
    return _project_root() / "data" / "reviewer_dashboard.db"


def _app_name() -> str:
    return "Reviewer Ticket Dashboard"


def _documents_dir() -> Path:
    return Path.home() / "Documents"


def _appdata_dir() -> Path:
    appdata = os.getenv("APPDATA")
    if appdata:
        return Path(appdata).expanduser()
    return Path.home() / "AppData" / "Roaming"


def _app_support_db_path() -> Path:
    if sys.platform == "darwin":
        base_dir = Path.home() / "Library" / "Application Support"
    elif sys.platform.startswith("win"):
        base_dir = _appdata_dir()
    else:
        base_dir = Path.home() / ".local" / "share"
    return base_dir / _app_name() / "reviewer_dashboard.db"


def _documents_db_path() -> Path:
    return _documents_dir() / "reviewer-ticket-dashboard" / "reviewer_dashboard.db"


def _is_standalone_mode() -> bool:
    return os.getenv("REVIEWER_DASHBOARD_STANDALONE", "").lower() in {"1", "true", "yes", "on"}


def _ensure_parent_dir(path: Path) -> bool:
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        return True
    except OSError:
        return False


def _resolve_db_path() -> Path:
    override = os.getenv("REVIEWER_DASHBOARD_DB_PATH")
    if override:
        return Path(override).expanduser()

    legacy_db = _legacy_db_path()
    if _is_standalone_mode():
        docs_db = _documents_db_path()
        app_support_db = _app_support_db_path()

        preferred_db = docs_db if _ensure_parent_dir(docs_db) else app_support_db
        _ensure_parent_dir(preferred_db)

        if not preferred_db.exists():
            if preferred_db != app_support_db and app_support_db.exists():
                shutil.copy2(app_support_db, preferred_db)
            elif legacy_db.exists():
                shutil.copy2(legacy_db, preferred_db)
        return preferred_db

    return legacy_db


DB_PATH = _resolve_db_path()


def get_conn() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    with get_conn() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS manuscripts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS tickets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                manuscript_id INTEGER NOT NULL,
                reviewer_id TEXT NOT NULL,
                reviewer_group_sort INTEGER NOT NULL DEFAULT 1,
                reviewer_num_sort INTEGER NOT NULL DEFAULT 2147483647,
                line_number_display TEXT NOT NULL,
                line_number_sort INTEGER NOT NULL DEFAULT 2147483647,
                verbatim_comment TEXT NOT NULL,
                comment_category TEXT NOT NULL CHECK (comment_category IN ('editorial', 'major', 'minor')),
                response_text TEXT NOT NULL DEFAULT '',
                status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'COMPLETED')),
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (manuscript_id) REFERENCES manuscripts (id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_tickets_manuscript ON tickets (manuscript_id);
            CREATE INDEX IF NOT EXISTS idx_tickets_sort ON tickets (
                manuscript_id,
                status,
                reviewer_group_sort,
                reviewer_num_sort,
                line_number_sort,
                created_at,
                id
            );
            """
        )


def ensure_default_manuscript() -> int:
    with get_conn() as conn:
        row = conn.execute("SELECT id FROM manuscripts ORDER BY created_at, id LIMIT 1").fetchone()
        if row:
            return int(row["id"])
        cur = conn.execute("INSERT INTO manuscripts (name) VALUES (?)", ("Default Manuscript",))
        return int(cur.lastrowid)
