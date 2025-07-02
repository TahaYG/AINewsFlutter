import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/kategori.dart'; // YENİ: Kategori modelinin adresini ekledik.
import '../models/haber.dart';   // YENİ: Haber modelinin adresini ekledik.

class ApiService {
  // !!! ÇOK ÖNEMLİ !!!
  // Android emülatörü için bu adres genellikle çalışır.
  // Fiziksel bir cihaz veya iOS simülatörü kullanıyorsanız,
  // buraya bilgisayarınızın yerel IP adresini yazmalısınız.
  // Örn: 'http://192.168.1.10:5203'
  static const String _baseUrl = 'http://10.0.2.2:5203';

  Future<List<Kategori>> getKategoriler() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/Kategoriler'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Kategori> kategoriler = body.map((dynamic item) => Kategori.fromJson(item)).toList();
      return kategoriler;
    } else {
      throw Exception('Kategoriler yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }

  Future<List<Haber>> getHaberler() async {
     final response = await http.get(Uri.parse('$_baseUrl/api/Haberler'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Haber> haberler = body.map((dynamic item) => Haber.fromJson(item)).toList();
      return haberler;
    } else {
      throw Exception('Haberler yüklenemedi. Hata kodu: ${response.statusCode}');
    }
  }
}