import 'dart:math';

import 'package:flutter/material.dart';


class KlasikOkeyPage extends StatefulWidget {
  const KlasikOkeyPage({super.key});

  @override
  State<KlasikOkeyPage> createState() => _KlasikOkeyPageState();
}

enum _KlasikRenk { mavi, sari, kirmizi, siyah, sahte }

class _KlasikTas {
  final String id;
  final int? sayi;
  final _KlasikRenk renk;
  final bool sahteOkey;

  const _KlasikTas({
    required this.id,
    required this.sayi,
    required this.renk,
    this.sahteOkey = false,
  });
}

class _KlasikOkeyPageState extends State<KlasikOkeyPage> {
  static const int _rackKapasite = 30;
  static const double _tasW = 31;
  static const double _tasH = 45;

  final List<_KlasikTas?> _istaka = List<_KlasikTas?>.filled(_rackKapasite, null);
  final Map<String, List<_KlasikTas>> _botElleri = <String, List<_KlasikTas>>{};
  final Map<String, List<_KlasikTas>> _atilanlar = <String, List<_KlasikTas>>{};
  final List<String> _oyuncular = <String>['sen', 'bot3', 'bot2', 'bot1'];
  final Map<String, String> _adlar = const <String, String>{
    'sen': 'Sen',
    'bot1': 'Bot 1',
    'bot2': 'Bot 2',
    'bot3': 'Bot 3',
  };

  List<_KlasikTas> _deste = <_KlasikTas>[];
  _KlasikTas? _gosterge;
  _KlasikTas? _okey;
  String _durum = 'Klasik okey salonu hazır. Masa açıp tek kişilik bot testine başlayabilirsin.';
  String _aktifOyuncu = 'sen';
  String? _baslayan;
  String? _seciliTasId;
  bool _masaAcildi = false;
  bool _turdaTasAlindi = false;
  bool _oyunBitti = false;

  void _masaAc() {
    final taslar = _desteOlustur()..shuffle();
    final gostergeIndex = taslar.indexWhere((t) => !t.sahteOkey && t.sayi != null);
    final gosterge = taslar.removeAt(gostergeIndex < 0 ? 0 : gostergeIndex);
    final okey = _okeyHesapla(gosterge);

    final baslayan = _oyuncular[Random().nextInt(_oyuncular.length)];
    final botElleri = <String, List<_KlasikTas>>{};
    final atilanlar = <String, List<_KlasikTas>>{};

    for (final oyuncu in _oyuncular) {
      final adet = oyuncu == baslayan ? 15 : 14;
      final el = taslar.take(adet).toList();
      taslar.removeRange(0, adet);
      if (oyuncu == 'sen') {
        _istakaTemizle();
        for (var i = 0; i < el.length && i < _istaka.length; i++) {
          _istaka[i] = el[i];
        }
      } else {
        botElleri[oyuncu] = el;
      }
      atilanlar[oyuncu] = <_KlasikTas>[];
    }

    setState(() {
      _deste = taslar;
      _gosterge = gosterge;
      _okey = okey;
      _botElleri
        ..clear()
        ..addAll(botElleri);
      _atilanlar
        ..clear()
        ..addAll(atilanlar);
      _aktifOyuncu = baslayan;
      _baslayan = baslayan;
      _turdaTasAlindi = baslayan == 'sen';
      _seciliTasId = null;
      _oyunBitti = false;
      _masaAcildi = true;
      _durum = baslayan == 'sen'
          ? 'Masa açıldı. Başlayan sensin; 15 taşın var, taş atarak başla.'
          : 'Masa açıldı. Başlayan ${_adlar[baslayan]}. Botlar oynuyor.';
      _otomatikDiz(sadeceGorsel: true);
    });

    if (baslayan != 'sen') _botlariOynat();
  }

  void _istakaTemizle() {
    for (var i = 0; i < _istaka.length; i++) {
      _istaka[i] = null;
    }
  }

