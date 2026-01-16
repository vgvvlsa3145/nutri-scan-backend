from flask import Blueprint, request, jsonify
from database import db
from models.profile import Profile
from utils.auth import token_required, get_current_user_id

profile_bp = Blueprint('profile', __name__)

@profile_bp.route('/create', methods=['POST'])
@token_required
def create_profile():
    try:
        user_id = get_current_user_id()
        data = request.get_json()
        print(f"DEBUG: Received profile create request. User: {user_id}, Data: {data}", flush=True)

        name = data.get('name')
        age = int(data.get('age', 0))
        gender = data.get('gender')
        weight = float(data.get('weight', 0))
        height = float(data.get('height', 0))
        location = data.get('location', '')
        fitness_goal = data.get('fitness_goal', 'maintain')
        health_issues = data.get('health_issues', [])
        allergies = data.get('allergies', [])

        if not all([name, age, gender, weight, height]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Check if profile already exists
        existing_profile = db.profiles.find_one({'user_id': user_id})
        if existing_profile:
            # Update existing profile
            profile_data = Profile.create_profile(
                user_id, name, age, gender, weight, height, location, fitness_goal, health_issues, allergies
            )
            db.profiles.update_one(
                {'user_id': user_id},
                {'$set': profile_data}
            )
            profile = db.profiles.find_one({'user_id': user_id})
        else:
            # Create new profile
            profile_data = Profile.create_profile(
                user_id, name, age, gender, weight, height, location, fitness_goal, health_issues, allergies
            )
            result = db.profiles.insert_one(profile_data)
            profile = db.profiles.find_one({'_id': result.inserted_id})

        return jsonify({
            'message': 'Profile saved successfully',
            'profile': Profile.to_dict(profile)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@profile_bp.route('/get', methods=['GET'])
@token_required
def get_profile():
    try:
        user_id = get_current_user_id()
        profile = db.profiles.find_one({'user_id': user_id})

        if not profile:
            return jsonify({'error': 'Profile not found'}), 404

        return jsonify({
            'profile': Profile.to_dict(profile)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@profile_bp.route('/update', methods=['PUT'])
@token_required
def update_profile():
    try:
        user_id = get_current_user_id()
        data = request.get_json()

        profile = db.profiles.find_one({'user_id': user_id})
        if not profile:
            return jsonify({'error': 'Profile not found'}), 404

        # Update fields
        update_data = {}
        if 'name' in data:
            update_data['name'] = data['name']
        if 'age' in data:
            update_data['age'] = int(data['age'])
        if 'gender' in data:
            update_data['gender'] = data['gender']
        if 'weight' in data:
            update_data['weight'] = float(data['weight'])
        if 'height' in data:
            update_data['height'] = float(data['height'])
        if 'location' in data:
            update_data['location'] = data['location']
        if 'fitness_goal' in data:
            update_data['fitness_goal'] = data['fitness_goal']
        if 'health_issues' in data:
            update_data['health_issues'] = data['health_issues']
        if 'allergies' in data:
            update_data['allergies'] = data['allergies']

        # Recalculate BMI and requirements if weight or height changed
        if 'weight' in update_data or 'height' in update_data or 'fitness_goal' in update_data:
            weight = update_data.get('weight', profile['weight'])
            height = update_data.get('height', profile['height'])
            age = update_data.get('age', profile['age'])
            gender = update_data.get('gender', profile['gender'])
            fitness_goal = update_data.get('fitness_goal', profile.get('fitness_goal', 'maintain'))
            
            update_data['bmi'] = Profile.calculate_bmi(weight, height)
            update_data['bmi_category'] = Profile.get_bmi_category(update_data['bmi'])
            update_data['daily_requirements'] = Profile.calculate_daily_requirements(
                weight, height, age, gender, fitness_goal=fitness_goal
            )

        update_data['updated_at'] = Profile.create_profile.__globals__['datetime'].utcnow()

        db.profiles.update_one(
            {'user_id': user_id},
            {'$set': update_data}
        )

        updated_profile = db.profiles.find_one({'user_id': user_id})
        return jsonify({
            'message': 'Profile updated successfully',
            'profile': Profile.to_dict(updated_profile)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
