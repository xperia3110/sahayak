import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Headers for authenticated requests
  static Map<String, String> _getHeaders(String? token) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  // Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: _getHeaders(null),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? middleName, 
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: _getHeaders(null),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'middle_name': middleName ?? '',
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        // Handle Django dictionary error response
        String errorMessage = 'Registration failed';
        if (error is Map) {
          // If valid keys exist, take the first error message
          if (error.isNotEmpty) {
             errorMessage = error.values.first is List ? error.values.first[0] : error.values.first.toString();
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Logout
  static Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: _getHeaders(token),
      );
    } catch (e) {
      throw Exception('Logout error: $e');
    }
  }

  // Get children
  static Future<List<dynamic>> getChildren(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch children');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create child
  static Future<Map<String, dynamic>> createChild(String token, String nickname, int ageInMonths) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/children/'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'nickname': nickname,
          'age_in_months': ageInMonths,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create child');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get sessions
  static Future<List<dynamic>> getSessions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch sessions');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create session
  static Future<Map<String, dynamic>> createSession(String token, int childId, String gameType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'child': childId,
          'game_type': gameType,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create session');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Submit drawing data
  static Future<void> submitDrawingData(String token, int sessionId, Map<String, dynamic> drawingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/submit-drawing/'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'session_id': sessionId,
          'drawing_data': drawingData,
        }),
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit drawing data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  // Analyze Stroke
  static Future<Map<String, dynamic>> analyzeStroke(String token, List<Map<String, dynamic>> userPoints) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/analyze-stroke/'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'user_points': userPoints,
          // 'target_points': ... (Optional, add if we have guide path)
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Analysis failed');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
