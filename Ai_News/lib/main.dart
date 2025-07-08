import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'screens/ana_ekran.dart';
import 'screens/giris_ekrani.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService()..initAuth(),
      child: const HaberUygulamasi(),
    ),
  );
}

class HaberUygulamasi extends StatelessWidget {
  const HaberUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    // Sizin sağladığınız tema kodu buraya entegre edildi.
    final lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor:
          const Color(0xFFF5F7FA), // Hafif gri/mavi arka plan
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.lato(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D47A1), // Ana Renk: Koyu Mavi
        background: const Color(0xFFF5F7FA),
        surface: Colors.white, // Kartların rengi
        onSurface: Colors.black87, // Kartların üzerindeki yazı rengi
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: Colors.black.withOpacity(0.8),
        displayColor: Colors.black,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: const Color(0xFF0D47A1),
        unselectedLabelColor: Colors.black54,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 3.0),
        ),
      ),
    );

    return MaterialApp(
      title: 'AI Haber Motoru',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          // Giriş durumuna göre doğru ekranı göster
          return authService.isLoggedIn
              ? const AnaEkran()
              : const GirisEkrani();
        },
      ),
    );
  }
}
