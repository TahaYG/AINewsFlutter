import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/haber.dart';

class HaberDetayEkrani extends StatelessWidget {
  final Haber haber;

  const HaberDetayEkrani({super.key, required this.haber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(haber.baslik, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              haber.baslik,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.w900, // Daha kalın başlık
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(haber.yayinTarihi),
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            Divider(
              height: 40,
              color: Colors.grey[300],
            ),
            Text(
              haber.icerik ?? 'İçerik yüklenemedi.',
              style: GoogleFonts.lato(
                fontSize: 17,
                height: 1.6, // Satır aralığı
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}