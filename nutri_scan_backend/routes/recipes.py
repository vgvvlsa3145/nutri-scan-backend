from flask import Blueprint, request, jsonify
from database import db
from utils.auth import token_required
import json
import os
from groq import Groq
from config import Config

recipes_bp = Blueprint('recipes', __name__)

# Recipe database (simplified - in production, use a comprehensive database)
RECIPE_DATABASE = {
    'chicken': [
        {
            'name': 'Grilled Chicken Breast',
            'ingredients': ['chicken', 'olive oil', 'salt', 'pepper', 'garlic'],
            'instructions': '1. Season chicken with salt, pepper, and garlic\n2. Heat olive oil in pan\n3. Grill chicken for 6-8 minutes per side',
            'calories': 231, 'protein': 43, 'carbs': 0, 'fat': 5
        },
        {
            'name': 'Chicken Curry',
            'ingredients': ['chicken', 'onions', 'tomatoes', 'curry powder', 'coconut milk'],
            'instructions': '1. Cook onions until golden\n2. Add chicken and cook until browned\n3. Add tomatoes and spices\n4. Simmer with coconut milk',
            'calories': 280, 'protein': 35, 'carbs': 12, 'fat': 10
        },
        {
             'name': 'Chicken Stir Fry',
             'ingredients': ['chicken', 'broccoli', 'carrots', 'soy sauce', 'ginger'],
             'instructions': '1. Cut chicken and veggies\n2. Stir fry chicken\n3. Add veggies and sauce',
             'calories': 250, 'protein': 30, 'carbs': 15, 'fat': 8
        }
    ],
    'rice': [
        {
            'name': 'Steamed Rice',
            'ingredients': ['rice', 'water', 'salt'],
            'instructions': '1. Rinse rice\n2. Add water (1:2 ratio)\n3. Bring to boil, then simmer for 15-20 minutes',
            'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3
        },
        {
            'name': 'Vegetable Fried Rice',
            'ingredients': ['rice', 'vegetables', 'soy sauce', 'eggs', 'oil'],
            'instructions': '1. Cook rice and let cool\n2. Stir-fry vegetables\n3. Add rice and soy sauce\n4. Mix in scrambled eggs',
            'calories': 200, 'protein': 6, 'carbs': 35, 'fat': 4
        },
        {
             'name': 'Lemon Rice',
             'ingredients': ['rice', 'lemon', 'peanuts', 'turmeric', 'mustard seeds'],
             'instructions': '1. Cook rice\n2. Temper spices and peanuts\n3. Mix with rice and lemon juice',
             'calories': 180, 'protein': 4, 'carbs': 30, 'fat': 6
        }
    ],
    'vegetables': [
        {
            'name': 'Steamed Vegetables',
            'ingredients': ['broccoli', 'carrots', 'cauliflower', 'salt'],
            'instructions': '1. Cut vegetables\n2. Steam for 5-7 minutes\n3. Season with salt',
            'calories': 50, 'protein': 3, 'carbs': 10, 'fat': 0.5
        },
        {
            'name': 'Stir-Fried Vegetables',
            'ingredients': ['mixed vegetables', 'garlic', 'ginger', 'soy sauce', 'oil'],
            'instructions': '1. Heat oil in wok\n2. Add garlic and ginger\n3. Stir-fry vegetables\n4. Add soy sauce',
            'calories': 80, 'protein': 4, 'carbs': 12, 'fat': 2
        },
        {
            'name': 'Mixed Salad',
            'ingredients': ['lettuce', 'tomato', 'cucumber', 'olive oil', 'lemon'],
            'instructions': '1. Chop all vegetables\n2. Toss with olive oil and lemon',
            'calories': 45, 'protein': 1, 'carbs': 5, 'fat': 3
        }
    ],
    'eggs': [
        {
            'name': 'Scrambled Eggs',
            'ingredients': ['eggs', 'butter', 'salt', 'pepper'],
            'instructions': '1. Beat eggs\n2. Heat butter in pan\n3. Cook eggs, stirring constantly\n4. Season with salt and pepper',
            'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11
        },
        {
            'name': 'Boiled Eggs',
            'ingredients': ['eggs', 'water'],
            'instructions': '1. Place eggs in boiling water\n2. Cook for 7-8 minutes\n3. Cool in cold water',
            'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11
        },
        {
            'name': 'Omelette',
            'ingredients': ['eggs', 'onions', 'tomato', 'chili', 'oil'],
            'instructions': '1. Whisk eggs with chopped veggies\n2. Pour into hot pan\n3. Flip and cook both sides',
            'calories': 180, 'protein': 14, 'carbs': 3, 'fat': 12
        }
    ],
    'oats': [
        {
             'name': 'Oatmeal with Fruits',
             'ingredients': ['oats', 'milk', 'apple', 'banana', 'honey'],
             'instructions': '1. Cook oats in milk\n2. Top with cut fruits and honey',
             'calories': 300, 'protein': 10, 'carbs': 50, 'fat': 6
        },
        {
             'name': 'Savory Oats',
             'ingredients': ['oats', 'water', 'vegetables', 'spices'],
             'instructions': '1. Roast oats\n2. Cook veggies\n3. Add water and oats, cook until soft',
             'calories': 250, 'protein': 8, 'carbs': 40, 'fat': 5
        }
    ],
    'milk': [
        {
             'name': 'Fruit Smoothie',
             'ingredients': ['milk', 'banana', 'strawberry', 'honey'],
             'instructions': '1. Blend all ingredients until smooth',
             'calories': 200, 'protein': 8, 'carbs': 30, 'fat': 5
        }
    ],
    'pasta': [
        {
            'name': 'Tomato Pasta',
            'ingredients': ['pasta', 'tomato sauce', 'garlic', 'basil'],
            'instructions': '1. Boil pasta\n2. Warm sauce\n3. Toss pasta in sauce',
            'calories': 350, 'protein': 12, 'carbs': 60, 'fat': 5
        },
        {
            'name': 'Creamy Pasta',
            'ingredients': ['pasta', 'cream', 'cheese', 'pepper'],
            'instructions': '1. Boil pasta\n2. Make sauce with cream and cheese\n3. Combine',
            'calories': 450, 'protein': 15, 'carbs': 55, 'fat': 20
        }
    ],
    'bread': [
        {
            'name': 'Avocado Toast',
            'ingredients': ['bread', 'avocado', 'salt', 'pepper', 'lemon'],
            'instructions': '1. Toast bread\n2. Mash avocado and spread\n3. Season',
            'calories': 250, 'protein': 6, 'carbs': 20, 'fat': 15
        },
        {
            'name': 'Sandwich',
            'ingredients': ['bread', 'vegetables', 'cheese', 'butter'],
            'instructions': '1. Butter bread\n2. Layer veggies and cheese\n3. Grill or eat fresh',
            'calories': 300, 'protein': 10, 'carbs': 35, 'fat': 12
        }
    ]
}

