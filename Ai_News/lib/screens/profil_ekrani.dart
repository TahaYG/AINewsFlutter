import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilEkrani extends StatelessWidget {
  const ProfilEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthService'e erişmek için Provider kullanıyoruz.
    final authService = Provider.of<AuthService>(context, listen: false);

    print(
        "--- ProfilEkrani build ediliyor. Görülen kullanıcı adı: ${authService.username ?? 'YOK'} ---");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Profil ikonu
              CircleAvatar(
                radius: 50,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person_outline,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              // Kullanıcı adı
              Text(
                authService.username ?? 'Kullanıcı Adı Yüklenemedi',
                style: GoogleFonts.lato(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Rol etiketleri
              if (authService.isAdmin)
                const Chip(
                  label: Text('Admin'),
                  backgroundColor: Colors.red,
                  labelStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              if (!authService.isAdmin && authService.isModerator)
                const Chip(
                  label: Text('Moderatör'),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),

              const Spacer(), // Boşluğu doldurur ve butonu en alta iter

              // Çıkış Yap Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                  onPressed: () {
                    // Önce çıkış yapma işlemini çağır.
                    authService.logout();
                    // Ardından, bu ekran dahil tüm ekranları kapatıp
                    // uygulama başlangıcına (Giriş Ekranı'na) dön.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
