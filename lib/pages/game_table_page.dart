import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';

enum TasRengi {
  mavi,
  sari,
  kirmizi,
  siyah,
  sahteOkey,
}

class OkeyTasi {
  final int? sayi;
  final TasRengi renk;
  final int kopyaNo;

  const OkeyTasi({
    required this.sayi,
    required this.renk,
    required this.kopyaNo,
  });

  bool get sahteOkeyMi => renk == TasRengi.sahteOkey;
}

class GameTablePage extends StatelessWidget {
  final String roomId;

  const GameTablePage({
    super.key,
    required this.roomId,
  });

  List<OkeyTasi> _standartOkeySetiOlustur() {
    final taslar = <OkeyTasi>[];

    for (final renk in [
      TasRengi.mavi,
      TasRengi.sari,
      TasRengi.kirmizi,
      TasRengi.siyah,
    ]) {
      for (int kopya = 1; kopya <= 2; kopya++) {
        for (int sayi = 1; sayi <= 13; sayi++) {
          taslar.add(OkeyTasi(sayi: sayi, renk: renk, kopyaNo: kopya));
        }
      }
    }

    taslar.add(const OkeyTasi(sayi: null, renk: TasRengi.sahteOkey, kopyaNo: 1));
    taslar.add(const OkeyTasi(sayi: null, renk: TasRengi.sahteOkey, kopyaNo: 2));

    return taslar;
  }

