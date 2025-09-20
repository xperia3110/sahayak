// Import necessary packages.
import 'package:flutter/foundation.dart'; // Provides `ChangeNotifier`.
import 'package:shared_preferences/shared_preferences.dart'; // For storing simple data locally on the device.
import '../models/user.dart'; // The data model for a user.
import '../services/api_service.dart'; // The service that handles communication with your backend API.

// The AuthProvider class manages the authentication state of the application.
// It uses `with ChangeNotifier` to allow widgets to listen for changes in its state.
// This is a core concept of the Provider state management pattern.
class AuthProvider with ChangeNotifier {
  // Private properties to hold the state.
  // The underscore `_` makes them private to this file.
  User? _user; // Holds the current logged-in user's data. Null if no one is logged in.
  bool _isLoading = false; // Tracks if an async operation (like login) is in progress.
  String? _error; // Holds the last error message, if any.

  // Public "getters" to allow other parts of the app to read the state
  // without being able to modify it directly.
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // A computed property that returns true if a user is logged in.
  // This is a clean way to check for authentication status.
  bool get isAuthenticated => _user != null;

  // This method is called when the app starts to check if a user was already logged in.
  Future<void> initializeAuth() async {
    _isLoading = true; // Set loading state to true.
    notifyListeners(); // Notify listening widgets that the state has changed (e.g., to show a loading spinner).

    try {
      // Get an instance of SharedPreferences to access local storage.
      final prefs = await SharedPreferences.getInstance();
      // Try to retrieve the stored user data using the key 'user'.
      final userJson = prefs.getString('user');
      
      // If user data was found in local storage...
      if (userJson != null) {
        // The data is stored as a query string (e.g., "key1=value1&key2=value2").
        // This block parses it back into a Map.
        final userData = Map<String, dynamic>.from(
          Uri.splitQueryString(userJson)
        );
        // Create a User object from the parsed map.
        _user = User.fromJson(userData);
      }
    } catch (e) {
      // If anything goes wrong (e.g., data is corrupt), set an error message.
      _error = 'Failed to initialize authentication';
    } finally {
      // This block always runs, whether there was an error or not.
      _isLoading = false; // Set loading state back to false.
      notifyListeners(); // Notify widgets that loading is complete.
    }
  }

  // Handles the user login process.
  Future<bool> login(String username, String password) async {
    _isLoading = true; // Set loading state.
    _error = null; // Clear any previous errors.
    notifyListeners(); // Notify widgets.

    try {
      // Call the login method from the ApiService, which makes the HTTP request to the backend.
      final response = await ApiService.login(username, password);
      // If the API call is successful, create a User object from the response data.
      _user = User.fromJson(response);
      
      // Persist the user data locally for session management.
      final prefs = await SharedPreferences.getInstance();
      // Convert the user object to a Map, then to a query string, and save it.
      await prefs.setString('user', Uri(queryParameters: _user!.toJson()).query);
      
      return true; // Return true to indicate a successful login.
    } catch (e) {
      // If the API call or any other part of the `try` block fails...
      _error = e.toString(); // Store the error message.
      return false; // Return false to indicate a failed login.
    } finally {
      // Always runs after the try/catch block.
      _isLoading = false; // Reset loading state.
      notifyListeners(); // Notify widgets that the login process is finished.
    }
  }

  // Handles the user registration process.
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call the register method from the ApiService.
      final response = await ApiService.register(username, email, password);
      // Create a User object from the response.
      _user = User.fromJson(response);
      
      // Store the new user's data locally, effectively logging them in.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', Uri(queryParameters: _user!.toJson()).query);
      
      return true; // Indicate successful registration.
    } catch (e) {
      _error = e.toString(); // Store any error.
      return false; // Indicate failed registration.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handles the user logout process.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // If the user has a token, it's good practice to invalidate it on the backend.
      if (_user?.token != null) {
        // Call the API to perform server-side logout (e.g., blacklist the token).
        await ApiService.logout(_user!.token!);
      }
    } catch (e) {
      // We don't want to stop the local logout process even if the API call fails.
      // The user should still be logged out on the device.
      // So, we catch the error but don't do anything with it.
    }

    // Clear all local user data to complete the logout on the client side.
    _user = null;
    _error = null;
    
    // Remove the user data from local storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    
    _isLoading = false;
    notifyListeners(); // Notify widgets that the user has logged out.
  }

  // A simple utility method to clear the error state.
  // This might be called when the user dismisses an error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
