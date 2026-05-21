import os
import json
import faiss
import torch
import hashlib
import numpy as np
from PIL import Image
from scanner import scan_for_photos
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
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")

INDEX_FILE = os.path.join(FAISS_DB_DIR, "index.faiss")
SQL_DB_FILE = os.path.join(SQL_DB_DIR, "localmind.db")

# -----------------------------
# UTILS
# -----------------------------
def calculate_file_hash(path):
    """Calculates MD5 hash of a file to detect duplicates/moves."""
    hash_md5 = hashlib.md5()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except Exception:
        return None

# -----------------------------
# IMAGE COLLECTION
# -----------------------------
def get_all_image_paths():
    if not os.path.exists(CONFIG_PATH):
        print(f"Warning: Configuration file not found at {CONFIG_PATH}")
        return []
    with open(CONFIG_PATH, 'r') as f:
        config = json.load(f)
    all_paths = []
    for folder in config.get("Folder_Paths", []):
        print(f"Scanning folder: {folder}")
        all_paths.extend(scan_for_photos(folder))
    return list(dict.fromkeys(all_paths))

# -----------------------------
# INDEXING LOGIC
# -----------------------------
def run_indexing():
    print("Scanning configured directories for photos...")
    image_paths = get_all_image_paths()
    if not image_paths:
        print("No images found to index. Check your config.json.")
        return

    print(f"Found {len(image_paths)} image(s) to process.")
    
    if not os.path.exists(MODEL_PATH):
        print(f"\nModel not found at {MODEL_PATH}. Downloading from Hugging Face...")
        model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
        processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
        print(f"Saving model locally to {MODEL_PATH}...")
        os.makedirs(MODEL_PATH, exist_ok=True)
        model.save_pretrained(MODEL_PATH)
        processor.save_pretrained(MODEL_PATH)
    else:
        print(f"\nLoading CLIP model from local path: {MODEL_PATH}")
        model = CLIPModel.from_pretrained(MODEL_PATH)
        processor = CLIPProcessor.from_pretrained(MODEL_PATH)
    
    # Ensure DB directories exist
    os.makedirs(FAISS_DB_DIR, exist_ok=True)
    os.makedirs(SQL_DB_DIR, exist_ok=True)
    db = MediaDatabase(SQL_DB_FILE)
    
    # Clear database first to start fresh and ensure alignment with FAISS row IDs
    print("Clearing database for a clean rebuild...")
    db.clear_all()

    embeddings = []
    valid_paths = []
    
    print(f"\nStarting indexing of {len(image_paths)} images...")
    indexed_count = 0
    for idx, path in enumerate(image_paths):
        try:
            image = Image.open(path).convert("RGB")
            inputs = processor(images=image, return_tensors="pt")
            
            with torch.no_grad():
                image_embeds = model.get_image_features(pixel_values=inputs['pixel_values'])
            
            vector = image_embeds.cpu().numpy().astype("float32")
            vector /= np.linalg.norm(vector, axis=1, keepdims=True)
            
            # Store in SQL (row_id must match FAISS index ID)
            file_hash = calculate_file_hash(path)
            db.insert_media(row_id=indexed_count, file_path=path, file_hash=file_hash)
            
            embeddings.append(vector[0])
            valid_paths.append(path)
            print(f"  [{indexed_count + 1}/{len(image_paths)}] Indexed: {os.path.basename(path)}")
            indexed_count += 1
        except Exception as e:
            print(f"  Error indexing {path}: {e}")

    if not embeddings:
        print("No valid embeddings were created. Indexing aborted.")
        return

    print("\nBuilding FAISS index...")
    # FAISS setup
    dimension = embeddings[0].shape[0]
    index = faiss.IndexFlatIP(dimension)
    index.add(np.array(embeddings).astype("float32"))

    # Save FAISS Index
    faiss.write_index(index, INDEX_FILE)
    
    print(f"\nSuccess! Indexing complete.")
    print(f"  - Total indexed images: {index.ntotal}")
    print(f"  - FAISS index saved to: {INDEX_FILE}")
    print(f"  - SQLite DB saved to: {SQL_DB_FILE}")

if __name__ == "__main__":
    run_indexing()
