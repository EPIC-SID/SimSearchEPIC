import os
import requests
import shutil

# Configuration: Repositories and their sub-folders
DATASETS = {
    "landscapes": {
        "repo": "tommypurcell/landscape-design-image-dataset",
        "path": ""
    },
    "furniture": {
        "repo": "MohamedSameh77i/Furniture_Synthetic_Dataset",
        "path": ""
    },
    "interiors": {
        "repo": "bhoomikagp/interior-design",
        "path": "new_designs"
    }
}

# Specific Animal Varieties
ANIMAL_VARIETIES = ["bear", "cat", "deer", "dog", "lion", "tiger"]
ANIMAL_REPO = "mertcobanov/animals"

LIMIT_PER_CATEGORY = 100 
BASE_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "images")

def get_file_list(repo, path):
    """Uses HF API to list all files in a repo folder."""
    api_url = f"https://huggingface.co/api/datasets/{repo}/tree/main/{path}"
    try:
        response = requests.get(api_url, timeout=10)
        if response.status_code == 200:
            files = response.json()
            return [f["path"] for f in files if f["type"] == "file" and f["path"].lower().endswith(('.jpg', '.png', '.jpeg'))]
    except Exception as e:
        print(f"Error fetching file list for {repo}: {e}")
    return []

def download_file(repo, file_path, category):
    """Downloads a single file from HF resolve URL."""
    url = f"https://huggingface.co/datasets/{repo}/resolve/main/{file_path}"
    save_path = os.path.join(BASE_DIR, category, os.path.basename(file_path))
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    
    try:
        response = requests.get(url, stream=True, timeout=15)
        if response.status_code == 200:
            with open(save_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return True
    except Exception as e:
        pass
    return False

if __name__ == "__main__":
    print("--- SimSearch Diverse Dataset Downloader ---")
    
    # 1. Handle Animals separately for variety
    animal_dir = os.path.join(BASE_DIR, "animals")
    if os.path.exists(animal_dir):
        print("Cleaning old animal images for variety...")
        shutil.rmtree(animal_dir)
    os.makedirs(animal_dir, exist_ok=True)

    total_count = 0
    
    print("\nDownloading Diverse Animals...")
    per_animal_limit = LIMIT_PER_CATEGORY // len(ANIMAL_VARIETIES)
    for animal in ANIMAL_VARIETIES:
        print(f"  Fetching {animal}...")
        files = get_file_list(ANIMAL_REPO, f"animals/{animal}")
        count = 0
        for f_path in files:
            if count >= per_animal_limit: break
            if download_file(ANIMAL_REPO, f_path, "animals"):
                count += 1
                total_count += 1
        print(f"    Done: {count} images.")

    # 2. Handle other categories
    for category, info in DATASETS.items():
        print(f"\nScanning category: {category}...")
        files = get_file_list(info["repo"], info["path"])
        
        if not files: continue
            
        category_count = 0
        for f_path in files:
            if category_count >= LIMIT_PER_CATEGORY: break
            if download_file(info["repo"], f_path, category):
                category_count += 1
                total_count += 1
                if category_count % 20 == 0:
                    print(f"    Progress: {category_count}/{LIMIT_PER_CATEGORY}")

    print(f"\nFinished! Total images in dataset: {total_count}")
    print(f"Data saved to: {os.path.abspath(BASE_DIR)}")
