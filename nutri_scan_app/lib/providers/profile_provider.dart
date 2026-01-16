import 'package:flutter/foundation.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  Future<bool> createProfile(Map<String, dynamic> profileData) async {
    print("DEBUG: createProfile called with $profileData");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("DEBUG: Sending request to ApiService.createProfile");
      final response = await ApiService.createProfile(profileData);
      print("DEBUG: Received response: $response");
      _profile = ProfileModel.fromJson(response['profile']);
      print("DEBUG: Profile Parsed successfully");
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("DEBUG: Error in createProfile: $e");
      _error = e.toString();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getProfile();
      _profile = ProfileModel.fromJson(response['profile']);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