  List<_KlasikTas> _desteOlustur() {
    final taslar = <_KlasikTas>[];
    for (final renk in [_KlasikRenk.mavi, _KlasikRenk.sari, _KlasikRenk.kirmizi, _KlasikRenk.siyah]) {
      for (var kopya = 1; kopya <= 2; kopya++) {
        for (var sayi = 1; sayi <= 13; sayi++) {
          taslar.add(_KlasikTas(id: '${renk.name}_${sayi}_$kopya', sayi: sayi, renk: renk));
        }
      }
    }
    taslar.add(const _KlasikTas(id: 'sahte_okey_1', sayi: null, renk: _KlasikRenk.sahte, sahteOkey: true));
    taslar.add(const _KlasikTas(id: 'sahte_okey_2', sayi: null, renk: _KlasikRenk.sahte, sahteOkey: true));
    return taslar;
  }

  _KlasikTas _okeyHesapla(_KlasikTas gosterge) {
    final sayi = gosterge.sayi ?? 1;
    return _KlasikTas(
      id: 'okey_${gosterge.renk.name}_${sayi == 13 ? 1 : sayi + 1}',
      sayi: sayi == 13 ? 1 : sayi + 1,
      renk: gosterge.renk,
    );
  }

  bool _gercekOkeyMi(_KlasikTas tas) {
    final okey = _okey;
    return okey != null && !tas.sahteOkey && tas.sayi == okey.sayi && tas.renk == okey.renk;
  }

  int? _hesapSayi(_KlasikTas tas) {
    if (tas.sahteOkey) return _okey?.sayi;
    return tas.sayi;
  }

  _KlasikRenk _hesapRenk(_KlasikTas tas) {
    if (tas.sahteOkey) return _okey?.renk ?? _KlasikRenk.sahte;
    return tas.renk;
  }

  void _tasCek() {
    if (!_masaAcildi || _oyunBitti) return;
    if (_aktifOyuncu != 'sen') {
      _mesaj('Sıra sende değil.');
      return;
    }
    if (_turdaTasAlindi) {
      _mesaj('Bu tur taş aldın. Şimdi taş atmalısın.');
      return;
    }
    if (_deste.isEmpty) {
      setState(() {
        _oyunBitti = true;
        _durum = 'Deste bitti. Klasik test eli kapandı.';
      });
      return;
    }
    final bos = _istaka.indexWhere((t) => t == null);
    if (bos == -1) {
      _mesaj('Istaka dolu. Önce taş at.');
      return;
    }
    setState(() {
      _istaka[bos] = _deste.removeAt(0);
      _turdaTasAlindi = true;
      _durum = 'Desteden taş aldın. Şimdi taş at.';
    });
  }

  void _soldanAtikAl() {
    if (!_masaAcildi || _oyunBitti) return;
    if (_aktifOyuncu != 'sen') {
      _mesaj('Sıra sende değil.');
      return;
    }
    if (_turdaTasAlindi) {
      _mesaj('Bu tur taş aldın. Şimdi taş atmalısın.');
      return;
    }
    final onceki = _oncekiOyuncu('sen');
    final liste = _atilanlar[onceki];
    if (liste == null || liste.isEmpty) {
      _mesaj('Alınacak atılan taş yok.');
      return;
    }
    final bos = _istaka.indexWhere((t) => t == null);
    if (bos == -1) {
      _mesaj('Istaka dolu. Önce taş at.');
      return;
    }
    setState(() {
      _istaka[bos] = liste.removeLast();
      _turdaTasAlindi = true;
      _durum = 'Atılan taşı aldın. Şimdi taş at.';
    });
  }

