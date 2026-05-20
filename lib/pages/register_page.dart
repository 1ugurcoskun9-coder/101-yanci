import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ana_menu_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController kullaniciAdiController = TextEditingController();
  final TextEditingController epostaController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();

  bool sifreGizli = true;
  bool kayitYapiliyor = false;

  @override
  void dispose() {
    kullaniciAdiController.dispose();
    epostaController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  Future<void> _hesapOlustur() async {
    final kullaniciAdi = kullaniciAdiController.text.trim();
    final eposta = epostaController.text.trim();
    final sifre = sifreController.text.trim();

    if (kullaniciAdi.isEmpty || eposta.isEmpty || sifre.isEmpty) {
      _mesaj('Lütfen tüm alanları doldurun.');
      return;
    }

    if (!eposta.contains('@') || !eposta.contains('.')) {
      _mesaj('Geçerli bir e-posta girin.');
      return;
    }

    if (sifre.length < 6) {
      _mesaj('Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() => kayitYapiliyor = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı.');
      }

      await user.updateDisplayName(kullaniciAdi);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'kullaniciAdi': kullaniciAdi,
        'email': eposta,
        'coin': 29500,
        'seviye': 1,
        'xp': 0,
        'toplamOyun': 0,
        'kazandigiOyun': 0,
        'profilResmi': '',
        'hesapTipi': 'email',
        'kayitTarihi': FieldValue.serverTimestamp(),
        'sonGirisTarihi': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnaMenuPage(kullaniciAdi: kullaniciAdi),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Kayıt başarısız.';

      if (e.code == 'email-already-in-use') {
        mesaj = 'Bu e-posta zaten kullanılıyor.';
      } else if (e.code == 'invalid-email') {
        mesaj = 'E-posta adresi geçersiz.';
      } else if (e.code == 'weak-password') {
        mesaj = 'Şifre çok zayıf.';
      } else if (e.message != null) {
        mesaj = 'Kayıt başarısız: ${e.message}';
      }

      _mesaj(mesaj);
    } catch (e) {
      _mesaj('Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => kayitYapiliyor = false);
    }
  }

  void _mesaj(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(
        title: const Text('Oyun Hesabı Oluştur'),
        backgroundColor: const Color(0xff102446),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff102446),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber.withOpacity(.55)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1, color: Colors.amber, size: 66),
                  const SizedBox(height: 12),
                  const Text(
                    '101Yancı Hesabı',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 24),
                  _alan(
                    controller: kullaniciAdiController,
                    label: 'Kullanıcı Adı',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _alan(
                    controller: epostaController,
                    label: 'E-posta',
                    icon: Icons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sifreController,
                    obscureText: sifreGizli,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(sifreGizli ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => sifreGizli = !sifreGizli),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(.25),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: kayitYapiliyor ? null : _hesapOlustur,
                      icon: kayitYapiliyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        kayitYapiliyor ? 'Kaydediliyor...' : 'Hesabı Oluştur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: kayitYapiliyor ? null : () => Navigator.pop(context),
                    child: const Text('Giriş ekranına dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alan({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.black.withOpacity(.25),
      ),
    );
  }
}
