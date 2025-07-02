

class Kategori {
  final int id;
  final String ad;

  Kategori({required this.id, required this.ad});

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'],
      ad: json['ad'],
    );
  }
}