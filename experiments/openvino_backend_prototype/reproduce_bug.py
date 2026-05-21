import sys
import os
import numpy as np
from unittest.mock import MagicMock

# Add backend/src to path
sys.path.append(os.path.abspath("backend/src"))

# Mocking transformers and torch to avoid heavy loading
sys.modules['transformers'] = MagicMock()
sys.modules['torch'] = MagicMock()
import torch
torch.no_grad = MagicMock()

from core.engine import SearchEngine

def test_concurrency_bug():
    engine = SearchEngine()
    
    # Mock model and processor
    engine.model = MagicMock()
    engine.processor = MagicMock()
    
    # Mock _image_embedding to return a dummy vector
    engine._image_embedding = MagicMock(return_value=np.random.rand(512).astype(np.float32))
    engine._text_embedding = MagicMock(return_value=np.random.rand(512).astype(np.float32))
    
    # 1. Initial indexing
    # We need real files or mock os.walk
    import os
    from unittest.mock import patch
    
    with patch('os.walk') as mock_walk:
        mock_walk.return_value = [
            ('/data', ('',), ('img1.jpg', 'img2.jpg', 'img3.jpg'))
        ]
        with patch('PIL.Image.open') as mock_open:
            mock_open.return_value.convert.return_value = MagicMock()
            engine.index_folder('/data')
    
    print(f"Indexed count: {engine.indexed_count}")
    print(f"Paths: {len(engine._paths)}")
    print(f"Embeddings shape: {engine._embeddings.shape}")
    
    # 2. Start second indexing, but intercept it halfway
    # We can't easily intercept a loop unless we mock the whole process
    # Let's just simulate the state manually
    
    # Simulate being halfway through a new indexing
    engine._paths = ['new_img1.jpg'] # Cleared and started adding
    # engine._embeddings is STILL the old one (3, 512)
    # engine.indexed_count is STILL 3
    
    print("\nSimulating search during re-indexing...")
    try:
        results = engine.search_text("query", top_k=5)
        print("Search results:", results)
    except IndexError as e:
        print("Caught expected IndexError:", e)
    except Exception as e:
        print("Caught unexpected exception:", type(e).__name__, e)

if __name__ == "__main__":
    test_concurrency_bug()
