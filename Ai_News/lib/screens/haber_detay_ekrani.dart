import 'dart:async';
import 'package:flutter/material.dart';
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
  void _togglePlayPause() {
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
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // AppBar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'News Detail',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          onPressed: _toggleBookmark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Haber Başlığı
                      Text(
                        widget.haber.baslik,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Haber Bilgileri
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.access_time,
                                      color: Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd.MM.yyyy HH:mm', 'en_US')
                                        .format(widget.haber.yayinTarihi),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.visibility,
                                    color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _guncelTiklanmaSayisi.toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.headphones,
                                    color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _guncelOkunmaSayisi.toString(),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Haber İçeriği
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.haber.icerik ?? 'Content not found.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Fixed Play Button at Bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isPlaying ? Colors.grey.shade800 : Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isPlaying ? 'Stop Playing' : 'Listen to News',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
