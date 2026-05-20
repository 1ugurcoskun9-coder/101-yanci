import 'package:flutter/material.dart';

class KullanimKosullariPage extends StatelessWidget {
  const KullanimKosullariPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Kullanım Koşulları',
      content: '''
101Yancı Kullanım Koşulları

1. Bu oyun eğlence amacıyla tasarlanmaktadır.
2. Kullanıcı, oyuna giriş yaparak kurallara uygun davranmayı kabul eder.
3. Hile, kötüye kullanım ve sistemi bozacak davranışlar yasaktır.
4. Oyun içi kurallar ve ceza sistemi proje geliştikçe güncellenecektir.
5. Gerçek para sistemi eklenirse ayrıca açık onay ve yasal bilgilendirme gerekir.

Bu metin taslak metindir. Yayına çıkmadan önce resmi kullanım koşulları hazırlanmalıdır.
''',
    );
  }
}

class GizlilikPolitikasiPage extends StatelessWidget {
  const GizlilikPolitikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Gizlilik Politikası',
      content: '''
101Yancı Gizlilik Politikası

1. Bu prototip sürümde gerçek kullanıcı verisi toplanmamaktadır.
2. Hesap oluşturma ekranı şimdilik görsel ve test amaçlıdır.
3. Google, Facebook veya oyun hesabı bağlantıları ileride gerçek sisteme bağlanabilir.
4. Gerçek giriş sistemi eklendiğinde hangi verilerin saklandığı açıkça belirtilecektir.
5. Kullanıcı gizliliği, güvenli hesap sistemi ve veri koruma oyunun temel parçalarından biri olacaktır.

Bu metin taslak metindir. Yayına çıkmadan önce resmi gizlilik politikası hazırlanmalıdır.
''',
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String content;

  const _LegalPage({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Text(
          content,
          style: const TextStyle(fontSize: 17, height: 1.5),
        ),
      ),
    );
  }
}
