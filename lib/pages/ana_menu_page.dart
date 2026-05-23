import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'app_pages.dart';
import 'create_room_page.dart';
import 'game_table_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'rooms_page.dart';

class AnaMenuPage extends StatelessWidget {
  final String kullaniciAdi;

  const AnaMenuPage({
    super.key,
    required this.kullaniciAdi,
  });

  Future<void> _cikisYap(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _git(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ad = user?.displayName ?? kullaniciAdi;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/menu_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(color: Colors.black.withOpacity(.08)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ekranYuksekligi = constraints.maxHeight;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: ekranYuksekligi),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Column(
                        children: [
                          _ustBar(context, ad, user?.email),

                          // Üstteki logoyu açık bırakmak için orta alan boş bırakıldı.
                          SizedBox(height: ekranYuksekligi < 780 ? 250 : 310),

                          _modKartlari(context),
                          const SizedBox(height: 14),
                          _hemenOyna(context),
                          const SizedBox(height: 16),
                          _acikOdalar(context),
                          const SizedBox(height: 14),
                          _altMenu(context),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ustBar(BuildContext context, String ad, String? email) {
    return Row(
      children: [
        InkWell(
          onTap: () => _git(context, const ProfilPage()),
          borderRadius: BorderRadius.circular(20),
          child: _profilKutusu(ad, email),
        ),
        const Spacer(),
        InkWell(
          onTap: () => _git(context, const CoinMagazasiPage()),
          borderRadius: BorderRadius.circular(18),
          child: _paraKutusu(),
        ),
        const SizedBox(width: 12),
        _yuvarlakButon(
          icon: Icons.card_giftcard,
          label: 'Ödül',
          onTap: () => _git(context, const GunlukOdulPage()),
        ),
        const SizedBox(width: 10),
        _yuvarlakButon(
          icon: Icons.notifications,
          label: 'Bildirim',
          onTap: () => _git(context, const BildirimPage()),
          badge: true,
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: () => _cikisYap(context),
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Çıkış Yap',
        ),
      ],
    );
  }

  Widget _modKartlari(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 14,
      children: [
        _modKarti(
          title: '101 OYNA',
          subtitle: 'Klasik 101 oyun odaları',
          icon: Icons.casino,
          color: Colors.blue,
          onTap: () => _git(context, const OdalarPage(oyunTuru: '101')),
        ),
        _modKarti(
          title: '81 OYNA',
          subtitle: '81 oyun modeli',
          icon: Icons.looks,
          color: Colors.greenAccent,
          onTap: () => _git(context, const OdalarPage(oyunTuru: '81')),
        ),
        _modKarti(
          title: 'KLASİK OKEY',
          subtitle: 'Klasik okey masaları',
          icon: Icons.grid_on,
          color: Colors.orangeAccent,
          onTap: () => _git(context, const KlasikOkeyPage()),
        ),
        _modKarti(
          title: 'ÖZEL ODA',
          subtitle: 'Kendi masanı oluştur',
          icon: Icons.star,
          color: Colors.redAccent,
          onTap: () => _git(context, const OdaOlusturPage()),
        ),
        _modKarti(
          title: 'VIP ODA',
          subtitle: 'Özel kurallı VIP masa',
          icon: Icons.workspace_premium,
          color: Colors.amber,
          onTap: () => _git(
            context,
            const OdaOlusturPage(
              baslangicOyunTuru: 'VIP',
              oyunTuruKilitli: true,
            ),
          ),
        ),
        _modKarti(
          title: 'TURNUVA',
          subtitle: 'Yakında aktif olacak',
          icon: Icons.emoji_events,
          color: Colors.purpleAccent,
          onTap: () => _git(context, const TurnuvaPage()),
        ),
      ],
    );
  }

  Widget _modKarti({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 165,
      height: 165,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 9),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.54),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(.75), width: 1.4),
              boxShadow: [
                BoxShadow(color: color.withOpacity(.18), blurRadius: 14),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 39),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.white70,
                      height: 1.16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hemenOyna(BuildContext context) {
    return SizedBox(
      width: 410,
      height: 66,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(38),
          onTap: () async {
            final service = RoomService();
            final roomId = await service.odaOlustur(
              oyunTuru: '101',
              oyunSekli: 'Tek',
              katlamali: true,
              yardimli: false,
              cezali: false,
              elSayisi: 11,
              girisUcreti: 10000,
              sifreli: false,
              sifre: '',
            );

            if (!context.mounted) return;

            _git(context, GameTablePage(roomId: roomId, cezali: false, oyunSekli: 'Tek', elSayisi: 11));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff704400),
                  Color(0xffffc44d),
                  Color(0xff704400),
                ],
              ),
              border: Border.all(color: Colors.amberAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.amber,
                  blurRadius: 20,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino, color: Colors.white, size: 31),
                SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HEMEN OYNA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '101 hızlı eşleşme odası aç',
                      style: TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(width: 18),
                Icon(Icons.chevron_right, color: Colors.white, size: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _acikOdalar(BuildContext context) {
    final service = RoomService();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.50),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(.18)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'AÇIK ODALAR',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                label: const Text('CANLI'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.acikOdalarStream(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              }

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Henüz açık oda yok. İlk odayı sen oluşturabilirsin.',
                  ),
                );
              }

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final doc in docs.take(4))
                    _odaKarti(
                      title: '${doc.data()['oyunTuru'] ?? '101'} ODA',
                      no:
                          'Kod: ${doc.data()['odaKodu'] ?? doc.id.substring(0, 6).toUpperCase()}',
                      kisi:
                          '${doc.data()['oyuncuSayisi'] ?? 1} / ${doc.data()['maxOyuncu'] ?? 4}',
                      coin: '${doc.data()['girisUcreti'] ?? 0}',
                      color: _odaRengi(doc.data()['oyunTuru'] ?? '101'),
                      onTap: () async {
                        try {
                          await service.odayaKatil(doc.id);

                          if (!context.mounted) return;

                          _git(context, GameTablePage(roomId: doc.id));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Odaya girilemedi: $e')),
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _odaRengi(String oyunTuru) {
    if (oyunTuru == '81') return Colors.green;
    if (oyunTuru == 'VIP') return Colors.amber;
    if (oyunTuru == 'OKEY') return Colors.orangeAccent;
    return Colors.blue;
  }

  Widget _odaKarti({
    required String title,
    required String no,
    required String kisi,
    required String coin,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 198,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.55)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(no, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 4),
              Text(kisi),
              const SizedBox(width: 12),
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(coin),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('KATIL'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _altMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.54),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _altItem(Icons.home, 'ANA MENÜ', Colors.amber, () {}),
          _altItem(
            Icons.person,
            'PROFİL',
            Colors.white70,
            () => _git(context, const ProfilPage()),
          ),
          _altItem(
            Icons.emoji_events,
            'SIRALAMA',
            Colors.white70,
            () => _git(context, const SiralamaPage()),
          ),
          _altItem(
            Icons.group,
            'ARKADAŞLAR',
            Colors.white70,
            () => _git(context, const ArkadaslarPage()),
          ),
          _altItem(
            Icons.settings,
            'AYARLAR',
            Colors.white70,
            () => _git(context, const AyarlarPage()),
          ),
        ],
      ),
    );
  }

  Widget _altItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilKutusu(String ad, String? email) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xff44326d),
            child: Icon(Icons.person, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (email != null)
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 145,
                child: LinearProgressIndicator(
                  value: .57,
                  color: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paraKutusu() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(.45)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.amber, size: 30),
          SizedBox(width: 8),
          Text(
            '29.500',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(width: 10),
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.green,
            child: Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _yuvarlakButon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.52),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(.35)),
                ),
                child: Icon(icon, color: Colors.amber, size: 28),
              ),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
          if (badge)
            const Positioned(
              right: 2,
              top: 1,
              child: CircleAvatar(radius: 7, backgroundColor: Colors.red),
            ),
        ],
      ),
    );
  }
}
