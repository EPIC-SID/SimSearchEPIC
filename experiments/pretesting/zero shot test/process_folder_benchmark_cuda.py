import os
import time
import torch
from transformers import pipeline, AutoProcessor, AutoModelForZeroShotImageClassification
from PIL import Image

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

model_id = "openai/clip-vit-base-patch32"
local_model_dir = "clip-vit-base-patch32-ir"
IMAGE_DIR = "images"

print(f"Loading model on target device: {DEVICE}...")

# Load model and processor
model = AutoModelForZeroShotImageClassification.from_pretrained(model_id)
processor = AutoProcessor.from_pretrained(model_id)

# Initialize pipeline
# We use torch.float16 (fp16) on CUDA for faster inference on modern NVIDIA GPUs.
pipe = pipeline(
    "zero-shot-image-classification", 
    model=model, 
    feature_extractor=processor.image_processor, 
    tokenizer=processor.tokenizer,
    device=0 if DEVICE == "cuda" else -1, # device=0 means the first GPU
    model_kwargs={"torch_dtype": torch.float16 if DEVICE == "cuda" else torch.float32}
)

candidate_labels = [
    "a photo of a cat", "Daughter", "a photo of a dog", "a photo of a car",
    "woman", "man", "girl", "boy", "child", "brother", "sister", "family",
    "mom", "dad", "group photo", "couple", "friends", "cruise", "garden",
    "men", "women"
]

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

# Warmup to avoid CUDA initialization overhead in benchmark timing
if len(image_files) > 0 and DEVICE == "cuda":
    print("Warming up GPU...")
    image_warmup = Image.open(os.path.join(IMAGE_DIR, image_files[0])).convert("RGB")
    _ = pipe(image_warmup, candidate_labels=candidate_labels)
    torch.cuda.synchronize()

# ---- START BENCHMARKING ----
start_time = time.time()

for filename in image_files:
    filepath = os.path.join(IMAGE_DIR, filename)
    print(f"--- Processing: {filename} ---")
    
    try:
        # Load the image and force it into RGB format
        image = Image.open(filepath).convert("RGB")
        
        results = pipe(
            image, 
            candidate_labels=candidate_labels
        )
        
        for result in results:
            print(f"  -> Label: {result['label']} - Score: {result['score']:.4f}")
            
    except Exception as e:
        print(f"  -> Failed to process {filename}: {e}")
    print()

if DEVICE == "cuda":
    torch.cuda.synchronize() # Ensure all GPU tasks are complete before stopping the timer

# ---- END BENCHMARKING ----
end_time = time.time()
processing_time = end_time - start_time

print("=========================================")
print(f"      BENCHMARKING RESULTS ({DEVICE.upper()})      ")
print("=========================================")
print(f"Total images processed : {len(image_files)}")
print(f"Total processing time  : {processing_time:.2f} seconds")
if len(image_files) > 0:
    print(f"Average time per image : {processing_time / len(image_files):.2f} seconds")
print("=========================================")