  void _tasAt() {
    if (!_masaAcildi || _oyunBitti) return;
    if (_aktifOyuncu != 'sen') {
      _mesaj('Sıra sende değil.');
      return;
    }
    if (!_turdaTasAlindi) {
      _mesaj('Taş atmadan önce desteden veya atıktan taş almalısın.');
      return;
    }
    final id = _seciliTasId;
    if (id == null) {
      _mesaj('Atmak için önce ıstakadan taş seç.');
      return;
    }
    final index = _istaka.indexWhere((t) => t?.id == id);
    if (index == -1) return;

    final eldeki = _eldekiTaslar();
    final bitirmeEli = List<_KlasikTas>.from(eldeki)..removeWhere((t) => t.id == id);
    final biterMi = bitirmeEli.length == 14 && _kazananElMi(bitirmeEli);

    setState(() {
      final tas = _istaka[index];
      if (tas == null) return;
      _istaka[index] = null;
      _atilanlar.putIfAbsent('sen', () => <_KlasikTas>[]).add(tas);
      _seciliTasId = null;
      if (biterMi) {
        _oyunBitti = true;
        _durum = 'Tebrikler! 14 taşı per yapıp son taşı attın. Klasik okey eli bitti.';
      } else {
        _aktifOyuncu = _sonrakiOyuncu('sen');
        _turdaTasAlindi = false;
        _durum = 'Taş attın. Sıra ${_adlar[_aktifOyuncu]} oyuncusunda.';
      }
    });
    if (!biterMi) _botlariOynat();
  }

  void _botlariOynat() {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_masaAcildi || _oyunBitti || _aktifOyuncu == 'sen') return;
      final bot = _aktifOyuncu;
      final el = _botElleri[bot];
      if (el == null || el.isEmpty) return;

      final baslayanIlkAtis = bot == _baslayan && el.length == 15;
      if (!baslayanIlkAtis && _deste.isNotEmpty && el.length < 15) {
        el.add(_deste.removeAt(0));
      }

      final atilacak = _botAtilacakIndex(el);
      final bitirmeEli = List<_KlasikTas>.from(el)..removeAt(atilacak);
      final biterMi = bitirmeEli.length == 14 && _kazananElMi(bitirmeEli);
      final atilan = el.removeAt(atilacak);

      setState(() {
        _atilanlar.putIfAbsent(bot, () => <_KlasikTas>[]).add(atilan);
        if (biterMi) {
          _oyunBitti = true;
          _durum = '${_adlar[bot]} eli bitirdi. Yeni masa açarak tekrar deneyebilirsin.';
        } else {
          _aktifOyuncu = _sonrakiOyuncu(bot);
          _turdaTasAlindi = _aktifOyuncu == 'sen' ? false : false;
          _durum = '${_adlar[bot]} taş attı. Sıra ${_adlar[_aktifOyuncu]} oyuncusunda.';
        }
      });

