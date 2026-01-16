# Nutri Scan Backend

Python Flask backend for the Nutri Scan mobile application.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your MongoDB URI and API keys
```

3. Make sure MongoDB is running:
```bash
# MongoDB should be running on localhost:27017
# Or update MONGODB_URI in .env
```

4. Run the application:
```bash
python app.py
```

The API will be available at `http://localhost:5000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Profile
- `POST /api/profile/create` - Create user profile
- `GET /api/profile/get` - Get user profile
- `PUT /api/profile/update` - Update user profile

### Food Detection
- `POST /api/food/upload` - Upload and detect food from image
- `POST /api/food/detect` - Detect food items (without saving)

### Nutrition
- `POST /api/nutrition/analyze` - Analyze nutrition data
- `POST /api/nutrition/visualize` - Get nutrition visualization data

### Diet Plan
- `POST /api/diet-plan/generate` - Generate personalized diet plan
- `GET /api/diet-plan/get` - Get today's diet plan

### Reports
- `GET /api/reports/daily` - Get daily nutrition report
- `GET /api/reports/weekly` - Get weekly nutrition report

### Recipes
- `POST /api/recipes/suggest` - Get recipe suggestions based on ingredients
- `GET /api/recipes/all` - Get all available recipes

## Notes

- For production, you should train or download a food-specific YOLO model
- Add your Nutrition API keys (Edamam, Nutritionix, etc.) in .env
- The upload folder will be created automatically for storing food images
