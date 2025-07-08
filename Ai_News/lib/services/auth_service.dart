import 'package:ai_news/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  String? _token;
  bool _isLoggedIn = false;

  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  // Uygulama açıldığında token var mı diye kontrol et
  Future<void> initAuth() async {
    _token = await _storage.read(key: 'auth_token');
    if (_token != null) {
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
    }
    notifyListeners(); // Dinleyen widget'ları haberdar et
  }

  Future<bool> login(String username, String password) async {
    try {
      final token = await _apiService.login(username, password);
      if (token != null) {
        await _storage.write(key: 'auth_token', value: token);
        _token = token;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login hatası: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
