import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'game_table_page.dart';

class OdaOlusturPage extends StatefulWidget {
  final String baslangicOyunTuru;
  final bool oyunTuruKilitli;

  const OdaOlusturPage({
    super.key,
    this.baslangicOyunTuru = '101',
    this.oyunTuruKilitli = false,
  });

  @override
  State<OdaOlusturPage> createState() => _OdaOlusturPageState();
}

class _OdaOlusturPageState extends State<OdaOlusturPage> {
  final RoomService _roomService = RoomService();
  final TextEditingController sifreController = TextEditingController();

  late String oyunTuru;
  String oyunSekli = 'Tek';
  bool katlamali = true;
  bool yardimli = false;
  bool cezali = false;
  bool sifreli = false;
  int girisUcreti = 10000;
  int elSayisi = 11;
  bool yukleniyor = false;

  @override
  void initState() {
    super.initState();
    oyunTuru = widget.baslangicOyunTuru;
  }

  @override
  void dispose() {
    sifreController.dispose();
    super.dispose();
  }

  Future<void> _odaOlustur() async {
    if (sifreli && sifreController.text.trim().isEmpty) {
      _mesaj('Şifreli oda için şifre yazmalısın.');
      return;
    }

    setState(() => yukleniyor = true);

    try {
      final roomId = await _roomService.odaOlustur(
        oyunTuru: oyunTuru,
        oyunSekli: oyunSekli,
        katlamali: katlamali,
        yardimli: yardimli,
        cezali: cezali,
        elSayisi: elSayisi,
        girisUcreti: girisUcreti,
        sifreli: sifreli,
        sifre: sifreController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameTablePage(roomId: roomId, cezali: cezali, yardimli: yardimli, oyunSekli: oyunSekli, elSayisi: elSayisi),
        ),
      );
    } catch (e) {
      _mesaj('Oda oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  void _mesaj(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String get _sayfaBaslik {
    if (widget.oyunTuruKilitli) {
      return '$oyunTuru Odası Oluştur';
    }
    return 'Özel Oda Oluştur';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff071827),
      appBar: AppBar(
        title: Text(_sayfaBaslik),
        backgroundColor: const Color(0xff102446),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: 620,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.35),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.amber.withOpacity(.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.oyunTuruKilitli ? '$oyunTuru Masa Ayarları' : 'Masa Ayarları',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),

                if (!widget.oyunTuruKilitli) ...[
                  _baslik('Oyun Türü'),
                  _secimSatiri([
                    _secimButonu('101', oyunTuru == '101', () => setState(() => oyunTuru = '101')),
                    _secimButonu('81', oyunTuru == '81', () => setState(() => oyunTuru = '81')),
                  ]),
                  const SizedBox(height: 18),
                ],

                _baslik('Oyun Şekli'),
                _secimSatiri([
                  _secimButonu('Tek', oyunSekli == 'Tek', () => setState(() => oyunSekli = 'Tek')),
                  _secimButonu('Eşli', oyunSekli == 'Eşli', () => setState(() => oyunSekli = 'Eşli')),
                ]),
                const SizedBox(height: 18),



                _baslik('El Sayısı'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int sayi = 1; sayi <= 11; sayi++)
                      ChoiceChip(
                        selected: elSayisi == sayi,
                        label: Text('$sayi'),
                        onSelected: (_) => setState(() => elSayisi = sayi),
                        selectedColor: Colors.amber,
                        labelStyle: TextStyle(
                          color: elSayisi == sayi ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                _baslik('Kurallar'),
                SwitchListTile(
                  value: katlamali,
                  onChanged: (value) => setState(() => katlamali = value),
                  title: Text(katlamali ? 'Katlamalı' : 'Katlamasız'),
                  subtitle: const Text('Katlamalı / katlamasız seçimi'),
                  activeColor: Colors.amber,
                ),
                SwitchListTile(
                  value: yardimli,
                  onChanged: (value) => setState(() => yardimli = value),
                  title: Text(yardimli ? 'Yardımlı' : 'Yardımsız'),
                  subtitle: const Text('Yardımlı masada taşlar otomatik işlenebilir'),
                  activeColor: Colors.amber,
                ),
                SwitchListTile(
                  value: cezali,
                  onChanged: (value) => setState(() => cezali = value),
                  title: Text(cezali ? 'Cezalı' : 'Cezasız'),
                  subtitle: const Text('Cezalı / cezasız oyun seçimi'),
                  activeColor: Colors.amber,
                ),
                SwitchListTile(
                  value: sifreli,
                  onChanged: (value) => setState(() => sifreli = value),
                  title: Text(sifreli ? 'Şifreli Oda' : 'Şifresiz Oda'),
                  subtitle: const Text('Sadece şifreyi bilenler katılır'),
                  activeColor: Colors.amber,
                ),
                if (sifreli) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: sifreController,
                    decoration: InputDecoration(
                      labelText: 'Oda Şifresi',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.black.withOpacity(.25),
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                _baslik('Giriş Ücreti'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final ucret in [5000, 10000, 25000, 50000, 100000])
                      ChoiceChip(
                        selected: girisUcreti == ucret,
                        label: Text(ucret.toString()),
                        onSelected: (_) => setState(() => girisUcreti = ucret),
                        selectedColor: Colors.amber,
                        labelStyle: TextStyle(
                          color: girisUcreti == ucret ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: yukleniyor ? null : _odaOlustur,
                    icon: yukleniyor
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle),
                    label: Text(
                      yukleniyor ? 'Oda oluşturuluyor...' : 'Odayı Oluştur',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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

  Widget _baslik(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }

  Widget _secimSatiri(List<Widget> children) {
    return Row(
      children: [
        for (final child in children)
          Expanded(child: Padding(padding: const EdgeInsets.all(4), child: child)),
      ],
    );
  }

  Widget _secimButonu(String text, bool secili, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: secili ? Colors.amber : Colors.black.withOpacity(.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(.55)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: secili ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
