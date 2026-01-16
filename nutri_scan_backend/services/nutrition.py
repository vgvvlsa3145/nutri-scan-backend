import requests
import json
import os
import google.generativeai as genai
from groq import Groq
from config import Config

class NutritionService:
    def __init__(self):
        # Configure Gemini (Only for backup or consistency)
        if Config.GEMINI_API_KEY:
            genai.configure(api_key=Config.GEMINI_API_KEY)
            self.gemini_model = genai.GenerativeModel('gemini-flash-latest')
        else:
            self.gemini_model = None

        # Configure Groq
        if Config.GROQ_API_KEY:
            self.groq_client = Groq(api_key=Config.GROQ_API_KEY)
        else:
            self.groq_client = None

        # You can use APIs like Edamam, Nutritionix, or USDA FoodData Central
        self.api_key = os.getenv('NUTRITION_API_KEY', '')
        self.api_url = 'https://api.edamam.com/api/food-database/v2/parser'
        self.app_id = os.getenv('EDAMAM_APP_ID', '')
        self.app_key = os.getenv('EDAMAM_APP_KEY', '')

    def get_nutrition_data(self, food_name, quantity=100):
        """
        Get nutrition data for a food item
        quantity is in grams
        """
        try:
            # Priority 1: Groq (Llama-3 High Performance)
            if self.groq_client:
                try:
                    return self._get_from_groq(food_name, quantity)
                except Exception as e:
                    print(f"Groq Nutrition Error: {e}")

            # Priority 2: Gemini (Backup)
            if self.gemini_model:
                 # ... fallback logic if needed, but for now we skip to API
                 pass

            # Priority 3: API (Edamam)
            if self.app_id and self.app_key:
                return self._get_from_api(food_name, quantity)
            else:
                # Fallback to mock data
                return self._get_mock_nutrition(food_name, quantity)
        except Exception as e:
            print(f"Error fetching nutrition data: {e}")
            return self._get_mock_nutrition(food_name, quantity)

    def _get_from_groq(self, food_name, quantity):
        """Get nutrition estimation from Groq (Llama-3)"""
        if not self.groq_client:
            return None

        prompt = f"""
        Analyze the nutrition for {quantity} grams of '{food_name}'.
        Return ONLY a JSON object with the following keys (values as numbers, no units):
        - calories (kcal)
        - protein (g)
        - carbs (g)
        - fat (g)
        - fiber (g)
        - sugar (g)
        - sodium (mg)
        - calcium (mg)
        - iron (mg)
        - vitamin_c (mg)
        - vitamin_a (mcg)

        Example format:
        {{
            "calories": 150,
            "protein": 12.5,
            ...
        }}
        """
        
        completion = self.groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are a nutritional database. Output valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=500,
            response_format={"type": "json_object"}
        )

        text = completion.choices[0].message.content
        try:
            # Handle potential markdown code blocks
            if "```" in text:
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
            
            data = json.loads(text.strip())
            
            # Normalize keys to snake_case
            normalized_data = {}
            for k, v in data.items():
                key = k.lower().replace(" ", "_").replace("-", "_")
                # Handle potential nested "nutrition" object
                if key == 'nutrition' and isinstance(v, dict):
                    for sub_k, sub_v in v.items():
                        sub_key = sub_k.lower().replace(" ", "_").replace("-", "_")
                        normalized_data[sub_key] = sub_v
                else:
                    normalized_data[key] = v
                    
            # Map common variations
            mappings = {
                'vit_a': 'vitamin_a', 'vit_c': 'vitamin_c', 
                'vitamin_a': 'vitamin_a', 'vitamin_c': 'vitamin_c',
                'calcium': 'calcium', 'iron': 'iron', 'sodium': 'sodium',
                'sugars': 'sugar'
            }
            
            final_data = {
                'food_name': food_name,
                'quantity': quantity,
                'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 
                'fiber': 0, 'sugar': 0, 'sodium': 0, 
                'calcium': 0, 'iron': 0, 'vitamin_a': 0, 'vitamin_c': 0
            }
            
            for k, v in normalized_data.items():
                # Direct match
                if k in final_data:
                    final_data[k] = v
                # Mapped match
                elif k in mappings:
                    final_data[mappings[k]] = v
                # Substring match (e.g., "vitamin a (mcg)")
                else:
                    for target in final_data.keys():
                        if target in k:
                            final_data[target] = v
                            break
                            
            return final_data
            
        except json.JSONDecodeError:
            print(f"Failed to parse Groq response: {text}")
            raise

    def _get_from_api(self, food_name, quantity):
        """Fetch nutrition data from Edamam API"""
        try:
            params = {
                'q': food_name,
                'app_id': self.app_id,
                'app_key': self.app_key
            }
            response = requests.get(self.api_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('hints'):
                    food = data['hints'][0]['food']
                    nutrients = food.get('nutrients', {})
                    
                    # Calculate based on quantity
                    scale = quantity / 100
                    
                    return {
                        'food_name': food.get('label', food_name),
                        'calories': round(nutrients.get('ENERC_KCAL', 0) * scale, 2),
                        'protein': round(nutrients.get('PROCNT', 0) * scale, 2),
                        'carbs': round(nutrients.get('CHOCDF', 0) * scale, 2),
                        'fat': round(nutrients.get('FAT', 0) * scale, 2),
                        'fiber': round(nutrients.get('FIBTG', 0) * scale, 2),
                        'sugar': round(nutrients.get('SUGAR', 0) * scale, 2),
                        'sodium': round(nutrients.get('NA', 0) * scale, 2),
                        'calcium': round(nutrients.get('CA', 0) * scale, 2),
                        'iron': round(nutrients.get('FE', 0) * scale, 2),
                        'vitamin_c': round(nutrients.get('VITC', 0) * scale, 2),
                        'vitamin_a': round(nutrients.get('VITA_RAE', 0) * scale, 2),
                        'quantity': quantity
                    }
        except Exception as e:
            print(f"API error: {e}")
        
        return self._get_mock_nutrition(food_name, quantity)

    def _get_mock_nutrition(self, food_name, quantity):
        """Mock nutrition data for development"""
        # This is a simplified nutrition database
        # In production, use a comprehensive database
        nutrition_db = {
            # COCO Food Classes
            'apple': {'calories': 52, 'protein': 0.3, 'carbs': 14, 'fat': 0.2, 'fiber': 2.4},
            'banana': {'calories': 89, 'protein': 1.1, 'carbs': 23, 'fat': 0.3, 'fiber': 2.6},
            'sandwich': {'calories': 300, 'protein': 12, 'carbs': 35, 'fat': 10, 'fiber': 2}, # Generic
            'orange': {'calories': 47, 'protein': 0.9, 'carbs': 11.8, 'fat': 0.1, 'fiber': 2.4},
            'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4, 'fiber': 2.6},
            'carrot': {'calories': 41, 'protein': 0.9, 'carbs': 9.6, 'fat': 0.2, 'fiber': 2.8},
            'hot dog': {'calories': 290, 'protein': 10, 'carbs': 25, 'fat': 16, 'fiber': 1},
            'pizza': {'calories': 266, 'protein': 11, 'carbs': 33, 'fat': 10, 'fiber': 2}, # Per slice
            'donut': {'calories': 452, 'protein': 4.9, 'carbs': 51, 'fat': 25, 'fiber': 1.5}, # Per portion
            'cake': {'calories': 371, 'protein': 5.5, 'carbs': 53.4, 'fat': 15.1, 'fiber': 0.5}, # Per slice
            'bowl': {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0}, # Container
            'cup': {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0}, # Container
            
            # Common Extras often detected
            'chicken': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6, 'fiber': 0},
            'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3, 'fiber': 0.4},
            'bread': {'calories': 265, 'protein': 9, 'carbs': 49, 'fat': 3.2, 'fiber': 2.7},
            'egg': {'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11, 'fiber': 0},
            'milk': {'calories': 42, 'protein': 3.4, 'carbs': 5, 'fat': 1, 'fiber': 0},
            'salmon': {'calories': 208, 'protein': 20, 'carbs': 0, 'fat': 12, 'fiber': 0},
            'tomato': {'calories': 18, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2, 'fiber': 1.2},
        }
        
        food_lower = food_name.lower()
        base_nutrition = nutrition_db.get(food_lower, {
            'calories': 100,
            'protein': 5,
            'carbs': 15,
            'fat': 3,
            'fiber': 2
        })
        
        scale = quantity / 100
        return {
            'food_name': food_name,
            'calories': round(base_nutrition['calories'] * scale, 2),
            'protein': round(base_nutrition['protein'] * scale, 2),
            'carbs': round(base_nutrition['carbs'] * scale, 2),
            'fat': round(base_nutrition['fat'] * scale, 2),
            'fiber': round(base_nutrition.get('fiber', 2) * scale, 2),
            'sugar': round(5 * scale, 2),
            'sodium': round(10 * scale, 2),
            'calcium': round(50 * scale, 2),
            'iron': round(1 * scale, 2),
            'vitamin_c': round(10 * scale, 2),
            'vitamin_a': round(50 * scale, 2),
            'quantity': quantity
        }

    def get_multiple_foods_nutrition(self, food_items):
        """Get combined nutrition for multiple food items"""
        total_nutrition = {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
            'fiber': 0,
            'sugar': 0,
            'sodium': 0,
            'calcium': 0,
            'iron': 0,
            'vitamin_c': 0,
            'vitamin_a': 0,
            'foods': []
        }
        
        for item in food_items:
            food_name = item.get('name', '')
            quantity = item.get('quantity', 100)
            nutrition = self.get_nutrition_data(food_name, quantity)
            
            total_nutrition['calories'] += nutrition['calories']
            total_nutrition['protein'] += nutrition['protein']
            total_nutrition['carbs'] += nutrition['carbs']
            total_nutrition['fat'] += nutrition['fat']
            total_nutrition['fiber'] += nutrition.get('fiber', 0)
            total_nutrition['sugar'] += nutrition.get('sugar', 0)
            total_nutrition['sodium'] += nutrition.get('sodium', 0)
            total_nutrition['calcium'] += nutrition.get('calcium', 0)
            total_nutrition['iron'] += nutrition.get('iron', 0)
            total_nutrition['vitamin_c'] += nutrition.get('vitamin_c', 0)
            total_nutrition['vitamin_a'] += nutrition.get('vitamin_a', 0)
            
            total_nutrition['foods'].append(nutrition)
        
        # Round all values
        for key in total_nutrition:
            if isinstance(total_nutrition[key], (int, float)):
                total_nutrition[key] = round(total_nutrition[key], 2)
        
        return total_nutrition

# Singleton instance
nutrition_service = NutritionService()