@recipes_bp.route('/suggest', methods=['POST'])
@token_required
def suggest_recipes():
    try:
        data = request.get_json()
        available_items = data.get('ingredients', [])
        
        if not available_items:
            return jsonify({'error': 'No ingredients provided'}), 400
            
        # Try Groq API first if key is available
        if Config.GROQ_API_KEY:
            try:
                print(f"Using Groq API with key: {Config.GROQ_API_KEY[:5]}...")
                client = Groq(api_key=Config.GROQ_API_KEY)
                
                ingredients_str = ", ".join(available_items)
                prompt = f"""
                Suggest at least 20 healthy, distinct, and delicious recipes using these ingredients: {ingredients_str}.
                You MUST use the provided ingredients but can add common pantry items (salt, oil, spices, herbs, vegetables, etc.) to make complete meals.
                The goal is to provide a wide variety of options (Breakfast, Lunch, Dinner, Snacks).

                Return ONLY a JSON array with this exact structure for each recipe:
                [
                    {{
                        "name": "Recipe Name",
                        "description": "A appetizing description of the dish...",
                        "ingredients": ["ingredient1", "ingredient2", "ingredient3", ...],
                        "instructions": "1. Step 1 detail...\\n2. Step 2 detail...\\n3. Step 3 detail...",
                        "calories": 0,
                        "protein": 0,
                        "carbs": 0,
                        "fat": 0
                    }}
                ]
                Ensure the cooking instructions are detailed and step-by-step.
                Do not include any markdown formatting or explanation. Just the JSON.
                """
                
                chat_completion = client.chat.completions.create(
                    messages=[
                        {
                            "role": "user",
                            "content": prompt,
                        }
                    ],
                    model="llama-3.3-70b-versatile",
                )
                
                response_content = chat_completion.choices[0].message.content
                # Clean up potential markdown code blocks
                if "```json" in response_content:
                    response_content = response_content.split("```json")[1].split("```")[0]
                elif "```" in response_content:
                    response_content = response_content.split("```")[1].split("```")[0]
                    
                recipes = json.loads(response_content)
                return jsonify({'recipes': recipes, 'count': len(recipes)}), 200
                
            except Exception as e:
                print(f"Groq API Error: {e}")
                # Fallback to local database if API fails
                pass
        
        # Find matching recipes (Local Fallback)
        suggested_recipes = []
        available_lower = [item.lower() for item in available_items]
        
        for ingredient, recipes in RECIPE_DATABASE.items():
            if ingredient.lower() in available_lower:
                # Add up to 5 recipes per ingredient
                suggested_recipes.extend(recipes[:5])
        
        # Limit to 20 recipes as per requirements
        suggested_recipes = suggested_recipes[:20]
        
        # If no matches, provide general healthy recipes
        if not suggested_recipes:
             suggested_recipes = [
                {
                    'name': 'Healthy Mixed Bowl',
                    'ingredients': available_items[:5],
                    'instructions': '1. Prepare all ingredients\n2. Combine in a bowl\n3. Season to taste',
                    'calories': 200,
                    'protein': 10,
                    'carbs': 25,
                    'fat': 5
                }
            ]
            
        return jsonify({
            'recipes': suggested_recipes,
            'count': len(suggested_recipes)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@recipes_bp.route('/all', methods=['GET'])
@token_required
def get_all_recipes():
    """Get all available recipes"""
    try:
        all_recipes = []
        for recipes in RECIPE_DATABASE.values():
            all_recipes.extend(recipes)
        
        return jsonify({
            'recipes': all_recipes,
            'count': len(all_recipes)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
