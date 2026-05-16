import os
import webview
import json
from datetime import datetime

class SimSearchAPI:
    def __init__(self):
        self.window = None
        # Placeholder for AI engine
        self.engine = None 

    def set_window(self, window):
        self.window = window

    def search_by_text(self, query):
        print(f"Searching for: {query}")
        # TODO: Connect to src.core.engine
        # Mock results for now to test UI
        return [
            {"path": "C:/Windows/Web/Wallpaper/Windows/img0.jpg", "score": 0.95},
            {"path": "C:/Windows/Web/Wallpaper/Theme1/img1.jpg", "score": 0.88}
        ]

    def search_by_image(self, file_path):
        print(f"Searching by image: {file_path}")
        # TODO: Connect to src.core.engine
        return []

    def pick_file(self):
        result = self.window.create_file_dialog(webview.OPEN_DIALOG, allow_multiple=False, file_types=('Image Files (*.jpg;*.jpeg;*.png)', 'All files (*.*)'))
        return result[0] if result else None

    def open_settings(self):
        print("Opening settings...")
        return True

def main():
    api = SimSearchAPI()
    
    # Path to our converted Stitch UI
    html_path = os.path.join(os.path.dirname(__file__), 'src', 'gui', 'index.html')
    
    window = webview.create_window(
        'SimSearch Desktop',
        url=html_path,
        js_api=api,
        width=1200,
        height=800,
        background_color='#f9f9f9'
    )
    
    api.set_window(window)
    webview.start(debug=True)

if __name__ == '__main__':
    main()
