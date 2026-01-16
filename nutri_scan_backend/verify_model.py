import sys
import os

# Add current directory to path so imports work
sys.path.append(os.getcwd())

try:
    print("Testing FoodDetectionService initialization...")
    from services.food_detection import food_detection_service
    
    if food_detection_service.model:
        print("SUCCESS: Model loaded successfully!")
    else:
        print("FAILURE: Model failed to load.")
        
except Exception as e:
    print(f"ERROR: {e}")
