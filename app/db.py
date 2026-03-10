from __future__ import annotations

import os
import sqlite3
import shutil
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _legacy_db_path() -> Path:
    return _project_root() / "data" / "reviewer_dashboard.db"


def _app_support_db_path() -> Path:
    return Path.home() / "Library" / "Application Support" / "Reviewer Ticket Dashboard" / "reviewer_dashboard.db"


def _is_standalone_mode() -> bool:
    return os.getenv("REVIEWER_DASHBOARD_STANDALONE", "").lower() in {"1", "true", "yes", "on"}


def _resolve_db_path() -> Path:
    override = os.getenv("REVIEWER_DASHBOARD_DB_PATH")
    if override:
        return Path(override).expanduser()

    legacy_db = _legacy_db_path()
    if _is_standalone_mode():
        app_db = _app_support_db_path()
        if not app_db.exists() and legacy_db.exists():
            app_db.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(legacy_db, app_db)
        return app_db

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
