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
  late Future<List<Haber>> _kaydedilenlerFuture;

  @override
  void initState() {
    super.initState();
    _yenile();
  }

  void _yenile() {
    setState(() {
      _kaydedilenlerFuture = _apiService.getYerIsaretliHaberler();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaydedilen Haberler'),
      ),
      body: FutureBuilder<List<Haber>>(
        future: _kaydedilenlerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Haberler yüklenemedi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Henüz hiç haber kaydetmediniz.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final haberler = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _yenile(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: haberler.length,
              itemBuilder: (context, index) {
                return HaberKarti(
                  haber: haberler[index],
                  onGeriDonuldu: _yenile,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
