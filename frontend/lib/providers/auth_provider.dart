import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize auth state from stored data
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(
          Uri.splitQueryString(userJson)
        );
        _user = User.fromJson(userData);
      }
    } catch (e) {
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);
      _user = User.fromJson(response);
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', Uri(queryParameters: _user!.toJson()).query);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(username, email, password);
      _user = User.fromJson(response);
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', Uri(queryParameters: _user!.toJson()).query);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user?.token != null) {
        await ApiService.logout(_user!.token!);
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear local data
    _user = null;
    _error = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