  List<OkeyTasi> _demoIstakaTaslari() {
    final tumTaslar = _standartOkeySetiOlustur();

    return [
      ...tumTaslar.where((t) => t.renk == TasRengi.mavi).take(7),
      ...tumTaslar.where((t) => t.renk == TasRengi.sari).take(5),
      ...tumTaslar.where((t) => t.renk == TasRengi.kirmizi).take(5),
      ...tumTaslar.where((t) => t.renk == TasRengi.siyah).take(4),
      ...tumTaslar.where((t) => t.sahteOkeyMi).take(1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final service = RoomService();

    return Scaffold(
      backgroundColor: const Color(0xff06141f),
      appBar: AppBar(
        title: const Text('Oyun Masası'),
        backgroundColor: const Color(0xff102446),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: service.odaStream(roomId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (data == null) {
            return const Center(child: Text('Oda bulunamadı.'));
          }

          final oyunTuru = data['oyunTuru'] ?? '101';
          final oyunSekli = data['oyunSekli'] ?? 'Tek';
          final katlamali = data['katlamali'] == true;
          final yardimli = data['yardimli'] == true;
          final oyuncuSayisi = data['oyuncuSayisi'] ?? 1;
          final maxOyuncu = data['maxOyuncu'] ?? 4;
          final odaKodu = data['odaKodu'] ?? roomId.substring(0, 6).toUpperCase();
          final oyuncular = List<String>.from(data['oyuncular'] ?? []);
          final oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});
          final oyunBasladi = data['oyunBasladi'] == true;

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Color(0xff0f564b),
                      Color(0xff08251f),
                      Color(0xff02090c),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _masaBilgi(oyunTuru, oyunSekli, katlamali, yardimli, odaKodu),
                      const SizedBox(height: 14),
                      _beklemeKontrolleri(
                        context: context,
                        service: service,
                        oyuncuSayisi: oyuncuSayisi,
                        maxOyuncu: maxOyuncu,
                        oyunBasladi: oyunBasladi,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: _oyuncularPaneli(oyuncular, oyuncuAdlari),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: _masaOrtasi(oyuncuSayisi, maxOyuncu, oyunBasladi),
                            ),
                          ],
                        ),
                      ),
                      _istakaAlani(),
                      const SizedBox(height: 12),
                      _altButonlar(yardimli),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _masaBilgi(
    String oyunTuru,
    String oyunSekli,
    bool katlamali,
    bool yardimli,
    String odaKodu,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Text(
            '$oyunTuru MASA',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
          ),
          const Spacer(),
          Text('Kod: $odaKodu'),
          const SizedBox(width: 18),
          Text(oyunSekli),
          const SizedBox(width: 10),
          Text(katlamali ? 'Katlamalı' : 'Katlamasız'),
          const SizedBox(width: 10),
          Text(yardimli ? 'Yardımlı' : 'Yardımsız'),
        ],
      ),
    );
  }

  Widget _beklemeKontrolleri({
    required BuildContext context,
    required RoomService service,
    required int oyuncuSayisi,
    required int maxOyuncu,
    required bool oyunBasladi,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: oyuncuSayisi >= maxOyuncu
              ? null
              : () async {
                  try {
                    await service.botEkle(roomId);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bot eklenemedi: $e')),
                    );
                  }
                },
          icon: const Icon(Icons.smart_toy),
          label: const Text('Bot Ekle'),
        ),
        ElevatedButton.icon(
          onPressed: oyunBasladi
              ? null
              : () async {
                  try {
                    await service.oyunuBaslat(roomId);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Oyun başlatılamadı: $e')),
                    );
                  }
                },
          icon: const Icon(Icons.play_arrow),
          label: Text(oyunBasladi ? 'Oyun Başladı' : 'Oyunu Başlat'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await service.masadanCik(roomId);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Masadan Çık'),
        ),
      ],
    );
  }

  Widget _oyuncularPaneli(List<String> oyuncular, Map<String, dynamic> oyuncuAdlari) {
    final slots = List<String?>.filled(4, null);

    for (int i = 0; i < oyuncular.length && i < 4; i++) {
      slots[i] = oyuncular[i];
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        for (int i = 0; i < slots.length; i++)
          _oyuncuKarti(
            slots[i] == null ? 'Boş Koltuk' : '${oyuncuAdlari[slots[i]] ?? 'Oyuncu'}',
            slots[i] == null,
            i,
          ),
      ],
    );
  }

  Widget _oyuncuKarti(String ad, bool bos, int index) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bos ? Colors.black.withOpacity(.22) : Colors.black.withOpacity(.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bos ? Colors.white24 : Colors.amber.withOpacity(.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: bos ? Colors.grey.shade700 : const Color(0xff44326d),
            child: Icon(
              bos ? Icons.chair : (ad.startsWith('Bot') ? Icons.smart_toy : Icons.person),
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              ad,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: bos ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _masaOrtasi(int oyuncuSayisi, int maxOyuncu, bool oyunBasladi) {
    return Container(
      width: 420,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.28),
        borderRadius: BorderRadius.circular(120),
        border: Border.all(color: Colors.amber.withOpacity(.38), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              oyunBasladi ? Icons.sports_esports : Icons.table_bar,
              color: Colors.amber,
              size: 54,
            ),
            const SizedBox(height: 10),
            Text(
              oyunBasladi ? 'Oyun Başladı' : 'Oyuncular: $oyuncuSayisi / $maxOyuncu',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              oyunBasladi
                  ? 'Şimdi taş sistemi ve sıra mantığını bağlayacağız.'
                  : 'Bot ekleyerek tek başına test edebilirsin.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _istakaAlani() {
    final taslar = _demoIstakaTaslari();
    final ustSira = taslar.take(11).toList();
    final altSira = taslar.skip(11).take(11).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xff2a1608).withOpacity(.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(.48), width: 1.4),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          _istakaSira(ustSira),
          const SizedBox(height: 8),
          _istakaSira(altSira),
        ],
      ),
    );
  }

  Widget _istakaSira(List<OkeyTasi> taslar) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tas in taslar) ...[
            _tasWidget(tas),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }

  Widget _tasWidget(OkeyTasi tas) {
    final renk = _tasYaziRengi(tas.renk);

    return Container(
      width: 48,
      height: 66,
      decoration: BoxDecoration(
        color: const Color(0xfffff8e5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.black.withOpacity(.45), width: 1.1),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              tas.sahteOkeyMi ? '★' : '${tas.sayi}',
              style: TextStyle(
                color: renk,
                fontSize: tas.sahteOkeyMi ? 30 : 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 13,
                height: 5,
                decoration: BoxDecoration(
                  color: renk,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _tasYaziRengi(TasRengi renk) {
    switch (renk) {
      case TasRengi.mavi:
        return Colors.blue;
      case TasRengi.sari:
        return const Color(0xffd49a00);
      case TasRengi.kirmizi:
        return Colors.red;
      case TasRengi.siyah:
        return Colors.black;
      case TasRengi.sahteOkey:
        return Colors.purple;
    }
  }

  Widget _altButonlar(bool yardimli) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        _aksiyonButonu('Taş Çek', Icons.download),
        _aksiyonButonu('Taş At', Icons.upload),
        _aksiyonButonu('Per Aç', Icons.grid_view),
        _aksiyonButonu('Çift Aç', Icons.filter_2),
        _aksiyonButonu(
          yardimli ? 'Oto İşle' : 'Taş İşle',
          yardimli ? Icons.auto_fix_high : Icons.handyman,
        ),
        _aksiyonButonu('Bit', Icons.flag),
      ],
    );
  }

  Widget _aksiyonButonu(String text, IconData icon) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }
}
