import 'package:flutter/foundation.dart';

class AppConfig {
  // Use 'true' for Render/Cloud, 'false' for Local development
  // Use 'true' for Render/Cloud, 'false' for Local development
  static const bool useProduction = false; 

  // Render/Cloud Backend API URL - Replace this with your actual Render URL after deployment
  static const String productionBaseUrl = 'https://nutri-scan-api.onrender.com/api';

  static String get localBaseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    // Updated to use your detected LAN IP for physical device testing
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.238.223.232:5000/api';
    return 'http://127.0.0.1:5000/api';
  }

  static String get baseUrl => useProduction ? productionBaseUrl : localBaseUrl;
  // For physical device, use your computer's IP: http://192.168.x.x:5000/api
  
  // API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String profileCreate = '/profile/create';
  static const String profileGet = '/profile/get';
  static const String profileUpdate = '/profile/update';
  static const String foodUpload = '/food/upload';
  static const String foodDetect = '/food/detect';
  static const String nutritionAnalyze = '/nutrition/analyze';
  static const String nutritionManual = '/nutrition/manual';
  static const String nutritionVisualize = '/nutrition/visualize';
  static const String dietPlanGenerate = '/diet-plan/generate';
  static const String dietPlanGet = '/diet-plan/get';
  static const String reportsDaily = '/reports/daily';
  static const String reportsWeekly = '/reports/weekly';
  static const String recipesSuggest = '/recipes/suggest';
  static const String recipesAll = '/recipes/all';
}
