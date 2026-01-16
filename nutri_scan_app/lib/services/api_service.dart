import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> _handleResponse(
      http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'An error occurred');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.authRegister}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.authLogin}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    final result = await _handleResponse(response);
    if (result['token'] != null) {
      await _saveToken(result['token']);
    }
    return result;
  }

  static Future<void> logout() async {
    await _removeToken();
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> createProfile(
      Map<String, dynamic> profileData) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.profileCreate}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(profileData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl${AppConfig.profileGet}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return await _handleResponse(response);
  }

  // Food detection endpoints
  static Future<Map<String, dynamic>> uploadFoodImage(XFile imageFile) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl${AppConfig.foodUpload}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return await _handleResponse(response);
  }

  // Nutrition endpoints
  static Future<Map<String, dynamic>> analyzeNutrition(
      List<Map<String, dynamic>> foodItems) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.nutritionAnalyze}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'food_items': foodItems}),
    );
    return await _handleResponse(response);
  }

  // Diet plan endpoints
  static Future<Map<String, dynamic>> generateDietPlan(
      {String? location, Map<String, dynamic>? rdaAnalysis, String? mealTime}) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.dietPlanGenerate}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'location': location,
        'rda_analysis': rdaAnalysis,
        'meal_time': mealTime,
      }),
    );
    return await _handleResponse(response);
  }

  // Manual Entry endpoint
  static Future<Map<String, dynamic>> analyzeManualEntry(
      List<Map<String, dynamic>> ingredients) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.nutritionManual}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'ingredients': ingredients}),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> logManualEntry({
    required List<Map<String, dynamic>> ingredients,
    required Map<String, dynamic> totalNutrition,
    required String mealTime,
    required String date,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/nutrition/log'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'ingredients': ingredients,
        'total_nutrition': totalNutrition,
        'meal_time': mealTime,
        'date': date,
      }),
    );
    return await _handleResponse(response);
  }

  // Reports endpoints
  static Future<Map<String, dynamic>> getDailyReport(
      {String? date}) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl${AppConfig.reportsDaily}');
    final finalUri = date != null ? uri.replace(queryParameters: {'date': date}) : uri;
    
    final response = await http.get(
      finalUri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return await _handleResponse(response);
  }

  // Recipes endpoints
  static Future<Map<String, dynamic>> suggestRecipes(
      List<String> ingredients) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl${AppConfig.recipesSuggest}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'ingredients': ingredients}),
    );
    return await _handleResponse(response);
  }
}
