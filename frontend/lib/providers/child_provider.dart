import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/child.dart'; // We assume this exists or will need to create it

class ChildProvider with ChangeNotifier {
  List<dynamic> _children = []; // Using dynamic for now, will map to Child model
  bool _isLoading = false;
  String? _error;

  List<dynamic> get children => _children;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch children from API
  Future<void> fetchChildren(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedChildren = await ApiService.getChildren(token); // Pass token
      _children = fetchedChildren;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refreshChildren(String token) {
    fetchChildren(token);
  }
}
