import json
from groq import Groq
from config import Config

class DietPlanService:
    def __init__(self):
        self.client = Groq(api_key=Config.GROQ_API_KEY) if Config.GROQ_API_KEY else None

    def generate_ai_diet_plan(self, profile, rda_analysis, meal_time=None, recent_foods=None):
        """Uses Groq AI to generate a highly personalized and accurate diet plan."""
        if not self.client:
            return None

        # Extract context
        health_issues = ", ".join(profile.get('health_issues', [])) or "None"
        goals = ", ".join(profile.get('goals', [])) or "Maintain weight"
        age = profile.get('age', 'Unknown')
        weight = profile.get('weight', 'Unknown')
        height = profile.get('height', 'Unknown')
        gender = profile.get('gender', 'Unknown')
        location = profile.get('location', 'Global')
        
        # Context strings
        meal_context = f"Focus specifically on a healthy {meal_time} option." if meal_time else "Generate a full day plan."
        history_context = f"The user has already eaten: {', '.join(recent_foods)}. Ensure the new suggestions complement these foods to balance daily intake." if recent_foods else ""

        # Format RDA deficiencies for the prompt
        deficiencies = []
        for nutrient, data in rda_analysis.items():
            if isinstance(data, dict) and data.get('status') in ['low', 'high']:
                deficiencies.append(f"{nutrient}: {data['status']} ({data['consumed']}/{data['target']})")
        
        deficiencies_str = "\n".join(deficiencies)

        # JSON Format Construction
        if meal_time:
            json_format = f"""
            {{
                "meal_plan": {{
                    "{meal_time.lower()}": ["Food 1 (qty)", "Food 2 (qty)"]
                }},
                "logic": "Brief explanation of why these {meal_time} options were chosen."
            }}
            """
            requirements = f"""
            1. Provide a plan ONLY for {meal_time}.
            2. Be specific about portion sizes.
            3. Tailor to {location} cuisine.
            4. Adhere to health issues: {health_issues}.
            5. Return ONLY a JSON object.
            """
        else:
            json_format = """
            {
                "meal_plan": {
                    "breakfast": ["Food 1 (qty)", "Food 2 (qty)"],
                    "lunch": ["Food 1 (qty)", "Food 2 (qty)"],
                    "dinner": ["Food 1 (qty)", "Food 2 (qty)"],
                    "snacks": ["Food 1 (qty)", "Food 2 (qty)"]
                },
                "logic": "Brief explanation of why these foods were chosen."
            }
            """
            requirements = f"""
            1. Provide a full day plan (Breakfast, Lunch, Dinner, Snacks).
            2. Be specific about portion sizes.
            3. Tailor to {location} cuisine.
            4. Adhere to health issues: {health_issues}.
            5. Return ONLY a JSON object.
            """

        prompt = f"""
        Generate a highly accurate and personalized diet plan for a {age} year old {gender} ({weight}kg, {height}cm) living in {location}.
        
        Personal Context:
        - Health Issues: {health_issues}
        - Goals: {goals}
        - Current Nutrient Gaps:
        {deficiencies_str}
        
        Request Context:
        - {meal_context}
        - {history_context}

        Requirements:
        {requirements}

        JSON Format:
        {json_format}
        """

        try:
            completion = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                response_format={"type": "json_object"}
            )
            
            response_text = completion.choices[0].message.content
            return json.loads(response_text)
        except Exception as e:
            print(f"Error generating AI diet plan: {e}")
            return None

diet_plan_service = DietPlanService()
