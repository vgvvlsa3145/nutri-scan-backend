import sys
import os
from services.food_detection import FoodDetectionService
from config import Config

try:
    # Add current directory to path
    sys.path.append(os.getcwd())

    print(f"DEBUG: Checking Config. GROQ_API_KEY present? {bool(Config.GROQ_API_KEY)}", flush=True)
    if Config.GROQ_API_KEY:
        print(f"DEBUG: Key starts with: {Config.GROQ_API_KEY[:5]}", flush=True)
    else:
        print("DEBUG: GROQ_API_KEY is MISSING in Config!", flush=True)

    print("Initializing FoodDetectionService...", flush=True)
    service = FoodDetectionService()

    # Image to test (from user's pics folder)
    image_path = r"c:\Users\Sweet.Vellyn_Vgvvlsa\Desktop\ece\nutri_scan_app\pics\crispy-sesame-lemon-chicken-8830c24.jpg"

    if not os.path.exists(image_path):
        print(f"Error: Image not found at {image_path}", flush=True)
        sys.exit(1)

    print(f"Testing detection on: {image_path}", flush=True)

    # 1. Run Detection
    detected_items = service.detect_food(image_path)
    
    print("\n--- Detection Results ---", flush=True)
    if detected_items:
        for item in detected_items:
            print(f"✅ Found: {item['name']} (Confidence: {item['confidence']})", flush=True)
    else:
        print("❌ No food items detected.", flush=True)

    print("\n--- Raw YOLO Model Output ---", flush=True)
    if service.model:
        results = service.model(image_path, conf=0.1)
        for r in results:
             print(f"YOLO saw: {[getattr(b.cls, 'item', lambda: b.cls)() for b in r.boxes]}")

except Exception as e:
    print(f"CRITICAL ERROR in script: {e}", flush=True)
    import traceback
    traceback.print_exc()
