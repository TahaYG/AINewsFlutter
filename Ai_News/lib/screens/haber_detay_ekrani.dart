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

  // Eksik değişkenler
  bool _isBookmarked = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // DEĞİŞİKLİK: Servis referansını initState içinde, context olmadan alıyoruz.
    // Bu, dispose metodunda güvenli bir şekilde kullanılmasını sağlar.
    _ttsService = Provider.of<TtsService>(context, listen: false);

    // İyimser Arayüz: Detay ekranı açılır açılmaz tıklanma sayısını 1 artır.
    _guncelTiklanmaSayisi = widget.haber.tiklanmaSayisi + 1;
    _guncelOkunmaSayisi = widget.haber.okunmaSayisi;

    // Bookmark durumunu kontrol et
    _checkIfBookmarked();

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

  // Bookmark durumunu kontrol et
  Future<void> _checkIfBookmarked() async {
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

  // Bookmark toggle fonksiyonu
  Future<void> _toggleBookmark() async {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      if (_isBookmarked) {
        await _apiService.yerIsaretiEkle(widget.haber.id);
      } else {
        await _apiService.yerIsaretiSil(widget.haber.id);
      }
    } catch (e) {
      print("Bookmark toggle hatası: $e");
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }
    }
  }

  // TTS toggle fonksiyonu
  void _toggleTts() {
    if (_isPlaying) {
      _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _ttsService.stop().then((_) {
        if (mounted) {
          _ttsService.speakSingle(widget.haber);
          setState(() {
            _isPlaying = true;
          });
        }
      });
    }
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
    return Consumer<TtsService>(
      builder: (context, ttsService, child) {
        // TTS durumunu güncelle
        final bool isThisPlaying =
            ttsService.isPlaying && ttsService.playbackId == widget.haber.id;
        if (_isPlaying != isThisPlaying) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isPlaying = isThisPlaying;
              });
            }
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and stats
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Text(
                                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                                      .format(widget.haber.yayinTarihi),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              _buildStatChip(Icons.visibility_outlined,
                                  _guncelTiklanmaSayisi.toString()),
                              const SizedBox(width: 8),
                              _buildStatChip(Icons.headphones_outlined,
                                  _guncelOkunmaSayisi.toString()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Title
                          Text(
                            widget.haber.baslik,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Content
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.haber.icerik ?? 'İçerik mevcut değil.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _toggleBookmark,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Icon(
                                          _isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          key: ValueKey(_isBookmarked),
                                          color: _isBookmarked
                                              ? Colors.amber
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isBookmarked ? 'Kaydedildi' : 'Kaydet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isPlaying
                                  ? Colors.red.withOpacity(0.8)
                                  : Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _toggleTts,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isPlaying
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isPlaying ? 'Durdur' : 'Sesli Oku',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
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
