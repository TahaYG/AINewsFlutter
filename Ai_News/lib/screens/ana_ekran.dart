import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../widgets/haber_karti.dart';

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

  void _yenile() {
    setState(() {
      _kategorilerFuture = _apiService.getKategoriler();
      _haberlerFuture = _apiService.getHaberler();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kategori>>(
      future: _kategorilerFuture,
      builder: (context, kategoriSnapshot) {
        if (kategoriSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (kategoriSnapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Hata')), body: Center(child: Text('Hata: ${kategoriSnapshot.error}')));
        }
        if (!kategoriSnapshot.hasData || kategoriSnapshot.data!.isEmpty) {
          // === HATA DÜZELTMESİ: 'const' anahtar kelimesi kaldırıldı ===
          // Nedeni: İçindeki AppBar ve Text widget'ları const değil.
          return Scaffold(
            appBar: AppBar(title: const Text('Veri Yok')),
            body: const Center(child: Text('Hiç kategori bulunamadı.')),
          );
        }

        final kategoriler = kategoriSnapshot.data!;
        final tumKategoriler = [Kategori(id: 0, ad: 'Tümü'), ...kategoriler];

        return DefaultTabController(
          length: tumKategoriler.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('AI Haber Motoru'),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                  onPressed: _yenile,
                  tooltip: 'Yenile',
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tumKategoriler.map((kategori) => Tab(text: kategori.ad.toUpperCase())).toList(),
              ),
            ),
            body: FutureBuilder<List<Haber>>(
              future: _haberlerFuture,
              builder: (context, haberSnapshot) {
                if (haberSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (haberSnapshot.hasError) {
                  return Center(child: Text('Haberler yüklenemedi: ${haberSnapshot.error}'));
                }
                if (!haberSnapshot.hasData || haberSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Hiç haber bulunamadı.'));
                }

                final tumHaberler = haberSnapshot.data!;
                tumHaberler.sort((a, b) => b.yayinTarihi.compareTo(a.yayinTarihi));

                return TabBarView(
                  children: tumKategoriler.map((kategori) {
                    final filtrelenmisHaberler = kategori.id == 0
                        ? tumHaberler
                        : tumHaberler.where((haber) => haber.kategoriId == kategori.id).toList();
                    
                    if (filtrelenmisHaberler.isEmpty) {
                      return Center(child: Text('${kategori.ad} kategorisinde haber bulunamadı.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: filtrelenmisHaberler.length,
                      itemBuilder: (context, index) {
                        return HaberKarti(haber: filtrelenmisHaberler[index]);
                      },
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