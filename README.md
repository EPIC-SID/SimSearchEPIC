# SimSearch

Semantic image search: index local photos with CLIP + FAISS, search by text description, browse results in a Flutter UI.

## Quick start

### 1. Backend (Python)

```powershell
cd app
pip install faiss-cpu torch transformers pillow fastapi uvicorn
```

Configure folders in `app/config.json`, then build the index:

```powershell
python index.py
```

Start the API server (required for the UI):

```powershell
python api.py
```

Or from the repo root: `scripts\start_backend.bat`

API runs at **http://127.0.0.1:8000**

- `GET /health` — index status
- `POST /search` — body: `{"query": "kitchen interior"}`

If anything breaks: `python clear_db.py` then `python index.py`

### 2. Frontend (Flutter)

```powershell
cd frontend\v1
flutter pub get
flutter run -d windows
```

Ensure the backend is running before searching.

## Architecture

```
images/ + test_media/  →  index.py  →  FAISS + SQLite
                              ↑
User query  →  Flutter UI  →  api.py  →  search.py (CLIP)  →  paths + scores
```
