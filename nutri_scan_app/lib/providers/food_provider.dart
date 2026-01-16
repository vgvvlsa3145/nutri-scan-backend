import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/food_model.dart';
import '../services/api_service.dart';

class FoodProvider with ChangeNotifier {
  List<FoodItem> _detectedFoods = [];
  NutritionData? _totalNutrition;
  RDAAnalysis? _rdaAnalysis;
  bool _isLoading = false;
  String? _error;

  List<FoodItem> get detectedFoods => _detectedFoods;
  NutritionData? get totalNutrition => _totalNutrition;
  RDAAnalysis? get rdaAnalysis => _rdaAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> uploadAndDetectFood(XFile imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.uploadFoodImage(imageFile);
      
      _detectedFoods = (response['detected_foods'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList();
      
      if (response['total_nutrition'] != null) {
        _totalNutrition = NutritionData.fromJson(response['total_nutrition']);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> analyzeNutrition(List<Map<String, dynamic>> foodItems) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.analyzeNutrition(foodItems);
      
      if (response['nutrition'] != null) {
        _totalNutrition = NutritionData.fromJson(response['nutrition']);
      }
      
      if (response['rda_analysis'] != null) {
        _rdaAnalysis = RDAAnalysis.fromJson(response['rda_analysis']);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tracking Manual Entry Context
  DateTime? _manualDate;
  String? _manualMealTime;

  Future<bool> analyzeManualEntry(List<Map<String, dynamic>> ingredients, {DateTime? date, String? mealTime}) async {
    _isLoading = true;
    _error = null;
    _manualDate = date;
    _manualMealTime = mealTime;
    notifyListeners();

    try {
      final response = await ApiService.analyzeManualEntry(ingredients);

      if (response['nutrition'] != null) {
        _totalNutrition = NutritionData.fromJson(response['nutrition']);
      }

      if (response['rda_analysis'] != null) {
        _rdaAnalysis = RDAAnalysis.fromJson(response['rda_analysis']);
      }

      // Populate detected foods list for display in results
      _detectedFoods = [];
      if (response['ingredients'] != null) {
        for (var item in response['ingredients']) {
          _detectedFoods.add(FoodItem(
            name: item['name'],
            confidence: 1.0,
            source: 'manual', // Mark as manual
            quantity: item['weight'].toString(),
          ));
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logManualEntry() async {
    if (_detectedFoods.isEmpty || _totalNutrition == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Reconstruct ingredients
      final ingredients = _detectedFoods.map((f) => {
        'name': f.name,
        'weight': double.tryParse(f.quantity ?? '100') ?? 100.0,
      }).toList();

      await ApiService.logManualEntry(
        ingredients: ingredients,
        totalNutrition: _totalNutrition!.toJson(),
        mealTime: _manualMealTime ?? 'Snack',
        date: (_manualDate ?? DateTime.now()).toIso8601String().split('T')[0],
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _detectedFoods = [];
    _totalNutrition = null;
    _rdaAnalysis = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
