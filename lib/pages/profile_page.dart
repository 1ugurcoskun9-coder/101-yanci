import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Profil için giriş yapmalısın.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xff102446),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          final kullaniciAdi = data?['kullaniciAdi'] ?? user.displayName ?? 'Oyuncu';
          final email = data?['email'] ?? user.email ?? '';
          final coin = data?['coin'] ?? 0;
          final seviye = data?['seviye'] ?? 1;
          final xp = data?['xp'] ?? 0;
          final toplamOyun = data?['toplamOyun'] ?? 0;
          final kazandigiOyun = data?['kazandigiOyun'] ?? 0;

          final kazanmaOrani = toplamOyun == 0
              ? 0
              : ((kazandigiOyun / toplamOyun) * 100).round();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.35),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.amber.withOpacity(.45)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(0xff44326d),
                      child: Icon(Icons.person, color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      kullaniciAdi,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    _xpBolumu(seviye, xp),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        _istatistik('Coin', coin.toString(), Icons.monetization_on, Colors.amber),
                        _istatistik('Seviye', seviye.toString(), Icons.shield, Colors.blueAccent),
                        _istatistik('Toplam Oyun', toplamOyun.toString(), Icons.casino, Colors.greenAccent),
                        _istatistik('Galibiyet', kazandigiOyun.toString(), Icons.emoji_events, Colors.orangeAccent),
                        _istatistik('Kazanma', '%$kazanmaOrani', Icons.trending_up, Colors.purpleAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _xpBolumu(int seviye, int xp) {
    final sonraki = seviye * 5000;
    final oran = sonraki == 0 ? 0.0 : (xp / sonraki).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Text('Seviye $seviye', style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            Text('$xp / $sonraki XP'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: oran,
            backgroundColor: Colors.white.withOpacity(.15),
            color: Colors.lightBlueAccent,
          ),
        ),
      ],
    );
  }

  Widget _istatistik(String title, String value, IconData icon, Color color) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
