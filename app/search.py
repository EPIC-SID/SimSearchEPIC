import os
import sys
import json
import faiss
import torch
import numpy as np
from db import MediaDatabase
from transformers import CLIPModel, CLIPProcessor

# -----------------------------
# CONFIGURATION & PATHS
# -----------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(SCRIPT_DIR)

MODEL_PATH = os.path.join(SCRIPT_DIR, "models", "clip-vit-base-patch32")
FAISS_DB_DIR = os.path.join(SCRIPT_DIR, "faiss_db")
SQL_DB_DIR = os.path.join(SCRIPT_DIR, "sql_db")

INDEX_FILE = os.path.join(FAISS_DB_DIR, "index.faiss")
SQL_DB_FILE = os.path.join(SQL_DB_DIR, "localmind.db")
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")

def _get_confidence_threshold() -> float:
    """Read the confidence threshold from config.json, defaulting to 0.24."""
    try:
        with open(CONFIG_PATH, "r") as f:
            config = json.load(f)
        return float(config.get("confidence_threshold", 0.24))
    except Exception:
        return 0.24

def format_search_results(results):
    """Convert (path, score) tuples to a JSON-friendly list, highest score first."""
    return [
        {
            "path": path,
            "score": round(confidence, 4),
            "name": os.path.basename(path),
        }
        for path, confidence in results
    ]


class SearchEngine:
    """Loads CLIP, FAISS, and SQLite once for CLI and API use."""

    def __init__(self, model, processor, index, db):
        self.model = model
        self.processor = processor
        self.index = index
        self.db = db

    @classmethod
    def load(cls):
        if not os.path.exists(INDEX_FILE) or not os.path.exists(SQL_DB_FILE):
            raise FileNotFoundError(
                "FAISS index or SQLite database not found. Run: python index.py"
            )

        if not os.path.exists(MODEL_PATH):
            print(f"Model not found at {MODEL_PATH}. Downloading from Hugging Face...")
            model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
            processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
            os.makedirs(MODEL_PATH, exist_ok=True)
            model.save_pretrained(MODEL_PATH)
            processor.save_pretrained(MODEL_PATH)
        else:
            model = CLIPModel.from_pretrained(MODEL_PATH)
            processor = CLIPProcessor.from_pretrained(MODEL_PATH)

        index = faiss.read_index(INDEX_FILE)
        db = MediaDatabase(SQL_DB_FILE)
        return cls(model, processor, index, db)

    @property
    def total_indexed(self):
        return self.index.ntotal

    def search(self, query, top_k=None):
        return perform_search(
            query, self.index, self.model, self.processor, self.db, top_k=top_k
        )


def perform_search(query, index, model, processor, db, top_k=None):
    """Executes a search query and returns the matching paths and confidence scores."""
    # Process text query
    inputs = processor(text=[query], return_tensors="pt", padding=True)
    with torch.no_grad():
        text_embeds = model.get_text_features(
            input_ids=inputs['input_ids'], 
            attention_mask=inputs['attention_mask']
        )
    
    # Extract and normalize the query vector
    query_vector = text_embeds.cpu().numpy().astype("float32")
    query_vector /= np.linalg.norm(query_vector, axis=1, keepdims=True)

    # Search FAISS index
    if top_k is None:
        # Calculate 20% of total indexed photos (minimum of 1)
        top_k = max(1, int(np.ceil(index.ntotal * 0.2)))
        print(f"  [INFO] Returning top {int(top_k/index.ntotal*100)}% of photos ({top_k} out of {index.ntotal})")

    k = min(top_k, index.ntotal)
    if k == 0:
        return []

    distances, indices = index.search(query_vector, k)

    threshold = _get_confidence_threshold()
    results = []
    for rank, idx in enumerate(indices[0]):
        if idx == -1:
            continue
        # Look up path from SQLite database
        path = db.get_path_by_id(int(idx))
        if path:
            confidence = float(distances[0][rank])
            if confidence <= threshold:
                continue
            results.append((path, confidence))
            
    return results

def main():
    try:
        engine = SearchEngine.load()
    except FileNotFoundError:
        print("Error: FAISS index or SQLite database not found!")
        print(f"Please run the indexing script first:\n  python index.py")
        sys.exit(1)

    print(f"SimSearch Search Engine Ready. Total indexed images: {engine.total_indexed}")

    # Check if a query was provided as command line arguments
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:])
        print(f"\nSearching for: '{query}'")
        try:
            results = engine.search(query)
            if not results:
                print("No results found.")
            else:
                print("\nResults:")
                print(json.dumps(format_search_results(results), indent=4))
        except Exception as e:
            print(f"Search failed: {e}")
            sys.exit(1)
    else:
        # Fallback to interactive search loop
        print("\nEntering interactive search mode. Type 'exit' to quit.")
        while True:
            try:
                query = input("\nSearch: ").strip()
                if not query:
                    continue
                if query.lower() in ("exit", "quit"):
                    print("Exiting search.")
                    break

                results = engine.search(query)
                if not results:
                    print("No results found.")
                else:
                    print("\nResults:")
                    print(json.dumps(format_search_results(results), indent=4))
            except KeyboardInterrupt:
                print("\nExiting search.")
                break
            except Exception as e:
                print(f"Search failed: {e}")

if __name__ == "__main__":
    main()
