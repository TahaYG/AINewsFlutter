class YorumDto {
  final int id;
  final String icerik;
  final DateTime olusturmaTarihi;
  final bool onaylandi;
  final int haberId;
  final String kullaniciId;
  final String kullaniciAdi;
  final int likeSayisi;
  final int dislikeSayisi;
  final int yanitSayisi;
  final bool? kullaniciLikeDurumu;
  final List<YorumYanitiDto> yanitlar;

  YorumDto({
    required this.id,
    required this.icerik,
    required this.olusturmaTarihi,
    required this.onaylandi,
    required this.haberId,
    required this.kullaniciId,
    required this.kullaniciAdi,
    required this.likeSayisi,
    required this.dislikeSayisi,
    required this.yanitSayisi,
    required this.kullaniciLikeDurumu,
    required this.yanitlar,
  });

  factory YorumDto.fromJson(Map<String, dynamic> json) {
    return YorumDto(
      id: json['id'],
      icerik: json['icerik'],
      olusturmaTarihi: DateTime.parse(json['olusturmaTarihi']),
      onaylandi: json['onaylandi'],
      haberId: json['haberId'],
      kullaniciId: json['kullaniciId'],
      kullaniciAdi: json['kullaniciAdi'],
      likeSayisi: json['likeSayisi'],
      dislikeSayisi: json['dislikeSayisi'],
      yanitSayisi: json['yanitSayisi'],
      kullaniciLikeDurumu: json['kullaniciLikeDurumu'],
      yanitlar: (json['yanitlar'] as List<dynamic>?)?.map((e) => YorumYanitiDto.fromJson(e)).toList() ?? [],
    );
  }
}

class YorumYanitiDto {
  final int id;
  final String icerik;
  final DateTime olusturmaTarihi;
  final bool onaylandi;
  final int yorumId;
  final String kullaniciId;
  final String kullaniciAdi;
  final int likeSayisi;
  final int dislikeSayisi;
  final bool? kullaniciLikeDurumu;

  YorumYanitiDto({
    required this.id,
    required this.icerik,
    required this.olusturmaTarihi,
    required this.onaylandi,
    required this.yorumId,
    required this.kullaniciId,
    required this.kullaniciAdi,
    required this.likeSayisi,
    required this.dislikeSayisi,
    required this.kullaniciLikeDurumu,
  });

  factory YorumYanitiDto.fromJson(Map<String, dynamic> json) {
    return YorumYanitiDto(
      id: json['id'],
      icerik: json['icerik'],
      olusturmaTarihi: DateTime.parse(json['olusturmaTarihi']),
      onaylandi: json['onaylandi'],
      yorumId: json['yorumId'],
      kullaniciId: json['kullaniciId'],
      kullaniciAdi: json['kullaniciAdi'],
      likeSayisi: json['likeSayisi'],
      dislikeSayisi: json['dislikeSayisi'],
      kullaniciLikeDurumu: json['kullaniciLikeDurumu'],
    );
  }
} 