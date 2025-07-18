import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/haber.dart';
import '../services/tts_service.dart';

class NewsPlayerScreen extends StatefulWidget {
  final List<Haber> haberler;
  final int initialIndex;
  const NewsPlayerScreen(
      {Key? key, required this.haberler, this.initialIndex = 0})
      : super(key: key);

  @override
  State<NewsPlayerScreen> createState() => _NewsPlayerScreenState();
}

class _NewsPlayerScreenState extends State<NewsPlayerScreen> {
  late int _currentIndex;
  bool _isPlaying = false;
  String _currentText = '';
  int _currentWordIndex = 0;
  List<String> _words = [];
  List<int> _wordOffsets = [];
  TtsService? _ttsService;
  final ScrollController _lyricsScrollController = ScrollController();
  final Map<int, GlobalKey> _wordKeys = {};
  bool _autoNextInProgress = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ttsService = Provider.of<TtsService>(context, listen: false);
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
    _ttsService!.addListener(_onTtsCompleteForNext);
  }

  @override
  void dispose() {
    // TTS service referansını güvenli şekilde al
    if (_ttsService != null) {
      _ttsService!.removeListener(_onTtsProgress);
      _ttsService!.removeListener(_onTtsCompleteForNext);
      // NewsPlayerScreen'dan çıkıldığında TTS'i durdur
      _ttsService!.stop();
    }
    _lyricsScrollController.dispose();
    super.dispose();
  }

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
        _isPlaying = _ttsService!.isPlaying; // TTS service'den al
      });
      // Scroll to active word
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

  void _onTtsCompleteForNext() {
    // Sadece otomatik okuma tamamlandığında ve autoNextInProgress true ise sonraki habere geç
    if (_autoNextInProgress && _currentIndex < widget.haberler.length - 1) {
      setState(() {
        _autoNextInProgress = false;
        _currentIndex++;
      });
      _prepareCurrent();
      _playCurrent(autoNext: true); // Yeni haberi otomatik başlat
    } else {
      setState(() {
        _autoNextInProgress = false;
      });
    }
  }

  void _prepareCurrent() {
    final haber = widget.haberler[_currentIndex];
    final text = "${haber.baslik}. ${haber.icerik ?? ''}";
    setState(() {
      _currentText = text;
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

  void _playCurrent({bool autoNext = false}) async {
    final haber = widget.haberler[_currentIndex];
    setState(() {
      _isPlaying = true;
      _autoNextInProgress = autoNext;
    });
    await _ttsService?.speakSingle(haber);
  }

  void _pause() async {
    await _ttsService?.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resume() {
    // Sadece mevcut haberi baştan oku, _next() tetiklenmesin
    _playCurrent();
  }

  void _next() {
    if (_currentIndex < widget.haberler.length - 1) {
      setState(() {
        _currentIndex++;
        _autoNextInProgress = false;
      });
      _prepareCurrent();
      if (_isPlaying) {
        _playCurrent(autoNext: false); // elle ileri/geri de autoNext: false
      }
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _autoNextInProgress = false;
      });
      _prepareCurrent();
      if (_isPlaying) {
        _playCurrent(autoNext: false); // elle ileri/geri de autoNext: false
      }
    }
  }

  void _onPlayPausePressed() async {
    if (!_isPlaying) {
      // Okuma başlamamışsa başlat
      _playCurrent(autoNext: false); // elle başlatmada autoNext: false
    } else {
      // Okuma devam ediyorsa durdur
      await _ttsService?.stop();
      setState(() {
        _isPlaying = false;
        _autoNextInProgress = false;
      });
    }
  }

  List<int> _calculateWordOffsets(String text) {
    List<int> offsets = [];
    int idx = 0;
    for (final word in text.split(' ')) {
      offsets.add(idx);
      idx += word.length + 1; // +1 boşluk için
    }
    return offsets;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Haber Player',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
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
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Haber Metni Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: _buildModernLyrics(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Progress Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LinearProgressIndicator(
                  value:
                      _words.isNotEmpty ? _currentWordIndex / _words.length : 0,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              const SizedBox(height: 40),

              // Control Buttons
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.skip_previous_rounded,
                      onPressed: _prev,
                      size: 32,
                    ),
                    _buildPlayPauseButton(),
                    _buildControlButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: _next,
                      size: 32,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLyrics() {
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.white.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: Colors.white.withOpacity(0.5))
                  : null,
            ),
            child: Text(
              _words[i],
              style: TextStyle(
                fontSize: isActive ? 20 : 18,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                height: 1.5,
                shadows: isActive
                    ? [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 28,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              color: Colors.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(_isPlaying),
                color: Color(0xFF667eea),
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
