import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/haber.dart';
import '../screens/haber_detay_ekrani.dart';
import '../services/api_service.dart';

// DEĞİŞİKLİK: Widget, yer işareti durumunu (kaydedildi/kaydedilmedi)
// takip edebilmesi için StatefulWidget'a dönüştürüldü.
/// Haber kartı widget'ı - her haberi görsel olarak temsil eder
class HaberKarti extends StatefulWidget {
  final Haber haber;
  final VoidCallback onGeriDonuldu;

  const HaberKarti({
    super.key,
    required this.haber,
    required this.onGeriDonuldu,
  });

  @override
  State<HaberKarti> createState() => _HaberKartiState();
}

class _HaberKartiState extends State<HaberKarti> {
  final ApiService _apiService = ApiService();
  // Bu haberin o anki yer işareti durumunu tutan yerel değişken
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    // Widget ekrana ilk geldiğinde, bu haberin kayıtlı olup olmadığını kontrol et
    _checkIfBookmarked();
  }

  // API'ye gidip bu haberin kullanıcının yer işaretlerinde olup olmadığını kontrol eder.
  /// Haberin yer işaretli olup olmadığını kontrol eder
  Future<void> _checkIfBookmarked() async {
    // Not: Bu basit kontrol için tüm kayıtlıları çekiyoruz.
    // Çok büyük uygulamalarda bu, API'den tek bir sorgu ile yapılabilir.
    try {
      final bookmarkedList = await _apiService.getYerIsaretliHaberler();
      if (mounted) {
        setState(() {
          _isBookmarked = bookmarkedList.any((h) => h.id == widget.haber.id);
        });
      }
    } catch (e) {
      print("Bookmark kontrol hatası: $e");
    }
  }

  // Bookmark butonuna basıldığında çalışır.
  /// Yer işareti durumunu toggle eder (ekle/kaldır)
  Future<void> _toggleBookmark() async {
    // 1. Arayüzü anında güncelle (İyimser Yaklaşım)
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    // 2. API'ye ilgili isteği gönder
    try {
      if (_isBookmarked) {
        await _apiService.yerIsaretiEkle(widget.haber.id);
      } else {
        await _apiService.yerIsaretiSil(widget.haber.id);
      }
    } catch (e) {
      // 3. Eğer API'de bir hata olursa, yaptığımız değişikliği geri al.
      print("Bookmark toggle hatası: $e");
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background with gradient - arka plan gradyanı
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                    Colors.grey.shade300,
                  ],
                ),
              ),
            ),

            // Blur effect overlay - bulanık efekt katmanı
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Content - ana içerik
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  // Haber tıklanma sayısını artır ve detay sayfasına git
                  await _apiService.haberTiklandi(widget.haber.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HaberDetayEkrani(haber: widget.haber),
                      ),
                    ).then((_) => widget.onGeriDonuldu());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      // Date - Top Right - tarih sağ üstte
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Text(
                          DateFormat('dd MMM yyyy', 'en_US')
                              .format(widget.haber.yayinTarihi),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Title and Bookmark - Bottom Row - başlık ve yer işareti alt satırda
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Haber başlığı
                            Expanded(
                              child: Text(
                                widget.haber.baslik,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Yer işareti butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _toggleBookmark,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      _isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      key: ValueKey(_isBookmarked),
                                      color: _isBookmarked
                                          ? Colors.black
                                          : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
