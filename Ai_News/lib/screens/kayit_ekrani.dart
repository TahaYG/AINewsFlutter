import 'package:flutter/material.dart';
import '../services/api_service.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    // === DEĞİŞİKLİK BURADA: Artık bool yerine String? bekliyoruz ===
    final String? errorMessage = await _apiService.register(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      // Eğer errorMessage null ise, işlem başarılıdır.
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context)
            .pop(); // Kayıt başarılıysa giriş ekranına geri dön
      } else {
        // Eğer bir hata mesajı varsa, onu göster.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı (E-posta)'),
                  validator: (value) => value!.isEmpty
                      ? 'Lütfen bir kullanıcı adı belirleyin.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir şifre belirleyin.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Kayıt Ol'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
