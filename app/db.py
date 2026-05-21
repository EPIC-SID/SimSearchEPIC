import sqlite3
import json
import os
from datetime import datetime

class MediaDatabase:
    def __init__(self, db_path):
        self.db_path = db_path
        self._create_table()

    def _get_connection(self):
        return sqlite3.connect(self.db_path)

    def _create_table(self):
        with self._get_connection() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS media (
                    row_id INTEGER PRIMARY KEY,
                    file_path TEXT NOT NULL,
                    date_indexed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    file_hash TEXT,
                    people TEXT
                )
            """)

    def insert_media(self, row_id, file_path, file_hash=None, people=None):
        """Inserts a new media record. row_id must match FAISS index ID."""
        people_json = json.dumps(people if people else [])
        with self._get_connection() as conn:
            conn.execute(
                "INSERT OR REPLACE INTO media (row_id, file_path, file_hash, people) VALUES (?, ?, ?, ?)",
                (row_id, file_path, file_hash, people_json)
            )

    def get_path_by_id(self, row_id):
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT file_path FROM media WHERE row_id = ?", (row_id,))
            row = cursor.fetchone()
            return row[0] if row else None

    def get_all_paths(self):
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT file_path FROM media ORDER BY row_id ASC")
            return [row[0] for row in cursor.fetchall()]

    def get_media_by_hash(self, file_hash):
        with self._get_connection() as conn:
            cursor = conn.execute("SELECT row_id, file_path FROM media WHERE file_hash = ?", (file_hash,))
            return cursor.fetchone()

    def clear_all(self):
        with self._get_connection() as conn:
            conn.execute("DELETE FROM media")
