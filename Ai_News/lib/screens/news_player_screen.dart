import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/haber.dart';
import '../services/tts_service.dart';

class NewsPlayerScreen extends StatefulWidget {
  final List<Haber> haberler;
  final int initialIndex;
  const NewsPlayerScreen({Key? key, required this.haberler, this.initialIndex = 0}) : super(key: key);

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
      _ttsService = Provider.of<TtsService>(context, listen: false);
      _prepareCurrent(); // Sadece metni hazırla, otomatik okuma başlatma
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TtsService değişikliklerini dinle
    Provider.of<TtsService>(context).addListener(_onTtsProgress);
    // Tamamlandığında otomatik geçiş için listener ekle
    Provider.of<TtsService>(context).addListener(_onTtsCompleteForNext);
  }

  void _onTtsCompleteForNext() {
    // Sadece otomatik okuma tamamlandığında ve autoNextInProgress true ise sonraki habere geç
    if (_isPlaying == false && _ttsService?.isPlaying == false && _autoNextInProgress && _currentIndex < widget.haberler.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playCurrent(autoNext: true);
    } else {
      setState(() {
        _autoNextInProgress = false;
      });
    }
  }

  @override
  void dispose() {
    Provider.of<TtsService>(context, listen: false).removeListener(_onTtsProgress);
    Provider.of<TtsService>(context, listen: false).removeListener(_onTtsCompleteForNext);
    _ttsService?.stop();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _onTtsProgress() {
    final tts = Provider.of<TtsService>(context, listen: false);
    if (_wordOffsets.isNotEmpty) {
      int idx = 0;
      for (int i = 0; i < _wordOffsets.length; i++) {
        if (tts.currentWordLocation >= _wordOffsets[i]) {
          idx = i;
        } else {
          break;
        }
      }
      setState(() {
        _currentWordIndex = idx;
        _isPlaying = tts.isPlaying;
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
    setState(() {
      _isPlaying = true;
      _autoNextInProgress = autoNext;
    });
    final haber = widget.haberler[_currentIndex];
    await _ttsService?.speakSingle(haber);
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
      });
      _prepareCurrent();
      if (_isPlaying) {
        _playCurrent(autoNext: false);
      }
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _prepareCurrent();
      if (_isPlaying) {
        _playCurrent(autoNext: false);
      }
    }
  }

  void _onPlayPausePressed() async {
    if (!_isPlaying) {
      // Okuma başlamamışsa başlat
      _playCurrent(autoNext: false);
    } else {
      // Okuma devam ediyorsa durdur
      await _ttsService?.stop();
      setState(() {
        _isPlaying = false;
        _autoNextInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Haber Player')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: media.size.height * 0.35,
                      minHeight: 80,
                      minWidth: double.infinity,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _buildLyrics(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom: media.viewInsets.bottom + 12,
                top: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous, size: 28),
                      onPressed: _prev,
                      tooltip: 'Önceki Haber',
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          size: 28,
                        ),
                        label: FittedBox(
                          child: Text(
                            _isPlaying ? 'Durdur' : 'Başlat',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: _onPlayPausePressed,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      onPressed: _next,
                      tooltip: 'Sonraki Haber',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyrics() {
    if (_words.isEmpty) return const SizedBox();
    return SingleChildScrollView(
      controller: _lyricsScrollController,
      child: Wrap(
        children: List.generate(_words.length, (i) {
          final isActive = i == _currentWordIndex;
          return Container(
            key: _wordKeys[i],
            child: Text(
              _words[i] + ' ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue : Colors.black,
                backgroundColor: isActive ? Colors.yellow[200] : null,
              ),
            ),
          );
        }),
      ),
    );
  }
} 