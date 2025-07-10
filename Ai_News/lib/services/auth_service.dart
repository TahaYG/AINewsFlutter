import 'package:ai_news/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  String? _token;
  List<String> _roles = [];
  bool _isLoggedIn = false;

  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _roles.contains('Admin');
  bool get isModerator => _roles.contains('Moderator');

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
      // DEĞİŞİKLİK: ApiService'ten artık Map olarak veri bekliyoruz.
      final authData = await _apiService.login(username, password);
      if (authData != null) {
        _token = authData['token'];
        _roles = authData['roles']; // Rolleri state'e ata
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
    await _storage.delete(key: 'user_roles'); // Çıkış yaparken rolleri de sil
    _token = null;
    _roles = [];
    _isLoggedIn = false;
    notifyListeners();
  }
}
