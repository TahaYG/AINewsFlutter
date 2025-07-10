import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../widgets/haber_karti.dart';
import '../utils/icon_helper.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'kaydedilenler_ekrani.dart';
import 'profil_ekrani.dart';

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
    final authService = Provider.of<AuthService>(context, listen: false);

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
              title: const Row(
                children: [
                  Icon(Icons.smart_toy_outlined),
                  SizedBox(width: 8),
                  Text('news.ai'),
                ],
              ),
              // DEĞİŞİKLİK: Manuel yenileme butonu kaldırıldı.
              actions: [
                if (authService.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: Icon(
                        Icons.admin_panel_settings,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      label: Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (!authService.isAdmin && authService.isModerator)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: Icon(Icons.security_outlined,
                          size: 18, color: Colors.white),
                      label: const Text('Mod',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      backgroundColor: Colors.orange[700], // Farklı bir renk
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                // YENİ: Kaydedilenler ekranına gitme butonu
                IconButton(
                  icon: const Icon(Icons.bookmark_border_outlined),
                  tooltip: 'Kaydedilenler',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const KaydedilenlerEkrani()),
                    );
                    // Kaydedilenler ekranından geri dönüldüğünde ana ekranı yenile
                    _yenile();
                  },
                ),
                // YENİ: Çıkış yapma butonu
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Profil',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilEkrani()),
                    );
                  },
                ),
              ],
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
