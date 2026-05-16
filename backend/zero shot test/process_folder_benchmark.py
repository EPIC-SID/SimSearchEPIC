import os
import time
import argparse
from optimum.intel import OVModelForZeroShotImageClassification
from transformers import AutoProcessor, pipeline
import openvino as ov
from PIL import Image

# Setup argparse for device selection
parser = argparse.ArgumentParser(description="Zero-shot Image Classification using OpenVINO")
parser.add_argument("--device", type=str, default="NPU", choices=["CPU", "GPU", "NPU"], help="Target device: CPU, GPU (Intel Arc), or NPU")
args = parser.parse_args()

DEVICE = args.device

model_id = "openai/clip-vit-base-patch32"
local_model_dir = "clip-vit-base-patch32-ir"
IMAGE_DIR = "images"  # Change this to your local folder path containing images

if not os.path.exists(local_model_dir):
    print("1. Exporting model to IR (without compiling)...")
    model = OVModelForZeroShotImageClassification.from_pretrained(
        model_id, 
        export=True, 
        compile=False 
    )
    processor = AutoProcessor.from_pretrained(model_id)
    model.save_pretrained(local_model_dir)
    processor.save_pretrained(local_model_dir)
    print("Model exported and saved to local directory.")

print(f"Loading local IR model with cache compiling enabled for {DEVICE}...")
# This config enables OpenVINO to cache the compiled model (creates .blob or other cache files)
ov_config = {"CACHE_DIR": "./model_cache"}
model = OVModelForZeroShotImageClassification.from_pretrained(
    local_model_dir, 
    compile=False,
    ov_config=ov_config
)
processor = AutoProcessor.from_pretrained(local_model_dir)

print(f"2. Fixing dynamic shapes for the {DEVICE}...")
# We must lock ALL inputs to static shapes for the NPU. 
# It also provides peak performance and predictable caching for CPU and GPU.
shapes = {}

# IMPORTANT: If you add or remove labels here, you MUST update the `num_labels` variable below!
candidate_labels = ["a photo of a cat", "Daughter","a photo of a dog", "a photo of a car","woman","man","girl","boy","child","brother","sister","family","mom","dad","group photo","couple","friends","cruise","garden","men","women"]
num_labels = len(candidate_labels) # Dynamically calculate the batch size based on the labels array

for input_node in model.model.inputs:
    name = input_node.any_name
    
    if "pixel_values" in name:
        # 1 image, 3 color channels, 224x224 pixels
        shapes[name] = ov.PartialShape([1, 3, 224, 224])
        
    elif "input_ids" in name or "attention_mask" in name:
        # Batch size matches the number of labels. 
        # CLIP's max sequence length is always 77.
        shapes[name] = ov.PartialShape([num_labels, 77])
        
    else:
        shapes[name] = input_node.get_partial_shape()

# Apply the fixed shapes
model.model.reshape(shapes)

print(f"3. Compiling for {DEVICE}...")
model.to(DEVICE)
model.compile()

print(f"\n4. Preparing inference pipeline on {DEVICE}...")
pipe = pipeline(
    "zero-shot-image-classification", 
    model=model, 
    feature_extractor=processor.image_processor, 
    tokenizer=processor.tokenizer
)

# Ensure the image directory exists
if not os.path.exists(IMAGE_DIR):
    os.makedirs(IMAGE_DIR)
    print(f"Directory '{IMAGE_DIR}' created. Please place some images in it and run the script again!")
    exit()

valid_extensions = ('.jpg', '.jpeg', '.png', '.bmp', '.webp')
image_files = [f for f in os.listdir(IMAGE_DIR) if f.lower().endswith(valid_extensions)]

if not image_files:
    print(f"No images found in '{IMAGE_DIR}'. Please add some and try again.")
    exit()

print(f"Found {len(image_files)} image(s) in '{IMAGE_DIR}'. Starting batch processing...\n")

# ---- START BENCHMARKING ----
start_time = time.time()

for filename in image_files:
    filepath = os.path.join(IMAGE_DIR, filename)
    print(f"--- Processing: {filename} ---")
    
    try:
        # Load the image and force it into RGB format (to ensure 3 channels, discarding any alpha channels)
        image = Image.open(filepath).convert("RGB")
        
        results = pipe(
            image, 
            candidate_labels=candidate_labels,
            tokenizer_kwargs={"padding": "max_length", "max_length": 77, "truncation": True}
        )
        
        for result in results:
            print(f"  -> Label: {result['label']} - Score: {result['score']:.4f}")
            
    except Exception as e:
        print(f"  -> Failed to process {filename}: {e}")
    print() # Empty line for readability

# ---- END BENCHMARKING ----
end_time = time.time()
processing_time = end_time - start_time

print("=========================================")
print(f"      BENCHMARKING RESULTS ({DEVICE})      ")
print("=========================================")
print(f"Total images processed : {len(image_files)}")
print(f"Total processing time  : {processing_time:.2f} seconds")
if len(image_files) > 0:
    print(f"Average time per image : {processing_time / len(image_files):.2f} seconds")
print("=========================================")
