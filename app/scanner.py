import os
from typing import List

def scan_for_photos(folder_path: str) -> List[str]:
    """
    Recursively scans the given folder path for photo files.
    
    This function traverses all subfolders to the deepest levels and identifies
    files with common image extensions.
    
    Args:
        folder_path (str): The path to the folder to scan.
        
    Returns:
        List[str]: A list of absolute paths to all found photo files.
    """
    # Comprehensive list of photo/image extensions
    image_extensions = {
        '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', 
        '.tiff', '.tif', '.heic', '.heif', '.raw', '.arw',
        '.cr2', '.nef', '.dng'
    }
    
    photo_paths = []
    
    # Validate that the folder path exists and is a directory
    if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
        return []

    # os.walk performs a recursive traversal of the directory tree
    for root, _, files in os.walk(folder_path):
        for file in files:
            # Check the file extension against our allowed list
            _, ext = os.path.splitext(file)
            if ext.lower() in image_extensions:
                # Store the absolute path of the photo
                full_path = os.path.abspath(os.path.join(root, file))
                photo_paths.append(full_path)
                
    return photo_paths

if __name__ == "__main__":
    # Example usage:
    test_path = r"s:\\Coding\\Projects\\Project_LocalMind\\SimSearch\\test_media"
    photos = scan_for_photos(test_path)
    print(photos)
    print(f"Found {len(photos)} photos.")
