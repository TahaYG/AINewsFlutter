import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/kategori.dart';
import '../models/haber.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5175';
  static const int _pageSize = 10;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Korumalı API'lere istek atarken token'ı header'a ekleyen yardımcı metot
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- AUTH METOTLARI ---
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await _storage.write(key: 'auth_token', value: responseData['token']);
      await _storage.write(
          key: 'user_roles', value: jsonEncode(responseData['roles']));
      await _storage.write(key: 'username', value: responseData['username']);
      return responseData;
    }
    return null;
  }

  Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) return null;
    try {
      return jsonDecode(response.body)['message'] ??
          'Bilinmeyen bir kayıt hatası.';
    } catch (e) {
      return 'Sunucu hatası: ${response.statusCode}';
    }
  }

  // --- YER İŞARETİ METOTLARI ---
  Future<List<Haber>> getYerIsaretliHaberler() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/YerIsaretleri'),
        headers: await _getHeaders());
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => Haber.fromJson(item)).toList();
    } else {
      throw Exception('Yer işaretli haberler yüklenemedi.');
    }
  }

  Future<void> yerIsaretiEkle(int haberId) async {
    await http.post(Uri.parse('$_baseUrl/api/YerIsaretleri/$haberId'),
        headers: await _getHeaders());
  }

  Future<void> yerIsaretiSil(int haberId) async {
    await http.delete(Uri.parse('$_baseUrl/api/YerIsaretleri/$haberId'),
        headers: await _getHeaders());
  }

  // --- GENEL VERİ ÇEKME METOTLARI ---
  Future<List<Kategori>> getKategoriler() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/Kategoriler'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => Kategori.fromJson(item)).toList();
      } else {
        throw Exception(
            'Kategoriler yüklenemedi. Hata: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Sunucuya ulaşılamadı. (Timeout)');
    } on SocketException {
      throw Exception('Ağ hatası. İnternet bağlantınızı kontrol edin.');
    } catch (e) {
      rethrow;
    }
  }

  // === DEĞİŞİKLİK: C# Controller'ınızdaki doğru endpoint'i çağıracak şekilde güncellendi ===
  Future<PagedHaberResult> getHaberler(
      {int pageNumber = 1, int? kategoriId}) async {
    final kategoriQuery = (kategoriId != null && kategoriId != 0)
        ? '&kategoriId=$kategoriId'
        : '';

    // DÜZELTME: API'nizdeki Flutter için olan endpoint'in doğru adresi "paged"
    final url =
        '$_baseUrl/api/Haberler/paged?pageNumber=$pageNumber&pageSize=$_pageSize$kategoriQuery';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // API'den gelen PagedResult formatını doğru şekilde işliyoruz
        final List<dynamic> items = data['items'];
        final List<Haber> haberler =
            items.map((item) => Haber.fromJson(item)).toList();

        final pagination = data['pagination'];
        final bool sonSayfaMi = !(pagination['hasNextPage'] ?? false);

        return PagedHaberResult(haberler: haberler, sonSayfaMi: sonSayfaMi);
      } else {
        throw Exception(
            'Haberler yüklenemedi. Hata: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on TimeoutException {
      throw Exception('Sunucu yanıt vermiyor. (Timeout)');
    } on SocketException {
      throw Exception(
          'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.');
    } catch (e) {
      rethrow;
    }
  }

  // --- SAYAÇ METOTLARI ---
  Future<bool> haberTiklandi(int haberId) async {
    // C# Controller'ınızdaki metoda uygun olarak PUT kullanıyoruz.
    final response = await http.put(
        Uri.parse('$_baseUrl/api/Haberler/$haberId/increment-click'),
        headers: await _getHeaders());
    return response.statusCode == 200;
  }

  Future<bool> haberOkundu(int haberId) async {
    // C# Controller'ınızdaki metoda uygun olarak PUT kullanıyoruz.
    final response = await http.put(
        Uri.parse('$_baseUrl/api/Haberler/$haberId/increment-read'),
        headers: await _getHeaders());
    return response.statusCode == 200;
  }
}

// PagedHaberResult sınıfı
class PagedHaberResult {
  final List<Haber> haberler;
  final bool sonSayfaMi;
  PagedHaberResult({required this.haberler, required this.sonSayfaMi});
}
