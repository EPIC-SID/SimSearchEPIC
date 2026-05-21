# SimSearch

Semantic image search for local photo folders. SimSearch indexes images with CLIP, stores vectors in FAISS, keeps image metadata in SQLite, and lets you search from a Flutter UI using natural language.

## Active Project Layout

```text
app/             Python backend: indexing, FAISS, SQLite, FastAPI
frontend/v1/     Flutter UI
scripts/         Convenience scripts
experiments/     Older OpenVINO/prototype work kept for reference
```

Large generated files such as model downloads, FAISS indexes, SQLite databases, and bulk sample media are intentionally ignored by Git.

## Backend

```powershell
cd app
pip install -r requirements.txt
python api.py
```

The API runs at `http://127.0.0.1:8000`.

Useful endpoints:

- `GET /health` - backend and index readiness
- `POST /search` - text search, body: `{"query": "kitchen interior"}`
- `GET /config` - current folders and confidence threshold
- `PUT /config` - update folders and threshold
- `GET /index/status` - indexing job status
- `POST /index/rebuild` - start indexing in the background

You can still rebuild manually:

```powershell
cd app
python clear_db.py
python index.py
```

## Frontend

```powershell
cd frontend\v1
flutter pub get
flutter run -d windows
```

Open Settings to add indexed folders, adjust the confidence threshold, and rebuild the index from the UI.

## Tests

```powershell
python -m unittest discover -s tests
```

## Architecture

```text
Configured folders -> app/index.py -> FAISS index + SQLite metadata
User query -> Flutter UI -> app/api.py -> app/search.py -> matching image paths and scores
```
