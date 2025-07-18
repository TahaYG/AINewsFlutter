import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/haber.dart';
import '../widgets/haber_karti.dart';

class KaydedilenlerEkrani extends StatefulWidget {
  const KaydedilenlerEkrani({super.key});

  @override
  State<KaydedilenlerEkrani> createState() => _KaydedilenlerEkraniState();
}

class _KaydedilenlerEkraniState extends State<KaydedilenlerEkrani> {
  final ApiService _apiService = ApiService();
  late Future<List<Haber>> _kaydedilenHaberlerFuture;

  @override
  void initState() {
    super.initState();
    _kaydedilenHaberlerFuture = _apiService.getYerIsaretliHaberler();
  }

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
        title: Text(
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.black87,
              ),
            );
          }
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
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
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
                    Text(
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

          final haberler = snapshot.data!;
          return RefreshIndicator(
            color: Colors.black87,
            onRefresh: () async {
              setState(() {
                _kaydedilenHaberlerFuture = _apiService.getYerIsaretliHaberler();
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
                      setState(() {
                        _kaydedilenHaberlerFuture = _apiService.getYerIsaretliHaberler();
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
