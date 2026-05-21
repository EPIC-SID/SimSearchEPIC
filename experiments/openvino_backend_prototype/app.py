import os
import asyncio
from concurrent.futures import ThreadPoolExecutor

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List

from src.core.engine import SearchEngine

# ── App setup ──────────────────────────────────────────────────────────────────

app = FastAPI(title="SimSearch Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Absolute path to the image data folder
DATA_DIR = os.path.normpath(os.path.join(os.path.dirname(__file__), "data", "images"))

engine = SearchEngine()
_executor = ThreadPoolExecutor(max_workers=1)

# ── Startup: index images in background ───────────────────────────────────────

@app.on_event("startup")
async def startup_event():
    loop = asyncio.get_event_loop()
    loop.run_in_executor(_executor, engine.index_folder, DATA_DIR)

# ── Health ─────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {
        "status": "ok" if engine.indexed_count > 0 else "indexing",
        "indexed_count": engine.indexed_count,
        "data_dir": DATA_DIR,
    }

# ── Search ─────────────────────────────────────────────────────────────────────

class SearchRequest(BaseModel):
    query: str

class SearchResult(BaseModel):
    path: str
    score: float
    name: str

class SearchResponse(BaseModel):
    query: str
    results: List[SearchResult]
    count: int
    total_indexed: int

@app.post("/search", response_model=SearchResponse)
async def search(req: SearchRequest):
    if engine.indexed_count == 0:
        raise HTTPException(
            status_code=503,
            detail="Index not ready yet — images are still being embedded. Try again in a moment."
        )

    raw = engine.search_text(req.query.strip(), top_k=20)
    results = [
        SearchResult(path=r["path"], score=r["score"], name=r["name"])
        for r in raw
    ]
    return SearchResponse(
        query=req.query,
        results=results,
        count=len(results),
        total_indexed=engine.indexed_count,
    )

# ── Image serving (for web / non-desktop Flutter) ─────────────────────────────

@app.get("/images/{file_path:path}")
async def serve_image(file_path: str):
    """Serve image files by relative path under DATA_DIR."""
    full_path = os.path.join(DATA_DIR, file_path)
    if not os.path.isfile(full_path):
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(full_path)

# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=False)
