class ProfileModel {
  final String? id;
  final String userId;
  final String name;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String location;
  final String fitnessGoal;
  final double bmi;
  final String bmiCategory;
  final List<String> healthIssues;
  final List<String> allergies;
  final DailyRequirements dailyRequirements;

  ProfileModel({
    this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.location,
    required this.fitnessGoal,
    required this.bmi,
    required this.bmiCategory,
    required this.healthIssues,
    required this.allergies,
    required this.dailyRequirements,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id'] ?? json['id'],
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      location: json['location'] ?? 'India',
      fitnessGoal: json['fitness_goal'] ?? 'Maintain',
      bmi: (json['bmi'] ?? 0).toDouble(),
      bmiCategory: json['bmi_category'] ?? '',
      healthIssues: List<String>.from(json['health_issues'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      dailyRequirements: DailyRequirements.fromJson(
        json['daily_requirements'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'location': location,
      'fitness_goal': fitnessGoal,
      'health_issues': healthIssues,
      'allergies': allergies,
    };
  }
}

class DailyRequirements {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  DailyRequirements({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DailyRequirements.fromJson(Map<String, dynamic> json) {
    return DailyRequirements(
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
    );
  }
}
