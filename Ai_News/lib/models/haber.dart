class Haber {
  final int id;
  final String baslik;
  final String? icerik;
  final DateTime yayinTarihi;
  final int kategoriId;
  final bool onaylandi;
  final int tiklanmaSayisi;
  final int okunmaSayisi;
  final String? resimYolu;

  Haber(
      {required this.id,
      required this.baslik,
      this.icerik,
      required this.yayinTarihi,
      required this.kategoriId,
      required this.onaylandi,
      required this.tiklanmaSayisi,
      required this.okunmaSayisi,
      this.resimYolu});

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
        resimYolu: json['resimYolu']);
  }
}

class PagedHaberResult {
  final List<Haber> haberler;
  final bool sonSayfaMi;

  PagedHaberResult({required this.haberler, required this.sonSayfaMi});
}
