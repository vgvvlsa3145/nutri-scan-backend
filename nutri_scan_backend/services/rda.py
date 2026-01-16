class RDAService:
    """RDA (Recommended Daily Allowance) comparison service"""
    
    # RDA values for adults (general guidelines)
    RDA_VALUES = {
        'calories': {'male': 2500, 'female': 2000},
        'protein': {'male': 56, 'female': 46},  # grams
        'carbs': {'male': 300, 'female': 250},  # grams
        'fat': {'male': 78, 'female': 65},  # grams
        'fiber': {'male': 38, 'female': 25},  # grams
        'calcium': {'male': 1000, 'female': 1000},  # mg
        'iron': {'male': 8, 'female': 18},  # mg
        'vitamin_c': {'male': 90, 'female': 75},  # mg
        'vitamin_a': {'male': 900, 'female': 700},  # mcg
    }
    
    @staticmethod
    def compare_with_rda(consumed_nutrition, user_profile):
        """
        Compare consumed nutrition with RDA standards
        Returns analysis with suggestions
        """
        gender = user_profile.get('gender', 'male').lower()
        daily_req = user_profile.get('daily_requirements', {})
        
        # Use personalized requirements if available, otherwise use RDA
        target_calories = daily_req.get('calories', RDAService.RDA_VALUES['calories'].get(gender, 2000))
        target_protein = daily_req.get('protein', RDAService.RDA_VALUES['protein'].get(gender, 50))
        target_carbs = daily_req.get('carbs', RDAService.RDA_VALUES['carbs'].get(gender, 250))
        target_fat = daily_req.get('fat', RDAService.RDA_VALUES['fat'].get(gender, 65))
        
        analysis = {
            'calories': RDAService._analyze_nutrient(
                consumed_nutrition.get('calories', 0),
                target_calories,
                'calories'
            ),
            'protein': RDAService._analyze_nutrient(
                consumed_nutrition.get('protein', 0),
                target_protein,
                'protein'
            ),
            'carbs': RDAService._analyze_nutrient(
                consumed_nutrition.get('carbs', 0),
                target_carbs,
                'carbs'
            ),
            'fat': RDAService._analyze_nutrient(
                consumed_nutrition.get('fat', 0),
                target_fat,
                'fat'
            ),
            'overall_status': 'balanced'
        }
        
        # Determine overall status
        low_count = sum(1 for nutrient in ['calories', 'protein', 'carbs', 'fat'] 
                       if analysis[nutrient]['status'] == 'low')
        high_count = sum(1 for nutrient in ['calories', 'protein', 'carbs', 'fat'] 
                        if analysis[nutrient]['status'] == 'high')
        
        if low_count > 0 or high_count > 0:
            analysis['overall_status'] = 'not_balanced'
        
        # Generate suggestions
        suggestions = RDAService._generate_suggestions(analysis)
        analysis['suggestions'] = suggestions
        
        return analysis
    
    @staticmethod
    def _analyze_nutrient(consumed, target, nutrient_name):
        """Analyze a single nutrient"""
        percentage = (consumed / target * 100) if target > 0 else 0
        
        if percentage < 80:
            status = 'low'
        elif percentage > 120:
            status = 'high'
        else:
            status = 'balanced'
        
        return {
            'consumed': round(consumed, 2),
            'target': round(target, 2),
            'percentage': round(percentage, 2),
            'status': status,
            'difference': round(consumed - target, 2)
        }
    
    @staticmethod
    def _generate_suggestions(analysis):
        """Generate suggestions based on analysis"""
        suggestions = {
            'increase': [],
            'reduce': []
        }
        
        for nutrient, data in analysis.items():
            if nutrient == 'overall_status' or nutrient == 'suggestions':
                continue
            
            if data['status'] == 'low':
                suggestions['increase'].append({
                    'nutrient': nutrient,
                    'current': data['consumed'],
                    'target': data['target'],
                    'needed': round(data['target'] - data['consumed'], 2)
                })
            elif data['status'] == 'high':
                suggestions['reduce'].append({
                    'nutrient': nutrient,
                    'current': data['consumed'],
                    'target': data['target'],
                    'excess': round(data['consumed'] - data['target'], 2)
                })
        
        return suggestions

# Singleton instance
rda_service = RDAService()
