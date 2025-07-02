

class Haber {
  final int id;
  final String baslik;
  final String? icerik;
  final DateTime yayinTarihi;
  final int kategoriId;

  Haber({
    required this.id,
    required this.baslik,
    this.icerik,
    required this.yayinTarihi,
    required this.kategoriId,
  });

  factory Haber.fromJson(Map<String, dynamic> json) {
    return Haber(
      id: json['id'],
      baslik: json['baslik'],
      icerik: json['icerik'],
      yayinTarihi: DateTime.parse(json['yayinTarihi']),
      kategoriId: json['kategoriId'],
    );
  }
}