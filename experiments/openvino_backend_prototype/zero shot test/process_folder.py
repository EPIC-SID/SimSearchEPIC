import os
from optimum.intel.openvino.modeling import OVModelForZeroShotImageClassification
from transformers import AutoProcessor, pipeline
import openvino as ov
from PIL import Image

# --- Paths ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
model_id = "openai/clip-vit-base-patch32"
local_model_dir = os.path.join(SCRIPT_DIR, "clip-vit-base-patch32-ir")

# Point to the actual data folder (backend/data/images)
IMAGE_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "data", "images"))

# --- Auto-detect best available device (NPU > GPU > CPU) ---
def get_best_device():
    core = ov.Core()
    available = core.available_devices
    print(f"Available OpenVINO devices: {available}")
    for preferred in ["NPU", "GPU", "CPU"]:
        if any(d.startswith(preferred) for d in available):
            print(f"Using device: {preferred}")
            return preferred
    return "CPU"

DEVICE = get_best_device()

# --- Model export (only first run) ---
if not os.path.exists(local_model_dir):
    print("1. Exporting model to IR (without compiling)...")
    model = OVModelForZeroShotImageClassification.from_pretrained(
        model_id, export=True, compile=False
    )
    processor = AutoProcessor.from_pretrained(model_id)
    model.save_pretrained(local_model_dir)
    processor.save_pretrained(local_model_dir)
    print("Model exported and saved to local directory.")

print("Loading local IR model with BLOB caching enabled...")
ov_config = {"CACHE_DIR": os.path.join(SCRIPT_DIR, "model_cache")}
model = OVModelForZeroShotImageClassification.from_pretrained(
    local_model_dir, compile=False, ov_config=ov_config
)
processor = AutoProcessor.from_pretrained(local_model_dir)

# --- Labels ---
candidate_labels = [
    "a photo of a cat", "a photo of a dog", "a photo of a car",
    "woman", "man", "girl", "boy", "child", "brother", "sister",
    "family", "mom", "dad", "group photo", "couple", "friends",
    "cruise", "garden", "men", "women",
    "animal", "landscape", "furniture", "interior", "nature", "building"
]
num_labels = len(candidate_labels)

# --- Fix static shapes for device ---
print(f"2. Fixing dynamic shapes for {DEVICE}...")
shapes = {}
for input_node in model.model.inputs:
    name = input_node.any_name
    if "pixel_values" in name:
        shapes[name] = ov.PartialShape([1, 3, 224, 224])
    elif "input_ids" in name or "attention_mask" in name:
        shapes[name] = ov.PartialShape([num_labels, 77])
    else:
        shapes[name] = input_node.get_partial_shape()

model.model.reshape(shapes)

print(f"3. Compiling for {DEVICE}...")
model.to(DEVICE)
model.compile()

print(f"\n4. Running inference on images in: {IMAGE_DIR}\n")
pipe = pipeline(
    "zero-shot-image-classification",
    model=model,
    feature_extractor=processor.image_processor,
    tokenizer=processor.tokenizer
)

# --- Recursively collect all images from all subdirectories ---
if not os.path.exists(IMAGE_DIR):
    print(f"Image directory not found: {IMAGE_DIR}")
    exit()

valid_extensions = ('.jpg', '.jpeg', '.png', '.bmp', '.webp')
image_files = []
for root, dirs, files in os.walk(IMAGE_DIR):
    for f in files:
        if f.lower().endswith(valid_extensions):
            image_files.append(os.path.join(root, f))

if not image_files:
    print(f"No images found in '{IMAGE_DIR}'. Please add some and try again.")
    exit()

print(f"Found {len(image_files)} image(s) across all subfolders. Starting batch processing...\n")

for filepath in image_files:
    rel_path = os.path.relpath(filepath, IMAGE_DIR)
    print(f"--- Processing: {rel_path} ---")
    try:
        image = Image.open(filepath).convert("RGB")
        results = pipe(
            image,
            candidate_labels=candidate_labels,
            tokenizer_kwargs={"padding": "max_length", "max_length": 77, "truncation": True}
        )
        for result in results[:3]:
            print(f"  -> Label: {result['label']} - Score: {result['score']:.4f}")
    except Exception as e:
        print(f"  -> Failed to process {rel_path}: {e}")
    print()
