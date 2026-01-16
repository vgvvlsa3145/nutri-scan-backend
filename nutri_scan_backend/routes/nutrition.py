from flask import Blueprint, request, jsonify
from database import db
from utils.auth import token_required, get_current_user_id
from services.nutrition import nutrition_service
from services.rda import rda_service
from models.profile import Profile
import json
from groq import Groq
from config import Config

nutrition_bp = Blueprint('nutrition', __name__)

@nutrition_bp.route('/analyze', methods=['POST'])
@token_required
def analyze_nutrition():
    try:
        user_id = get_current_user_id()
        data = request.get_json()
        
        food_items = data.get('food_items', [])
        if not food_items:
            return jsonify({'error': 'No food items provided'}), 400
        
        # Get nutrition data
        total_nutrition = nutrition_service.get_multiple_foods_nutrition(food_items)
        
        # Get user profile for RDA comparison
        profile = db.profiles.find_one({'user_id': user_id})
        if not profile:
            return jsonify({'error': 'Profile not found. Please create profile first.'}), 404
        
        # Compare with RDA
        rda_analysis = rda_service.compare_with_rda(total_nutrition, profile)
        
        return jsonify({
            'nutrition': total_nutrition,
            'rda_analysis': rda_analysis
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@nutrition_bp.route('/visualize', methods=['POST'])
@token_required
def visualize_nutrition():
    """Get nutrition data formatted for visualization"""
    try:
        user_id = get_current_user_id()
        data = request.get_json()
        
        food_items = data.get('food_items', [])
        if not food_items:
            return jsonify({'error': 'No food items provided'}), 400
        
        # Get nutrition data
        total_nutrition = nutrition_service.get_multiple_foods_nutrition(food_items)
        
        # Format for pie chart (macronutrients)
        pie_chart_data = {
            'labels': ['Protein', 'Carbs', 'Fat'],
            'values': [
                total_nutrition['protein'] * 4,  # calories from protein
                total_nutrition['carbs'] * 4,    # calories from carbs
                total_nutrition['fat'] * 9        # calories from fat
            ],
            'colors': ['#FF6384', '#36A2EB', '#FFCE56']
        }
        
        # Summary table
        summary = {
            'calories': total_nutrition['calories'],
            'protein': f"{total_nutrition['protein']}g",
            'carbs': f"{total_nutrition['carbs']}g",
            'fat': f"{total_nutrition['fat']}g",
            'fiber': f"{total_nutrition.get('fiber', 0)}g"
        }
        
        return jsonify({
            'pie_chart': pie_chart_data,
            'summary': summary,
            'detailed': total_nutrition
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@nutrition_bp.route('/manual', methods=['POST'])
@token_required
def manual_entry():
    """Get nutrition for manually entered food items and weights"""
    try:
        user_id = get_current_user_id()
        data = request.get_json()
        
        ingredients = data.get('ingredients', [])
        # Support legacy single item format for backward compatibility if needed, or just standardizing on list
        if not ingredients and 'food_name' in data:
            ingredients = [{'name': data['food_name'], 'weight': float(data.get('weight', 100))}]
            
        if not ingredients:
            return jsonify({'error': 'No ingredients provided'}), 400
            
        nutrition_data = None

        # 1. Try Groq API for precise estimation of the entire meal/list
        if Config.GROQ_API_KEY:
            try:
                # Construct list string for prompt
                items_str = ", ".join([f"{item['weight']}g of {item['name']}" for item in ingredients])
                print(f"Using Groq for manual entry: {items_str}")
                
                client = Groq(api_key=Config.GROQ_API_KEY)
                
                prompt = f"""
                Analyze the TOTAL nutrition for this meal consisting of: {items_str}.
                Provide precise AGGREGATED values for Calories, Protein, Carbs, Fat, Fiber, Vitamin A, Vitamin C, Calcium, and Iron.
                
                Return ONLY a JSON object with this exact structure (numbers only, no units in values):
                {{
                    "calories": 0,
                    "protein": 0.0,
                    "carbs": 0.0,
                    "fat": 0.0,
                    "fiber": 0.0,
                    "vitamins": {{
                        "a": "0%",
                        "c": "0%"
                    }},
                    "minerals": {{
                        "calcium": "0%",
                        "iron": "0%"
                    }}
                }}
                Do not include markdown. Just key-value JSON.
                """
                
                chat_completion = client.chat.completions.create(
                    messages=[{"role": "user", "content": prompt}],
                    model="llama-3.3-70b-versatile",
                )
                
                response_content = chat_completion.choices[0].message.content
                # Clean up markdown
                if "```json" in response_content:
                    response_content = response_content.split("```json")[1].split("```")[0]
                elif "```" in response_content:
                    response_content = response_content.split("```")[1].split("```")[0]
                    
                nutrition_data = json.loads(response_content)
                
            except Exception as e:
                print(f"Groq Manual Entry Error: {e}")
                pass
        
        # 2. Fallback to Local DB (iterative summing) if Groq failed or no key
        if not nutrition_data:
             nutrition_data = {
                 'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0,
                 'vitamins': {}, 'minerals': {}
             }
             
             for item in ingredients:
                 name = item.get('name')
                 weight = float(item.get('weight', 100))
                 
                 base = nutrition_service.get_nutrition(name)
                 ratio = weight / 100.0
                 
                 nutrition_data['calories'] += base['calories'] * ratio
                 nutrition_data['protein'] += base['protein'] * ratio
                 nutrition_data['carbs'] += base['carbs'] * ratio
                 nutrition_data['fat'] += base['fat'] * ratio
                 nutrition_data['fiber'] += base.get('fiber', 0) * ratio
                 # Note: Vitamins/Minerals aggregation in fallback is tricky without standardized units, defaulting to base for single or skipped for complex sum in MVP fallback.
                 # Let's keep it simple for fallback.

        # Compare with RDA
        profile = db.profiles.find_one({'user_id': user_id})
        rda_analysis = None
        if profile:
            rda_analysis = rda_service.compare_with_rda(nutrition_data, profile)

        return jsonify({
            'ingredients': ingredients,
            'nutrition': nutrition_data,
            'rda_analysis': rda_analysis
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@nutrition_bp.route('/log', methods=['POST'])
@token_required
def log_manual_entry():
    """Save manual entry to food logs"""
    try:
        user_id = get_current_user_id()
        data = request.get_json()

        ingredients = data.get('ingredients', [])
        total_nutrition = data.get('total_nutrition', {})
        meal_time = data.get('meal_time')
        date = data.get('date', datetime.utcnow().date().isoformat())
        
        # Structure payload for detected_foods format
        detected_foods = []
        for item in ingredients:
             detected_foods.append({
                 'name': item.get('name'),
                 'quantity': item.get('weight', 100),
                 'nutrition': {}, # Optional: could fetch if needed, or rely on aggregation
                 'source': 'manual',
                 'confidence': 1.0
             })

        food_log = {
            'user_id': user_id,
            'image_path': None, # Manual entry
            'detected_foods': detected_foods,
            'total_nutrition': total_nutrition,
            'meal_time': meal_time,
            'timestamp': datetime.utcnow(),
            'date': date,
            'source': 'manual'
        }

        db.food_logs.insert_one(food_log)

        return jsonify({'message': 'Food log saved successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
