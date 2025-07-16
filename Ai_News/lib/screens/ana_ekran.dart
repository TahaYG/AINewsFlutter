import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import '../models/kategori.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import '../widgets/haber_karti.dart';
import '../utils/icon_helper.dart';
import '../services/auth_service.dart';
import '../services/tts_service.dart';
import 'kaydedilenler_ekrani.dart';
import 'profil_ekrani.dart';
import 'news_player_screen.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});
  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Kategori>> _kategorilerFuture;

  final Map<int, PagingController<int, Haber>> _pagingControllers = {};
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _kategorilerFuture = _apiService.getKategoriler();
    _kategorilerFuture.then((kategoriler) {
      if (mounted) {
        _tabController =
            TabController(length: kategoriler.length + 1, vsync: this);
        _tabController!.addListener(_handleTabSelection);
        _setupPagingController(0); // "Tümü" sekmesi için
        for (var kategori in kategoriler) {
          _setupPagingController(kategori.id);
        }
        setState(() {}); // TabController oluşturulduktan sonra arayüzü güncelle
      }
    });
  }

  void _handleTabSelection() {
    // Sekme değiştiğinde, devam eden bir okuma varsa durdur.
    if (_tabController!.indexIsChanging) {
      Provider.of<TtsService>(context, listen: false).stop();
    }
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
    _pagingControllers.forEach((_, controller) => controller.dispose());
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final ttsService = Provider.of<TtsService>(context);

    return FutureBuilder<List<Kategori>>(
      future: _kategorilerFuture,
      builder: (context, kategoriSnapshot) {
        if (kategoriSnapshot.connectionState == ConnectionState.waiting ||
            _tabController == null) {
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

        // DEĞİŞİKLİK: DefaultTabController kaldırıldı. Artık kendi controller'ımızı kullanıyoruz.
        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.smart_toy_outlined),
                SizedBox(width: 8),
                Text('news.ai'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  ttsService.isPlaying && ttsService.playbackId == -1
                      ? Icons.stop_circle_outlined
                      : Icons.playlist_play_outlined,
                  size: 22,
                  color: ttsService.isPlaying && ttsService.playbackId == -1
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
                tooltip: ttsService.isPlaying && ttsService.playbackId == -1
                    ? 'Okumayı Durdur'
                    : 'Bu Sekmeyi Oku',
                onPressed: () {
                  if (ttsService.isPlaying) {
                    ttsService.stop();
                  } else {
                    final activeTabIndex = _tabController?.index ?? 0;
                    final activeKategoriId = tumKategoriler[activeTabIndex].id;
                    final activeController =
                        _pagingControllers[activeKategoriId];
                    if (activeController?.itemList != null &&
                        activeController!.itemList!.isNotEmpty) {
                      ttsService.speakList(activeController.itemList!);
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded, size: 22),
                tooltip: 'Player',
                onPressed: () {
                  final activeTabIndex = _tabController?.index ?? 0;
                  final activeKategoriId = tumKategoriler[activeTabIndex].id;
                  final activeController = _pagingControllers[activeKategoriId];
                  if (activeController?.itemList != null && activeController!.itemList!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsPlayerScreen(
                          haberler: activeController.itemList!,
                          initialIndex: 0,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bu sekmede oynatılacak haber yok.')),
                    );
                  }
                },
              ),
              if (authService.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    avatar: Icon(
                      Icons.admin_panel_settings,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Admin',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
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
                    label: const Text('Mod',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert, size: 22),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_border_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text('Kaydedilenler'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 4,
                    child: Row(
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text('Profil'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 3) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const KaydedilenlerEkrani()),
                    );
                    _pagingControllers.forEach((_, controller) => controller.refresh());
                  } else if (value == 4) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilEkrani()),
                    );
                  }
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
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
                        ),
                      ))
                  .toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
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
                        child:
                            Text('İlk sayfa yüklenemedi: ${controller.error}')),
                    noItemsFoundIndicatorBuilder: (context) => Center(
                        child: Text(
                            '${kategori.ad} kategorisinde haber bulunamadı.')),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
