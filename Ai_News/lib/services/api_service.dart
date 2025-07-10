import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/kategori.dart';
import '../models/haber.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5203';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // YENİ: Korumalı API'lere istek atarken token'ı header'a ekleyen yardımcı metot
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      return {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  // --- YENİ AUTH METOTLARI ---
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final token = responseData['token'];
      final roles = List<String>.from(responseData['roles']);

      // Token'ı ve rolleri güvenli depolamaya yaz
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(
          key: 'user_roles',
          value: jsonEncode(roles)); // Rolleri JSON string olarak sakla

      return {'token': token, 'roles': roles};
    }
    return null;
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return response.statusCode == 200;
  }

  // --- YENİ YER İŞARETİ METOTLARI (KORUMALI) ---
  Future<List<Haber>> getYerIsaretliHaberler() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/YerIsaretleri'),
      headers: await _getHeaders(), // Token'lı header kullanılıyor
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Haber.fromJson(item)).toList();
    } else {
      throw Exception('Yer işaretli haberler yüklenemedi.');
    }
  }

  Future<void> yerIsaretiEkle(int haberId) async {
    // Bu metodun başarılı olup olmadığını kontrol etmek için response'u alabiliriz.
    await http.post(
      Uri.parse('$_baseUrl/api/YerIsaretleri/$haberId'),
      headers: await _getHeaders(),
    );
  }

  Future<void> yerIsaretiSil(int haberId) async {
    await http.delete(
      Uri.parse('$_baseUrl/api/YerIsaretleri/$haberId'),
      headers: await _getHeaders(),
    );
  }

  // --- MEVCUT METOTLARINIZ ---
  Future<List<Kategori>> getKategoriler() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/Kategoriler'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Kategori.fromJson(item)).toList();
    } else {
      throw Exception(
          'Kategoriler yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<List<Haber>> getHaberler() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/Haberler'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Haber.fromJson(item)).toList();
    } else {
      throw Exception(
          'Haberler yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<bool> haberTiklandi(int haberId) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/api/Haberler/$haberId/tiklandi'));
      return response.statusCode == 200;
    } catch (e) {
      print('Tıklanma sayacı gönderilirken hata: $e');
      return false;
    }
  }

  Future<bool> haberOkundu(int haberId) async {
    try {
      final response =
          await http.post(Uri.parse('$_baseUrl/api/Haberler/$haberId/okundu'));
      return response.statusCode == 200;
    } catch (e) {
      print('Okunma sayacı gönderilirken hata: $e');
      return false;
    }
  }
}
