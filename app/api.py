"""
FastAPI server exposing SimSearch image search to the Flutter frontend.
Run: python api.py
"""

import os
import sys
import json
import threading
from datetime import datetime
from contextlib import asynccontextmanager
from urllib.parse import quote

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

from index import run_indexing
from search import SearchEngine, format_search_results

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")
DEFAULT_PORT = int(os.environ.get("SIMSEARCH_PORT", "8000"))

_engine: SearchEngine | None = None
_index_lock = threading.Lock()
_index_status = {
    "running": False,
    "status": "idle",
    "message": "Indexing has not started",
    "stage": "idle",
    "processed": 0,
    "total": 0,
    "percent": 0.0,
    "current_file": None,
    "started_at": None,
    "finished_at": None,
}


def _now_iso() -> str:
    return datetime.now().isoformat(timespec="seconds")


def _set_index_status(**updates):
    with _index_lock:
        _index_status.update(updates)


def _get_index_status() -> dict:
    with _index_lock:
        return dict(_index_status)


def _update_index_progress(event: dict):
    total = int(event.get("total") or 0)
    processed = int(event.get("processed") or 0)
    percent = (processed / total) if total > 0 else 0.0
    message = event.get("message") or "Index rebuild is running"
    _set_index_status(
        stage=event.get("stage") or "indexing",
        processed=processed,
        total=total,
        percent=round(max(0.0, min(1.0, percent)), 4),
        current_file=event.get("current_file"),
        message=message,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _engine
    print("Loading search engine...")
    try:
        _engine = SearchEngine.load()
        print(f"Ready. Indexed images: {_engine.total_indexed}")
    except FileNotFoundError as e:
        print(f"Warning: {e}", file=sys.stderr)
        _engine = None
    yield
    _engine = None


app = FastAPI(title="SimSearch API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SearchRequest(BaseModel):
    query: str = Field(..., min_length=1)
    top_k: int | None = Field(default=None, ge=1)


class ConfigUpdate(BaseModel):
    confidence_threshold: float | None = Field(default=None, ge=0.0, le=1.0)
    folder_paths: list[str] | None = None


def _require_engine() -> SearchEngine:
    if _engine is None:
        raise HTTPException(
            status_code=503,
            detail="Search index not ready. Run: python clear_db.py && python index.py",
        )
    return _engine


def _resolve_media_path(path: str) -> str | None:
    """Resolve stored media paths, including older demo paths from C:\\SimSearch."""
    if os.path.isfile(path):
        return path

    legacy_prefix = os.path.normcase(os.path.normpath(r"C:\SimSearch"))
    normalized = os.path.normcase(os.path.normpath(path))
    if normalized.startswith(legacy_prefix):
        relative = os.path.relpath(os.path.normpath(path), r"C:\SimSearch")
        candidate = os.path.join(PROJECT_DIR, relative)
        if os.path.isfile(candidate):
            return candidate

    return None


def _format_search_results_with_urls(results, request: Request):
    base_url = str(request.base_url).rstrip("/")
    formatted = format_search_results(results)
    for item in formatted:
        resolved = _resolve_media_path(item["path"])
        item["exists"] = resolved is not None
        if resolved is not None:
            item["image_url"] = f"{base_url}/media?path={quote(item['path'])}"
    return formatted


def _format_library_items(paths: list[str], request: Request):
    base_url = str(request.base_url).rstrip("/")
    items = []
    for path in paths:
        resolved = _resolve_media_path(path)
        item = {
            "path": path,
            "score": 1.0,
            "name": os.path.basename(path),
            "exists": resolved is not None,
        }
        if resolved is not None:
            item["image_url"] = f"{base_url}/media?path={quote(path)}"
        items.append(item)
    return items


def _run_index_rebuild():
    global _engine
    _set_index_status(
        running=True,
        status="indexing",
        message="Index rebuild is running",
        stage="starting",
        processed=0,
        total=0,
        percent=0.0,
        current_file=None,
        started_at=_now_iso(),
        finished_at=None,
    )
    try:
        run_indexing(progress_callback=_update_index_progress)
        _engine = SearchEngine.load()
        _set_index_status(
            running=False,
            status="ready",
            message=f"Index rebuild complete. {_engine.total_indexed} images indexed.",
            stage="complete",
            processed=_engine.total_indexed,
            total=_engine.total_indexed,
            percent=1.0,
            current_file=None,
            finished_at=_now_iso(),
        )
    except Exception as e:
        _engine = None
        _set_index_status(
            running=False,
            status="failed",
            message=f"Index rebuild failed: {e}",
            stage="failed",
            current_file=None,
            finished_at=_now_iso(),
        )


@app.get("/health")
def health():
    index_status = _get_index_status()
    if index_status["running"]:
        return {"status": "indexing", "indexed_count": 0}
    if _engine is None:
        return {"status": "unavailable", "indexed_count": 0}
    return {"status": "ok", "indexed_count": _engine.total_indexed}


@app.get("/index/status")
def index_status():
    status = _get_index_status()
    status["indexed_count"] = _engine.total_indexed if _engine is not None else 0
    return status


@app.post("/index/rebuild")
def rebuild_index():
    status = _get_index_status()
    if status["running"]:
        return {**status, "indexed_count": _engine.total_indexed if _engine else 0}

    thread = threading.Thread(target=_run_index_rebuild, daemon=True)
    thread.start()
    return {
        "running": True,
        "status": "indexing",
        "message": "Index rebuild started",
        "stage": "starting",
        "processed": 0,
        "total": 0,
        "percent": 0.0,
        "current_file": None,
        "started_at": _now_iso(),
        "finished_at": None,
        "indexed_count": _engine.total_indexed if _engine else 0,
    }


@app.get("/media")
def media(path: str):
    resolved = _resolve_media_path(path)
    if resolved is None:
        raise HTTPException(status_code=404, detail="Image file not found")
    return FileResponse(resolved)


@app.get("/library")
def library(request: Request):
    engine = _require_engine()
    paths = engine.db.get_all_paths()
    results = _format_library_items(paths, request)
    return {
        "total_indexed": engine.total_indexed,
        "count": len(results),
        "results": results,
    }


@app.post("/search")
def search(body: SearchRequest, request: Request):
    engine = _require_engine()
    query = body.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        raw = engine.search(query, top_k=body.top_k)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {e}") from e

    results = _format_search_results_with_urls(raw, request)
    return {
        "query": query,
        "total_indexed": engine.total_indexed,
        "count": len(results),
        "results": results,
    }


def _read_config() -> dict:
    """Read config.json, returning defaults if it doesn't exist."""
    defaults = {"Folder_Paths": [], "confidence_threshold": 0.24}
    if not os.path.exists(CONFIG_PATH):
        return defaults
    try:
        with open(CONFIG_PATH, "r") as f:
            data = json.load(f)
        # Merge with defaults
        return {**defaults, **data}
    except Exception:
        return defaults


def _write_config(data: dict) -> None:
    """Write config.json."""
    with open(CONFIG_PATH, "w") as f:
        json.dump(data, f, indent=4)


@app.get("/config")
def get_config():
    config = _read_config()
    return {
        "confidence_threshold": config.get("confidence_threshold", 0.24),
        "folder_paths": config.get("Folder_Paths", []),
    }


@app.put("/config")
def update_config(body: ConfigUpdate):
    config = _read_config()
    if body.confidence_threshold is not None:
        config["confidence_threshold"] = body.confidence_threshold
    if body.folder_paths is not None:
        config["Folder_Paths"] = body.folder_paths
    _write_config(config)
    return {
        "status": "ok",
        "confidence_threshold": config.get("confidence_threshold", 0.24),
        "folder_paths": config.get("Folder_Paths", []),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("api:app", host="127.0.0.1", port=DEFAULT_PORT, reload=False)
