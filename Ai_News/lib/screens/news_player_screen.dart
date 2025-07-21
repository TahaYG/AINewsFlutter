import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/haber.dart';
import '../services/tts_service.dart';

/// Haber oynatıcı ekranı - TTS ile haber okuma ve kelime takibi
class NewsPlayerScreen extends StatefulWidget {
  final List<Haber> haberler; // Oynatılacak haber listesi
  final int initialIndex; // Başlangıç haber indeksi
  const NewsPlayerScreen(
      {Key? key, required this.haberler, this.initialIndex = 0})
      : super(key: key);

  @override
  State<NewsPlayerScreen> createState() => _NewsPlayerScreenState();
}

class _NewsPlayerScreenState extends State<NewsPlayerScreen> {
  // Oynatma kontrolü için değişkenler
  late int _currentIndex; // Şu anki haber indeksi
  bool _isPlaying = false; // Oynatma durumu
  int _currentWordIndex = 0; // Şu anki kelime indeksi
  List<String> _words = []; // Haber metnindeki kelimeler
  List<int> _wordOffsets = []; // Kelimelerin metindeki pozisyonları
  
  // Servis referansları
  TtsService? _ttsService;
  
  // UI kontrolü
  final ScrollController _lyricsScrollController = ScrollController();
  final Map<int, GlobalKey> _wordKeys = {}; // Kelime widget'larının key'leri

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ttsService = Provider.of<TtsService>(context, listen: false);
        _ttsService?.setCompletionCallback(_onTtsCompleted);
        _prepareCurrent(); // Sadece metni hazırla, otomatik okuma başlatma
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TtsService referansını al ve listener'ları ekle
    _ttsService = Provider.of<TtsService>(context, listen: false);
    _ttsService!.addListener(_onTtsProgress);
  }

  @override
  void dispose() {
    // TTS service referansını güvenli şekilde al
    if (_ttsService != null) {
      _ttsService!.removeListener(_onTtsProgress);
      _ttsService!.clearCompletionCallback(); // Callback'i temizle
      // NewsPlayerScreen'dan çıkıldığında TTS'i durdur
      _ttsService!.stop();
    }
    _lyricsScrollController.dispose();
    super.dispose();
  }

  /// TTS progress değişikliklerini dinler ve kelime takibini günceller
  void _onTtsProgress() {
    if (_ttsService != null && _wordOffsets.isNotEmpty) {
      int idx = 0;
      for (int i = 0; i < _wordOffsets.length; i++) {
        if (_ttsService!.currentWordLocation >= _wordOffsets[i]) {
          idx = i;
        } else {
          break;
        }
      }
      setState(() {
        _currentWordIndex = idx;
        _isPlaying = _ttsService!.isPlaying &&
            !_ttsService!.isPaused; // TTS service'den al
      });
      // Aktif kelimeye scroll yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _wordKeys[_currentWordIndex];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 200),
            alignment: 0.3,
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// Mevcut haberin metnini hazırlar ve kelime listesini oluşturur
  void _prepareCurrent() {
    final haber = widget.haberler[_currentIndex];
    final text = "${haber.baslik}. ${haber.icerik ?? ''}";
    setState(() {
      _words = text.split(' ');
      _wordOffsets = _calculateWordOffsets(text);
      _currentWordIndex = 0;
      _isPlaying = false;
      _wordKeys.clear();
      for (int i = 0; i < _words.length; i++) {
        _wordKeys[i] = GlobalKey();
      }
    });
  }

  /// Mevcut haberi oynatmaya başlar
  Future<void> _playCurrent() async {
    // Pause durumundaysa önce temizle
    if (_ttsService?.isPaused == true) {
      await _ttsService?.stop();
    }

    final haber = widget.haberler[_currentIndex];
    setState(() {
      _isPlaying = true;
    });
    await _ttsService?.speakSingle(haber);
  }

  /// Oynatmayı duraklatır
  Future<void> _pause() async {
    await _ttsService?.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  /// Duraklatılan oynatmayı devam ettirir
  Future<void> _resume() async {
    await _ttsService?.resume();
    setState(() {
      _isPlaying = true;
    });
  }

  /// Sonraki habere geçer
  Future<void> _next() async {
    if (_currentIndex < widget.haberler.length - 1) {
      // Pause durumundaysa önce temizle
      if (_ttsService?.isPaused == true) {
        await _ttsService?.stop();
      }

      // Haber okunuyorsa durdur
      if (_isPlaying) {
        await _ttsService?.stop();
      }

      setState(() {
        _currentIndex++;
        _isPlaying = false; // Okuma durumunu sıfırla
      });
      _prepareCurrent();
    }
  }

  /// Önceki habere geçer
  Future<void> _prev() async {
    if (_currentIndex > 0) {
      // Pause durumundaysa önce temizle
      if (_ttsService?.isPaused == true) {
        await _ttsService?.stop();
      }

      // Haber okunuyorsa durdur
      if (_isPlaying) {
        await _ttsService?.stop();
      }

      setState(() {
        _currentIndex--;
        _isPlaying = false; // Okuma durumunu sıfırla
      });
      _prepareCurrent();
    }
  }

  /// Play/Pause butonuna basıldığında çağrılır
  Future<void> _onPlayPausePressed() async {
    if (_ttsService?.isPaused == true) {
      // Pause durumundaysa resume et
      await _resume();
    } else if (!_isPlaying) {
      // Okuma başlamamışsa başlat
      await _playCurrent();
    } else {
      // Okuma devam ediyorsa pause et
      await _pause();
    }
  }

  /// Kelimelerin metindeki pozisyonlarını hesaplar
  List<int> _calculateWordOffsets(String text) {
    List<int> offsets = [];
    int idx = 0;
    for (final word in text.split(' ')) {
      offsets.add(idx);
      idx += word.length + 1; // +1 boşluk için
    }
    return offsets;
  }

  /// TTS okuma tamamlandığında çağrılır
  void _onTtsCompleted() {
    // Haber tamamlandığında otomatik olarak sonraki habere geç
    if (_currentIndex < widget.haberler.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _prepareCurrent();
      // Otomatik olarak sonraki haberi başlat
      _playCurrent();
    } else {
      // Son haberse durdu
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'news.ai player',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Haber metni kartı - kelime takibi ile
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildClassicLyrics(),
            ),
          ),

          // İlerleme barı - okuma ilerlemesini gösterir
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: LinearProgressIndicator(
              value: _words.isNotEmpty ? _currentWordIndex / _words.length : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
            ),
          ),

          // Kontrol butonları - önceki, play/pause, sonraki
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildClassicControlButton(
                  icon: Icons.skip_previous_rounded,
                  onPressed: _prev,
                  size: 28,
                ),
                _buildClassicPlayPauseButton(),
                _buildClassicControlButton(
                  icon: Icons.skip_next_rounded,
                  onPressed: _next,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Klasik şarkı sözü görünümü - kelime vurgulama ile
  Widget _buildClassicLyrics() {
    if (_words.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      controller: _lyricsScrollController,
      child: Wrap(
        alignment: WrapAlignment.start,
        runSpacing: 8,
        spacing: 4,
        children: List.generate(_words.length, (i) {
          final isActive = i == _currentWordIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            key: _wordKeys[i],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.grey.shade100 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: Colors.grey.shade400) : null,
            ),
            child: Text(
              _words[i],
              style: TextStyle(
                fontSize: isActive ? 18 : 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.black87 : Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Klasik kontrol butonu (önceki/sonraki için)
  Widget _buildClassicControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 28,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            color: Colors.black87,
            size: size,
          ),
        ),
      ),
    );
  }

  /// Ana play/pause butonu - özel tasarım ile
  Widget _buildClassicPlayPauseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: _onPlayPausePressed,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                (_isPlaying && !(_ttsService?.isPaused ?? false))
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key:
                    ValueKey('${_isPlaying}_${_ttsService?.isPaused ?? false}'),
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
