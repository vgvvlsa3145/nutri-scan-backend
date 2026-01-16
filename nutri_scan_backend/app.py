from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'dev-secret-key')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'dev-secret-key')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', 86400))

# Initialize JWT Manager
jwt = JWTManager(app)

# Import routes
from routes.auth import auth_bp
from routes.profile import profile_bp
from routes.food_detection import food_bp
from routes.nutrition import nutrition_bp
from routes.diet_plan import diet_plan_bp
from routes.reports import reports_bp
from routes.recipes import recipes_bp

# Register blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(profile_bp, url_prefix='/api/profile')
app.register_blueprint(food_bp, url_prefix='/api/food')
app.register_blueprint(nutrition_bp, url_prefix='/api/nutrition')
app.register_blueprint(diet_plan_bp, url_prefix='/api/diet-plan')
app.register_blueprint(reports_bp, url_prefix='/api/reports')
app.register_blueprint(recipes_bp, url_prefix='/api/recipes')

@app.route('/')
def index():
    return {'message': 'Nutri Scan API is running', 'status': 'success'}

@app.route('/api/health')
def health():
    return {'status': 'healthy', 'message': 'API is operational'}

if __name__ == '__main__':
    # Get port from environment variable for Render/Deployment
    port = int(os.environ.get("PORT", 5000))
    # We disable reloader to prevent the infinite reload loop on Windows
    app.run(debug=True, host='0.0.0.0', port=port, use_reloader=False)
