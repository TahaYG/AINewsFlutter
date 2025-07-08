import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../widgets/haber_karti.dart';
import '../utils/icon_helper.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  final ApiService _apiService = ApiService();
  late Future<List<Kategori>> _kategorilerFuture;
  late Future<List<Haber>> _haberlerFuture;

  @override
  void initState() {
    super.initState();
    _yenile();
  }

  // DEĞİŞİKLİK: Metodun dönüş tipi Future<void> olarak güncellendi.
  // Bu, RefreshIndicator'ın ne zaman duracağını bilmesini sağlar.
  Future<void> _yenile() async {
    setState(() {
      _kategorilerFuture = _apiService.getKategoriler();
      _haberlerFuture = _apiService.getHaberler();
    });
    // İki API isteğinin de tamamlanmasını bekle
    await Future.wait([_kategorilerFuture, _haberlerFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kategori>>(
      future: _kategorilerFuture,
      builder: (context, kategoriSnapshot) {
        if (kategoriSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (kategoriSnapshot.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text('Hata')),
              body: Center(child: Text('Hata: ${kategoriSnapshot.error}')));
        }
        if (!kategoriSnapshot.hasData || kategoriSnapshot.data!.isEmpty) {
          return Scaffold(
              appBar: AppBar(title: const Text('Veri Yok')),
              body: const Center(child: Text('Hiç kategori bulunamadı.')));
        }

        final kategoriler = kategoriSnapshot.data!;
        final tumKategoriler = [Kategori(id: 0, ad: 'Tümü'), ...kategoriler];

        return DefaultTabController(
          length: tumKategoriler.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('AI Haber Motoru'),
              // DEĞİŞİKLİK: Manuel yenileme butonu kaldırıldı.
              actions: const [],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tumKategoriler.map((kategori) {
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(getIconForCategory(kategori.ad), size: 18),
                        const SizedBox(width: 8),
                        Text(kategori.ad.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            body: FutureBuilder<List<Haber>>(
              future: _haberlerFuture,
              builder: (context, haberSnapshot) {
                if (haberSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (haberSnapshot.hasError) {
                  return Center(
                      child:
                          Text('Haberler yüklenemedi: ${haberSnapshot.error}'));
                }
                if (!haberSnapshot.hasData || haberSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Hiç haber bulunamadı.'));
                }

                final tumHaberler = haberSnapshot.data!;
                tumHaberler
                    .sort((a, b) => b.yayinTarihi.compareTo(a.yayinTarihi));

                return TabBarView(
                  children: tumKategoriler.map((kategori) {
                    final filtrelenmisHaberler = kategori.id == 0
                        ? tumHaberler
                        : tumHaberler
                            .where((haber) => haber.kategoriId == kategori.id)
                            .toList();

                    if (filtrelenmisHaberler.isEmpty) {
                      return Center(
                          child: Text(
                              '${kategori.ad} kategorisinde gösterilecek onaylı haber bulunamadı.'));
                    }

                    // === DEĞİŞİKLİK: ListView.builder, RefreshIndicator ile sarmalandı ===
                    return RefreshIndicator(
                      onRefresh:
                          _yenile, // Aşağı çekildiğinde _yenile fonksiyonunu çağırır.
                      child: ListView.builder(
                        // ListView'in her zaman kaydırılabilir olmasını sağlar,
                        // böylece az haber varken bile yenileme çalışır.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: filtrelenmisHaberler.length,
                        itemBuilder: (context, index) {
                          final haber = filtrelenmisHaberler[index];
                          // HATA DÜZELTMESİ: HaberKarti artık 'kategoriAdi' parametresi almadığı için
                          // ilgili satırlar kaldırıldı.
                          return HaberKarti(
                            haber: haber,
                            onGeriDonuldu: _yenile,
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
