import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/haber.dart';
import '../widgets/haber_karti.dart';

/// Kaydedilen haberler ekranı - kullanıcının yer işaretlediği haberleri listeler
class KaydedilenlerEkrani extends StatefulWidget {
  const KaydedilenlerEkrani({super.key});

  @override
  State<KaydedilenlerEkrani> createState() => _KaydedilenlerEkraniState();
}

class _KaydedilenlerEkraniState extends State<KaydedilenlerEkrani> {
  // API servis instance'ı
  final ApiService _apiService = ApiService();
  // Yer işaretli haberleri tutacak Future
  late Future<List<Haber>> _kaydedilenHaberlerFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında yer işaretli haberleri yükle
    _kaydedilenHaberlerFuture = _apiService.getYerIsaretliHaberler();
  }

  /// Listeyi yeniler - pull to refresh için kullanılır
  void _yenile() {
    setState(() {
      _kaydedilenHaberlerFuture = _apiService.getYerIsaretliHaberler();
    });
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
          'Bookmarks',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Haber>>(
        future: _kaydedilenHaberlerFuture,
        builder: (context, snapshot) {
          // Yükleme durumu göstergesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black87,
              ),
            );
          }
          // Hata durumu gösterimi
          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bookmarked news could not be loaded: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Boş liste durumu gösterimi
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      color: Colors.grey.shade400,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Bookmarks Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To bookmark a news article, click the bookmark button on the news detail page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Başarılı veri yükleme - haber listesi gösterimi
          final haberler = snapshot.data!;
          return RefreshIndicator(
            color: Colors.black87,
            onRefresh: () async {
              // Pull to refresh ile listeyi yenile
              setState(() {
                _kaydedilenHaberlerFuture =
                    _apiService.getYerIsaretliHaberler();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                final haber = haberler[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: HaberKarti(
                    haber: haber,
                    onGeriDonuldu: () {
                      // Haber detayından geri dönüldüğünde listeyi yenile
                      setState(() {
                        _kaydedilenHaberlerFuture =
                            _apiService.getYerIsaretliHaberler();
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
