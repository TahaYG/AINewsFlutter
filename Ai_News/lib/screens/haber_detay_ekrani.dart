import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class HaberDetayEkrani extends StatefulWidget {
  final Haber haber;

  const HaberDetayEkrani({super.key, required this.haber});

  @override
  State<HaberDetayEkrani> createState() => _HaberDetayEkraniState();
}

class _HaberDetayEkraniState extends State<HaberDetayEkrani> {
  Timer? _okunmaSayacTimer;
  final ApiService _apiService = ApiService();

  // YENİ: TtsService referansını tutacak bir değişken.
  late TtsService _ttsService;

  late int _guncelTiklanmaSayisi;
  late int _guncelOkunmaSayisi;

  @override
  void initState() {
    super.initState();

    // DEĞİŞİKLİK: Servis referansını initState içinde, context olmadan alıyoruz.
    // Bu, dispose metodunda güvenli bir şekilde kullanılmasını sağlar.
    _ttsService = Provider.of<TtsService>(context, listen: false);

    // İyimser Arayüz: Detay ekranı açılır açılmaz tıklanma sayısını 1 artır.
    _guncelTiklanmaSayisi = widget.haber.tiklanmaSayisi + 1;
    _guncelOkunmaSayisi = widget.haber.okunmaSayisi;

    // Okunma sayacını 4 saniye sonra tetiklemek için zamanlayıcıyı başlat.
    _okunmaSayacTimer = Timer(const Duration(seconds: 4), () async {
      print(
          '${widget.haber.id} ID\'li haber için okunma isteği gönderiliyor...');

      bool basarili = await _apiService.haberOkundu(widget.haber.id);

      if (basarili && mounted) {
        print('Okundu sayacı başarıyla güncellendi. Arayüz yenileniyor.');
        setState(() {
          _guncelOkunmaSayisi++;
        });
      } else if (mounted) {
        print('Okundu sayacı güncellenemedi.');
      }
    });
  }

  @override
  void dispose() {
    _okunmaSayacTimer?.cancel();
    // DEĞİŞİKLİK: Artık güvenli olan lokal referansı kullanıyoruz.
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // DEĞİŞİKLİK: Provider'ı dinleyen bir Consumer widget'ı kullanıyoruz.
    // Bu, sadece butonun ve ilgili yerlerin yeniden çizilmesini sağlar.
    return Consumer<TtsService>(
      builder: (context, ttsService, child) {
        final bool isThisPlaying =
            ttsService.isPlaying && ttsService.playbackId == widget.haber.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.haber.baslik,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  widget.haber.baslik,
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // İstatistik Bölümü
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isThisPlaying
                            ? Icons.pause_circle_filled_outlined
                            : Icons.play_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      tooltip: isThisPlaying ? 'Durdur' : 'Sesli Oku',
                      onPressed: () {
                        if (isThisPlaying) {
                          ttsService.stop();
                        } else {
                          ttsService.stop().then((_) {
                            if (mounted) {
                              ttsService.speakSingle(widget.haber);
                            }
                          });
                        }
                      },
                    ),
                    // Tarih Bilgisi
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMMM yyyy, HH:mm', 'tr_TR')
                          .format(widget.haber.yayinTarihi),
                      style:
                          GoogleFonts.lato(fontSize: 13, color: Colors.black54),
                    ),
                    const Spacer(), // Arada boşluk bırakır
                    // Tıklanma Sayısı
                    _buildStatChip(
                      context: context,
                      icon: Icons.remove_red_eye_outlined,
                      label: _guncelTiklanmaSayisi.toString(),
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 12),
                    // Okunma Sayısı
                    _buildStatChip(
                      context: context,
                      icon: Icons.menu_book_outlined,
                      label: _guncelOkunmaSayisi.toString(),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),

                Divider(height: 40, color: Colors.grey[300]),

                // İçerik
                Text(
                  widget.haber.icerik ?? 'İçerik yüklenemedi.',
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    height: 1.6,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // İstatistikleri göstermek için yardımcı bir widget metodu
  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
