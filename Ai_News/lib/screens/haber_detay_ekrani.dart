import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../models/yorum.dart';

/// Haber detay ekranı - haberin tam içeriğini gösterir ve TTS ile okuma sağlar
class HaberDetayEkrani extends StatefulWidget {
  final Haber haber; // Gösterilecek haber

  const HaberDetayEkrani({super.key, required this.haber});

  @override
  State<HaberDetayEkrani> createState() => _HaberDetayEkraniState();
}

class _HaberDetayEkraniState extends State<HaberDetayEkrani> {
  // Timer ile okunma sayacı kontrolü
  Timer? _okunmaSayacTimer;
  // API servis instance'ı
  final ApiService _apiService = ApiService();

  // YENİ: TtsService referansını tutacak bir değişken.
  late TtsService _ttsService;

  // İyimser UI için güncel sayaçlar
  late int _guncelTiklanmaSayisi;
  late int _guncelOkunmaSayisi;

  // UI durum değişkenleri
  bool _isBookmarked = false; // Yer işareti durumu
  bool _isPlaying = false; // TTS oynatma durumu

  // Yorumlar
  List<YorumDto> _yorumlar = [];
  bool _yorumlarYukleniyor = false;
  final TextEditingController _yorumController = TextEditingController();
  bool _yorumEkleniyor = false;
  String? _yorumHata;

