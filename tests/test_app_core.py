import json
import os
import sqlite3
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT_DIR = Path(__file__).resolve().parents[1]
APP_DIR = ROOT_DIR / "app"
sys.path.insert(0, str(APP_DIR))

from db import MediaDatabase
from scanner import scan_for_photos


class ScannerTests(unittest.TestCase):
    def test_scan_for_photos_finds_supported_images_recursively(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            nested = root / "nested"
            nested.mkdir()
            image = nested / "photo.JPG"
            ignored = nested / "notes.txt"
            image.write_bytes(b"fake image bytes")
            ignored.write_text("not an image", encoding="utf-8")

            results = scan_for_photos(str(root))

        self.assertEqual(results, [str(image.resolve())])

    def test_scan_for_photos_returns_empty_for_missing_folder(self):
        self.assertEqual(scan_for_photos("does-not-exist"), [])


class MediaDatabaseTests(unittest.TestCase):
    def test_insert_and_lookup_media_by_id_and_hash(self):
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "media.db"
            db = MediaDatabase(str(db_path))

            db.insert_media(row_id=7, file_path="C:/Photos/kitchen.jpg", file_hash="abc")

            self.assertEqual(db.get_path_by_id(7), "C:/Photos/kitchen.jpg")
            self.assertEqual(db.get_media_by_hash("abc"), (7, "C:/Photos/kitchen.jpg"))
            self.assertEqual(db.get_all_paths(), ["C:/Photos/kitchen.jpg"])

    def test_clear_all_removes_media_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = MediaDatabase(str(Path(tmp) / "media.db"))
            db.insert_media(row_id=1, file_path="one.jpg")
            db.clear_all()

            self.assertEqual(db.get_all_paths(), [])


class SearchFormattingTests(unittest.TestCase):
    def test_format_search_results_is_json_friendly(self):
        self._install_search_import_stubs()
        import search

        results = search.format_search_results([
            ("C:/Photos/sunset.jpg", 0.87654),
            ("C:/Photos/kitchen.png", 0.33333),
        ])

        self.assertEqual(
            results,
            [
                {"path": "C:/Photos/sunset.jpg", "score": 0.8765, "name": "sunset.jpg"},
                {"path": "C:/Photos/kitchen.png", "score": 0.3333, "name": "kitchen.png"},
            ],
        )

    def test_confidence_threshold_reads_config_with_default_fallback(self):
        self._install_search_import_stubs()
        import search

        with tempfile.TemporaryDirectory() as tmp:
            config_path = Path(tmp) / "config.json"
            config_path.write_text(json.dumps({"confidence_threshold": 0.42}), encoding="utf-8")
            with patch.object(search, "CONFIG_PATH", str(config_path)):
                self.assertEqual(search._get_confidence_threshold(), 0.42)

            with patch.object(search, "CONFIG_PATH", str(Path(tmp) / "missing.json")):
                self.assertEqual(search._get_confidence_threshold(), 0.24)

    @staticmethod
    def _install_search_import_stubs():
        sys.modules.setdefault("faiss", types.SimpleNamespace())
        sys.modules.setdefault("torch", types.SimpleNamespace(no_grad=lambda: _NoOpContext()))
        transformers = types.SimpleNamespace(CLIPModel=object, CLIPProcessor=object)
        sys.modules.setdefault("transformers", transformers)


class _NoOpContext:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


if __name__ == "__main__":
    unittest.main()
