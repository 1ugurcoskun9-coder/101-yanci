import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ana_menu_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum AuthMode {
  giris,
  kayit,
  sifremiUnuttum,
}

class _AuthPageState extends State<AuthPage> {
  AuthMode mode = AuthMode.giris;

  final girisKullaniciController = TextEditingController();
  final girisSifreController = TextEditingController();

  final kayitKullaniciController = TextEditingController();
  final kayitEpostaController = TextEditingController();
  final kayitSifreController = TextEditingController();

  final sifremiUnuttumController = TextEditingController();

  bool yukleniyor = false;
  bool sifreGizli = true;
  bool beniHatirla = false;

  @override
  void initState() {
    super.initState();
    _hatirlananBilgileriYukle();
  }

  Future<void> _hatirlananBilgileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final hatirla = prefs.getBool('beniHatirla') ?? false;
    final kayitliGiris = prefs.getString('hatirlananGiris') ?? '';

    if (!mounted) return;

    setState(() {
      beniHatirla = hatirla;
      if (hatirla) {
        girisKullaniciController.text = kayitliGiris;
      }
    });
  }

  Future<void> _hatirlaKaydet(String kullaniciAdiVeyaEmail) async {
    final prefs = await SharedPreferences.getInstance();

    if (beniHatirla) {
      await prefs.setBool('beniHatirla', true);
      await prefs.setString('hatirlananGiris', kullaniciAdiVeyaEmail.trim());
    } else {
      await prefs.setBool('beniHatirla', false);
      await prefs.remove('hatirlananGiris');
    }
  }

  @override
  void dispose() {
    girisKullaniciController.dispose();
    girisSifreController.dispose();
    kayitKullaniciController.dispose();
    kayitEpostaController.dispose();
    kayitSifreController.dispose();
    sifremiUnuttumController.dispose();
    super.dispose();
  }

  Future<String?> _emailBul(String kullaniciAdiVeyaEmail) async {
    final girilen = kullaniciAdiVeyaEmail.trim();

    if (girilen.contains('@')) {
      return girilen;
    }

    final sonuc = await FirebaseFirestore.instance
        .collection('users')
        .where('kullaniciAdiLower', isEqualTo: girilen.toLowerCase())
        .limit(1)
        .get();

    if (sonuc.docs.isEmpty) {
      return null;
    }

    return sonuc.docs.first.data()['email'] as String?;
  }

  Future<void> _girisYap() async {
    final kullaniciAdiVeyaEmail = girisKullaniciController.text.trim();
    final sifre = girisSifreController.text.trim();

    if (kullaniciAdiVeyaEmail.isEmpty || sifre.isEmpty) {
      _mesaj('Kullanıcı adı/e-posta ve şifre girin.');
      return;
    }

    setState(() => yukleniyor = true);

    try {
      final email = await _emailBul(kullaniciAdiVeyaEmail);

      if (email == null) {
        _mesaj('Bu kullanıcı adı bulunamadı.');
        return;
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: sifre,
      );

      final user = credential.user;
      if (user == null) {
        _mesaj('Giriş yapılamadı.');
        return;
      }

      await _hatirlaKaydet(kullaniciAdiVeyaEmail);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'sonGirisTarihi': FieldValue.serverTimestamp(),
      });

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final kullaniciAdi = data?['kullaniciAdi'] as String? ?? user.displayName ?? 'Oyuncu';

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnaMenuPage(kullaniciAdi: kullaniciAdi),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _mesaj('Şifre hatalı.');
      } else if (e.code == 'user-not-found') {
        _mesaj('Bu kullanıcı bulunamadı.');
      } else {
        _mesaj('Giriş başarısız: ${e.message ?? e.code}');
      }
    } catch (e) {
      _mesaj('Giriş hatası: $e');
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> _hesapOlustur() async {
    final kullaniciAdi = kayitKullaniciController.text.trim();
    final eposta = kayitEpostaController.text.trim();
    final sifre = kayitSifreController.text.trim();

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

    setState(() => yukleniyor = true);

    try {
      final kullaniciAdiKontrol = await FirebaseFirestore.instance
          .collection('users')
          .where('kullaniciAdiLower', isEqualTo: kullaniciAdi.toLowerCase())
          .limit(1)
          .get();

      if (kullaniciAdiKontrol.docs.isNotEmpty) {
        _mesaj('Bu kullanıcı adı zaten kullanılıyor.');
        return;
      }

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
        'kullaniciAdiLower': kullaniciAdi.toLowerCase(),
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

      await _hatirlaKaydet(kullaniciAdi);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnaMenuPage(kullaniciAdi: kullaniciAdi),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _mesaj('Bu e-posta zaten kullanılıyor.');
      } else if (e.code == 'invalid-email') {
        _mesaj('E-posta adresi geçersiz.');
      } else if (e.code == 'weak-password') {
        _mesaj('Şifre çok zayıf.');
      } else {
        _mesaj('Kayıt başarısız: ${e.message ?? e.code}');
      }
    } catch (e) {
      _mesaj('Kayıt hatası: $e');
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> _sifreSifirla() async {
    final kullaniciAdiVeyaEmail = sifremiUnuttumController.text.trim();

    if (kullaniciAdiVeyaEmail.isEmpty) {
      _mesaj('Kullanıcı adı veya e-posta girin.');
      return;
    }

    setState(() => yukleniyor = true);

    try {
      final email = await _emailBul(kullaniciAdiVeyaEmail);

      if (email == null) {
        _mesaj('Bu kullanıcı adı bulunamadı.');
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _mesaj('Şifre sıfırlama bağlantısı e-posta adresine gönderildi.');
      setState(() => mode = AuthMode.giris);
    } on FirebaseAuthException catch (e) {
      _mesaj('Şifre sıfırlama başarısız: ${e.message ?? e.code}');
    } catch (e) {
      _mesaj('Hata: $e');
    } finally {
      if (mounted) setState(() => yukleniyor = false);
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
        title: Text(_baslik),
        backgroundColor: const Color(0xff102446),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff102446),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amber.withOpacity(.55)),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle, color: Colors.amber, size: 70),
                  const SizedBox(height: 12),
                  Text(
                    _baslik,
                    style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  _modSecici(),
                  const SizedBox(height: 22),
                  if (mode == AuthMode.giris) _girisFormu(),
                  if (mode == AuthMode.kayit) _kayitFormu(),
                  if (mode == AuthMode.sifremiUnuttum) _sifremiUnuttumFormu(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _baslik {
    switch (mode) {
      case AuthMode.giris:
        return 'Giriş Yap';
      case AuthMode.kayit:
        return 'Hesap Oluştur';
      case AuthMode.sifremiUnuttum:
        return 'Şifremi Unuttum';
    }
  }

  Widget _modSecici() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _modButon('Giriş Yap', AuthMode.giris),
          _modButon('Hesap Oluştur', AuthMode.kayit),
        ],
      ),
    );
  }

  Widget _modButon(String text, AuthMode hedef) {
    final secili = mode == hedef;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: yukleniyor ? null : () => setState(() => mode = hedef),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: secili ? Colors.amber : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secili ? Colors.black : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _girisFormu() {
    return Column(
      children: [
        _alan(
          controller: girisKullaniciController,
          label: 'Kullanıcı adı veya e-posta',
          icon: Icons.person,
        ),
        const SizedBox(height: 14),
        _sifreAlani(girisSifreController),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: beniHatirla,
          onChanged: yukleniyor
              ? null
              : (value) {
                  setState(() {
                    beniHatirla = value ?? false;
                  });
                },
          title: const Text(
            'Beni hatırla',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Kullanıcı adın/e-postan bu cihazda kayıtlı kalır.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          activeColor: Colors.amber,
          checkColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),
        _anaButon(
          text: 'Giriş Yap',
          icon: Icons.login,
          onPressed: _girisYap,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: yukleniyor ? null : () => setState(() => mode = AuthMode.sifremiUnuttum),
          child: const Text('Şifremi unuttum'),
        ),
      ],
    );
  }

  Widget _kayitFormu() {
    return Column(
      children: [
        _alan(
          controller: kayitKullaniciController,
          label: 'Kullanıcı adı',
          icon: Icons.person,
        ),
        const SizedBox(height: 14),
        _alan(
          controller: kayitEpostaController,
          label: 'E-posta',
          icon: Icons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _sifreAlani(kayitSifreController),
        const SizedBox(height: 10),
        CheckboxListTile(
          value: beniHatirla,
          onChanged: yukleniyor
              ? null
              : (value) {
                  setState(() {
                    beniHatirla = value ?? false;
                  });
                },
          title: const Text(
            'Beni hatırla',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Hesap oluşturduktan sonra kullanıcı adın hatırlansın.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          activeColor: Colors.amber,
          checkColor: Colors.black,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),
        _anaButon(
          text: 'Hesabı Oluştur',
          icon: Icons.person_add_alt_1,
          onPressed: _hesapOlustur,
        ),
      ],
    );
  }

  Widget _sifremiUnuttumFormu() {
    return Column(
      children: [
        const Text(
          'Kullanıcı adını veya e-posta adresini yaz. Sana şifre sıfırlama bağlantısı gönderelim.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 18),
        _alan(
          controller: sifremiUnuttumController,
          label: 'Kullanıcı adı veya e-posta',
          icon: Icons.mail,
        ),
        const SizedBox(height: 20),
        _anaButon(
          text: 'Şifre Sıfırlama Gönder',
          icon: Icons.lock_reset,
          onPressed: _sifreSifirla,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: yukleniyor ? null : () => setState(() => mode = AuthMode.giris),
          child: const Text('Giriş ekranına dön'),
        ),
      ],
    );
  }

  Widget _anaButon({
    required String text,
    required IconData icon,
    required Future<void> Function() onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: yukleniyor ? null : onPressed,
        icon: yukleniyor
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(
          yukleniyor ? 'İşleniyor...' : text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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

  Widget _sifreAlani(TextEditingController controller) {
    return TextField(
      controller: controller,
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
    );
  }
}
