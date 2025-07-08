import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/haber.dart';
import '../screens/haber_detay_ekrani.dart';
import '../services/api_service.dart';

// DEĞİŞİKLİK: Widget, yer işareti durumunu (kaydedildi/kaydedilmedi)
// takip edebilmesi için StatefulWidget'a dönüştürüldü.
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () async {
          _apiService.haberTiklandi(widget.haber.id);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HaberDetayEkrani(haber: widget.haber),
            ),
          );
          widget.onGeriDonuldu();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Text(
                widget.haber.baslik,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // İçerik
              Text(
                widget.haber.icerik ?? 'İçerik mevcut değil.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Tarih ve Bookmark Butonu
              Row(
                children: [
                  Text(
                    DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
                        .format(widget.haber.yayinTarihi),
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const Spacer(), // Aradaki boşluğu doldurur
                  // YENİ: Bookmark butonu
                  IconButton(
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Kaydet',
                    onPressed: _toggleBookmark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