  // Yanıt ekleme için kontrol
  Map<int, TextEditingController> _yanitControllerlar = {};
  Map<int, bool> _yanitEkleniyor = {};
  Map<int, String?> _yanitHata = {};
  Map<int, bool> _yorumLikeLoading = {};
  Map<int, bool> _yanitLikeLoading = {};

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
    _yorumlariGetir();
  }

  Future<void> _yorumlariGetir() async {
    setState(() {
      _yorumlarYukleniyor = true;
    });
    try {
      final yorumlar = await _apiService.getYorumlar(widget.haber.id);
      setState(() {
        _yorumlar = yorumlar;
        _yorumlarYukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _yorumlarYukleniyor = false;
      });
    }
  }

  Future<void> _yorumEkle() async {
    final icerik = _yorumController.text.trim();
    if (icerik.isEmpty) return;
    setState(() {
      _yorumEkleniyor = true;
      _yorumHata = null;
    });
    try {
      final yeniYorum =
          await _apiService.yorumEkle(haberId: widget.haber.id, icerik: icerik);
      setState(() {
        _yorumlar.insert(0, yeniYorum);
        _yorumController.clear();
        _yorumEkleniyor = false;
      });
    } catch (e) {
      setState(() {
        _yorumEkleniyor = false;
        _yorumHata = 'Comment cannot be added.';
      });
    }
  }

  Future<void> _yanitEkle(int yorumId) async {
    final controller = _yanitControllerlar[yorumId] ?? TextEditingController();
    final icerik = controller.text.trim();
    if (icerik.isEmpty) return;
    setState(() {
      _yanitEkleniyor[yorumId] = true;
      _yanitHata[yorumId] = null;
    });
    try {
      final yeniYanit =
          await _apiService.yorumYanitiEkle(yorumId: yorumId, icerik: icerik);
      setState(() {
        final yorumIndex = _yorumlar.indexWhere((y) => y.id == yorumId);
        if (yorumIndex != -1) {
          _yorumlar[yorumIndex].yanitlar.add(yeniYanit);
          _yorumlar[yorumIndex] = YorumDto(
            id: _yorumlar[yorumIndex].id,
            icerik: _yorumlar[yorumIndex].icerik,
            olusturmaTarihi: _yorumlar[yorumIndex].olusturmaTarihi,
            onaylandi: _yorumlar[yorumIndex].onaylandi,
            haberId: _yorumlar[yorumIndex].haberId,
            kullaniciId: _yorumlar[yorumIndex].kullaniciId,
            kullaniciAdi: _yorumlar[yorumIndex].kullaniciAdi,
            likeSayisi: _yorumlar[yorumIndex].likeSayisi,
            dislikeSayisi: _yorumlar[yorumIndex].dislikeSayisi,
            yanitSayisi: _yorumlar[yorumIndex].yanitSayisi + 1,
            kullaniciLikeDurumu: _yorumlar[yorumIndex].kullaniciLikeDurumu,
            yanitlar: List.from(_yorumlar[yorumIndex].yanitlar),
          );
        }
        controller.clear();
        _yanitEkleniyor[yorumId] = false;
      });
    } catch (e) {
      setState(() {
        _yanitEkleniyor[yorumId] = false;
        _yanitHata[yorumId] = 'Reply cannot be added.';
      });
    }
  }

  Future<void> _yorumLike(int yorumId, bool isLike) async {
    setState(() {
      _yorumLikeLoading[yorumId] = true;
    });
    try {
      await _apiService.yorumLike(yorumId: yorumId, isLike: isLike);
      await _yorumlariGetir();
    } catch (e) {}
    setState(() {
      _yorumLikeLoading[yorumId] = false;
    });
  }

  Future<void> _yanitLike(int yanitId, bool isLike) async {
    setState(() {
      _yanitLikeLoading[yanitId] = true;
    });
    try {
      await _apiService.yorumYanitiLike(yanitId: yanitId, isLike: isLike);
      await _yorumlariGetir();
    } catch (e) {}
    setState(() {
      _yanitLikeLoading[yanitId] = false;
    });
  }

  // Bookmark durumunu kontrol et
  /// Haberin yer işaretli olup olmadığını API'den kontrol eder
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
  /// Yer işareti durumunu değiştirir (ekle/kaldır)
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
      print("Bookmark toggle error: $e");
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }
    }
  }

  // TTS toggle fonksiyonu
  /// TTS oynatma/durdurma işlemini kontrol eder
  void _togglePlayPause() {
    if (_isPlaying) {
      // Oynatılıyorsa durdur
      _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Duruyorsa başlat
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
    // Timer'ı iptal et
    _okunmaSayacTimer?.cancel();
    // DEĞİŞİKLİK: Artık güvenli olan lokal referansı kullanıyoruz.
    _ttsService.stop();
    _yorumController.dispose();
    _yanitControllerlar.values.forEach((c) => c.dispose());
    super.dispose();
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  Widget buildCommentItem(YorumDto yorum,
      {void Function()? onLike, bool likeLoading = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              yorum.kullaniciAdi.isNotEmpty
                  ? yorum.kullaniciAdi[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
          ),
          const SizedBox(width: 16),
          // Yorum içeriği
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı adı ve zaman
                Row(
                  children: [
                    Text(
                      yorum.kullaniciAdi,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      timeAgo(yorum.olusturmaTarihi),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Yorum metni
                Text(
                  yorum.icerik,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                const SizedBox(height: 10),
                // Kalp ve like sayısı
                Row(
                  children: [
                    GestureDetector(
                      onTap: likeLoading ? null : onLike,
                      child: Icon(
                        yorum.kullaniciLikeDurumu == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      yorum.likeSayisi.toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCommentInput({
    required TextEditingController controller,
    required VoidCallback onSend,
    bool sending = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Write your comment...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          sending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }

  Widget buildReplyInput({
    required TextEditingController controller,
    required VoidCallback onSend,
    bool sending = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Reply...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ),
          sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.reply, color: Colors.black, size: 20),
                  onPressed: onSend,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
        ],
      ),
    );
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
              // Özel AppBar tasarımı
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
                        const Expanded(
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
                        // Yer işareti butonu
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

              // Kaydırılabilir içerik bölümü
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Haber başlığı
                      Text(
                        widget.haber.baslik,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Haber bilgileri (tarih ve istatistikler)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            // Yayın tarihi
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
                            // İstatistikler (görüntülenme ve okunma sayısı)
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
                                Icon(Icons.menu_book_outlined,
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

                      // Haber içerik metni
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
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // --- YORUMLAR ---
                      const Text(
                        'Comments',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (_yorumlarYukleniyor)
                        const Center(child: CircularProgressIndicator()),
                      if (!_yorumlarYukleniyor && _yorumlar.isEmpty)
                        const Text('No commnets yet.'),
                      if (!_yorumlarYukleniyor && _yorumlar.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _yorumlar.length,
                          itemBuilder: (context, index) {
                            final yorum = _yorumlar[index];
                            _yanitControllerlar.putIfAbsent(
                                yorum.id, () => TextEditingController());
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildCommentItem(
                                  yorum,
                                  onLike: _yorumLikeLoading[yorum.id] == true
                                      ? null
                                      : () => _yorumLike(yorum.id, true),
                                  likeLoading:
                                      _yorumLikeLoading[yorum.id] == true,
                                ),
                                // Yanıtlar
                                if (yorum.yanitlar.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 56.0, top: 4, bottom: 4),
                                    child: Column(
                                      children: yorum.yanitlar.map((yanit) {
                                        return buildCommentItem(
                                          YorumDto(
                                            id: yanit.id,
                                            icerik: yanit.icerik,
                                            olusturmaTarihi:
                                                yanit.olusturmaTarihi,
                                            onaylandi: yanit.onaylandi,
                                            haberId: yorum.haberId,
                                            kullaniciId: yanit.kullaniciId,
                                            kullaniciAdi: yanit.kullaniciAdi,
                                            likeSayisi: yanit.likeSayisi,
                                            dislikeSayisi: yanit.dislikeSayisi,
                                            yanitSayisi: 0,
                                            kullaniciLikeDurumu:
                                                yanit.kullaniciLikeDurumu,
                                            yanitlar: [],
                                          ),
                                          onLike: _yanitLikeLoading[yanit.id] ==
                                                  true
                                              ? null
                                              : () =>
                                                  _yanitLike(yanit.id, true),
                                          likeLoading:
                                              _yanitLikeLoading[yanit.id] ==
                                                  true,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                // Yanıt yazma kutusu
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 56.0, top: 4, bottom: 8),
                                  child: buildReplyInput(
                                    controller: _yanitControllerlar[yorum.id]!,
                                    onSend: _yanitEkleniyor[yorum.id] == true
                                        ? () {}
                                        : () => _yanitEkle(yorum.id),
                                    sending: _yanitEkleniyor[yorum.id] == true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      // --- YORUM EKLEME ALANI ---
                      buildCommentInput(
                        controller: _yorumController,
                        onSend: _yorumEkleniyor ? () {} : _yorumEkle,
                        sending: _yorumEkleniyor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sabit oynatma butonu - ekranın altında
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
                              style: const TextStyle(
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

  /// İstatistik chip'i oluşturucu widget
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