      if (!biterMi && _aktifOyuncu != 'sen') {
        _botlariOynat();
      }
    });
  }

  int _botAtilacakIndex(List<_KlasikTas> el) {
    var secilen = 0;
    var enDusuk = 99999;
    for (var i = 0; i < el.length; i++) {
      final t = el[i];
      var skor = t.sayi ?? 0;
      if (_gercekOkeyMi(t)) skor += 10000;
      if (t.sahteOkey) skor += 5000;
      for (final d in el) {
        if (d.id == t.id || d.sayi == null || t.sayi == null) continue;
        if (d.sayi == t.sayi && d.renk != t.renk) skor += 35;
        if (d.renk == t.renk && ((d.sayi! - t.sayi!).abs() <= 2)) skor += 30;
      }
      if (skor < enDusuk) {
        enDusuk = skor;
        secilen = i;
      }
    }
    return secilen;
  }

  String _sonrakiOyuncu(String oyuncu) {
    final index = _oyuncular.indexOf(oyuncu);
    return _oyuncular[(index + 1) % _oyuncular.length];
  }

  String _oncekiOyuncu(String oyuncu) {
    final index = _oyuncular.indexOf(oyuncu);
    return _oyuncular[(index - 1 + _oyuncular.length) % _oyuncular.length];
  }

  List<_KlasikTas> _eldekiTaslar() => _istaka.whereType<_KlasikTas>().toList();

  void _otomatikDiz({bool sadeceGorsel = false}) {
    void uygula() {
      final taslar = _eldekiTaslar().toList()
        ..sort((a, b) {
          final renk = _hesapRenk(a).index.compareTo(_hesapRenk(b).index);
          if (renk != 0) return renk;
          final sayi = (_hesapSayi(a) ?? 99).compareTo(_hesapSayi(b) ?? 99);
          if (sayi != 0) return sayi;
          return a.id.compareTo(b.id);
        });
      for (var i = 0; i < _istaka.length; i++) {
        _istaka[i] = i < taslar.length ? taslar[i] : null;
      }
    }

    if (sadeceGorsel) {
      uygula();
    } else {
      setState(uygula);
    }
  }

  bool _kazananElMi(List<_KlasikTas> taslar) {
    if (taslar.length != 14) return false;
    final memo = <String, bool>{};
    bool ara(List<_KlasikTas> kalan) {
      if (kalan.isEmpty) return true;
      final key = kalan.map((e) => e.id).toList()..sort();
      final memoKey = key.join('|');
      final eski = memo[memoKey];
      if (eski != null) return eski;

      final ilk = kalan.first;
      final adaylar = _ilkTasinPerAdaylari(ilk, kalan);
      for (final aday in adaylar) {
        final ids = aday.map((e) => e.id).toSet();
        final yeni = kalan.where((t) => !ids.contains(t.id)).toList();
        if (ara(yeni)) {
          memo[memoKey] = true;
          return true;
        }
      }
      memo[memoKey] = false;
      return false;
    }

    return ara(List<_KlasikTas>.from(taslar));
  }

  List<List<_KlasikTas>> _ilkTasinPerAdaylari(_KlasikTas ilk, List<_KlasikTas> kalan) {
    final adaylar = <List<_KlasikTas>>[];
    final jokerler = kalan.where((t) => _gercekOkeyMi(t)).toList();
    final normal = kalan.where((t) => !_gercekOkeyMi(t)).toList();

    List<_KlasikTas> tamamla(List<_KlasikTas> secilen, int gerekenJoker) {
      if (gerekenJoker <= 0) return secilen;
      if (jokerler.length < gerekenJoker) return const <_KlasikTas>[];
      return <_KlasikTas>[...secilen, ...jokerler.take(gerekenJoker)];
    }

    final ilkSayi = _hesapSayi(ilk);
    final ilkRenk = _hesapRenk(ilk);
    if (ilkSayi == null) return adaylar;

    // Aynı sayı, farklı renk grup adayları.
    final ayniSayi = normal.where((t) => _hesapSayi(t) == ilkSayi).toList();
    final renkMap = <_KlasikRenk, _KlasikTas>{};
    for (final t in ayniSayi) {
      renkMap.putIfAbsent(_hesapRenk(t), () => t);
    }
    if (renkMap.containsKey(ilkRenk)) {
      final secilenler = renkMap.values.toList();
      for (final uzunluk in <int>[4, 3]) {
        if (secilenler.length >= uzunluk) {
          adaylar.add(secilenler.take(uzunluk).toList());
        } else if (secilenler.length < uzunluk && secilenler.contains(ilk)) {
          final tamam = tamamla(secilenler, uzunluk - secilenler.length);
          if (tamam.length == uzunluk) adaylar.add(tamam);
        }
      }
    }

    // Aynı renk sıralı adaylar. 13-1 kabul edilir, 13-1-2 kabul edilmez.
    for (var bas = 1; bas <= 13; bas++) {
      for (var uzunluk = 3; uzunluk <= 5; uzunluk++) {
        final sayilar = List<int>.generate(uzunluk, (i) {
          final deger = bas + i;
          return deger == 14 ? 1 : deger;
        });
        if (sayilar.contains(2) && sayilar.contains(13) && sayilar.contains(1)) continue;
        if (!sayilar.contains(ilkSayi)) continue;
        final secilen = <_KlasikTas>[];
        var eksik = 0;
        for (final sayi in sayilar) {
          final tas = normal.firstWhere(
            (t) => !secilen.any((s) => s.id == t.id) && _hesapRenk(t) == ilkRenk && _hesapSayi(t) == sayi,
            orElse: () => const _KlasikTas(id: 'bos', sayi: null, renk: _KlasikRenk.sahte),
          );
          if (tas.sayi == null) {
            eksik++;
          } else {
            secilen.add(tas);
          }
        }
        if (!secilen.any((t) => t.id == ilk.id) && !_gercekOkeyMi(ilk)) continue;
        final tamam = tamamla(secilen, eksik);
        if (tamam.length == uzunluk && tamam.any((t) => t.id == ilk.id)) adaylar.add(tamam);
      }
    }

    return adaylar;
  }

  void _mesaj(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff06141f),
      appBar: AppBar(
        title: const Text('Klasik Okey'),
        backgroundColor: const Color(0xff102446),
        actions: [
          TextButton.icon(
            onPressed: _masaAc,
            icon: const Icon(Icons.add, color: Colors.amber),
            label: const Text('Masa Aç', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final rackW = w < 760 ? w - 150 : 650.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -.12),
                    radius: 1.1,
                    colors: [Color(0xff08725f), Color(0xff064436), Color(0xff031d23), Color(0xff01070c)],
                  ),
                ),
              ),
              Positioned(left: 12, top: 12, child: _bilgiKutusu()),
              Positioned(top: 28, left: 0, right: 0, child: Center(child: _oyuncuKarti('bot2'))),
              Positioned(left: 45, top: h * .40, child: _yanOyuncu('bot1')),
              Positioned(right: 45, top: h * .40, child: _yanOyuncu('bot3')),
              Positioned(
                top: h * .28,
                left: w * .32,
                right: w * .32,
                child: _ortaAlan(),
              ),
              Positioned(
                bottom: 128,
                left: 0,
                right: 0,
                child: Center(child: _oyuncuKarti('sen')),
              ),
              Positioned(
                bottom: 18,
                left: (w - rackW) / 2,
                width: rackW,
                child: _istakaWidget(),
              ),
              Positioned(
                bottom: 42,
                right: max(12.0, (w - rackW) / 2 - 96),
                child: Column(
                  children: [
                    _kucukButon('Diz', Icons.sort, _masaAcildi ? () => _otomatikDiz() : null),
                    const SizedBox(height: 8),
                    _kucukButon('Taş at', Icons.upload, _masaAcildi ? _tasAt : null),
                  ],
                ),
              ),
              Positioned(
                bottom: 42,
                left: max(12.0, (w - rackW) / 2 - 96),
                child: Column(
                  children: [
                    _kucukButon('Çek', Icons.download, _masaAcildi ? _tasCek : null),
                    const SizedBox(height: 8),
                    _kucukButon('Atığı al', Icons.undo, _masaAcildi ? _soldanAtikAl : null),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 100,
                child: Text(
                  _durum,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bilgiKutusu() {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: _panelDekor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Klasik Test', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Sıra: ${_adlar[_aktifOyuncu] ?? _aktifOyuncu}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('Deste: ${_deste.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('El: ${_eldekiTaslar().length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _ortaAlan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _panelDekor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ortaTasKolonu('Deste', _desteKarti()),
              const SizedBox(width: 18),
              _ortaTasKolonu('Gösterge', _gosterge == null ? _bosTas() : _tasWidget(_gosterge!, false)),
              const SizedBox(width: 18),
              _ortaTasKolonu('Okey', _okey == null ? _bosTas() : _tasWidget(_okey!, false)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Amaç: 14 taşı per yapıp 15. taşı atarak bitmek', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _ortaTasKolonu(String text, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _desteKarti() {
    final aktif = _masaAcildi && !_oyunBitti && _aktifOyuncu == 'sen' && !_turdaTasAlindi;
    return GestureDetector(
      onDoubleTap: aktif ? _tasCek : null,
      child: Container(
        width: 44,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xff1a3565),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: aktif ? Colors.amber : Colors.white24, width: aktif ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: const Text('OKEY', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _yanOyuncu(String id) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _oyuncuKarti(id),
        const SizedBox(height: 10),
        _atikKutusu(id),
      ],
    );
  }

  Widget _oyuncuKarti(String id) {
    final aktif = _masaAcildi && !_oyunBitti && _aktifOyuncu == id;
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: aktif ? Colors.amber.withOpacity(.24) : Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aktif ? Colors.amber : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(id == 'sen' ? Icons.person : Icons.smart_toy, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(_adlar[id] ?? id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _atikKutusu(String id) {
    final tas = (_atilanlar[id] ?? const <_KlasikTas>[]).isEmpty ? null : _atilanlar[id]!.last;
    return Container(
      width: 62,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.black.withOpacity(.34), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
      child: tas == null ? const Text('Atık', style: TextStyle(color: Colors.white38, fontSize: 11)) : _tasWidget(tas, false),
    );
  }

  Widget _istakaWidget() {
    final ust = _istaka.sublist(0, 15);
    final alt = _istaka.sublist(15, 30);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xff3b2109).withOpacity(.96), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(.42), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [_istakaSatir(ust, 0), const SizedBox(height: 4), _istakaSatir(alt, 15)]),
    );
  }

  Widget _istakaSatir(List<_KlasikTas?> taslar, int offset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(taslar.length, (i) {
        final index = offset + i;
        final tas = taslar[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: DragTarget<int>(
            onWillAccept: (data) => data != null,
            onAccept: (from) => _istakaTasTasi(from, index),
            builder: (context, candidate, rejected) {
              final child = GestureDetector(
                onTap: tas == null ? null : () => setState(() => _seciliTasId = tas.id),
                onDoubleTap: tas == null
                    ? null
                    : () {
                        setState(() => _seciliTasId = tas.id);
                        _tasAt();
                      },
                child: tas == null ? _bosTas(vurgulu: candidate.isNotEmpty) : _tasWidget(tas, tas.id == _seciliTasId),
              );
              if (tas == null) return child;
              return Draggable<int>(
                data: index,
                feedback: Material(color: Colors.transparent, child: _tasWidget(tas, true)),
                childWhenDragging: Opacity(opacity: .25, child: _bosTas(vurgulu: true)),
                child: child,
              );
            },
          ),
        );
      }),
    );
  }

  void _istakaTasTasi(int from, int to) {
    if (from == to || from < 0 || from >= _istaka.length || to < 0 || to >= _istaka.length) return;
    setState(() {
      final tas = _istaka[from];
      _istaka[from] = _istaka[to];
      _istaka[to] = tas;
      if (tas != null) _seciliTasId = tas.id;
    });
  }

  Widget _kucukButon(String text, IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 82,
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(text, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap == null ? Colors.black38 : Colors.black.withOpacity(.82),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          disabledBackgroundColor: Colors.black26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: onTap == null ? Colors.white24 : Colors.amber.withOpacity(.75))),
        ),
      ),
    );
  }

  Widget _tasWidget(_KlasikTas tas, bool selected) {
    final text = tas.sahteOkey ? 'J' : '${tas.sayi}';
    return Container(
      width: _tasW,
      height: _tasH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xfffff1a8) : const Color(0xfffff7de),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? Colors.amber.shade700 : Colors.black87, width: selected ? 2.3 : 1.15),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2.2, offset: Offset(1, 2))],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: tas.sahteOkey ? 17 : 16.5,
          fontWeight: FontWeight.w900,
          color: _renkColor(_hesapRenk(tas)),
          height: .95,
        ),
      ),
    );
  }

  Widget _bosTas({bool vurgulu = false}) {
    return Container(
      width: _tasW,
      height: _tasH,
      decoration: BoxDecoration(color: vurgulu ? Colors.amber.withOpacity(.18) : Colors.black.withOpacity(.16), borderRadius: BorderRadius.circular(6), border: Border.all(color: vurgulu ? Colors.amber : Colors.white12)),
    );
  }

  Color _renkColor(_KlasikRenk renk) {
    switch (renk) {
      case _KlasikRenk.mavi:
        return const Color(0xff0057d8);
      case _KlasikRenk.sari:
        return const Color(0xffc58a00);
      case _KlasikRenk.kirmizi:
        return const Color(0xffd01616);
      case _KlasikRenk.siyah:
        return Colors.black;
      case _KlasikRenk.sahte:
        return const Color(0xff4737d5);
    }
  }

  BoxDecoration _panelDekor() => BoxDecoration(
        color: Colors.black.withOpacity(.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(.38)),
      );
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
