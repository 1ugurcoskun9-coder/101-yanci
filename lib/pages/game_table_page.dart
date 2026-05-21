import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'ana_menu_page.dart';
import 'app_pages.dart';

enum TasRengi { mavi, sari, kirmizi, siyah, sahteOkey, bos }

class OkeyTasi {
  final String id;
  final int? sayi;
  final TasRengi renk;
  final int kopyaNo;
  final bool sahteOkeyMi;
  final bool bosSlot;

  const OkeyTasi({
    required this.id,
    required this.sayi,
    required this.renk,
    required this.kopyaNo,
    required this.sahteOkeyMi,
    this.bosSlot = false,
  });

  factory OkeyTasi.bos() => const OkeyTasi(
        id: 'bos',
        sayi: null,
        renk: TasRengi.bos,
        kopyaNo: 0,
        sahteOkeyMi: false,
        bosSlot: true,
      );

  factory OkeyTasi.fromMap(Map<String, dynamic> map) {
    return OkeyTasi(
      id: '${map['id'] ?? '${map['renk']}_${map['sayi']}_${map['kopyaNo']}'}',
      sayi: map['sayi'] is int ? map['sayi'] as int : int.tryParse('${map['sayi']}'),
      renk: _renkFromString('${map['renk'] ?? 'mavi'}'),
      kopyaNo: map['kopyaNo'] is int ? map['kopyaNo'] as int : 1,
      sahteOkeyMi: map['sahteOkey'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sayi': sayi,
        'renk': _renkToString(renk),
        'kopyaNo': kopyaNo,
        'sahteOkey': sahteOkeyMi,
      };

  static TasRengi _renkFromString(String renk) {
    switch (renk) {
      case 'sari':
        return TasRengi.sari;
      case 'kirmizi':
        return TasRengi.kirmizi;
      case 'siyah':
        return TasRengi.siyah;
      case 'sahteOkey':
        return TasRengi.sahteOkey;
      case 'mavi':
      default:
        return TasRengi.mavi;
    }
  }

  static String _renkToString(TasRengi renk) {
    switch (renk) {
      case TasRengi.mavi:
        return 'mavi';
      case TasRengi.sari:
        return 'sari';
      case TasRengi.kirmizi:
        return 'kirmizi';
      case TasRengi.siyah:
        return 'siyah';
      case TasRengi.sahteOkey:
        return 'sahteOkey';
      case TasRengi.bos:
        return 'bos';
    }
  }
}

class GameTablePage extends StatefulWidget {
  final String roomId;
  final bool cezali;

  const GameTablePage({
    super.key,
    required this.roomId,
    this.cezali = false,
  });

  @override
  State<GameTablePage> createState() => _GameTablePageState();
}

class _GameTablePageState extends State<GameTablePage> {
  final RoomService _service = RoomService();
  static const int _istakaSiraKapasite = 18;
  static const int _istakaKapasite = _istakaSiraKapasite * 2;
  static const double _tasGenislik = 28;
  static const double _tasYukseklik = 41;
  final List<OkeyTasi?> _istaka = List<OkeyTasi?>.filled(_istakaKapasite, null);
  final Map<String, List<OkeyTasi>> _botElleri = <String, List<OkeyTasi>>{};
  final Map<String, List<OkeyTasi>> _atilanTaslar = <String, List<OkeyTasi>>{};
  final List<List<OkeyTasi>> _acilanSeriler = <List<OkeyTasi>>[];
  final List<List<OkeyTasi>> _acilanCiftler = <List<OkeyTasi>>[];


  List<String> _oyuncular = const <String>[];
  Map<String, String> _oyuncuAdlari = const <String, String>{};
  List<OkeyTasi> _ortaTaslar = <OkeyTasi>[];
  OkeyTasi? _gosterge;
  OkeyTasi? _okey;
  OkeyTasi? _geriBirakTasi;
  String? _geriBirakSahibi;
  String? _seciliTasId;
  bool _oyunBasladi = false;
  bool _ciftModu = false;
  bool _turdaTasCekildiMi = true;
  bool _islemYapiliyor = false;
  int _aktifOyuncuIndex = 0;
  int _seriToplam = 0;
  int _ciftSayisi = 0;
  int _timerKey = 0;
  Timer? _botTimer;
  Timer? _siraTimer;
  String _sonIslemMesaji = 'Botlar hazır, Test başlat bekleniyor';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _testBotlariniMasayaOturttur();
    });
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _siraTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final benimSiramsa = _oyunBasladi && _oyuncular.isNotEmpty && _oyuncular[_aktifOyuncuIndex] == uid;
    return Scaffold(
      backgroundColor: const Color(0xff06141f),
      body: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _arkaPlan(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.amber.withOpacity(.42), width: 2),
                    color: Colors.black.withOpacity(.08),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      // Profesyonel masa düzeni: Bot ıstakaları görünmez, masa alanı oyuncu odaklı açılır.
                      // Oyun mantığına dokunmuyoruz; sadece widget konumları değişiyor.
                      final userRackWidth = min(660.0, max(530.0, w * .52));
                      final userRackHeight = 106.0;
                      final bottomRackLeft = (w - userRackWidth) / 2;
                      final bottomRackBottom = 18.0;
                      final actionWidth = 82.0;
                      final leftActionLeft = max(14.0, bottomRackLeft - actionWidth - 22);
                      final rightActionLeft = min(w - actionWidth - 16, bottomRackLeft + userRackWidth + 22);
                      final actionBottom = bottomRackBottom + 22;
                      final playerCardBottom = bottomRackBottom + userRackHeight + 16;
                      final messageBottom = bottomRackBottom + userRackHeight + 2;
                      final tasIsleWidth = 92.0;
                      final tasIsleLeft = (bottomRackLeft + userRackWidth - tasIsleWidth - 8).clamp(12.0, w - tasIsleWidth - 12.0);
                      final tasIsleBottom = bottomRackBottom + userRackHeight + 8;

                      final ortaLeft = max(210.0, w * .23);
                      final ortaRight = max(210.0, w * .23);
                      final ortaTop = max(220.0, h * .25);
                      final ortaBottom = bottomRackBottom + userRackHeight + 128;

                      final topBotId = _oyuncular.length > 2 ? _oyuncular[2] : 'bot_2';
                      final leftBotId = _solRakipId();
                      final rightBotId = _oyuncular.length > 3 ? _oyuncular[3] : 'bot_3';

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(left: 14, top: 10, child: _barajKutusu()),
                          Positioned(top: 8, left: 0, right: 0, child: Center(child: _turKutusu(_oyunBasladi, benimSiramsa))),
                          Positioned(
                            right: 12,
                            top: 8,
                            child: Row(
                              children: [
                                _miniButon(_oyunBasladi ? 'Test yenile' : 'Test başlat', Icons.play_arrow, _testBaslat),
                                const SizedBox(width: 8),
                                _miniButon('Yaz boz', Icons.edit_note, _yazbozAc),
                                const SizedBox(width: 8),
                                _miniButon('Çıkış', Icons.logout, _cikisYap),
                                const SizedBox(width: 8),
                                _miniButon('Ayarlar', Icons.settings, _ayarlarAc),
                              ],
                            ),
                          ),

                          // Üst bot: profil ve hemen altında attığı taş.
                          Positioned(
                            top: 86,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _oyuncuKarti(2),
                                  const SizedBox(height: 10),
                                  _sonAtilanTasAlani(topBotId),
                                ],
                              ),
                            ),
                          ),

                          // Sol bot: profil ve hemen altında attığı taş.
                          Positioned(
                            left: 52,
                            top: max(210.0, h * .42),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _oyuncuKarti(1),
                                const SizedBox(height: 12),
                                _sonAtilanTasAlani(leftBotId, alinabilir: benimSiramsa),
                                const SizedBox(height: 8),
                                _miniButon('Geri bırak', Icons.undo, _geriBirakTasi != null ? _geriBirak : null),
                              ],
                            ),
                          ),

                          // Sağ bot: profil ve hemen altında attığı taş.
                          Positioned(
                            right: 52,
                            top: max(210.0, h * .42),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _oyuncuKarti(3),
                                const SizedBox(height: 12),
                                _sonAtilanTasAlani(rightBotId),
                              ],
                            ),
                          ),

                          Positioned(
                            left: ortaLeft,
                            right: ortaRight,
                            top: ortaTop,
                            bottom: ortaBottom,
                            child: _ortaAlan(),
                          ),

                          Positioned(left: 0, right: 0, bottom: playerCardBottom, child: Center(child: _oyuncuKarti(0))),

                          Positioned(
                            left: bottomRackLeft,
                            width: userRackWidth,
                            height: userRackHeight,
                            bottom: bottomRackBottom,
                            child: _benimIstaka(benimSiramsa: benimSiramsa),
                          ),

                          // Sol aksiyonlar: Seri aç / Çift aç. Atılan taş alanından ayrıldı.
                          Positioned(
                            left: leftActionLeft,
                            bottom: actionBottom,
                            child: _aksiyonButonKolonu([
                              _aksiyonButon('Seri aç', Icons.view_agenda, _oyunBasladi ? () => _elAc(false) : null),
                              _aksiyonButon('Çift aç', Icons.filter_2, _oyunBasladi ? () => _elAc(true) : null),
                            ], actionWidth),
                          ),

                          // Sağ aksiyonlar: Seri diz / Çift diz. Oyuncu ıstakasının sağında sabit.
                          Positioned(
                            left: rightActionLeft,
                            bottom: actionBottom,
                            child: _aksiyonButonKolonu([
                              _aksiyonButon('Seri diz', Icons.timeline, _oyunBasladi ? _seriDiz : null),
                              _aksiyonButon('Çift diz', Icons.grid_view, _oyunBasladi ? _ciftDiz : null),
                            ], actionWidth),
                          ),

                          // Oyuncunun attığı taş: sağ aksiyonların üstünde, ayrı kutu.
                          Positioned(
                            left: rightActionLeft,
                            bottom: actionBottom + 82,
                            width: actionWidth,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Atılan taş', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                _benimAtilanTasAlani(benimSiramsa),
                              ],
                            ),
                          ),

                          // Taş işle: Oyuncu profilinin altından alındı; ıstakanın sağ üst köşesine, sağdan sola doğru yerleştirildi.
                          Positioned(
                            left: tasIsleLeft,
                            bottom: tasIsleBottom,
                            width: tasIsleWidth,
                            child: _miniButon('Taş işle', Icons.add_circle, _oyunBasladi ? _tasIsle : null),
                          ),
                          Positioned(
                            left: bottomRackLeft,
                            width: userRackWidth,
                            bottom: messageBottom,
                            child: IgnorePointer(
                              child: Text(_sonIslemMesaji, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _arkaPlan() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.1),
          radius: 1.18,
          colors: [Color(0xff08725f), Color(0xff064436), Color(0xff031d23), Color(0xff01070c)],
        ),
      ),
    );
  }

  BoxDecoration _kutuDekor() => BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(.45)),
      );

  Widget _barajKutusu() {
    return Container(
      width: 172,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _kutuDekor(),
      child: Text(_ciftModu ? 'Çift $_ciftSayisi\\5' : 'Seri $_seriToplam\\101', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }

  Widget _turKutusu(bool oyunBasladi, bool benimSiramsa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: _kutuDekor(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _siraSaati(oyunBasladi && benimSiramsa),
          const SizedBox(width: 10),
          Text(
            !oyunBasladi ? '1. Tur   Başlat bekleniyor' : (benimSiramsa ? '1. Tur   Sıra sizde' : '1. Tur   Bot sırası'),
            style: TextStyle(color: oyunBasladi && benimSiramsa ? Colors.amber : Colors.white70, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _siraSaati(bool aktif) {
    if (!aktif) {
      return const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(value: 1, strokeWidth: 3, color: Colors.white24));
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('timer_$_timerKey'),
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(seconds: 30),
      onEnd: _sureDolduysaOtomatikTasAt,
      builder: (context, value, _) => SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(value: value, strokeWidth: 3, color: Colors.amber, backgroundColor: Colors.white24),
      ),
    );
  }

  Widget _miniButon(String text, IconData icon, VoidCallback? onPressed) {
    final aktif = onPressed != null;
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(text, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.black.withOpacity(.30),
          disabledForegroundColor: Colors.white38,
          backgroundColor: aktif ? Colors.black.withOpacity(.82) : Colors.black.withOpacity(.30),
          foregroundColor: Colors.white,
          elevation: aktif ? 4 : 0,
          shadowColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(86, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: aktif ? Colors.amber.withOpacity(.78) : Colors.white24),
          ),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }


  Widget _aksiyonButon(String text, IconData icon, VoidCallback? onPressed) {
    final aktif = onPressed != null;
    return SizedBox(
      height: 31,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 12),
        label: Text(text, overflow: TextOverflow.ellipsis),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.black.withOpacity(.28),
          disabledForegroundColor: Colors.white38,
          backgroundColor: aktif ? Colors.black.withOpacity(.82) : Colors.black.withOpacity(.28),
          foregroundColor: Colors.white,
          elevation: aktif ? 3 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          minimumSize: const Size(76, 31),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: aktif ? Colors.amber.withOpacity(.75) : Colors.white24),
          ),
          textStyle: const TextStyle(fontSize: 9.2, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _aksiyonButonKolonu(List<Widget> butonlar, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < butonlar.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            butonlar[i],
          ],
        ],
      ),
    );
  }

  Widget _oyuncuKarti(int index) {
    final varMi = index >= 0 && index < _oyuncular.length;
    final id = varMi ? _oyuncular[index] : '';
    final ad = varMi ? (_oyuncuAdlari[id] ?? 'Oyuncu') : 'Boş Koltuk';
    final aktif = varMi && _oyunBasladi && index == _aktifOyuncuIndex;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: aktif ? Colors.amber.withOpacity(.24) : Colors.black.withOpacity(.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: aktif ? Colors.amber : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(varMi ? Icons.person : Icons.event_seat, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(ad, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _rakipIstaka({required bool yatay}) {
    return Container(
      width: double.infinity,
      height: yatay ? 78 : double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xff2a1608).withOpacity(.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(.30)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: yatay
            ? SizedBox(width: 450, height: 58, child: _rakipIstakaYatay())
            : SizedBox(width: 48, height: 252, child: _rakipIstakaDikey()),
      ),
    );
  }

  Widget _rakipIstakaYatay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _rakipSlotSatiri(),
        const SizedBox(height: 4),
        _rakipSlotSatiri(),
      ],
    );
  }

  Widget _rakipSlotSatiri() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_istakaSiraKapasite, (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _rakipBosSlot(),
          )),
    );
  }

  Widget _rakipIstakaDikey() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _rakipSlotKolonu(),
        const SizedBox(width: 4),
        _rakipSlotKolonu(),
      ],
    );
  }

  Widget _rakipSlotKolonu() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_istakaSiraKapasite, (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: _rakipBosSlot(),
          )),
    );
  }

  Widget _rakipBosSlot() {
    return Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.16),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white10),
      ),
    );
  }

  Widget _ortaAlan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(.14), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _desteGostergeKolonu('Deste', _kapaliDesteKarti()),
              const SizedBox(width: 14),
              _desteGostergeKolonu('Gösterge', _gosterge == null ? _bosTas() : _tasWidget(_gosterge!, false)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_ortaTaslar.length} taş', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          _acilanTaslarAlani(),
        ],
      ),
    );
  }

  Widget _desteGostergeKolonu(String baslik, Widget kart) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(baslik, style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        SizedBox(width: 42, height: 56, child: Center(child: kart)),
      ],
    );
  }

  Widget _kapaliDesteKarti() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final benimSiramsa = _oyunBasladi && _oyuncular.isNotEmpty && _oyuncular[_aktifOyuncuIndex] == uid;
    final aktif = benimSiramsa && !_turdaTasCekildiMi;
    return Draggable<String>(
      data: aktif ? 'deste' : 'pasif',
      feedback: Material(color: Colors.transparent, child: _desteKartGorunumu(aktif: true)),
      childWhenDragging: Opacity(opacity: .35, child: _desteKartGorunumu(aktif: aktif)),
      child: GestureDetector(
        onDoubleTap: aktif ? () => _tasCek() : null,
        child: _desteKartGorunumu(aktif: aktif),
      ),
    );
  }

  Widget _desteKartGorunumu({required bool aktif}) {
    return Container(
      width: 42,
      height: 56,
      decoration: BoxDecoration(color: const Color(0xff1a3565), borderRadius: BorderRadius.circular(8), border: Border.all(color: aktif ? Colors.amber : Colors.amber.withOpacity(.45), width: aktif ? 2 : 1)),
      alignment: Alignment.center,
      child: const Text('101', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900)),
    );
  }

  Widget _benimIstaka({required bool benimSiramsa}) {
    final ust = _istaka.sublist(0, _istakaSiraKapasite);
    final alt = _istaka.sublist(_istakaSiraKapasite, _istakaKapasite);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xff3b2109).withOpacity(.96), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(.42), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [_istakaSira(ust, 0), const SizedBox(height: 4), _istakaSira(alt, _istakaSiraKapasite)]),
    );
  }

  Widget _istakaSira(List<OkeyTasi?> taslar, int offset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(taslar.length, (i) {
        final index = offset + i;
        final tas = taslar[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: DragTarget<String>(
            onWillAccept: (data) => _oyunBasladi && !_turdaTasCekildiMi && (data == 'deste' || (data?.startsWith('atilan:') ?? false)),
            onAccept: (data) {
              if (data == 'deste') {
                _tasCek(hedefIndex: index);
              } else if (data.startsWith('atilan:')) {
                _soldanTasAl(data.substring(7), hedefIndex: index);
              }
            },
            builder: (context, candidate, rejected) => InkWell(
              onTap: tas == null ? null : () => setState(() => _seciliTasId = tas.id),
              onDoubleTap: tas == null ? null : () { setState(() => _seciliTasId = tas.id); _tasAt(); },
              child: tas == null ? _bosTas(vurgulu: candidate.isNotEmpty) : _tasWidget(tas, tas.id == _seciliTasId),
            ),
          ),
        );
      }),
    );
  }

  Widget _benimAtilanTasAlani(bool benimSiramsa) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final sonAtilan = _sonAtilanTas(uid);
    final aktif = _oyunBasladi && benimSiramsa && _turdaTasCekildiMi && _seciliTasId != null;
    return InkWell(
      onTap: aktif ? _tasAt : null,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.black.withOpacity(.48), borderRadius: BorderRadius.circular(12), border: Border.all(color: aktif ? Colors.amber : Colors.white24)),
        child: sonAtilan == null ? const Text('Atılan\ntaş', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 10)) : _tasWidget(sonAtilan, false),
      ),
    );
  }

  Widget _sonAtilanTasAlani(String oyuncuId, {bool alinabilir = false}) {
    final tas = _sonAtilanTas(oyuncuId);
    final aktif = alinabilir && tas != null && _oyunBasladi && !_turdaTasCekildiMi;
    return GestureDetector(
      onDoubleTap: aktif ? () => _soldanTasAl(oyuncuId) : null,
      child: Draggable<String>(
        data: aktif ? 'atilan:$oyuncuId' : 'pasif',
        feedback: Material(color: Colors.transparent, child: tas == null ? _bosTas() : _tasWidget(tas, false)),
        childWhenDragging: Opacity(opacity: .35, child: _atilanTasKutusu(tas, aktif)),
        child: _atilanTasKutusu(tas, aktif),
      ),
    );
  }

  Widget _atilanTasKutusu(OkeyTasi? tas, bool aktif) {
    return Container(width: 58, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black.withOpacity(.28), borderRadius: BorderRadius.circular(10), border: Border.all(color: aktif ? Colors.amber : Colors.white24)), child: tas == null ? const Icon(Icons.crop_square, color: Colors.white38, size: 16) : _tasWidget(tas, false));
  }

  OkeyTasi? _sonAtilanTas(String oyuncuId) {
    final liste = _atilanTaslar[oyuncuId] ?? const <OkeyTasi>[];
    if (liste.isEmpty) return null;
    return liste.last;
  }

  Widget _tasWidget(OkeyTasi tas, bool selected) {
    if (tas.bosSlot) return _bosTas();
    return Container(
      width: _tasGenislik,
      height: _tasYukseklik,
      decoration: BoxDecoration(
        color: selected ? const Color(0xfffff0a6) : const Color(0xfff5e3bb),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? Colors.amber : Colors.black26, width: selected ? 2 : 1),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(1, 2))],
      ),
      alignment: Alignment.center,
      child: Text(tas.sahteOkeyMi ? 'J' : '${tas.sayi}', style: TextStyle(fontSize: tas.sahteOkeyMi ? 15 : 13, fontWeight: FontWeight.w900, color: _tasYaziRengi(tas.renk))),
    );
  }

  Widget _bosTas({bool vurgulu = false}) {
    return Container(width: _tasGenislik, height: _tasYukseklik, decoration: BoxDecoration(color: vurgulu ? Colors.amber.withOpacity(.18) : Colors.black.withOpacity(.16), borderRadius: BorderRadius.circular(6), border: Border.all(color: vurgulu ? Colors.amber : Colors.white12)));
  }

  Color _tasYaziRengi(TasRengi renk) {
    switch (renk) {
      case TasRengi.mavi:
        return Colors.blue.shade700;
      case TasRengi.sari:
        return Colors.orange.shade700;
      case TasRengi.kirmizi:
        return Colors.red.shade700;
      case TasRengi.siyah:
        return Colors.black;
      case TasRengi.sahteOkey:
        return Colors.purple.shade700;
      case TasRengi.bos:
        return Colors.white24;
    }
  }

  void _testBaslat() {
    // Bu buton tamamen lokal test motorudur. Firestore, oda doluluk kontrolü veya online oyuncu beklemez.
    if (!mounted) return;
    _botTimer?.cancel();
    _lokalTestBaslat();
    _hataGoster('Test başladı: 3 bot masada, taşlar dağıtıldı.');
  }

  void _testBotlariniMasayaOturttur() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final ad = FirebaseAuth.instance.currentUser?.displayName ?? 'Oyuncu';
    final oyuncular = <String>[uid, 'bot_1', 'bot_2', 'bot_3'];
    setState(() {
      _oyuncular = oyuncular;
      _oyuncuAdlari = <String, String>{
        uid: ad,
        'bot_1': 'Akıllı Bot 1',
        'bot_2': 'Akıllı Bot 2',
        'bot_3': 'Akıllı Bot 3',
      };
      _botElleri
        ..clear()
        ..addAll(<String, List<OkeyTasi>>{
          'bot_1': <OkeyTasi>[],
          'bot_2': <OkeyTasi>[],
          'bot_3': <OkeyTasi>[],
        });
      _atilanTaslar
        ..clear()
        ..addAll(<String, List<OkeyTasi>>{
          uid: <OkeyTasi>[],
          'bot_1': <OkeyTasi>[],
          'bot_2': <OkeyTasi>[],
          'bot_3': <OkeyTasi>[],
        });
      _aktifOyuncuIndex = 0;
      _oyunBasladi = false;
      _turdaTasCekildiMi = true;
      _seciliTasId = null;
      _timerKey++;
      _sonIslemMesaji = '3 bot masada bekliyor. Test başlatınca taşlar dağıtılacak.';
    });
  }

  void _lokalTestBaslat() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final ad = FirebaseAuth.instance.currentUser?.displayName ?? 'Oyuncu';
    final taslar = _standartOkeySetiOlustur()..shuffle(Random());
    final gosterge = taslar.removeAt(taslar.indexWhere((t) => !t.sahteOkeyMi && t.sayi != null));
    final oyuncular = <String>[uid, 'bot_1', 'bot_2', 'bot_3'];
    final botElleri = <String, List<OkeyTasi>>{};
    final atilan = <String, List<OkeyTasi>>{};
    final benimEl = taslar.take(22).toList();
    taslar.removeRange(0, 22);

    for (final bot in oyuncular.skip(1)) {
      botElleri[bot] = taslar.take(21).toList();
      taslar.removeRange(0, 21);
    }
    for (final oyuncu in oyuncular) {
      atilan[oyuncu] = <OkeyTasi>[];
    }

    setState(() {
      _botTimer?.cancel();
      _oyuncular = oyuncular;
      _oyuncuAdlari = <String, String>{uid: ad, 'bot_1': 'Akıllı Bot 1', 'bot_2': 'Akıllı Bot 2', 'bot_3': 'Akıllı Bot 3'};
      _botElleri
        ..clear()
        ..addAll(botElleri);
      _atilanTaslar
        ..clear()
        ..addAll(atilan);
      _acilanSeriler.clear();
      _acilanCiftler.clear();
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _ortaTaslar = taslar;
      _gosterge = gosterge;
      _okey = _okeyTasiHesapla(gosterge);
      _aktifOyuncuIndex = 0;
      _turdaTasCekildiMi = true;
      _oyunBasladi = true;
      _seciliTasId = null;
      _ciftModu = false;
      _timerKey++;
      _istakaYerlestir(benimEl);
      _puanlariGuncelle();
      _sonIslemMesaji = 'Test başladı: Senin ıstakana 22 taş, botlara 21 taş dağıtıldı.';
    });
    _oyuncuSuresiniBaslat();
  }

  void _tasCek({int? hedefIndex}) {
    if (_ortaTaslar.isEmpty) {
      _hataGoster('Deste bitti.');
      return;
    }
    setState(() {
      final tas = _ortaTaslar.removeAt(0);
      final bosIndex = (hedefIndex != null && hedefIndex >= 0 && hedefIndex < _istaka.length && _istaka[hedefIndex] == null) ? hedefIndex : _istaka.indexWhere((t) => t == null);
      if (bosIndex != -1) {
        _istaka[bosIndex] = tas;
      } else {
        _hataGoster('Istaka dolu, önce bir taş at.');
      }
      _turdaTasCekildiMi = true;
      _puanlariGuncelle();
    });
  }

  void _tasAt() {
    _siraTimer?.cancel();
    final tasId = _seciliTasId;
    if (tasId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final index = _istaka.indexWhere((t) => t?.id == tasId);
    if (index == -1) return;

    setState(() {
      final tas = _istaka[index];
      if (tas == null) return;
      _istaka[index] = null;
      _atilanTaslar.putIfAbsent(uid, () => <OkeyTasi>[]).add(tas);
      _seciliTasId = null;
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _turdaTasCekildiMi = false;
      _aktifOyuncuIndex = 1;
      _puanlariGuncelle();
      _sonIslemMesaji = 'Taş atıldı. Botlar oynuyor...';
    });
    _botlariOynatVeSirayiVer();
  }

  void _botlariOynatVeSirayiVer() {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || !_oyunBasladi) return;
      setState(() {
        for (final bot in <String>['bot_1', 'bot_2', 'bot_3']) {
          final el = _botElleri[bot];
          if (el == null || el.isEmpty) continue;
          if (_ortaTaslar.isNotEmpty && el.length < 22) {
            el.add(_ortaTaslar.removeAt(0));
          }
          final atilacakIndex = _botAtilacakTasIndex(el);
          final atilan = el.removeAt(atilacakIndex);
          _atilanTaslar.putIfAbsent(bot, () => <OkeyTasi>[]).add(atilan);
        }
        _aktifOyuncuIndex = 0;
        _turdaTasCekildiMi = false;
        _timerKey++;
        _sonIslemMesaji = 'Botlar oynadı. Sıra sizde, taş çekip taş atabilirsiniz.';
      });
      _oyuncuSuresiniBaslat();
    });
  }

  void _oyuncuSuresiniBaslat() {
    _siraTimer?.cancel();
    _siraTimer = Timer(const Duration(seconds: 30), _sureDolduysaOtomatikTasAt);
  }

  void _sureDolduysaOtomatikTasAt() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    if (!mounted || !_oyunBasladi || _oyuncular.isEmpty || _oyuncular[_aktifOyuncuIndex] != uid) return;
    if (!_istaka.any((t) => t != null)) return;

    final doluIndexler = <int>[];
    for (var i = 0; i < _istaka.length; i++) {
      if (_istaka[i] != null) doluIndexler.add(i);
    }
    if (doluIndexler.isEmpty) return;
    final atilacakIndex = doluIndexler[Random().nextInt(doluIndexler.length)];

    setState(() {
      final tas = _istaka[atilacakIndex];
      if (tas == null) return;
      _istaka[atilacakIndex] = null;
      _atilanTaslar.putIfAbsent(uid, () => <OkeyTasi>[]).add(tas);
      _seciliTasId = null;
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _turdaTasCekildiMi = false;
      _aktifOyuncuIndex = 1;
      _puanlariGuncelle();
      _sonIslemMesaji = 'Süre doldu. Istakadan rastgele bir taş atıldı, sıra botlara geçti.';
    });
    _botlariOynatVeSirayiVer();
  }

  int _botAtilacakTasIndex(List<OkeyTasi> el) {
    var secilen = 0;
    var enDusuk = 9999;
    for (var i = 0; i < el.length; i++) {
      final t = el[i];
      var skor = t.sayi ?? 0;
      if (t.sahteOkeyMi) skor += 900;
      if (_okey != null && t.sayi == _okey!.sayi && t.renk == _okey!.renk) skor += 1000;
      final bag = el.where((d) => d.id != t.id && d.sayi != null && t.sayi != null && (d.sayi == t.sayi || (d.renk == t.renk && ((d.sayi! - t.sayi!).abs() <= 2)))).length;
      skor += bag * 50;
      if (skor < enDusuk) {
        enDusuk = skor;
        secilen = i;
      }
    }
    return secilen;
  }

  void _seriDiz() {
    final gruplar = _seriGruplari();
    final kullanilan = gruplar.expand((e) => e).map((e) => e.id).toSet();
    final artiklar = _eldekiTaslar().where((t) => !kullanilan.contains(t.id)).toList()..sort((a, b) => _tasSirala(a, b));
    setState(() {
      _ciftModu = false;
      _istakaGrupluYerlestir(gruplar: gruplar, artiklar: artiklar, gruplarArasiBosluk: true);
      _puanlariGuncelle();
      _sonIslemMesaji = 'Seriler boşluklu dizildi. Artan taşlar sağ alttan küçükten büyüğe sıralandı.';
    });
  }

  void _ciftDiz() {
    final ciftler = _ciftGruplari();
    final kullanilan = ciftler.expand((e) => e).map((e) => e.id).toSet();
    final artiklar = _eldekiTaslar().where((t) => !kullanilan.contains(t.id)).toList()..sort((a, b) => _tasSirala(a, b));
    setState(() {
      _ciftModu = true;
      _istakaGrupluYerlestir(gruplar: ciftler, artiklar: artiklar, gruplarArasiBosluk: false);
      _puanlariGuncelle();
      _sonIslemMesaji = 'Çiftler soldan sağa dizildi. Artan taşlar sağ alttan küçükten büyüğe sıralandı.';
    });
  }

  void _elAc(bool ciftModu) {
    final gruplar = ciftModu ? _ciftGruplari() : _seriGruplari();
    if (gruplar.isEmpty) {
      _hataGoster(ciftModu ? 'Açılacak çift bulunamadı.' : 'Açılacak seri/per bulunamadı.');
      return;
    }
    final kullanilan = gruplar.expand((e) => e).map((e) => e.id).toSet();
    setState(() {
      if (ciftModu) {
        _acilanCiftler.addAll(gruplar.map((g) => List<OkeyTasi>.from(g)));
      } else {
        _acilanSeriler.addAll(gruplar.map((g) => List<OkeyTasi>.from(g)));
      }
      for (var i = 0; i < _istaka.length; i++) {
        if (_istaka[i] != null && kullanilan.contains(_istaka[i]!.id)) {
          _istaka[i] = null;
        }
      }
      _puanlariGuncelle();
      _sonIslemMesaji = ciftModu ? 'Çiftler yere açıldı.' : 'Seriler yere açıldı.';
    });
  }

  void _geriBirak() {
    final tas = _geriBirakTasi;
    final sahip = _geriBirakSahibi;
    if (tas == null || sahip == null) return;
    final index = _istaka.indexWhere((t) => t?.id == tas.id);
    setState(() {
      if (index != -1) _istaka[index] = null;
      _atilanTaslar.putIfAbsent(sahip, () => <OkeyTasi>[]).add(tas);
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _turdaTasCekildiMi = false;
      _seciliTasId = null;
      _puanlariGuncelle();
      _sonIslemMesaji = 'Aldığınız taş eski yerine geri bırakıldı.';
    });
  }

  void _tasIsle() {
    _hataGoster('Taş işle sistemi yazboz/açılan per alanı tamamlanınca bağlanacak.');
  }


  void _soldanTasAl(String oyuncuId, {int? hedefIndex}) {
    final liste = _atilanTaslar[oyuncuId];
    if (liste == null || liste.isEmpty || _turdaTasCekildiMi) return;
    final tas = liste.removeLast();
    final bosIndex = (hedefIndex != null && hedefIndex >= 0 && hedefIndex < _istaka.length && _istaka[hedefIndex] == null) ? hedefIndex : _istaka.indexWhere((t) => t == null);
    if (bosIndex == -1) {
      liste.add(tas);
      _hataGoster('Istaka dolu. Taşı alamazsınız.');
      return;
    }
    setState(() {
      _istaka[bosIndex] = tas;
      _geriBirakTasi = tas;
      _geriBirakSahibi = oyuncuId;
      _turdaTasCekildiMi = true;
      _seciliTasId = tas.id;
      _puanlariGuncelle();
      _sonIslemMesaji = 'Sol rakibin attığı taş alındı. İşe yaramazsa Geri bırak ile yerine koyabilirsiniz.';
    });
  }

  Widget _acilanTaslarAlani() {
    final tum = <List<OkeyTasi>>[..._acilanSeriler, ..._acilanCiftler];
    if (tum.isEmpty) {
      return const Text('Açılan perler burada görünecek', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold));
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: tum.map((grup) {
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.24), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.withOpacity(.28))),
            child: Row(mainAxisSize: MainAxisSize.min, children: grup.map((t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: _tasWidget(t, false))).toList()),
          );
        }).toList(),
      ),
    );
  }

  void _istakaGrupluYerlestir({required List<List<OkeyTasi>> gruplar, required List<OkeyTasi> artiklar, required bool gruplarArasiBosluk}) {
    for (var i = 0; i < _istaka.length; i++) {
      _istaka[i] = null;
    }
    var index = 0;
    for (final grup in gruplar) {
      for (final tas in grup) {
        while (index < _istaka.length && _istaka[index] != null) {
          index++;
        }
        if (index >= _istaka.length) break;
        _istaka[index] = tas;
        index++;
      }
      if (gruplarArasiBosluk && index < _istaka.length) index++;
    }
    var hedef = _istaka.length - 1;
    for (final tas in artiklar) {
      while (hedef >= 0 && _istaka[hedef] != null) {
        hedef--;
      }
      if (hedef < 0) break;
      _istaka[hedef] = tas;
      hedef--;
    }
  }

  void _yazbozAc() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff101820),
        title: const Text('Yaz boz', style: TextStyle(color: Colors.amber)),
        content: const Text('Yazboz görselini gönderince bu alan puan tablosuna çevrilecek.', style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
      ),
    );
  }

  void _ayarlarAc() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: const SizedBox(width: 520, height: 620, child: AyarlarPage()),
        ),
      ),
    );
  }

  Future<void> _cikisYap() async {
    unawaited(_service.masadanCik(widget.roomId).catchError((_) {}));
    final ad = FirebaseAuth.instance.currentUser?.displayName ?? 'Oyuncu';
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AnaMenuPage(kullaniciAdi: ad)), (route) => false);
  }

  void _hataGoster(Object hata) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$hata')));
  }

  String _solRakipId() => _oyuncular.length > 1 ? _oyuncular[1] : '';

  void _istakaYerlestir(List<OkeyTasi> taslar) {
    for (var i = 0; i < _istaka.length; i++) {
      _istaka[i] = null;
    }
    for (var i = 0; i < taslar.length && i < _istaka.length; i++) {
      _istaka[i] = taslar[i];
    }
  }

  List<OkeyTasi> _eldekiTaslar() => _istaka.whereType<OkeyTasi>().toList();

  int _tasSirala(OkeyTasi a, OkeyTasi b) {
    final renkKarsilastir = a.renk.index.compareTo(b.renk.index);
    if (renkKarsilastir != 0) return renkKarsilastir;
    final sayiKarsilastir = (a.sayi ?? 99).compareTo(b.sayi ?? 99);
    if (sayiKarsilastir != 0) return sayiKarsilastir;
    return a.kopyaNo.compareTo(b.kopyaNo);
  }

  void _puanlariGuncelle() {
    final seriler = _seriGruplari();
    _seriToplam = seriler.fold<int>(0, (toplam, grup) => toplam + grup.fold<int>(0, (ara, t) => ara + (t.sayi ?? 0)));
    _ciftSayisi = _ciftGruplari().length;
  }

  List<List<OkeyTasi>> _seriGruplari() {
    final taslar = _eldekiTaslar().where((t) => !t.sahteOkeyMi && t.sayi != null).toList();
    final sonuc = <List<OkeyTasi>>[];
    final kullanilan = <String>{};

    for (final renk in [TasRengi.mavi, TasRengi.sari, TasRengi.kirmizi, TasRengi.siyah]) {
      final ayniRenk = taslar.where((t) => t.renk == renk).toList()..sort(_tasSirala);
      for (var i = 0; i < ayniRenk.length; i++) {
        final grup = <OkeyTasi>[ayniRenk[i]];
        var son = ayniRenk[i].sayi ?? 0;
        for (var j = i + 1; j < ayniRenk.length; j++) {
          final aday = ayniRenk[j];
          if ((aday.sayi ?? 0) == son + 1) {
            grup.add(aday);
            son = aday.sayi ?? son;
          } else if ((aday.sayi ?? 0) > son + 1) {
            break;
          }
        }
        if (grup.length >= 3) {
          final temiz = grup.where((t) => !kullanilan.contains(t.id)).toList();
          if (temiz.length >= 3) {
            sonuc.add(temiz);
            kullanilan.addAll(temiz.map((t) => t.id));
          }
        }
      }
    }

    for (var sayi = 1; sayi <= 13; sayi++) {
      final ayniSayi = taslar.where((t) => t.sayi == sayi && !kullanilan.contains(t.id)).toList();
      final renkler = <TasRengi>{};
      final grup = <OkeyTasi>[];
      for (final t in ayniSayi) {
        if (renkler.add(t.renk)) grup.add(t);
      }
      if (grup.length >= 3) {
        sonuc.add(grup);
        kullanilan.addAll(grup.map((t) => t.id));
      }
    }

    return sonuc;
  }

  List<List<OkeyTasi>> _ciftGruplari() {
    final taslar = _eldekiTaslar().where((t) => !t.sahteOkeyMi && t.sayi != null).toList()..sort(_tasSirala);
    final sonuc = <List<OkeyTasi>>[];
    final kullanilan = <String>{};
    for (final tas in taslar) {
      if (kullanilan.contains(tas.id)) continue;
      final esIndex = taslar.indexWhere((t) => !kullanilan.contains(t.id) && t.id != tas.id && t.sayi == tas.sayi && t.renk == tas.renk);
      if (esIndex != -1) {
        final es = taslar[esIndex];
        sonuc.add([tas, es]);
        kullanilan.add(tas.id);
        kullanilan.add(es.id);
      }
    }
    return sonuc;
  }

  List<OkeyTasi> _standartOkeySetiOlustur() {
    final taslar = <OkeyTasi>[];
    for (final renk in [TasRengi.mavi, TasRengi.sari, TasRengi.kirmizi, TasRengi.siyah]) {
      for (var kopya = 1; kopya <= 2; kopya++) {
        for (var sayi = 1; sayi <= 13; sayi++) {
          taslar.add(OkeyTasi(id: '${renk.name}_${sayi}_$kopya', sayi: sayi, renk: renk, kopyaNo: kopya, sahteOkeyMi: false));
        }
      }
    }
    taslar.add(const OkeyTasi(id: 'sahte_okey_1', sayi: null, renk: TasRengi.sahteOkey, kopyaNo: 1, sahteOkeyMi: true));
    taslar.add(const OkeyTasi(id: 'sahte_okey_2', sayi: null, renk: TasRengi.sahteOkey, kopyaNo: 2, sahteOkeyMi: true));
    return taslar;
  }

  OkeyTasi _okeyTasiHesapla(OkeyTasi gosterge) {
    final sayi = gosterge.sayi ?? 1;
    return OkeyTasi(id: 'okey_${gosterge.renk.name}_${sayi == 13 ? 1 : sayi + 1}', sayi: sayi == 13 ? 1 : sayi + 1, renk: gosterge.renk, kopyaNo: 0, sahteOkeyMi: false);
  }
}
