import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool isPlaying = false;

  TtsService() {
    // Okuma tamamlandığında veya iptal edildiğinde durumu güncelle
    _flutterTts.setCompletionHandler(() {
      isPlaying = false;
    });
    _flutterTts.setCancelHandler(() {
      isPlaying = false;
    });
    _flutterTts.setErrorHandler((_) {
      isPlaying = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.setLanguage("tr-TR"); // Dili Türkçe olarak ayarla
      await _flutterTts.setPitch(1.0); // Ses perdesi
      await _flutterTts.setSpeechRate(0.5); // Okuma hızı
      await _flutterTts.speak(text);
      isPlaying = true;
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    isPlaying = false;
  }
}
