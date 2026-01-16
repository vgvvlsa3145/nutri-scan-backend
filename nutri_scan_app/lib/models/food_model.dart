class FoodItem {
  final String name;
  final double confidence;
  final NutritionData? nutrition;
  final String? source;
  final String? quantity;

  FoodItem({
    required this.name,
    required this.confidence,
    this.nutrition,
    this.source,
    this.quantity,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      nutrition: json['nutrition'] != null
          ? NutritionData.fromJson(json['nutrition'])
          : null,
      source: json['source'],
    );
  }
}

class NutritionData {
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double vitaminA;
  final double vitaminC;
  final double calcium;
  final double iron;
  final double sodium;
  final double quantity;

  NutritionData({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium = 0.0,
    this.vitaminA = 0.0,
    this.vitaminC = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    required this.quantity,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      foodName: json['food_name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: json['fiber']?.toDouble(),
      sugar: json['sugar']?.toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      vitaminA: (json['vitamin_a'] ?? 0).toDouble(),
      vitaminC: (json['vitamin_c'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamin_a': vitaminA,
      'vitamin_c': vitaminC,
      'calcium': calcium,
      'iron': iron,
      'quantity': quantity,
    };
  }
}

class RDAAnalysis {
  final String overallStatus;
  final Map<String, NutrientAnalysis> nutrients;
  final Suggestions suggestions;

  RDAAnalysis({
    required this.overallStatus,
    required this.nutrients,
    required this.suggestions,
  });

  factory RDAAnalysis.fromJson(Map<String, dynamic> json) {
    final nutrientsMap = <String, NutrientAnalysis>{};
    
    json.forEach((key, value) {
      if (key != 'overall_status' && key != 'suggestions' && value != null) {
        try {
          nutrientsMap[key] = NutrientAnalysis.fromJson(
            value as Map<String, dynamic>,
          );
        } catch (e) {
          // Skip invalid entries
        }
      }
    });
    
    return RDAAnalysis(
      overallStatus: json['overall_status'] ?? 'balanced',
      nutrients: nutrientsMap,
      suggestions: Suggestions.fromJson(json['suggestions'] ?? {}),
    );
  }
}

class NutrientAnalysis {
  final double consumed;
  final double target;
  final double percentage;
  final String status;
  final double difference;

  NutrientAnalysis({
    required this.consumed,
    required this.target,
    required this.percentage,
    required this.status,
    required this.difference,
  });

  factory NutrientAnalysis.fromJson(Map<String, dynamic> json) {
    return NutrientAnalysis(
      consumed: (json['consumed'] ?? 0).toDouble(),
      target: (json['target'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'balanced',
      difference: (json['difference'] ?? 0).toDouble(),
    );
  }
}

class Suggestions {
  final List<SuggestionItem> increase;
  final List<SuggestionItem> reduce;

  Suggestions({
    required this.increase,
    required this.reduce,
  });

  factory Suggestions.fromJson(Map<String, dynamic> json) {
    return Suggestions(
      increase: (json['increase'] ?? [])
          .map((item) => SuggestionItem.fromJson(item))
          .toList(),
      reduce: (json['reduce'] ?? [])
          .map((item) => SuggestionItem.fromJson(item))
          .toList(),
    );
  }
}

class SuggestionItem {
  final String nutrient;
  final double current;
  final double target;
  final double needed;
  final double? excess;

  SuggestionItem({
    required this.nutrient,
    required this.current,
    required this.target,
    required this.needed,
    this.excess,
  });

  factory SuggestionItem.fromJson(Map<String, dynamic> json) {
    return SuggestionItem(
      nutrient: json['nutrient'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      target: (json['target'] ?? 0).toDouble(),
      needed: (json['needed'] ?? json['excess'] ?? 0).toDouble(),
      excess: json['excess']?.toDouble(),
    );
  }
}
