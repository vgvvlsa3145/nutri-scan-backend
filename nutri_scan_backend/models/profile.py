from datetime import datetime

class Profile:
    @staticmethod
    def calculate_bmi(weight_kg, height_cm):
        """Calculate BMI from weight (kg) and height (cm)"""
        height_m = height_cm / 100
        if height_m == 0:
            return 0
        bmi = weight_kg / (height_m ** 2)
        return round(bmi, 2)

    @staticmethod
    def get_bmi_category(bmi):
        """Get BMI category"""
        if bmi < 18.5:
            return 'Underweight'
        elif bmi < 25:
            return 'Normal'
        elif bmi < 30:
            return 'Overweight'
        else:
            return 'Obese'

    @staticmethod
    def calculate_daily_requirements(weight_kg, height_cm, age, gender, activity_level='moderate', fitness_goal='maintain'):
        """Calculate daily nutritional requirements based on user profile and goal"""
        # Calculate BMR (Basal Metabolic Rate) using Mifflin-St Jeor Equation
        height_m = height_cm / 100
        
        if gender.lower() == 'male':
            bmr = 10 * weight_kg + 6.25 * (height_cm) - 5 * age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * (height_cm) - 5 * age - 161
        
        # Activity multipliers
        activity_multipliers = {
            'sedentary': 1.2,
            'light': 1.375,
            'moderate': 1.55,
            'active': 1.725,
            'very_active': 1.9
        }
        
        multiplier = activity_multipliers.get(activity_level.lower(), 1.55)
        calories = int(bmr * multiplier)
        
        # Adjust for Fitness Goal
        goal = fitness_goal.lower()
        if 'bulk' in goal or 'gain' in goal:
            calories += 500  # Surplus for bulking
        elif 'cut' in goal or 'lose' in goal or 'lean' in goal:
            calories -= 500  # Deficit for cutting
            if calories < 1200: calories = 1200 # Safety floor

        # Calculate macronutrients (simplified)
        # Protein adjustment: Higher for bulk/cut to preserve muscle
        protein_factor = 2.0 if ('bulk' in goal or 'cut' in goal) else 1.6
        protein_g = int(weight_kg * protein_factor) 
        
        carbs_g = int((calories * 0.45) / 4)
        fat_g = int((calories * 0.30) / 9)
        
        return {
            'calories': calories,
            'protein': protein_g,
            'carbs': carbs_g,
            'fat': fat_g
        }

    @staticmethod
    def create_profile(user_id, name, age, gender, weight, height, location=None, fitness_goal='maintain', health_issues=None, allergies=None):
        """Create user profile"""
        bmi = Profile.calculate_bmi(weight, height)
        bmi_category = Profile.get_bmi_category(bmi)
        daily_requirements = Profile.calculate_daily_requirements(weight, height, age, gender, fitness_goal=fitness_goal)
        
        return {
            'user_id': user_id,
            'name': name,
            'age': age,
            'gender': gender,
            'weight': weight,
            'height': height,
            'location': location,
            'fitness_goal': fitness_goal,
            'bmi': bmi,
            'bmi_category': bmi_category,
            'health_issues': health_issues or [],
            'allergies': allergies or [],
            'daily_requirements': daily_requirements,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }

    @staticmethod
    def to_dict(profile):
        if profile is None:
            return None
        profile['_id'] = str(profile['_id'])
        return profile
