// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;
  bool loading = true;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final res = await ApiService.me();
      if (res['ok'] == true) user = Map<String, dynamic>.from(res['data']);
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;

  Future<Map<String, dynamic>> register(String email, String password, {String? displayName}) async {
    final res = await ApiService.register(email, password, displayName: displayName);
    if (res['ok'] == true) {
      // backend trả data.user hoặc user object
      final data = res['data'];
      if (data is Map && data['user'] != null) user = Map<String, dynamic>.from(data['user']);
      notifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.login(email, password);
    if (res['ok'] == true) {
      final data = res['data'];
      if (data is Map && data['user'] != null) user = Map<String, dynamic>.from(data['user']);
      notifyListeners();
    }
    return res;
  }

  Future<void> logout() async {
    await ApiService.logout();
    user = null;
    notifyListeners();
  }
}
