import 'package:flutter/material.dart';

class KlasikOkeyPage extends StatelessWidget {
  const KlasikOkeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Klasik Okey',
      icon: Icons.grid_on,
      text: 'Klasik okey modu burada olacak. Kuralları ve masa yapısını daha sonra bağlayacağız.',
    );
  }
}

class TurnuvaPage extends StatelessWidget {
  const TurnuvaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Turnuva',
      icon: Icons.emoji_events,
      text: 'Turnuva sistemi ileride aktif olacak.',
    );
  }
}

class CoinMagazasiPage extends StatelessWidget {
  const CoinMagazasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Coin Mağazası',
      icon: Icons.monetization_on,
      text: 'Burada coin paketleri ve satın alma seçenekleri olacak.',
    );
  }
}

class GunlukOdulPage extends StatelessWidget {
  const GunlukOdulPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Günlük Ödül',
      icon: Icons.card_giftcard,
      text: 'Burada günlük giriş ödülleri verilecek.',
    );
  }
}

class BildirimPage extends StatelessWidget {
  const BildirimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Bildirimler',
      icon: Icons.notifications,
      text: 'Burada oyun davetleri ve sistem bildirimleri gösterilecek.',
    );
  }
}

class SiralamaPage extends StatelessWidget {
  const SiralamaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Sıralama',
      icon: Icons.emoji_events,
      text: 'Burada haftalık ve genel liderlik tablosu olacak.',
    );
  }
}

class ArkadaslarPage extends StatelessWidget {
  const ArkadaslarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Arkadaşlar',
      icon: Icons.group,
      text: 'Burada arkadaş listesi ve davet sistemi olacak.',
    );
  }
}

class AyarlarPage extends StatelessWidget {
  const AyarlarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Ayarlar',
      icon: Icons.settings,
      text: 'Burada ses, hesap, gizlilik ve oyun ayarları olacak.',
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _SimplePage({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xff102446),
      ),
      body: Center(
        child: Container(
          width: 560,
          margin: const EdgeInsets.all(22),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.32),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withOpacity(.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.amber, size: 76),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
