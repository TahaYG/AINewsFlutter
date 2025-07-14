import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/kategori.dart';
import '../models/haber.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5175';
  static const int _pageSize = 10;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- AUTH METOTLARI (DÜZELTİLMİŞ) ---
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      // DEĞİŞİKLİK: API'den gelen tüm yanıtı bir değişkene alıyoruz.
      final responseData = jsonDecode(response.body);

      // DEĞİŞİKLİK: Gelen tüm verileri (token, roller, kullanıcı adı)
      // güvenli depolamaya yazıyoruz.
      await _storage.write(key: 'auth_token', value: responseData['token']);
      await _storage.write(
          key: 'user_roles', value: jsonEncode(responseData['roles']));
      await _storage.write(key: 'username', value: responseData['username']);

      // DEĞİŞİKLİK: Sadece bir kısmını değil, tüm veriyi geri döndürüyoruz.
      return responseData;
    }
    return null;
  }

  // DEĞİŞİKLİK: Metot artık hata mesajını döndürüyor.
  Future<String?> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) return null; // Başarılıysa null döndür.

    try {
      // Başarısızsa hata mesajını döndür.
      return jsonDecode(response.body)['message'] ??
          'Bilinmeyen bir kayıt hatası.';
    } catch (e) {
      return 'Sunucu hatası: ${response.statusCode}';
    }
  }

  // --- YER İŞARETİ METOTLARI (Değişiklik yok) ---
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

  // --- MEVCUT METOTLARINIZ (Değişiklik yok) ---
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

  Future<PagedHaberResult> getHaberler(
      {int pageNumber = 1, int? kategoriId}) async {
    final kategoriQuery = (kategoriId != null && kategoriId != 0)
        ? '&kategoriId=$kategoriId'
        : '';

    // YENİ: Cache-busting için URL'nin sonuna benzersiz bir parametre ekliyoruz.
    // O anki milisaniye cinsinden zamanı eklemek, her URL'yi benzersiz kılar.
    final cacheBuster = '&_cb=${DateTime.now().millisecondsSinceEpoch}';

    final url =
        '$_baseUrl/api/Haberler/paged?pageNumber=$pageNumber&pageSize=$_pageSize$kategoriQuery$cacheBuster';

    print("İstek atılan URL: $url"); // Hata ayıklama için URL'yi yazdır.

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> items = data['items'];
      final List<Haber> haberler =
          items.map((item) => Haber.fromJson(item)).toList();

      final pagination = data['pagination'];
      final bool sonSayfaMi = !(pagination['hasNextPage'] ?? false);

      return PagedHaberResult(haberler: haberler, sonSayfaMi: sonSayfaMi);
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
