import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'ana_menu_page.dart';
import 'auth_page.dart';
import 'legal_pages.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool yukleniyor = false;

  void _yakinda(BuildContext context, String servis) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$servis bağlantısı daha sonra eklenecek.')),
    );
  }

  Future<void> _misafirGiris() async {
    setState(() => yukleniyor = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AnaMenuPage(kullaniciAdi: 'Misafir Oyuncu'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Misafir girişi başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  void _authEkraniAc() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(.15),
                  Colors.black.withOpacity(.80),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                if (yukleniyor)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 15,
                  runSpacing: 14,
                  children: [
                    _girisButonu(
                      text: "Facebook'la\nBağlan",
                      icon: Icons.facebook,
                      color: const Color(0xff1767d8),
                      onTap: yukleniyor ? null : () => _yakinda(context, 'Facebook'),
                    ),
                    _girisButonu(
                      text: 'Google ile\nBağlan',
                      icon: Icons.g_mobiledata,
                      color: Colors.white,
                      textColor: Colors.black87,
                      iconColor: Colors.red,
                      onTap: yukleniyor ? null : () => _yakinda(context, 'Google'),
                    ),
                    _girisButonu(
                      text: 'Hesap Oluştur\n/ Giriş Yap',
                      icon: Icons.person_add_alt_1,
                      color: const Color(0xff07883a),
                      onTap: yukleniyor ? null : _authEkraniAc,
                    ),
                    _girisButonu(
                      text: 'Misafir',
                      icon: Icons.person,
                      color: const Color(0xffd6a000),
                      onTap: yukleniyor ? null : _misafirGiris,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withOpacity(.84),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'Devam ederek '),
                        TextSpan(
                          text: 'Kullanım Koşulları',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const KullanimKosullariPage(),
                                  ),
                                ),
                        ),
                        const TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Gizlilik Politikası',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GizlilikPolitikasiPage(),
                                  ),
                                ),
                        ),
                        const TextSpan(text: ' kabul etmiş olursunuz.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _girisButonu({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return SizedBox(
      width: 132,
      height: 112,
      child: Material(
        color: color,
        elevation: 14,
        shadowColor: Colors.black,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(.32),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 38, color: iconColor),
                const SizedBox(height: 9),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
