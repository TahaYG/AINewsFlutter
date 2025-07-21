import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/haber.dart';
import 'dart:io';

/// Text-to-Speech servisi - haber okuma ve kelime takibi
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  bool _isPaused = false;
  int? _playbackId; // null: durdu, -1: liste, >0: tek haber ID'si

  // YENİ: Çalma listesi ve mevcut sıra
  List<Haber> _playlist = [];
  int _currentIndex = 0;
  int _currentWordLocation = 0;
  int _lastWordLocation = 0;
  int _pausedWordLocation = 0; // Pause edildiğinde kelime pozisyonunu sakla
  int _resumeOffset = 0; // Resume edildiğinde offset
  int get currentWordLocation => _currentWordLocation;
  
  // Completion callback
  Function()? _onCompletionCallback;

  // Getter'lar - UI'dan erişim için
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  int? get playbackId => _playbackId;

  /// TTS servisini başlatır ve callback'leri ayarlar
  TtsService() {
    // DEĞİŞİKLİK: setCompletionHandler artık bir sonraki parçayı çalıyor.
    _flutterTts.setCompletionHandler(() {
      if (_playbackId == -1 && _currentIndex < _playlist.length - 1) {
        // Eğer liste çalıyorsa ve son parça değilse, bir sonrakine geç.
        _currentIndex++;
        _playCurrentItemInPlaylist();
      } else if (_onCompletionCallback != null) {
        // Completion callback varsa çağır (news_player_screen için)
        _onCompletionCallback!();
      } else {
        // Liste bittiyse veya tekli okuma bittiyse, tamamen durdur.
        _stopPlayback(clearPause: true);
      }
    });
    _flutterTts.setCancelHandler(() {
      if (!_isPaused) {
        _stopPlayback(clearPause: true);
      }
    });
    _flutterTts.setErrorHandler((msg) => _stopPlayback(clearPause: true));
    // PROGRESS HANDLER - kelime takibi için
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      // start: okunan kelimenin metindeki başlangıç indexi
      // end: okunan kelimenin metindeki bitiş indexi
      // word: okunan kelime
      
      // Resume durumunda offset ekle
      int actualPosition = _resumeOffset + start;
      
      _currentWordLocation = actualPosition;
      _lastWordLocation = actualPosition;
      notifyListeners();
    });
  }

  /// Oynatma state'ini sıfırlar
  void _stopPlayback({bool clearPause = true}) {
    _isPlaying = false;
    _playbackId = null;
    _playlist.clear();
    _currentIndex = 0;
    _currentWordLocation = 0;
    _resumeOffset = 0;
    if (clearPause) {
      _pausedWordLocation = 0;
      _isPaused = false;
    }
    notifyListeners();
  }

  /// TTS ayarlarını yapılandırır
  Future<void> _configureTts() async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  // YENİ: Sadece sıradaki parçayı çalan özel metot
  Future<void> _playCurrentItemInPlaylist() async {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length) {
      final haber = _playlist[_currentIndex];
      String okunacakMetin = "${haber.baslik}. ${haber.icerik ?? ''}";
      if (okunacakMetin.trim().isNotEmpty) {
        await _flutterTts.speak(okunacakMetin);
      }
    }
  }

  /// Tek bir haberi okumaya başlar
  // Tek bir haberi okumak için metot
  Future<void> speakSingle(Haber haber) async {
    await stop();
    await _configureTts();

    _playlist = [haber]; // Çalma listesine sadece bu haberi koy
    _currentIndex = 0;
    _playbackId = haber.id;
    _isPlaying = true;
    _resumeOffset = 0; // Yeni başlangıçta offset sıfırla
    notifyListeners();

    _playCurrentItemInPlaylist();
  }

  /// Haber listesini okumaya başlar
  // Bir haber listesini okumak için metot
  Future<void> speakList(List<Haber> haberler) async {
    if (haberler.isNotEmpty) {
      await stop();
      await _configureTts();

      _playlist = List<Haber>.from(haberler);
      _currentIndex = 0;
      _playbackId = -1; // Liste çaldığını belirtir
      _isPlaying = true;
      _resumeOffset = 0; // Yeni başlangıçta offset sıfırla
      notifyListeners();

      _playCurrentItemInPlaylist(); // Sadece ilk haberi başlat, gerisi otomatik gelecek.
    }
  }

  /// Oynatmayı duraklatır - kelime pozisyonu korunur
  Future<void> pause() async {
    // Pause edildiğinde mevcut pozisyonu sakla
    _pausedWordLocation = _lastWordLocation;
    
    if (Platform.isIOS || Platform.isMacOS) {
      await _flutterTts.pause();
    } else {
      // Android'de pause desteklenmiyor, stop ile durdur ama playlist'i temizleme
      await _flutterTts.stop();
    }
    
    _isPaused = true;
    _isPlaying = false;
    notifyListeners();
  }

  /// Duraklatılmış oynatmayı devam ettirir - kaldığı yerden
  Future<void> resume() async {
    // Her platformda kaldığı yerden devam et: _pausedWordLocation'dan itibaren metni tekrar okut
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length) {
      final haber = _playlist[_currentIndex];
      String okunacakMetin = "${haber.baslik}. ${haber.icerik ?? ''}";
      
      // Güvenli substring işlemi - pause edildiğinde kaydedilen pozisyonu kullan
      String devamMetni = okunacakMetin;
      if (_pausedWordLocation > 0 && _pausedWordLocation < okunacakMetin.length) {
        devamMetni = okunacakMetin.substring(_pausedWordLocation);
        _resumeOffset = _pausedWordLocation; // Resume offset'ini ayarla
      } else {
        _resumeOffset = 0;
      }
      
      await _configureTts();
      _isPaused = false;
      _isPlaying = true;
      _currentWordLocation = _pausedWordLocation; // Progress tracking için
      notifyListeners();
      
      await _flutterTts.speak(devamMetni);
    }
  }

  /// Oynatmayı tamamen durdurur
  Future<void> stop() async {
    await _flutterTts.stop();
    _stopPlayback(clearPause: true);
  }

  // Completion callback'i ayarla
  void setCompletionCallback(Function()? callback) {
    _onCompletionCallback = callback;
  }

  // Completion callback'i temizle
  void clearCompletionCallback() {
    _onCompletionCallback = null;
  }

  /// Servis kapatılırken temizlik işlemleri
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
