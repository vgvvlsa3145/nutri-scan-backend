from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
import os
from datetime import datetime
from database import db
from utils.auth import token_required, get_current_user_id
from services.food_detection import food_detection_service
from services.nutrition import nutrition_service
from config import Config

food_bp = Blueprint('food', __name__)

# Ensure upload directory exists
os.makedirs(Config.UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS

@food_bp.route('/upload', methods=['POST'])
@token_required
def upload_food_image():
    try:
        user_id = get_current_user_id()
        
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if file and allowed_file(file.filename):
            # Save file
            filename = secure_filename(f"{user_id}_{datetime.utcnow().timestamp()}_{file.filename}")
            filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Preprocess image
            preprocessed_path = food_detection_service.preprocess_image(filepath)
            
            # Detect food items
            detected_foods = food_detection_service.detect_food(preprocessed_path)
            
            # Get detailed nutrition and totals
            total_nutrition = nutrition_service.get_multiple_foods_nutrition(detected_foods)
            food_items = [{
                'name': f['food_name'],
                'confidence': next((d['confidence'] for d in detected_foods if d['name'] == f['food_name']), 0.99),
                'nutrition': f,
                'source': next((d.get('source', 'unknown') for d in detected_foods if d['name'] == f['food_name']), 'unknown'),
                'quantity': f['quantity']
            } for f in total_nutrition['foods']]
            
            # Save to food log
            food_log = {
                'user_id': user_id,
                'image_path': filepath,
                'detected_foods': food_items,
                'total_nutrition': total_nutrition,
                'timestamp': datetime.utcnow(),
                'date': datetime.utcnow().date().isoformat()
            }
            
            db.food_logs.insert_one(food_log)
            
            return jsonify({
                'message': 'Food detected successfully',
                'detected_foods': food_items,
                'total_nutrition': total_nutrition,
                'image_path': filepath
            }), 200
        
        return jsonify({'error': 'Invalid file type'}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@food_bp.route('/detect', methods=['POST'])
@token_required
def detect_food():
    """Detect food items from image without saving"""
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if file and allowed_file(file.filename):
            # Save temporarily
            filename = secure_filename(f"temp_{datetime.utcnow().timestamp()}_{file.filename}")
            filepath = os.path.join(Config.UPLOAD_FOLDER, filename)
            file.save(filepath)
            
            # Detect food
            detected_foods = food_detection_service.detect_food(filepath)
            
            # Clean up temp file
            if os.path.exists(filepath):
                os.remove(filepath)
            
            return jsonify({
                'detected_foods': detected_foods
            }), 200
        
        return jsonify({'error': 'Invalid file type'}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
