import sys
import os

# Add backend/src to path
sys.path.append(os.path.abspath("backend/src"))

try:
    from core.engine import SearchEngine
    print("Import successful")
    # engine = SearchEngine()
    # print("Initialization successful")
except Exception as e:
    print(f"Import/Init failed: {e}")
    import traceback
    traceback.print_exc()
