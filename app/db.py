from __future__ import annotations

import sqlite3
from pathlib import Path

DB_PATH = Path("data/reviewer_dashboard.db")


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
