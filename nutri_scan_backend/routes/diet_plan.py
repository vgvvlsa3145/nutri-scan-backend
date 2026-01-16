from flask import Blueprint, request, jsonify
from datetime import datetime
from database import db
from utils.auth import token_required, get_current_user_id
from services.rda import rda_service
from services.nutrition import nutrition_service
from geopy.geocoders import Nominatim
import random

diet_plan_bp = Blueprint('diet_plan', __name__)

from services.diet_plan import diet_plan_service

@diet_plan_bp.route('/generate', methods=['POST'])
@token_required
def generate_diet_plan():
    try:
        user_id = get_current_user_id()
        data = request.get_json()
        
        # Get user profile
        profile = db.profiles.find_one({'user_id': user_id})
        if not profile:
            return jsonify({'error': 'Profile not found'}), 404
        
        # Get RDA analysis
        rda_analysis = data.get('rda_analysis')
        if not rda_analysis:
            today = datetime.utcnow().date().isoformat()
            today_logs = list(db.food_logs.find({
                'user_id': user_id,
                'date': today
            }))
            
            total_nutrition = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0}
            for log in today_logs:
                n = log.get('total_nutrition', {})
                for k in total_nutrition.keys():
                    total_nutrition[k] += n.get(k, 0)
            
            rda_analysis = rda_service.compare_with_rda(total_nutrition, profile)
        
        # Get location and meal time context
        location = data.get('location') or profile.get('location', 'Global')
        meal_time = data.get('meal_time') # e.g., 'Breakfast', 'Lunch'

        # Fetch recent foods for context
        recent_foods = []
        try:
            today = datetime.utcnow().date().isoformat()
            today_logs = list(db.food_logs.find({
                'user_id': user_id,
                'date': today
            }))
            for log in today_logs:
                for food in log.get('detected_foods', []):
                    recent_foods.append(food.get('name', 'Unknown Food'))
        except Exception as e:
            print(f"Error fetching recent foods: {e}")

        # Use Advanced AI to generate the plan
        ai_result = diet_plan_service.generate_ai_diet_plan(profile, rda_analysis, meal_time, recent_foods)
        
        if not ai_result:
            return jsonify({'error': 'AI failed to generate plan'}), 500
            
        meal_plan = ai_result.get('meal_plan')
        logic = ai_result.get('logic', 'Custom plan generated based on your health profile.')

        # Calculate plan nutrition for the summary
        flat_foods = [food for meal in meal_plan.values() for food in meal]
        plan_nutrition = nutrition_service.get_multiple_foods_nutrition([
            {'name': f, 'quantity': 100} for f in flat_foods
        ])
        
        # Save diet plan
        diet_plan_doc = {
            'user_id': user_id,
            'meal_plan': meal_plan,
            'nutrition': plan_nutrition,
            'rda_analysis': rda_analysis,
            'location': location,
            'created_at': datetime.utcnow(),
            'date': datetime.utcnow().date().isoformat()
        }
        
        db.diet_plans.insert_one(diet_plan_doc)
        
        return jsonify({
            'message': 'Diet plan generated successfully',
            'meal_plan': meal_plan,
            'nutrition': plan_nutrition,
            'rda_analysis': rda_analysis
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@diet_plan_bp.route('/get', methods=['GET'])
@token_required
def get_diet_plan():
    try:
        user_id = get_current_user_id()
        today = datetime.utcnow().date().isoformat()
        
        diet_plan = db.diet_plans.find_one({
            'user_id': user_id,
            'date': today
        }, sort=[('created_at', -1)])
        
        if not diet_plan:
            return jsonify({'error': 'No diet plan found for today'}), 404
        
        diet_plan['_id'] = str(diet_plan['_id'])
        return jsonify({'diet_plan': diet_plan}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
