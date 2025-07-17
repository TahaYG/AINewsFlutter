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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await _apiService.haberTiklandi(widget.haber.id);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HaberDetayEkrani(haber: widget.haber),
                ),
              ).then((_) => widget.onGeriDonuldu());
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and bookmark
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy', 'tr_TR').format(widget.haber.yayinTarihi),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _toggleBookmark,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                key: ValueKey(_isBookmarked),
                                color: _isBookmarked ? Colors.amber : Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  widget.haber.baslik,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Content preview
                if (widget.haber.icerik != null && widget.haber.icerik!.isNotEmpty)
                  Text(
                    widget.haber.icerik!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 16),
                
                // Footer with stats
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.visibility_outlined,
                      value: widget.haber.tiklanmaSayisi.toString(),
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.headphones_outlined,
                      value: widget.haber.okunmaSayisi.toString(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Devamını Oku',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
