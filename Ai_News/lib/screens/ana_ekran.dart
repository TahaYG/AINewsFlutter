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

/// Ana haber ekranı - kategoriler ve haber listesi
/// TabController ile kategori geçişi ve infinite scroll pagination kullanır
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});
  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran>
    with SingleTickerProviderStateMixin {
  // Servisler
  final ApiService _apiService = ApiService();

  // Asenkron veri yönetimi
  late Future<List<Kategori>> _kategorilerFuture;

  // Her kategori için ayrı pagination controller
  final Map<int, PagingController<int, Haber>> _pagingControllers = {};

  // Tab kontrolü için controller
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    // Kategorileri API'den çek
    _kategorilerFuture = _apiService.getKategoriler();

    // Kategoriler yüklendikten sonra tab controller'ı kurulum
    _kategorilerFuture.then((kategoriler) {
      if (mounted) {
        // Tab sayısı = kategoriler + "Tümü" sekmesi
        _tabController =
            TabController(length: kategoriler.length + 1, vsync: this);

        // Tab değişikliklerini dinle (TTS durdurmak için)
        _tabController!.addListener(_handleTabSelection);

        // Her kategori için pagination controller kurulumu
        _setupPagingController(0); // "Tümü" sekmesi için (kategori ID = 0)
        for (var kategori in kategoriler) {
          _setupPagingController(kategori.id);
        }

        // UI'yi güncelle
        setState(() {}); // TabController oluşturulduktan sonra arayüzü güncelle
      }
    });
  }

  /// Tab seçimi değiştiğinde çağrılır - aktif TTS playback'i durdurur
  void _handleTabSelection() {
    // Sekme değiştiğinde, devam eden bir okuma varsa durdur.
    if (_tabController!.indexIsChanging) {
      Provider.of<TtsService>(context, listen: false).stop();
    }
  }

  /// Belirtilen kategori ID'si için pagination controller kurulumu
  /// Her kategori kendi pagination state'ini tutar
  void _setupPagingController(int kategoriId) {
    final controller = PagingController<int, Haber>(firstPageKey: 1);

    // Yeni sayfa talep edildiğinde çağrılır
    controller.addPageRequestListener((pageKey) {
      _fetchPage(pageKey, kategoriId, controller);
    });

    _pagingControllers[kategoriId] = controller;
  }

  /// API'den belirtilen sayfa ve kategori için haberleri çeker
  /// Infinite scroll pagination için kullanılır
  Future<void> _fetchPage(int pageKey, int kategoriId,
      PagingController<int, Haber> controller) async {
    try {
      // API'den haberleri çek
      final yeniSayfa = await _apiService.getHaberler(
          pageNumber: pageKey, kategoriId: kategoriId);

      // Son sayfa kontrolü
      final isLastPage = yeniSayfa.sonSayfaMi;
      if (isLastPage) {
        // Son sayfa ise pagination'ı sonlandır
        controller.appendLastPage(yeniSayfa.haberler);
      } else {
        // Daha fazla sayfa var, devam et
        final nextPageKey = pageKey + 1;
        controller.appendPage(yeniSayfa.haberler, nextPageKey);
      }
    } catch (error) {
      // Hata durumunda controller'a bildir
      controller.error = error;
    }
  }

  @override
  void dispose() {
    // Memory leak önleme - tüm controller'ları temizle
    _pagingControllers.forEach((_, controller) => controller.dispose());
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider'lardan servisleri al
    final authService = Provider.of<AuthService>(context);
    final ttsService = Provider.of<TtsService>(context);

    return FutureBuilder<List<Kategori>>(
      future: _kategorilerFuture,
      builder: (context, kategoriSnapshot) {
        // Yükleme durumu kontrolü
        if (kategoriSnapshot.connectionState == ConnectionState.waiting ||
            _tabController == null) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('news.ai'),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
              body: const Center(child: CircularProgressIndicator()));
        }

        // Hata durumu kontrolü
        if (kategoriSnapshot.hasError) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Error'),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
              ),
              body: Center(
                  child: Text(
                      'Categories could not be loaded: ${kategoriSnapshot.error}')));
        }

        // Veri kontrolü
        if (!kategoriSnapshot.hasData || kategoriSnapshot.data!.isEmpty) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('No Data'),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
              ),
              body: const Center(child: Text('No categories found.')));
        }

        final kategoriler = kategoriSnapshot.data!;
        // "Tümü" kategorisini başa ekle
        final tumKategoriler = [Kategori(id: 0, ad: 'All'), ...kategoriler];

        // DEĞİŞİKLİK: DefaultTabController kaldırıldı. Artık kendi controller'ımızı kullanıyoruz.
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Modern AppBar - özel tasarım
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Logo ve uygulama adı
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              color: Colors.black87, size: 28),
                          SizedBox(width: 8),
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

                      // TTS kontrol butonu - aktif tab'daki haberleri okur
                      _buildClassicActionButton(
                        icon:
                            ttsService.isPlaying && ttsService.playbackId == -1
                                ? Icons.stop_circle_outlined
                                : Icons.playlist_play_outlined,
                        onPressed: () {
                          if (ttsService.isPlaying) {
                            ttsService.stop();
                          } else {
                            // Aktif tab'daki haberleri al ve okumaya başla
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

                      // News Player butonu - detaylı oynatıcı ekranına git
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
                            // Haber yoksa uyarı göster
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('No news to play in this tab.'),
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

                      // Kullanıcı rolü badge'leri
                      if (authService.isAdmin)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 18, color: Colors.red),
                            SizedBox(width: 4),
                            Text('Admin',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      if (!authService.isAdmin && authService.isModerator)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.security_outlined,
                                size: 18, color: Colors.orange),
                            SizedBox(width: 4),
                            Text('Mod',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),

                      // Profil butonu
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
                            child: const Icon(
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

              // Modern Tab Bar - kategori seçimi
              Container(
                margin: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 0),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  // Seçili tab için siyah nokta indicator
                  indicator: const ShortOvalIndicator(
                    width: 24, // istediğin kadar kısaltabilirsin
                    height: 8,
                    color: Colors.black87,
                    radius: 8,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.only(top: 38),
                  indicatorWeight: 4.0,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 18),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 18),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  tabs: tumKategoriler
                      .map((kategori) => Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Kategori ikonu
                                  Icon(
                                    getIconForCategory(kategori.ad),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  // Kategori adı (çevrilmiş)
                                  Text(translateCategoryName(kategori.ad))
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Tab Content - haber listesi
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
                            // Her haber için kart widget'ı
                            itemBuilder: (context, haber, index) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: HaberKarti(
                                haber: haber,
                                onGeriDonuldu: () => controller.refresh(),
                              ),
                            ),
                            // İlk sayfa hata durumu
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
                                style: const TextStyle(color: Colors.black87),
                              ),
                            )),
                            // Veri bulunamadı durumu
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
                                style: const TextStyle(color: Colors.black87),
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

  /// Klasik stil aksiyon butonu oluşturucu
  /// AppBar'daki butonlar için tutarlı tasarım sağlar
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

// Kısa oval (dot) indicator için özel Decoration
class ShortOvalIndicator extends Decoration {
  final double width;
  final double height;
  final Color color;
  final double radius;

  const ShortOvalIndicator({
    this.width = 24,
    this.height = 8,
    this.color = Colors.black87,
    this.radius = 8,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _ShortOvalPainter(this);
  }
}

class _ShortOvalPainter extends BoxPainter {
  final ShortOvalIndicator decoration;

  _ShortOvalPainter(this.decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()..color = decoration.color;
    final double x =
        offset.dx + (configuration.size!.width - decoration.width) / 2;
    final double y =
        offset.dy + configuration.size!.height - decoration.height - 4;
    final Rect rect = Rect.fromLTWH(x, y, decoration.width, decoration.height);
    final RRect rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(decoration.radius));
    canvas.drawRRect(rrect, paint);
  }
}
