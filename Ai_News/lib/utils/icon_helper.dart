import 'package:flutter/material.dart';

IconData getIconForCategory(String kategoriAdi) {
  // Gelen kategori adını küçük harfe çevirerek karşılaştırmayı kolaylaştırıyoruz.
  final adi = kategoriAdi.toLowerCase();

  switch (adi) {
    case 'teknoloji':
      return Icons.computer_outlined;
    case 'spor':
      return Icons.sports_soccer_outlined;
    case 'gündem':
      return Icons.newspaper_outlined;
    case 'ekonomi':
      return Icons.trending_up_outlined;
    case 'sağlık':
      return Icons.local_hospital_outlined;
    case 'dünya':
      return Icons.language_outlined;
    case 'kültür & sanat':
      return Icons.palette_outlined;
    case 'tümü':
      return Icons.rss_feed_outlined;
    default:
      // Bilinmeyen bir kategori için varsayılan ikon
      return Icons.article_outlined;
  }
}
