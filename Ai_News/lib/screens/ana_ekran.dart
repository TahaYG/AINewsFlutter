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
              appBar: AppBar(title: const Text('news.ai')),
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
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                  Color(0xFFf093fb),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Modern AppBar
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.smart_toy_outlined,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'news.ai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _buildModernActionButton(
                          icon: ttsService.isPlaying &&
                                  ttsService.playbackId == -1
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
                                ttsService
                                    .speakList(activeController.itemList!);
                              }
                            }
                          },
                          isActive: ttsService.isPlaying &&
                              ttsService.playbackId == -1,
                        ),
                        const SizedBox(width: 8),
                        _buildModernActionButton(
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
                              Provider.of<TtsService>(context, listen: false).stop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Bu sekmede oynatılacak haber yok.'),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.9),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('Admin',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        if (!authService.isAdmin && authService.isModerator)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security_outlined,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('Mod',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        PopupMenuButton<int>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.more_vert,
                                color: Colors.white, size: 18),
                          ),
                          color: Colors.white.withOpacity(0.95),
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.black.withOpacity(0.2),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF667eea).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.bookmark_border_outlined,
                                        size: 18,
                                        color: Color(0xFF667eea),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Kaydedilenler',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF764ba2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.account_circle_outlined,
                                        size: 18,
                                        color: Color(0xFF764ba2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Profil',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 3) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const KaydedilenlerEkrani()),
                              );
                              _pagingControllers.forEach(
                                  (_, controller) => controller.refresh());
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
                    ),
                  ),

                  // Modern Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle:
                          TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                      tabs: tumKategoriler
                          .map((kategori) => Tab(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(getIconForCategory(kategori.ad),
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Text(kategori.ad.toUpperCase())
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: tumKategoriler.map((kategori) {
                        final controller = _pagingControllers[kategori.id];
                        if (controller == null) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: RefreshIndicator(
                            onRefresh: () =>
                                Future.sync(() => controller.refresh()),
                            child: PagedListView<int, Haber>(
                              pagingController: controller,
                              builderDelegate: PagedChildBuilderDelegate<Haber>(
                                itemBuilder: (context, haber, index) =>
                                    Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: HaberKarti(
                                    haber: haber,
                                    onGeriDonuldu: () => controller.refresh(),
                                  ),
                                ),
                                firstPageErrorIndicatorBuilder: (context) =>
                                    Center(
                                        child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'İlk sayfa yüklenemedi: ${controller.error}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )),
                                noItemsFoundIndicatorBuilder: (context) =>
                                    Center(
                                        child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${kategori.ad} kategorisinde haber bulunamadı.',
                                    style: TextStyle(color: Colors.white),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.3)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.9),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
