class Haber {
  final int id;
  final String baslik;
  final String? icerik;
  final DateTime yayinTarihi;
  final int kategoriId;
  final bool onaylandi;
  final int tiklanmaSayisi;
  final int okunmaSayisi;

  Haber({
    required this.id,
    required this.baslik,
    this.icerik,
    required this.yayinTarihi,
    required this.kategoriId,
    required this.onaylandi,
    required this.tiklanmaSayisi,
    required this.okunmaSayisi,
  });

  factory Haber.fromJson(Map<String, dynamic> json) {
    return Haber(
      id: json['id'],
      baslik: json['baslik'],
      icerik: json['icerik'],
      yayinTarihi: DateTime.parse(json['yayinTarihi']),
      kategoriId: json['kategoriId'],
      onaylandi: json['onaylandi'] ?? false,
      tiklanmaSayisi: json['tiklanmaSayisi'] ?? 0,
      okunmaSayisi: json['okunmaSayisi'] ?? 0,
    );
  }
}
