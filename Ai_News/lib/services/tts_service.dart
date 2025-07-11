import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/haber.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  int? _playbackId; // null: durdu, -1: liste, >0: tek haber ID'si

  // YENİ: Çalma listesi ve mevcut sıra
  List<Haber> _playlist = [];
  int _currentIndex = 0;

  bool get isPlaying => _isPlaying;
  int? get playbackId => _playbackId;

  TtsService() {
    // DEĞİŞİKLİK: setCompletionHandler artık bir sonraki parçayı çalıyor.
    _flutterTts.setCompletionHandler(() {
      if (_playbackId == -1 && _currentIndex < _playlist.length - 1) {
        // Eğer liste çalıyorsa ve son parça değilse, bir sonrakine geç.
        _currentIndex++;
        _playCurrentItemInPlaylist();
      } else {
        // Liste bittiyse veya tekli okuma bittiyse, tamamen durdur.
        _stopPlayback(log: "Okuma tamamlandı.");
      }
    });
    _flutterTts
        .setCancelHandler(() => _stopPlayback(log: "Okuma iptal edildi."));
    _flutterTts
        .setErrorHandler((msg) => _stopPlayback(log: "TTS Hatası: $msg"));
  }

  void _stopPlayback({String? log}) {
    if (log != null) print("--- TTS Durumu: $log ---");
    _isPlaying = false;
    _playbackId = null;
    _playlist.clear();
    _currentIndex = 0;
    notifyListeners();
  }

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

  // Tek bir haberi okumak için metot
  Future<void> speakSingle(Haber haber) async {
    await stop();
    await _configureTts();

    _playlist = [haber]; // Çalma listesine sadece bu haberi koy
    _currentIndex = 0;
    _playbackId = haber.id;
    _isPlaying = true;
    notifyListeners();

    _playCurrentItemInPlaylist();
  }

  // Bir haber listesini okumak için metot
  Future<void> speakList(List<Haber> haberler) async {
    if (haberler.isNotEmpty) {
      await stop();
      await _configureTts();

      _playlist = List<Haber>.from(haberler);
      _currentIndex = 0;
      _playbackId = -1; // Liste çaldığını belirtir
      _isPlaying = true;
      notifyListeners();

      _playCurrentItemInPlaylist(); // Sadece ilk haberi başlat, gerisi otomatik gelecek.
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _stopPlayback(log: "Manuel olarak durduruldu.");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
