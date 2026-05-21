# SimSearch Backend

This folder contains the active Python backend.

## Run

```powershell
pip install -r requirements.txt
python api.py
```

## Rebuild Index

Use the Flutter Settings screen, or run:

```powershell
python clear_db.py
python index.py
```

Generated files are written to `faiss_db/`, `sql_db/`, and `models/`; these folders are ignored by Git.
