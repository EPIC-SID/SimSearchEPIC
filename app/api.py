"""
FastAPI server exposing SimSearch image search to the Flutter frontend.
Run: python api.py
"""

import os
import sys
import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from search import SearchEngine, format_search_results

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")
DEFAULT_PORT = int(os.environ.get("SIMSEARCH_PORT", "8000"))

_engine: SearchEngine | None = None


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


@app.get("/health")
def health():
    if _engine is None:
        return {"status": "unavailable", "indexed_count": 0}
    return {"status": "ok", "indexed_count": _engine.total_indexed}


@app.post("/search")
def search(body: SearchRequest):
    engine = _require_engine()
    query = body.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        raw = engine.search(query, top_k=body.top_k)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {e}") from e

    results = format_search_results(raw)
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
