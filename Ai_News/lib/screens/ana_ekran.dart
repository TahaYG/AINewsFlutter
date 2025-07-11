import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../models/kategori.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../widgets/haber_karti.dart';
import '../utils/icon_helper.dart';
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

  final Map<int, PagingController<int, Haber>> _pagingControllers = {};

  @override
  void initState() {
    super.initState();
    _kategorilerFuture = _apiService.getKategoriler();
    _kategorilerFuture.then((kategoriler) {
      if (mounted) {
        _setupPagingController(0); // "Tümü" sekmesi için
        for (var kategori in kategoriler) {
          _setupPagingController(kategori.id);
        }
        setState(() {});
      }
    });
  }

  void _setupPagingController(int kategoriId) {
    final controller = PagingController<int, Haber>(firstPageKey: 1);
    controller.addPageRequestListener((pageKey) {
      _fetchPage(pageKey, kategoriId, controller);
    });
    _pagingControllers[kategoriId] = controller;
  }

  Future<void> _fetchPage(int pageKey, int kategoriId,
      PagingController<int, Haber> controller) async {
    try {
      final yeniSayfa = await _apiService.getHaberler(
          pageNumber: pageKey, kategoriId: kategoriId);
      final isLastPage = yeniSayfa.sonSayfaMi;
      if (isLastPage) {
        controller.appendLastPage(yeniSayfa.haberler);
      } else {
        final nextPageKey = pageKey + 1;
        controller.appendPage(yeniSayfa.haberler, nextPageKey);
      }
    } catch (error) {
      controller.error = error;
    }
  }

  @override
  void dispose() {
    _pagingControllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return FutureBuilder<List<Kategori>>(
      future: _kategorilerFuture,
      builder: (context, kategoriSnapshot) {
        if (kategoriSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(title: const Text('AI Haber Motoru')),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (kategoriSnapshot.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text('Hata')),
              body: Center(
                  child: Text(
                      'Kategoriler yüklenemedi: ${kategoriSnapshot.error}')));
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
              // === DEĞİŞİKLİK: Tüm butonlar geri eklendi ===
              actions: [
                if (authService.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: const Icon(Icons.admin_panel_settings_outlined,
                          size: 18, color: Colors.white),
                      label: const Text('Admin',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (!authService.isAdmin && authService.isModerator)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: const Icon(Icons.security_outlined,
                          size: 18, color: Colors.white),
                      label: const Text('Moderatör',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border_outlined),
                  tooltip: 'Kaydedilenler',
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const KaydedilenlerEkrani()));
                    // Kaydedilenler ekranından dönüldüğünde tüm listeleri yenile
                    _pagingControllers
                        .forEach((_, controller) => controller.refresh());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  tooltip: 'Profil',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfilEkrani()));
                  },
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tumKategoriler
                    .map((kategori) => Tab(
                            child: Row(
                          children: [
                            Icon(getIconForCategory(kategori.ad), size: 18),
                            const SizedBox(width: 8),
                            Text(kategori.ad.toUpperCase())
                          ],
                        )))
                    .toList(),
              ),
            ),
            body: TabBarView(
              children: tumKategoriler.map((kategori) {
                final controller = _pagingControllers[kategori.id];
                if (controller == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: () => Future.sync(() => controller.refresh()),
                  child: PagedListView<int, Haber>(
                    pagingController: controller,
                    builderDelegate: PagedChildBuilderDelegate<Haber>(
                      itemBuilder: (context, haber, index) => HaberKarti(
                        haber: haber,
                        onGeriDonuldu: () => controller.refresh(),
                      ),
                      firstPageErrorIndicatorBuilder: (context) => Center(
                          child: Text(
                              'İlk sayfa yüklenemedi: ${controller.error}')),
                      noItemsFoundIndicatorBuilder: (context) => Center(
                          child: Text(
                              '${kategori.ad} kategorisinde haber bulunamadı.')),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
