from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import os
import uvicorn
from typing import List
from pydantic import BaseModel

# Import our engine logic (we moved it to backend/src/core/engine.py)
from src.core.engine import SearchEngine

app = FastAPI(title="SimSearch Backend")

# Allow Flutter to talk to us
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = SearchEngine()

class SearchResult(BaseModel):
    path: str
    score: float

@app.get("/status")
async def get_status():
    return {"status": "healthy", "npu": "active", "indexed_images": 0}

@app.post("/search/text", response_model=List[SearchResult])
async def search_text(query: str):
    print(f"Searching for text: {query}")
    # Mock results for now
    return [
        {"path": "C:/Windows/Web/Wallpaper/Windows/img0.jpg", "score": 0.98},
        {"path": "C:/Windows/Web/Wallpaper/Theme1/img1.jpg", "score": 0.85}
    ]

@app.post("/search/image", response_model=List[SearchResult])
async def search_image(file: UploadFile = File(...)):
    # Save temp file and search
    return []

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
