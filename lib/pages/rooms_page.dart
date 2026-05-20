import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'create_room_page.dart';
import 'game_table_page.dart';

class OdalarPage extends StatelessWidget {
  final String oyunTuru;

  const OdalarPage({
    super.key,
    required this.oyunTuru,
  });

  @override
  Widget build(BuildContext context) {
    final roomService = RoomService();

    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(
        title: Text('$oyunTuru Odaları'),
        backgroundColor: const Color(0xff102446),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OdaOlusturPage(
                    baslangicOyunTuru: oyunTuru,
                    oyunTuruKilitli: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, color: Colors.amber),
            label: const Text('Oda Aç', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: roomService.acikOdalarStream(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs
                  .where((doc) => (doc.data()['oyunTuru'] ?? '') == oyunTuru)
                  .toList() ??
              [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (docs.isEmpty) {
            return Center(
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.32),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber.withOpacity(.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_bar, color: Colors.amber, size: 70),
                    const SizedBox(height: 16),
                    Text(
                      '$oyunTuru için açık oda yok.',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'İlk odayı sen oluşturabilirsin.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OdaOlusturPage(
                              baslangicOyunTuru: oyunTuru,
                              oyunTuruKilitli: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Oda Oluştur'),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 240,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return _odaKarti(context, roomService, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _odaKarti(
    BuildContext context,
    RoomService service,
    String roomId,
    Map<String, dynamic> data,
  ) {
    final oyunTuru = data['oyunTuru'] ?? '101';
    final oyunSekli = data['oyunSekli'] ?? 'Tek';
    final katlamali = data['katlamali'] == true;
    final yardimli = data['yardimli'] == true;
    final ucret = data['girisUcreti'] ?? 0;
    final oyuncuSayisi = data['oyuncuSayisi'] ?? 1;
    final maxOyuncu = data['maxOyuncu'] ?? 4;
    final odaKodu = data['odaKodu'] ?? roomId.substring(0, 6).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.amber.withOpacity(.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$oyunTuru ODA',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.amber),
          ),
          const SizedBox(height: 8),
          Text('Kod: $odaKodu', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _etiket(oyunSekli),
              _etiket(katlamali ? 'Katlamalı' : 'Katlamasız'),
              _etiket(yardimli ? 'Yardımlı' : 'Yardımsız'),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 4),
              Text('$oyuncuSayisi / $maxOyuncu'),
              const SizedBox(width: 18),
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('$ucret'),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () async {
              try {
                await service.odayaKatil(roomId);

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameTablePage(roomId: roomId),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Odaya girilemedi: $e')),
                );
              }
            },
            child: const Text('KATIL'),
          ),
        ],
      ),
    );
  }

  Widget _etiket(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(.35)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
