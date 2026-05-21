import os

# -----------------------------
# CONFIGURATION & PATHS
# -----------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

FAISS_DB_DIR = os.path.join(SCRIPT_DIR, "faiss_db")
SQL_DB_DIR = os.path.join(SCRIPT_DIR, "sql_db")

INDEX_FILE = os.path.join(FAISS_DB_DIR, "index.faiss")
SQL_DB_FILE = os.path.join(SQL_DB_DIR, "localmind.db")

def clear_databases():
    print("Clearing SimSearch databases...")
    
    deleted_any = False
    
    # 1. Remove FAISS Index file
    if os.path.exists(INDEX_FILE):
        try:
            os.remove(INDEX_FILE)
            print(f"  [SUCCESS] Removed FAISS index: {INDEX_FILE}")
            deleted_any = True
        except Exception as e:
            print(f"  [ERROR] Failed to remove FAISS index: {e}")
    else:
        print(f"  [INFO] FAISS index file not found (already clean).")
            
    # 2. Remove SQLite database file
    if os.path.exists(SQL_DB_FILE):
        try:
            os.remove(SQL_DB_FILE)
            print(f"  [SUCCESS] Removed SQLite database: {SQL_DB_FILE}")
            deleted_any = True
        except Exception as e:
            print(f"  [ERROR] Failed to remove SQLite database: {e}")
    else:
        print(f"  [INFO] SQLite database file not found (already clean).")
            
    if deleted_any:
        print("\nAll databases cleared successfully! Run 'python index.py' to rebuild them.")
    else:
        print("\nDatabases are already clean.")

if __name__ == "__main__":
    clear_databases()
