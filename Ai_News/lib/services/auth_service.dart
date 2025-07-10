import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  String? _token;
  List<String> _roles = [];
  String? _username;
  bool _isLoggedIn = false;

  String? get token => _token;
  String? get username => _username;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _roles.contains('Admin');
  bool get isModerator => _roles.contains('Moderator');

  Future<void> initAuth() async {
    print("--- initAuth BAŞLADI: Cihazdan veri okunuyor... ---");
    _token = await _storage.read(key: 'auth_token');
    final rolesString = await _storage.read(key: 'user_roles');
    _username = await _storage.read(key: 'username');

    // === DEBUG: Cihazdan ne okuduğumuzu görelim ===
    print("Okunan Token: ${_token ?? 'YOK'}");
    print("Okunan Roller (String): ${rolesString ?? 'YOK'}");
    print("Okunan Kullanıcı Adı: ${_username ?? 'YOK'}");

    if (_token != null) {
      _roles = (rolesString != null)
          ? List<String>.from(jsonDecode(rolesString))
          : [];
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
      _roles = [];
      _username = null;
    }
    print(
        "--- initAuth BİTTİ: Giriş durumu: $_isLoggedIn, Kullanıcı: $_username ---");
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final authData = await _apiService.login(username, password);
      if (authData != null) {
        print("--- login BAŞARILI: API'den gelen veri: $authData ---");

        _token = authData['token'];
        _roles = List<String>.from(authData['roles']);
        _username = authData['username']; // Kullanıcı adını state'e ata
        _isLoggedIn = true;

        // === DEBUG: Cihaza ne yazdığımızı görelim ===
        print("Yazılan Token: $_token");
        print("Yazılan Roller: $_roles");
        print("Yazılan Kullanıcı Adı: $_username");

        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_roles', value: jsonEncode(_roles));
        await _storage.write(key: 'username', value: _username);

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
    print("--- logout ÇAĞRILDI: Tüm veriler siliniyor... ---");
    await _storage.deleteAll();
    _token = null;
    _roles = [];
    _username = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
