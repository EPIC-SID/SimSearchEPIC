import os
import numpy as np
from PIL import Image
from transformers import CLIPModel, CLIPProcessor
import torch

class SearchEngine:
    """
    CLIP-based image search engine.
    - index_folder(): walks a directory, embeds every image with CLIP, stores in memory.
    - search_text(): encodes a text query, returns top-k images by cosine similarity.
    """

    MODEL_NAME = "openai/clip-vit-base-patch32"

    def __init__(self):
        self._paths: list[str] = []
        self._embeddings: np.ndarray | None = None   # shape (N, 512)
        self.indexed_count: int = 0
        self.model: CLIPModel | None = None
        self.processor: CLIPProcessor | None = None
        self._load_model()

    # ── Model loading ──────────────────────────────────────────────────────────

    def _load_model(self):
        print("[Engine] Loading CLIP model (openai/clip-vit-base-patch32)...")
        self.processor = CLIPProcessor.from_pretrained(self.MODEL_NAME)
        self.model = CLIPModel.from_pretrained(self.MODEL_NAME)
        self.model.eval()
        print("[Engine] CLIP model ready.")

    # ── Embedding helpers ──────────────────────────────────────────────────────

    def _image_embedding(self, image: Image.Image) -> np.ndarray:
        inputs = self.processor(images=image, return_tensors="pt")
        with torch.no_grad():
            feats = self.model.get_image_features(**inputs)
            feats = feats / feats.norm(dim=-1, keepdim=True)
        return feats.squeeze(0).cpu().numpy()

    def _text_embedding(self, text: str) -> np.ndarray:
        inputs = self.processor(
            text=[text], return_tensors="pt",
            padding=True, truncation=True, max_length=77
        )
        with torch.no_grad():
            feats = self.model.get_text_features(**inputs)
            feats = feats / feats.norm(dim=-1, keepdim=True)
        return feats.squeeze(0).cpu().numpy()

    # ── Indexing ───────────────────────────────────────────────────────────────

    def index_folder(self, folder_path: str):
        """Walk folder_path recursively and embed all images. Blocking."""
        print(f"[Engine] Indexing folder: {folder_path}")
        valid_ext = ('.jpg', '.jpeg', '.png', '.bmp', '.webp')

        all_paths = []
        for root, _, files in os.walk(folder_path):
            for f in files:
                if f.lower().endswith(valid_ext):
                    all_paths.append(os.path.join(root, f))

        if not all_paths:
            print("[Engine] No images found — index is empty.")
            return

        print(f"[Engine] Found {len(all_paths)} images. Embedding...")
        embeddings = []
        self._paths = []

        for i, path in enumerate(all_paths):
            try:
                img = Image.open(path).convert("RGB")
                emb = self._image_embedding(img)
                embeddings.append(emb)
                self._paths.append(path)
                if (i + 1) % 20 == 0 or (i + 1) == len(all_paths):
                    print(f"[Engine] {i + 1}/{len(all_paths)} images embedded")
            except Exception as e:
                print(f"[Engine] Skipped {path}: {e}")

        if embeddings:
            self._embeddings = np.stack(embeddings).astype(np.float32)
            self.indexed_count = len(self._paths)
            print(f"[Engine] Indexing complete — {self.indexed_count} images ready.")
        else:
            print("[Engine] No valid images could be embedded.")

    # ── Search ─────────────────────────────────────────────────────────────────

    def search_text(self, query: str, top_k: int = 20) -> list[dict]:
        """Return top-k results for a text query, sorted by cosine similarity."""
        if self._embeddings is None or len(self._paths) == 0:
            return []

        q_emb = self._text_embedding(query)                  # (512,)
        scores = self._embeddings @ q_emb                     # (N,) cosine sims

        top_k = min(top_k, len(self._paths))
        top_indices = np.argsort(scores)[::-1][:top_k]

        return [
            {
                "path": self._paths[idx],
                "score": float(scores[idx]),
                "name": os.path.basename(self._paths[idx]),
            }
            for idx in top_indices
        ]
