from optimum.intel import OVModelForZeroShotImageClassification
from transformers import AutoProcessor, pipeline
import openvino as ov
import requests
from PIL import Image
import os

model_id = "openai/clip-vit-base-patch32"
local_model_dir = "clip-vit-base-patch32-ir"

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

print("Loading local IR model with BLOB caching enabled...")
# This config enables OpenVINO to cache the compiled NPU blob (.blob) 
ov_config = {"CACHE_DIR": "./model_cache"}
model = OVModelForZeroShotImageClassification.from_pretrained(
    local_model_dir, 
    compile=False,
    ov_config=ov_config
)
processor = AutoProcessor.from_pretrained(local_model_dir)

print("2. Fixing dynamic shapes for the NPU...")
# We must lock ALL inputs to static shapes for the NPU
shapes = {}
num_labels = 3 # We have 3 candidate labels

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

print("3. Compiling for NPU...")
model.to("NPU")
model.compile()

print("4. Running inference...")
pipe = pipeline(
    "zero-shot-image-classification", 
    model=model, 
    feature_extractor=processor.image_processor, 
    tokenizer=processor.tokenizer
)

image_url = "http://images.cocodataset.org/val2017/000000039769.jpg"
image = Image.open(requests.get(image_url, stream=True).raw)

# IMPORTANT: If you add or remove labels here, you MUST update the `num_labels` variable above!
candidate_labels = ["a photo of a cat", "a photo of a dog", "a photo of a car"]

results = pipe(
    image, 
    candidate_labels=candidate_labels,
    tokenizer_kwargs={"padding": "max_length", "max_length": 77, "truncation": True}
)

print("\n--- Results ---")
for result in results:
    print(f"Label: {result['label']} - Score: {result['score']:.4f}")