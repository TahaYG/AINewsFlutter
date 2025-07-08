import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/haber.dart';
import '../screens/haber_detay_ekrani.dart';
import '../services/api_service.dart';

class HaberKarti extends StatelessWidget {
  final Haber haber;
  final VoidCallback onGeriDonuldu;
  final ApiService _apiService = ApiService();

  // DEĞİŞİKLİK: 'kategoriAdi' parametresi artık gerekli değil ve kaldırıldı.
  HaberKarti({
    super.key,
    required this.haber,
    required this.onGeriDonuldu,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () async {
          _apiService.haberTiklandi(haber.id);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HaberDetayEkrani(haber: haber),
            ),
          );
          onGeriDonuldu();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DEĞİŞİKLİK: Kategori Chip widget'ı ve altındaki SizedBox kaldırıldı.

              // Başlık
              Text(
                haber.baslik,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // İçerik
              Text(
                haber.icerik ?? 'İçerik mevcut değil.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Tarih
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
                      .format(haber.yayinTarihi),
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
