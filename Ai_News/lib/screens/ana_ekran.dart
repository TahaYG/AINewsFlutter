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
              appBar: AppBar(title: const Text('news.ai')),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (kategoriSnapshot.hasError) {
          return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                  child: Text(
                      'Categories could not be loaded: ${kategoriSnapshot.error}')));
        }
        if (!kategoriSnapshot.hasData || kategoriSnapshot.data!.isEmpty) {
          return Scaffold(
              appBar: AppBar(title: const Text('No Data')),
              body: const Center(child: Text('No categories found.')));
        }

        final kategoriler = kategoriSnapshot.data!;
        final tumKategoriler = [Kategori(id: 0, ad: 'All'), ...kategoriler];

        // DEĞİŞİKLİK: DefaultTabController kaldırıldı. Artık kendi controller'ımızı kullanıyoruz.
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Modern AppBar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              color: Colors.black87, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'news.ai',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildClassicActionButton(
                        icon:
                            ttsService.isPlaying && ttsService.playbackId == -1
                                ? Icons.stop_circle_outlined
                                : Icons.playlist_play_outlined,
                        onPressed: () {
                          if (ttsService.isPlaying) {
                            ttsService.stop();
                          } else {
                            final activeTabIndex = _tabController?.index ?? 0;
                            final activeKategoriId =
                                tumKategoriler[activeTabIndex].id;
                            final activeController =
                                _pagingControllers[activeKategoriId];
                            if (activeController?.itemList != null &&
                                activeController!.itemList!.isNotEmpty) {
                              ttsService.speakList(activeController.itemList!);
                            }
                          }
                        },
                        isActive:
                            ttsService.isPlaying && ttsService.playbackId == -1,
                      ),
                      const SizedBox(width: 8),
                      _buildClassicActionButton(
                        icon: Icons.queue_music_rounded,
                        onPressed: () async {
                          final activeTabIndex = _tabController?.index ?? 0;
                          final activeKategoriId =
                              tumKategoriler[activeTabIndex].id;
                          final activeController =
                              _pagingControllers[activeKategoriId];
                          if (activeController?.itemList != null &&
                              activeController!.itemList!.isNotEmpty) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewsPlayerScreen(
                                  haberler: activeController.itemList!,
                                  initialIndex: 0,
                                ),
                              ),
                            );
                            // NewsPlayerScreen'den çıkıldıktan sonra TTS'i durdur
                            Provider.of<TtsService>(context, listen: false)
                                .stop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No news to play in this tab.'),
                                backgroundColor: Colors.grey.shade800,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (authService.isAdmin)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('Admin',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      if (!authService.isAdmin && authService.isModerator)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.security_outlined,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('Mod',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfilEkrani()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.account_circle_outlined,
                              color: Colors.black87,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Modern Tab Bar
              Container(
                margin: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 0),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.only(top: 38),
                  indicatorWeight: 4.0,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  unselectedLabelStyle:
                      TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  tabs: tumKategoriler
                      .map((kategori) => Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    getIconForCategory(kategori.ad),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(translateCategoryName(kategori.ad))
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: tumKategoriler.map((kategori) {
                    final controller = _pagingControllers[kategori.id];
                    if (controller == null) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.black87));
                    }

                    return Container(
                      margin:
                          const EdgeInsets.only(left: 16, right: 16, top: 0),
                      child: RefreshIndicator(
                        color: Colors.black87,
                        onRefresh: () =>
                            Future.sync(() => controller.refresh()),
                        child: PagedListView<int, Haber>(
                          pagingController: controller,
                          builderDelegate: PagedChildBuilderDelegate<Haber>(
                            itemBuilder: (context, haber, index) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: HaberKarti(
                                haber: haber,
                                onGeriDonuldu: () => controller.refresh(),
                              ),
                            ),
                            firstPageErrorIndicatorBuilder: (context) => Center(
                                child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'First page could not be loaded: ${controller.error}',
                                style: TextStyle(color: Colors.black87),
                              ),
                            )),
                            noItemsFoundIndicatorBuilder: (context) => Center(
                                child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'No news found in ${translateCategoryName(kategori.ad)} category.',
                                style: TextStyle(color: Colors.black87),
                              ),
                            )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassicActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: isActive ? Colors.black : Colors.black.withOpacity(0.7),
            size: 28,
          ),
        ),
      ),
    );
  }
}
