import 'package:flutter/material.dart';

/// Kategori adına göre uygun ikonu döndürür
IconData getIconForCategory(String kategoriAdi) {
  // Gelen kategori adını küçük harfe çevirerek karşılaştırmayı kolaylaştırıyoruz.
  final adi = kategoriAdi.toLowerCase();

  switch (adi) {
    case 'teknoloji':
    case 'technology':
      return Icons.computer_outlined;
    case 'spor':
    case 'sports':
      return Icons.sports_soccer_outlined;
    case 'gündem':
    case 'news':
      return Icons.newspaper_outlined;
    case 'ekonomi':
    case 'economy':
      return Icons.trending_up_outlined;
    case 'sağlık':
    case 'health':
      return Icons.local_hospital_outlined;
    case 'dünya':
    case 'world':
      return Icons.language_outlined;
    case 'kültür & sanat':
    case 'culture & art':
      return Icons.palette_outlined;
    case 'tümü':
    case 'all':
      return Icons.rss_feed_outlined;
    default:
      // Bilinmeyen bir kategori için varsayılan ikon
      return Icons.article_outlined;
  }
}

// Kategori isimlerini Türkçe'den İngilizce'ye çeviren fonksiyon
/// Kategori adını Türkçe'den İngilizce'ye çevirir
String translateCategoryName(String kategoriAdi) {
  switch (kategoriAdi.toLowerCase()) {
    case 'teknoloji':
      return 'Technology';
    case 'spor':
      return 'Sports';
    case 'gündem':
      return 'News';
    case 'ekonomi':
      return 'Economy';
    case 'sağlık':
      return 'Health';
    case 'dünya':
      return 'World';
    case 'kültür & sanat':
      return 'Culture & Art';
    case 'tümü':
      return 'All';
    default:
      return kategoriAdi; // Bilinmeyen kategoriler için orijinal ismi döndür
  }
}
