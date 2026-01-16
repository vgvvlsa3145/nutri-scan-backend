from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from database import db
from utils.auth import token_required, get_current_user_id
from services.rda import rda_service
from models.profile import Profile

reports_bp = Blueprint('reports', __name__)

@reports_bp.route('/daily', methods=['GET'])
@token_required
def get_daily_report():
    try:
        user_id = get_current_user_id()
        date = request.args.get('date', datetime.utcnow().date().isoformat())
        
        # Get all food logs for the date
        food_logs = list(db.food_logs.find({
            'user_id': user_id,
            'date': date
        }))
        
        total_nutrition = {
            'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0,
            'vitamin_a': 0, 'vitamin_c': 0, 'calcium': 0, 'iron': 0, 'sodium': 0,
            'foods_consumed': [],
            'scans': []
        }
        
        for log in food_logs:
            scan_nutrition = log.get('total_nutrition', {})
            # Add to daily totals
            for key in ['calories', 'protein', 'carbs', 'fat', 'fiber', 'vitamin_a', 'vitamin_c', 'calcium', 'iron', 'sodium']:
                total_nutrition[key] += scan_nutrition.get(key, 0)
            
            # Formate time
            log_timestamp = log.get('timestamp') or log.get('created_at')
            time_str = "Unknown"
            if isinstance(log_timestamp, datetime):
                # Ensure UTC is clearly marked for frontend conversion
                time_str = log_timestamp.isoformat()
                if not time_str.endswith('Z'):
                    time_str += 'Z'
            
            # Prepare scan entry
            scan_entry = {
                'id': str(log['_id']),
                'time': time_str,
                'total_nutrition': scan_nutrition,
                'foods': log.get('detected_foods', [])
            }
            total_nutrition['scans'].append(scan_entry)
            
            # Backward compatibility for flattened list
            for food in log.get('detected_foods', []):
                total_nutrition['foods_consumed'].append({
                    'name': food.get('name', ''),
                    'time': time_str,
                    'calories': food.get('nutrition', {}).get('calories', 0)
                })
        
        # Get user profile for comparison
        profile = db.profiles.find_one({'user_id': user_id})
        if profile:
            rda_analysis = rda_service.compare_with_rda(total_nutrition, profile)
        else:
            rda_analysis = None
        
        # Generate insights
        insights = _generate_insights(total_nutrition, rda_analysis, profile)
        
        # Save or update daily report
        report = {
            'user_id': user_id,
            'date': date,
            'total_nutrition': total_nutrition,
            'rda_analysis': rda_analysis,
            'insights': insights,
            'food_logs_count': len(food_logs),
            'created_at': datetime.utcnow()
        }
        
        # Update or insert
        db.daily_reports.update_one(
            {'user_id': user_id, 'date': date},
            {'$set': report},
            upsert=True
        )
        
        return jsonify({
            'report': report
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@reports_bp.route('/weekly', methods=['GET'])
@token_required
def get_weekly_report():
    try:
        user_id = get_current_user_id()
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=6)
        
        # Get reports for the week
        reports = list(db.daily_reports.find({
            'user_id': user_id,
            'date': {
                '$gte': start_date.isoformat(),
                '$lte': end_date.isoformat()
            }
        }))
        
        # Calculate weekly averages
        weekly_totals = {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
            'days_logged': len(reports)
        }
        
        for report in reports:
            nutrition = report.get('total_nutrition', {})
            weekly_totals['calories'] += nutrition.get('calories', 0)
            weekly_totals['protein'] += nutrition.get('protein', 0)
            weekly_totals['carbs'] += nutrition.get('carbs', 0)
            weekly_totals['fat'] += nutrition.get('fat', 0)
        
        if len(reports) > 0:
            weekly_totals['avg_calories'] = round(weekly_totals['calories'] / len(reports), 2)
            weekly_totals['avg_protein'] = round(weekly_totals['protein'] / len(reports), 2)
            weekly_totals['avg_carbs'] = round(weekly_totals['carbs'] / len(reports), 2)
            weekly_totals['avg_fat'] = round(weekly_totals['fat'] / len(reports), 2)
        
        return jsonify({
            'weekly_report': {
                'start_date': start_date.isoformat(),
                'end_date': end_date.isoformat(),
                'totals': weekly_totals,
                'daily_reports': [r for r in reports]
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def _generate_insights(nutrition, rda_analysis, profile):
    """Generate health insights from nutrition data"""
    insights = []
    
    if not rda_analysis:
        return insights
    
    # Calorie insights
    if rda_analysis.get('calories', {}).get('status') == 'low':
        insights.append("You're consuming fewer calories than recommended. Consider adding healthy snacks.")
    elif rda_analysis.get('calories', {}).get('status') == 'high':
        insights.append("You're consuming more calories than recommended. Consider reducing portion sizes.")
    
    # Protein insights
    if rda_analysis.get('protein', {}).get('status') == 'low':
        insights.append("Your protein intake is below recommended levels. Add lean meats, eggs, or legumes.")
    elif rda_analysis.get('protein', {}).get('status') == 'high':
        insights.append("Your protein intake is quite high. Ensure you stay hydrated.")

    # Carbs insights
    if rda_analysis.get('carbs', {}).get('status') == 'low':
        insights.append("Carbohydrate intake is low. Ensure you have enough energy for your activities.")
    elif rda_analysis.get('carbs', {}).get('status') == 'high':
        insights.append("Carbohydrate intake is high. Consider choosing complex carbs over sugary foods.")

    # Fat insights
    if rda_analysis.get('fat', {}).get('status') == 'high':
        insights.append("Fat intake is above recommended limits. Watch out for saturated fats.")

    # Fiber insights
    if rda_analysis.get('fiber', {}).get('status') == 'low':
        insights.append("Low fiber intake detected. Eat more fruits, vegetables, and whole grains.")

    # Micronutrients
    if rda_analysis.get('iron', {}).get('status') == 'low':
        insights.append("Iron levels are low. Include spinach, red meat, or lentils.")
    if rda_analysis.get('calcium', {}).get('status') == 'low':
        insights.append("Calcium intake is low. Consider milk, yogurt, or fortified foods.")

    # Overall balance
    if rda_analysis.get('overall_status') == 'balanced':
        insights.append("Great job! Your nutrition is well-balanced today.")
    
    # Fallback if no specific insights
    if not insights:
        insights.append("Keep tracking your meals to get more detailed insights!")
    
    return insights
