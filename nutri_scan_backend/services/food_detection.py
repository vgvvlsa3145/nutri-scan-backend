import cv2
import numpy as np
from ultralytics import YOLO
import os
import base64
from groq import Groq
import google.generativeai as genai
from config import Config

class FoodDetectionService:
    def __init__(self):
        # Initialize YOLO model
        # Using yolov8x.pt (Extra Large) for maximum accuracy.
        self.model_name = 'yolov8m.pt'
        self.model = None
        
        # COCO classes that are food items
        # These are the names used in the standard COCO dataset which YOLOv8 is trained on
        self.food_classes = {
            'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 
            'hot dog', 'pizza', 'donut', 'cake'
        }
        
        self._load_model()

    def _load_model(self):
        """Load YOLO model for food detection"""
        try:
            print(f"Loading YOLO model: {self.model_name}...")
            # This will automatically download the model from the internet if it doesn't exist
            self.model = YOLO(self.model_name)
            print("Model loaded successfully.")
        except Exception as e:
            print(f"Error loading model: {e}")
            self.model = None

    def _encode_image(self, image_path):
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    def detect_with_gemini(self, image_path):
        """Use Google Gemini Vision for SUPER ACCURATE detection"""
        if not Config.GEMINI_API_KEY:
            return []
            
        try:
            print("Running Gemini Vision analysis...")
            genai.configure(api_key=Config.GEMINI_API_KEY)
            model = genai.GenerativeModel('gemini-flash-latest')
            
            # Load image directly using PIL or similar if supported, or pass path if library supports
            # google-generativeai supports PIL images
            from PIL import Image
            img = Image.open(image_path)
            
            prompt = """
            Analyze this food image. Identify the MAIN DISH NAME and ALL visible KEY INGREDIENTS.
            For each item, ESTIMATE the weight in GRAMS (g) based on the portion size visible.
            
            Return ONLY a JSON array. Example:
            [
              {"name": "Rice", "quantity": 150},
              {"name": "Chicken Curry", "quantity": 200},
              {"name": "Cucumber Slice", "quantity": 20}
            ]
            Ignore cutlery/bowls. Do not include markdown formatting.
            """
            
            response = model.generate_content([prompt, img])
            result = response.text.strip()
            
            # Clean up potential markdown code blocks
            if result.startswith("```"):
                result = result.split("```")[1]
                if result.startswith("json"):
                    result = result[4:]
            
            # Sanitize print for Windows Consoles
            safe_result = result.encode('ascii', 'ignore').decode('ascii')
            print(f"Gemini Vision Result: {safe_result}")
            
            import json
            try:
                items = json.loads(result)
            except json.JSONDecodeError:
                # Fallback to simple comma split if JSON fails
                items_str = [i.strip() for i in result.split(',') if i.strip()]
                items = [{"name": i, "quantity": 100} for i in items_str]

            if not items:
                return []
                
            detected = []
            for item in items:
                # Handle both JSON dict and simple string fallback
                name = item.get('name') if isinstance(item, dict) else str(item)
                qty = item.get('quantity', 100) if isinstance(item, dict) else 100
                
                detected.append({
                    'name': name,
                    'confidence': 0.99, 
                    'quantity': qty, # Store estimated quantity
                    'source': 'gemini',
                    'bbox': [0, 0, 0, 0] 
                })
            return detected
            
        except Exception as e:
            print(f"Gemini Vision Error: {e}")
            return []

    def detect_food(self, image_path):
        """
        Detect food items in an image using Gemini Vision (Priority) or YOLO (Fallback)
        """
        print(f"DEBUG IN DETECT_FOOD: Gemini Key Present? {bool(Config.GEMINI_API_KEY)}")
        
        # 1. Gemini Vision (Super Priority - EXCLUSIVE)
        if Config.GEMINI_API_KEY:
            gemini_results = self.detect_with_gemini(image_path)
            if gemini_results:
                print(f"Gemini Success! Returning {len(gemini_results)} items. Skipping YOLO.", flush=True)
                return gemini_results
        
        # 2. YOLO (Fallback ONLY)
        print("Gemini failed/missing. Falling back to YOLO.", flush=True)
        
        all_detections = []
        if not self.model:
            print("Model not loaded, attempting to reload...")
            self._load_model()

        if self.model:
            try:
                # Run inference
                results = self.model(image_path, conf=0.15) 
                
                for result in results:
                    boxes = result.boxes
                    for box in boxes:
                        class_id = int(box.cls[0])
                        confidence = float(box.conf[0])
                        class_name = result.names[class_id]
                        
                        if class_name.lower() in self.food_classes:
                            print(f"YOLO Detected {class_name} ({confidence:.2f})")
                            all_detections.append({
                                'name': class_name,
                                'confidence': round(confidence, 2),
                                'quantity': 100, # Default to 100g for YOLO as it can't estimate weight
                                'source': 'yolo',
                                'bbox': box.xyxy[0].tolist()
                            })
            except Exception as e:
                print(f"Error in YOLO detection: {e}")

        return all_detections

    def preprocess_image(self, image_path):
        """Preprocess image for better detection"""
        try:
            img = cv2.imread(image_path)
            if img is None:
                return None
            
            # Resize if too large
            height, width = img.shape[:2]
            if width > 1280 or height > 1280:
                scale = min(1280/width, 1280/height)
                new_width = int(width * scale)
                new_height = int(height * scale)
                img = cv2.resize(img, (new_width, new_height))
            
            # Basic enhancement
            # We skip heavy enhancement as YOLOv8 is robust enough
            
            # Save preprocessed image
            preprocessed_path = image_path.replace('.', '_preprocessed.')
            cv2.imwrite(preprocessed_path, img)
            
            return preprocessed_path
        except Exception as e:
            print(f"Error preprocessing image: {e}")
            return image_path

# Singleton instance
food_detection_service = FoodDetectionService()
