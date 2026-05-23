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
  final String oyunSekli;
  final int elSayisi;

  const GameTablePage({
    super.key,
    required this.roomId,
    this.cezali = false,
    this.oyunSekli = 'Tek',
    this.elSayisi = 11,
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
  final Map<int, Map<String, String>> _yazbozElPuanlari = <int, Map<String, String>>{};
  final Map<String, int> _yazbozKafaSayilari = <String, int>{};
  int? _benimIlkAcilisPuani;
  int? _benimIlkAcilisCiftSayisi;
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
  String? _benimAcilisTipi; // null, 'seri', 'cift'
  bool _benimTekHamleSilerAdayi = false;
  String? _baslayanOyuncuId;
  bool _baslayanIlkHamlesiniYaptiMi = false;
  bool _turdaTasCekildiMi = true;
  bool _islemYapiliyor = false;
  int _aktifOyuncuIndex = 0;
  int _seriToplam = 0;
  int _ciftSayisi = 0;
  int _timerKey = 0;
  int _mevcutEl = 1;
  bool _elSonuIsleniyor = false;
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
                                const SizedBox(height: 8),
                                _miniButon('Çifte Git', Icons.compare_arrows, () {}),
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
            !oyunBasladi ? '${_mevcutEl}. El   Başlat bekleniyor' : (benimSiramsa ? '${_mevcutEl}. El   Sıra sizde' : '${_mevcutEl}. El   Bot sırası'),
            style: TextStyle(color: oyunBasladi && benimSiramsa ? Colors.amber : Colors.white70, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _siraSaati(bool aktif) {
    if (!aktif) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: 1, strokeWidth: 3, color: Colors.white24),
            Text('45', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('timer_$_timerKey'),
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(seconds: 45),
      onEnd: _sureDolduysaOtomatikTasAt,
      builder: (context, value, _) {
        final kalan = max(0, (value * 45).ceil());
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: value, strokeWidth: 3, color: Colors.amber, backgroundColor: Colors.white24),
              Text('$kalan', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
            ],
          ),
        );
      },
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
    final acilisEtiketi = _benimIlkAcilisPuani != null
        ? 'Açılış: $_benimIlkAcilisPuani'
        : (_benimIlkAcilisCiftSayisi != null ? 'Açılış: $_benimIlkAcilisCiftSayisi çift' : 'Açılış: -');
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xff3b2109).withOpacity(.96), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(.42), width: 1.2), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))]),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(mainAxisSize: MainAxisSize.min, children: [_istakaSira(ust, 0), const SizedBox(height: 4), _istakaSira(alt, _istakaSiraKapasite)]),
          Positioned(
            left: 0,
            top: -24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.62), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(.45))),
              child: Text(acilisEtiketi, style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
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
            onWillAccept: (data) {
              if (!_oyunBasladi || data == null) return false;
              if (data.startsWith('istaka:')) return true;
              if (!_turdaTasCekildiMi && (data == 'deste' || data.startsWith('atilan:'))) return true;
              return false;
            },
            onAccept: (data) {
              if (data == 'deste') {
                _tasCek(hedefIndex: index);
              } else if (data.startsWith('atilan:')) {
                _soldanTasAl(data.substring(7), hedefIndex: index);
              } else if (data.startsWith('istaka:')) {
                final fromIndex = int.tryParse(data.substring(7));
                if (fromIndex != null) _istakaTasiniTasi(fromIndex, index);
              }
            },
            builder: (context, candidate, rejected) {
              final vurgulu = candidate.isNotEmpty;
              final child = InkWell(
                onTap: tas == null ? null : () => setState(() => _seciliTasId = tas.id),
                onDoubleTap: tas == null ? null : () { setState(() => _seciliTasId = tas.id); _tasAt(); },
                child: tas == null ? _bosTas(vurgulu: vurgulu) : _tasWidget(tas, tas.id == _seciliTasId),
              );
              if (tas == null) return child;
              return Draggable<String>(
                data: 'istaka:$index',
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

  void _istakaTasiniTasi(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 || fromIndex >= _istaka.length || toIndex < 0 || toIndex >= _istaka.length) return;
    setState(() {
      final tas = _istaka[fromIndex];
      if (tas == null) return;
      final hedef = _istaka[toIndex];
      _istaka[toIndex] = tas;
      _istaka[fromIndex] = hedef;
      _seciliTasId = tas.id;
      _puanlariGuncelle();
      _sonIslemMesaji = 'Istakadaki taşın yeri değiştirildi.';
    });
  }

  Widget _benimAtilanTasAlani(bool benimSiramsa) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final sonAtilan = _sonAtilanTas(uid);
    final tiklamaAktif = _oyunBasladi && benimSiramsa && _turdaTasCekildiMi && _seciliTasId != null;
    final suruklemeAktif = _oyunBasladi && benimSiramsa && _turdaTasCekildiMi;

    Widget kutu({required bool vurgulu}) {
      return InkWell(
        onTap: tiklamaAktif ? _tasAt : null,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: vurgulu ? Colors.amber.withOpacity(.18) : Colors.black.withOpacity(.48),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (tiklamaAktif || vurgulu) ? Colors.amber : Colors.white24, width: (tiklamaAktif || vurgulu) ? 2 : 1),
          ),
          child: sonAtilan == null
              ? const Text('Atılan\ntaş', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 10))
              : _tasWidget(sonAtilan, false),
        ),
      );
    }

    return DragTarget<String>(
      onWillAccept: (data) => suruklemeAktif && data != null && data.startsWith('istaka:'),
      onAccept: (data) {
        final fromIndex = int.tryParse(data.substring(7));
        if (fromIndex == null || fromIndex < 0 || fromIndex >= _istaka.length) return;
        final tas = _istaka[fromIndex];
        if (tas == null) return;
        setState(() => _seciliTasId = tas.id);
        _tasAt();
      },
      builder: (context, candidate, rejected) => kutu(vurgulu: candidate.isNotEmpty),
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
    final yaziRengi = _tasYaziRengi(tas.renk);
    final gorunenYazi = tas.sahteOkeyMi ? 'J' : '${tas.sayi}';
    return Container(
      width: _tasGenislik,
      height: _tasYukseklik,
      decoration: BoxDecoration(
        color: selected ? const Color(0xfffff1a8) : const Color(0xfffff7de),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? Colors.amber.shade700 : Colors.black87, width: selected ? 2.4 : 1.15),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2.4, offset: Offset(1, 2))],
      ),
      alignment: Alignment.center,
      child: Text(
        gorunenYazi,
        style: TextStyle(
          fontSize: tas.sahteOkeyMi ? 17 : 16,
          fontWeight: FontWeight.w900,
          color: yaziRengi,
          height: .95,
          letterSpacing: -.4,
          shadows: const [Shadow(color: Colors.white, blurRadius: .6, offset: Offset(.25, .25))],
        ),
      ),
    );
  }

  Widget _bosTas({bool vurgulu = false}) {
    return Container(width: _tasGenislik, height: _tasYukseklik, decoration: BoxDecoration(color: vurgulu ? Colors.amber.withOpacity(.18) : Colors.black.withOpacity(.16), borderRadius: BorderRadius.circular(6), border: Border.all(color: vurgulu ? Colors.amber : Colors.white12)));
  }

  Color _tasYaziRengi(TasRengi renk) {
    switch (renk) {
      case TasRengi.mavi:
        return const Color(0xff004fd6);
      case TasRengi.sari:
        return const Color(0xffd78300);
      case TasRengi.kirmizi:
        return const Color(0xffd00000);
      case TasRengi.siyah:
        return const Color(0xff050505);
      case TasRengi.sahteOkey:
        return const Color(0xff5e1bb5);
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
      _baslayanIlkHamlesiniYaptiMi = false;
      _turdaTasCekildiMi = true;
      _seciliTasId = null;
      _benimIlkAcilisPuani = null;
      _benimIlkAcilisCiftSayisi = null;
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
    final baslayanIndex = Random().nextInt(oyuncular.length);
    final baslayanId = oyuncular[baslayanIndex];
    final botElleri = <String, List<OkeyTasi>>{};
    final atilan = <String, List<OkeyTasi>>{};
    final benimTasSayim = baslayanId == uid ? 22 : 21;
    final benimEl = taslar.take(benimTasSayim).toList();
    taslar.removeRange(0, benimTasSayim);

    for (final bot in oyuncular.skip(1)) {
      final botTasSayisi = baslayanId == bot ? 22 : 21;
      botElleri[bot] = taslar.take(botTasSayisi).toList();
      taslar.removeRange(0, botTasSayisi);
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
      _aktifOyuncuIndex = baslayanIndex;
      _baslayanOyuncuId = baslayanId;
      _baslayanIlkHamlesiniYaptiMi = false;
      _turdaTasCekildiMi = baslayanId == uid; // Başlayan oyuncu çekmeden taş atar; diğerleri önce taş alır.
      _oyunBasladi = true;
      _mevcutEl = 1;
      _yazbozElPuanlari.clear();
      _yazbozKafaSayilari.clear();
      _benimIlkAcilisPuani = null;
      _benimIlkAcilisCiftSayisi = null;
      _elSonuIsleniyor = false;
      _seciliTasId = null;
      _ciftModu = false;
      _benimIlkAcilisPuani = null;
      _benimIlkAcilisCiftSayisi = null;
      _benimAcilisTipi = null;
      _benimTekHamleSilerAdayi = false;
      _timerKey++;
      _istakaYerlestir(benimEl);
      _puanlariGuncelle();
      _sonIslemMesaji = baslayanId == uid
          ? 'Test başladı: Başlayan oyuncu sensin. 22 taşla çekmeden taş atmalısın.'
          : 'Test başladı: Başlayan oyuncu ${_oyuncuAdlari[baslayanId] ?? baslayanId}. Senin ıstakana 21 taş dağıtıldı.';
    });
    if (baslayanId == uid) {
      _oyuncuSuresiniBaslat();
    } else {
      _botSiradanOynat();
    }
  }

  bool get _benimElActiMi => _benimAcilisTipi != null;

  List<String> _saatYonununTersiOyuncuSirasi() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    return <String>[uid, 'bot_3', 'bot_2', 'bot_1']
        .where((id) => _oyuncular.contains(id))
        .toList(growable: false);
  }

  void _sirayiSaatYonununTersineGecir() {
    if (_oyuncular.isEmpty) return;
    final aktifId = _oyuncular[_aktifOyuncuIndex];
    final sira = _saatYonununTersiOyuncuSirasi();
    if (sira.isEmpty) return;
    final mevcutSiraIndex = sira.indexOf(aktifId);
    final siradakiId = sira[(mevcutSiraIndex == -1 ? 0 : mevcutSiraIndex + 1) % sira.length];
    final yeniIndex = _oyuncular.indexOf(siradakiId);
    if (yeniIndex != -1) {
      _aktifOyuncuIndex = yeniIndex;
    } else {
      _aktifOyuncuIndex = (_aktifOyuncuIndex + 1) % _oyuncular.length;
    }
  }

  void _tasCek({int? hedefIndex}) {
    if (!_oyunBasladi) {
      _hataGoster('Oyun başlamadı.');
      return;
    }
    if (_turdaTasCekildiMi) {
      _hataGoster('Bu tur zaten taş aldınız. Şimdi taş atmalısınız.');
      return;
    }
    if (_ortaTaslar.isEmpty) {
      _desteBittiElSonu();
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
      // Taş çekmek tek başına per yapma sayılmaz; seri/çift göstergesi
      // ancak oyuncu Seri Diz/Çift Diz yaptığında veya ıstakada taşları
      // elle per haline getirdiğinde güncellenir.
    });
  }

  void _tasAt() {
    if (!_oyunBasladi) return;
    if (!_turdaTasCekildiMi) {
      _hataGoster('Taş atmadan önce desteden veya sol oyuncudan taş almalısınız.');
      return;
    }
    if (!_benimElActiMi && _eldekiTaslar().length <= 21) {
      _hataGoster('El açmadan ıstakada 21 taştan az kalamaz. Önce taş almalısınız.');
      return;
    }
    _siraTimer?.cancel();
    final tasId = _seciliTasId;
    if (tasId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final index = _istaka.indexWhere((t) => t?.id == tasId);
    if (index == -1) return;

    var elBitti = false;
    setState(() {
      final tas = _istaka[index];
      if (tas == null) return;
      _istaka[index] = null;
      _atilanTaslar.putIfAbsent(uid, () => <OkeyTasi>[]).add(tas);
      _seciliTasId = null;
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _turdaTasCekildiMi = false;
      if (uid == _baslayanOyuncuId && !_baslayanIlkHamlesiniYaptiMi) {
        _baslayanIlkHamlesiniYaptiMi = true;
      }

      elBitti = _benimAcilisTipi != null && !_istaka.any((t) => t != null);
      if (elBitti) {
        _sonTasIleElBitir(uid);
      } else {
        _sirayiSaatYonununTersineGecir();
        _puanlariGuncelle();
        _sonIslemMesaji = 'Taş atıldı. Sıra diğer oyuncuya geçti.';
      }
    });
    if (elBitti) return;
    if (_ortaTaslar.isEmpty) {
      _desteBittiElSonu();
      return;
    }
    _botSiradanOynat();
  }


  void _botSiradanOynat() {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || !_oyunBasladi || _oyuncular.isEmpty) return;
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
      final aktifId = _oyuncular[_aktifOyuncuIndex];
      if (aktifId == uid) {
        _turdaTasCekildiMi = false;
        _oyuncuSuresiniBaslat();
        return;
      }
      setState(() {
        final el = _botElleri[aktifId];
        if (el != null && el.isNotEmpty) {
          final baslayanIlkHamle = aktifId == _baslayanOyuncuId && !_baslayanIlkHamlesiniYaptiMi;
          if (!baslayanIlkHamle && _ortaTaslar.isNotEmpty && el.length < 22) {
            el.add(_ortaTaslar.removeAt(0));
          }
          final atilacakIndex = _botAtilacakTasIndex(el);
          final atilan = el.removeAt(atilacakIndex);
          _atilanTaslar.putIfAbsent(aktifId, () => <OkeyTasi>[]).add(atilan);
          if (baslayanIlkHamle) {
            _baslayanIlkHamlesiniYaptiMi = true;
          }
        }
        _sirayiSaatYonununTersineGecir();
        _timerKey++;
        _sonIslemMesaji = '${_oyuncuAdlari[aktifId] ?? aktifId} taş attı.';
      });
      if (_ortaTaslar.isEmpty) {
        _desteBittiElSonu();
        return;
      }
      final siradakiId = _oyuncular[_aktifOyuncuIndex];
      if (siradakiId == uid) {
        setState(() {
          _turdaTasCekildiMi = false;
          _sonIslemMesaji = 'Sıra sizde. Önce taş alın, sonra taş atın.';
        });
        _oyuncuSuresiniBaslat();
      } else {
        _botSiradanOynat();
      }
    });
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
      if (_ortaTaslar.isEmpty) {
        _desteBittiElSonu();
        return;
      }
      _oyuncuSuresiniBaslat();
    });
  }

  void _oyuncuSuresiniBaslat() {
    _siraTimer?.cancel();
    _siraTimer = Timer(const Duration(seconds: 45), _sureDolduysaOtomatikTasAt);
  }

  void _sureDolduysaOtomatikTasAt() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    if (!mounted || !_oyunBasladi || _oyuncular.isEmpty || _oyuncular[_aktifOyuncuIndex] != uid) return;
    if (!_istaka.any((t) => t != null)) return;

    if (!_turdaTasCekildiMi && _ortaTaslar.isNotEmpty) {
      final bosIndex = _istaka.indexWhere((t) => t == null);
      if (bosIndex != -1) {
        setState(() {
          _istaka[bosIndex] = _ortaTaslar.removeAt(0);
          _turdaTasCekildiMi = true;
        });
      }
    }

    final doluIndexler = <int>[];
    for (var i = 0; i < _istaka.length; i++) {
      if (_istaka[i] != null) doluIndexler.add(i);
    }
    if (doluIndexler.isEmpty) return;
    final atilacakIndex = doluIndexler[Random().nextInt(doluIndexler.length)];

    var elBitti = false;
    setState(() {
      final tas = _istaka[atilacakIndex];
      if (tas == null) return;
      _istaka[atilacakIndex] = null;
      _atilanTaslar.putIfAbsent(uid, () => <OkeyTasi>[]).add(tas);
      _seciliTasId = null;
      _geriBirakTasi = null;
      _geriBirakSahibi = null;
      _turdaTasCekildiMi = false;
      if (uid == _baslayanOyuncuId && !_baslayanIlkHamlesiniYaptiMi) {
        _baslayanIlkHamlesiniYaptiMi = true;
      }
      elBitti = _benimAcilisTipi != null && !_istaka.any((t) => t != null);
      if (elBitti) {
        _sonTasIleElBitir(uid);
      } else {
        _sirayiSaatYonununTersineGecir();
        _puanlariGuncelle();
        _sonIslemMesaji = 'Süre doldu. Istakadan rastgele bir taş atıldı, sıra saat yönünün tersine geçti.';
      }
    });
    if (elBitti) return;
    if (_ortaTaslar.isEmpty) {
      _desteBittiElSonu();
      return;
    }
    _botSiradanOynat();
  }

  void _sonTasIleElBitir(String bitirenOyuncuId) {
    if (_elSonuIsleniyor) return;
    _elSonuIsleniyor = true;
    _botTimer?.cancel();
    _siraTimer?.cancel();
    _silerElPuanlariniYazbozaIsle(bitirenOyuncuId);
    _oyunBasladi = false;
    _turdaTasCekildiMi = true;
    _puanlariGuncelle();

    final toplamEl = widget.elSayisi.clamp(1, 11).toInt();
    if (_mevcutEl >= toplamEl) {
      _sonIslemMesaji = 'Siler! ${_mevcutEl}. El yazboza işlendi. Oyun bitti, toplam hesaplamaya geçilecek.';
      return;
    }

    _sonIslemMesaji = 'Siler! ${_mevcutEl}. El yazboza işlendi. Yeni el hazırlanıyor...';
    Timer(const Duration(milliseconds: 900), _yeniEliBaslat);
  }

  void _silerElPuanlariniYazbozaIsle(String bitirenOyuncuId) {
    if (_yazbozElPuanlari.containsKey(_mevcutEl)) return;
    final oyuncular = _oyuncular.isNotEmpty
        ? List<String>.from(_oyuncular)
        : <String>[FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu', 'bot_1', 'bot_2', 'bot_3'];
    final puanlar = <String, String>{};

    final bendenBaskaAcanVarMi = _bendenBaskaElAcanVarMi();
    final agirSiler = bitirenOyuncuId == (FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu')
        && _benimTekHamleSilerAdayi
        && !bendenBaskaAcanVarMi;

    for (final oyuncu in oyuncular) {
      if (oyuncu == bitirenOyuncuId) {
        puanlar[oyuncu] = '—';
        continue;
      }

      if (agirSiler) {
        puanlar[oyuncu] = '404';
        continue;
      }

      final tip = _oyuncuAcilisTipi(oyuncu);
      if (tip == null) {
        puanlar[oyuncu] = '202';
      } else {
        final kalan = _oyuncuKalanPuan(oyuncu);
        puanlar[oyuncu] = tip == 'cift' ? '${kalan * 2}' : '$kalan';
      }
    }
    _yazbozElPuanlari[_mevcutEl] = puanlar;
  }

  bool _bendenBaskaElAcanVarMi() {
    // Bot el açma motoru bağlandığında burada botların açılış tipleri de okunacak.
    // Şu an lokal testte yalnızca oyuncunun el açma durumu takip ediliyor.
    return false;
  }

  String? _oyuncuAcilisTipi(String oyuncuId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    if (oyuncuId == uid) return _benimAcilisTipi;
    // Bot el açma motoru bağlandığında botların 'seri' / 'cift' bilgisi buraya eklenecek.
    return null;
  }

  int _oyuncuKalanPuan(String oyuncuId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    if (oyuncuId == uid) return _eldeKalanPuan();
    final el = _botElleri[oyuncuId] ?? const <OkeyTasi>[];
    return el.fold<int>(0, (toplam, tas) => toplam + _tasPuanDegeri(tas));
  }

  void _elSonuPuanlariniYazbozaIsle() {
    // Her el bitişinde yeni ele geçmeden önce yazbozun o el satırı doldurulur.
    // Toplam satırı sonraki kural aşamasında hesaplanacak; burada sadece el puanları saklanır.
    if (_yazbozElPuanlari.containsKey(_mevcutEl)) return;

    final puanlar = <String, String>{};
    final oyuncular = _oyuncular.isNotEmpty
        ? List<String>.from(_oyuncular)
        : <String>[FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu', 'bot_1', 'bot_2', 'bot_3'];

    final kimseElAcmadi = _benimAcilisTipi == null && _acilanSeriler.isEmpty && _acilanCiftler.isEmpty;
    if (kimseElAcmadi) {
      for (final oyuncu in oyuncular) {
        puanlar[oyuncu] = '202';
      }
      _yazbozElPuanlari[_mevcutEl] = puanlar;
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    for (final oyuncu in oyuncular) {
      if (oyuncu == uid && _benimAcilisTipi != null) {
        final kalan = _eldeKalanPuan();
        puanlar[oyuncu] = _benimAcilisTipi == 'cift' ? '${kalan * 2}' : '$kalan';
      } else {
        // Bot açılış motoru tam bağlanana kadar el açmamış rakipler 202 yer.
        puanlar[oyuncu] = '202';
      }
    }
    _yazbozElPuanlari[_mevcutEl] = puanlar;
  }

  void _desteBittiElSonu() {
    if (_elSonuIsleniyor) return;
    _elSonuIsleniyor = true;
    _botTimer?.cancel();
    _siraTimer?.cancel();
    _elSonuPuanlariniYazbozaIsle();
    final toplamEl = widget.elSayisi.clamp(1, 11).toInt();
    if (_mevcutEl >= toplamEl) {
      setState(() {
        _oyunBasladi = false;
        _turdaTasCekildiMi = true;
        _sonIslemMesaji = 'Deste bitti. ${_mevcutEl}. El puanları yazboza işlendi. Oyun bitti, toplam hesaplamaya geçilecek.';
      });
      return;
    }
    setState(() {
      _oyunBasladi = false;
      _turdaTasCekildiMi = true;
      _sonIslemMesaji = 'Deste bitti. ${_mevcutEl}. El puanları yazboza işlendi. Yeni el hazırlanıyor...';
    });
    Timer(const Duration(milliseconds: 900), _yeniEliBaslat);
  }

  void _yeniEliBaslat() {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    final ad = FirebaseAuth.instance.currentUser?.displayName ?? 'Oyuncu';
    final taslar = _standartOkeySetiOlustur()..shuffle(Random());
    final gostergeIndex = taslar.indexWhere((t) => !t.sahteOkeyMi && t.sayi != null);
    final gosterge = taslar.removeAt(gostergeIndex == -1 ? 0 : gostergeIndex);
    final oyuncular = <String>[uid, 'bot_1', 'bot_2', 'bot_3'];
    final baslayanIndex = Random().nextInt(oyuncular.length);
    final baslayanId = oyuncular[baslayanIndex];
    final botElleri = <String, List<OkeyTasi>>{};
    final atilan = <String, List<OkeyTasi>>{};
    final benimTasSayim = baslayanId == uid ? 22 : 21;
    final benimEl = taslar.take(benimTasSayim).toList();
    taslar.removeRange(0, benimTasSayim);
    for (final bot in oyuncular.skip(1)) {
      final botTasSayisi = baslayanId == bot ? 22 : 21;
      botElleri[bot] = taslar.take(botTasSayisi).toList();
      taslar.removeRange(0, botTasSayisi);
    }
    for (final oyuncu in oyuncular) {
      atilan[oyuncu] = <OkeyTasi>[];
    }
    setState(() {
      _botTimer?.cancel();
      _siraTimer?.cancel();
      _mevcutEl++;
      _elSonuIsleniyor = false;
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
      _aktifOyuncuIndex = baslayanIndex;
      _baslayanOyuncuId = baslayanId;
      _baslayanIlkHamlesiniYaptiMi = false;
      _turdaTasCekildiMi = baslayanId == uid;
      _oyunBasladi = true;
      _seciliTasId = null;
      _ciftModu = false;
      _benimIlkAcilisPuani = null;
      _benimIlkAcilisCiftSayisi = null;
      _benimAcilisTipi = null;
      _benimTekHamleSilerAdayi = false;
      _timerKey++;
      _istakaYerlestir(benimEl);
      _puanlariGuncelle();
      _sonIslemMesaji = '${_mevcutEl}. El başladı. Yeni deste ve yeni gösterge hazır.';
    });
    if (baslayanId == uid) {
      _oyuncuSuresiniBaslat();
    } else {
      _botSiradanOynat();
    }
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
    final tip = ciftModu ? 'cift' : 'seri';
    if (_benimAcilisTipi != null && _benimAcilisTipi != tip) {
      _hataGoster(_benimAcilisTipi == 'seri'
          ? 'Elinizi seri açtınız. Bu elde çift açamazsınız.'
          : 'Elinizi çift açtınız. Bu elde seri açamazsınız.');
      return;
    }

    final gruplar = ciftModu ? _ciftGruplari() : _guncelSeriGruplari();
    if (gruplar.isEmpty) {
      _hataGoster(ciftModu ? 'Açılacak çift bulunamadı.' : 'Açılacak seri/per bulunamadı.');
      return;
    }

    final ilkAcilisMi = _benimAcilisTipi == null;
    final acilisPuani = ciftModu ? 0 : gruplar.fold<int>(0, (toplam, grup) => toplam + _grupPuani(grup));
    final acilisCiftSayisi = ciftModu ? gruplar.length : 0;

    if (ilkAcilisMi) {
      if (ciftModu && acilisCiftSayisi < 5) {
        _hataGoster('Çift açmak için en az 5 çift gerekir. Şu an: $acilisCiftSayisi çift.');
        return;
      }
      if (!ciftModu && acilisPuani < 101) {
        _hataGoster('Seri açmak için per toplamı en az 101 olmalı. Şu an: $acilisPuani.');
        return;
      }
    }

    final kullanilan = gruplar.expand((e) => e).map((e) => e.id).toSet();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'oyuncu';
    setState(() {
      if (ilkAcilisMi) {
        _benimAcilisTipi = tip;
        if (ciftModu) {
          _benimIlkAcilisCiftSayisi = acilisCiftSayisi;
          _benimIlkAcilisPuani = null;
        } else {
          _benimIlkAcilisPuani = acilisPuani;
          _benimIlkAcilisCiftSayisi = null;
        }
        final kalanTasSayisi = _istaka.whereType<OkeyTasi>().where((t) => !kullanilan.contains(t.id)).length;
        _benimTekHamleSilerAdayi = kalanTasSayisi == 1;
        final kafa = _kafaSayisiHesapla(tip: tip, seriPuani: acilisPuani, ciftSayisi: acilisCiftSayisi);
        if (kafa > 0) {
          _yazbozKafaSayilari[uid] = (_yazbozKafaSayilari[uid] ?? 0) + kafa;
        }
      }

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
      _sonIslemMesaji = ciftModu
          ? (ilkAcilisMi ? 'Çiftler yere açıldı. Açılış: $acilisCiftSayisi çift.' : 'Çiftler yere eklendi.')
          : (ilkAcilisMi ? 'Seriler yere açıldı. Açılış puanı: $acilisPuani.' : 'Seriler yere eklendi.');
    });
  }

  int _kafaSayisiHesapla({required String tip, required int seriPuani, required int ciftSayisi}) {
    if (tip == 'seri') {
      if (seriPuani >= 213) return 3;
      if (seriPuani >= 183) return 2;
      if (seriPuani >= 153) return 1;
      return 0;
    }
    if (ciftSayisi >= 9) return 2;
    if (ciftSayisi >= 7) return 1;
    return 0;
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
    final seciliId = _seciliTasId;
    if (seciliId == null) {
      _hataGoster('Taş işlemek için önce ıstakadan bir taş seçin.');
      return;
    }
    final index = _istaka.indexWhere((t) => t?.id == seciliId);
    if (index == -1) {
      _hataGoster('Seçili taş ıstakada bulunamadı.');
      return;
    }
    final tas = _istaka[index];
    if (tas == null) return;

    final sonuc = _okeyGeriAlarakTasIsle(tas);
    if (sonuc) {
      setState(() {
        _istaka[index] = null;
        final bosIndex = _istaka.indexWhere((t) => t == null);
        if (bosIndex != -1 && _geriAlinanOkey != null) {
          _istaka[bosIndex] = _geriAlinanOkey;
        }
        _geriAlinanOkey = null;
        _seciliTasId = null;
        _puanlariGuncelle();
        _sonIslemMesaji = 'Gerçek taş işlendi, yerdeki okey ıstakaya geri alındı.';
      });
      return;
    }

    _hataGoster('Bu taş şu an açık perlerdeki bir okeyin yerine geçemiyor.');
  }

  OkeyTasi? _geriAlinanOkey;

  bool _okeyGeriAlarakTasIsle(OkeyTasi gercekTas) {
    if (_gercekOkeyMi(gercekTas) || gercekTas.sahteOkeyMi || gercekTas.sayi == null) return false;
    for (final grup in _acilanSeriler) {
      final jokerIndex = grup.indexWhere(_gercekOkeyMi);
      if (jokerIndex == -1) continue;
      final temsil = _jokerinTemsilEttigiTas(grup, jokerIndex);
      if (temsil == null) continue;
      if (temsil.$1 == gercekTas.renk && temsil.$2 == gercekTas.sayi) {
        _geriAlinanOkey = grup[jokerIndex];
        grup[jokerIndex] = gercekTas;
        return true;
      }
    }
    return false;
  }

  (TasRengi, int)? _jokerinTemsilEttigiTas(List<OkeyTasi> grup, int jokerIndex) {
    final normal = grup.where((t) => !_gercekOkeyMi(t) && !t.sahteOkeyMi && t.sayi != null).toList();
    if (normal.length < 2) return null;
    final renkler = normal.map((t) => t.renk).toSet();
    if (renkler.length != 1) return null;
    final renk = renkler.first;
    final sayilar = normal.map((t) => t.sayi!).toList()..sort();
    for (var beklenen = sayilar.first; beklenen <= sayilar.last; beklenen++) {
      if (!sayilar.contains(beklenen)) return (renk, beklenen);
    }
    if (jokerIndex == 0) return (renk, max(1, sayilar.first - 1));
    return (renk, min(13, sayilar.last + 1));
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
      // Soldan alınan taş ıstakaya girdi diye otomatik per sayılmasın.
      // Seri Diz/Çift Diz veya manuel sürükleme sonrası yeniden hesaplanacak.
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
      if (grup.isEmpty) continue;
      final satirSonu = index < _istakaSiraKapasite ? _istakaSiraKapasite : _istakaKapasite;
      if (index + grup.length > satirSonu) {
        if (index < _istakaSiraKapasite) {
          index = _istakaSiraKapasite;
        }
      }
      if (index + grup.length > _istakaKapasite) {
        artiklar.addAll(grup);
        continue;
      }
      for (final tas in grup) {
        _istaka[index] = tas;
        index++;
      }
      if (gruplarArasiBosluk) {
        final yeniSatirSonu = index <= _istakaSiraKapasite ? _istakaSiraKapasite : _istakaKapasite;
        if (index < yeniSatirSonu) index++;
      }
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
      barrierColor: Colors.black.withOpacity(.58),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: _yazbozDefterPopup(),
      ),
    );
  }

  Widget _yazbozDefterPopup() {
    final elSayisi = widget.elSayisi.clamp(1, 11).toInt();
    final esli = widget.oyunSekli.toLowerCase().contains('eş') || widget.oyunSekli.toLowerCase().contains('es');
    final satirlar = <String>[
      'Kafa',
      if (widget.cezali) 'Ceza',
      for (var i = 1; i <= elSayisi; i++) '$i. El',
      'Toplam',
    ];
    final basliklar = _yazbozSutunBasliklari(esli);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 780),
      child: AspectRatio(
        aspectRatio: 1.62,
        child: ClipPath(
          clipper: _YirtikDefterClipper(),
          child: Material(
            color: Colors.transparent,
            child: CustomPaint(
              painter: _KareliDefterPainter(),
              child: Container(
                padding: const EdgeInsets.fromLTRB(64, 30, 46, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 58),
                        Expanded(
                          child: Transform.rotate(
                            angle: -0.012,
                            child: const Text(
                              'YAZBOZ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xff112761),
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.4,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Transform.rotate(
                            angle: .08,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                'X',
                                style: TextStyle(
                                  color: Color(0xff112761),
                                  fontSize: 42,
                                  height: .9,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Comic Sans MS',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _yazbozTablo(basliklar: basliklar, satirlar: satirlar),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _yazbozSutunBasliklari(bool esli) {
    String ad(int index, String yedek) {
      if (index < 0 || index >= _oyuncular.length) return yedek;
      return _oyuncuAdlari[_oyuncular[index]] ?? yedek;
    }

    if (esli) {
      return <String>[
        '${ad(0, 'Oyuncu')} / ${ad(2, 'Bot 2')}',
        '${ad(1, 'Bot 1')} / ${ad(3, 'Bot 3')}',
      ];
    }

    return <String>[
      ad(0, 'Oyuncu'),
      ad(1, 'Bot 1'),
      ad(2, 'Bot 2'),
      ad(3, 'Bot 3'),
    ];
  }

  String _yazbozHucreDegeri(String satir, int sutunIndex, bool esli) {
    if (satir == 'Kafa') {
      String kafaDegeri(int index) {
        if (index < 0 || index >= _oyuncular.length) return '';
        final adet = _yazbozKafaSayilari[_oyuncular[index]] ?? 0;
        return adet <= 0 ? '' : List.filled(adet, 'X').join();
      }
      if (esli) {
        final indexes = sutunIndex == 0 ? <int>[0, 2] : <int>[1, 3];
        final toplam = indexes.fold<int>(0, (a, i) => a + (_oyuncular.length > i ? (_yazbozKafaSayilari[_oyuncular[i]] ?? 0) : 0));
        return toplam <= 0 ? '' : List.filled(toplam, 'X').join();
      }
      return kafaDegeri(sutunIndex);
    }

    final elMatch = RegExp(r'^(\d+)\. El$').firstMatch(satir);
    if (elMatch == null) return '';
    final elNo = int.tryParse(elMatch.group(1) ?? '') ?? 0;
    final puanlar = _yazbozElPuanlari[elNo];
    if (puanlar == null) return '';

    String oyuncuPuani(int index) {
      if (index < 0 || index >= _oyuncular.length) return '';
      return puanlar[_oyuncular[index]] ?? '';
    }

    if (esli) {
      final indexes = sutunIndex == 0 ? <int>[0, 2] : <int>[1, 3];
      final degerler = indexes.map(oyuncuPuani).where((v) => v.isNotEmpty).toList();
      if (degerler.isEmpty) return '';
      final sayilar = degerler.map(int.tryParse).whereType<int>().toList();
      return sayilar.length == degerler.length ? '${sayilar.fold<int>(0, (a, b) => a + b)}' : degerler.join('/');
    }

    return oyuncuPuani(sutunIndex);
  }

  Widget _yazbozTablo({required List<String> basliklar, required List<String> satirlar}) {
    final esli = basliklar.length == 2;
    final satirSayisi = satirlar.length + 1;
    const baslikYukseklik = 68.0;
    const normalSatirYukseklik = 64.0;
    final tabloYukseklik = baslikYukseklik + (satirlar.length * normalSatirYukseklik) + 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final genislik = constraints.maxWidth.isFinite ? constraints.maxWidth : 980.0;
        final solBaslikGenislik = genislik * (basliklar.length == 2 ? .24 : .19);

        return SizedBox(
          width: genislik,
          height: tabloYukseklik,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(genislik, tabloYukseklik),
                painter: _ElleCizilmisYazbozTabloPainter(
                  sutunSayisi: basliklar.length,
                  satirSayisi: satirSayisi,
                  solBaslikGenislik: solBaslikGenislik,
                  baslikYukseklik: baslikYukseklik,
                  satirYukseklik: normalSatirYukseklik,
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(
                      height: baslikYukseklik,
                      child: Row(
                        children: [
                          SizedBox(width: solBaslikGenislik),
                          for (var i = 0; i < basliklar.length; i++)
                            Expanded(
                              child: _elYazisiHucre(
                                basliklar[i].toUpperCase(),
                                baslik: true,
                                aci: i.isEven ? -0.011 : 0.009,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < satirlar.length; i++)
                      SizedBox(
                        height: normalSatirYukseklik,
                        child: Row(
                          children: [
                            SizedBox(
                              width: solBaslikGenislik,
                              child: _elYazisiHucre(
                                satirlar[i],
                                solBaslik: true,
                                aci: i.isEven ? -0.016 : 0.011,
                              ),
                            ),
                            for (var j = 0; j < basliklar.length; j++)
                              Expanded(
                                child: _elYazisiHucre(
                                  _yazbozHucreDegeri(satirlar[i], j, esli),
                                  aci: (i + j).isEven ? -0.008 : 0.007,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _elYazisiHucre(
    String text, {
    bool baslik = false,
    bool solBaslik = false,
    double aci = 0,
  }) {
    return Transform.rotate(
      angle: aci,
      child: Container(
        alignment: solBaslik ? Alignment.centerLeft : Alignment.center,
        padding: EdgeInsets.only(left: solBaslik ? 20 : 8, right: 8, top: baslik ? 4 : 0),
        child: Text(
          text,
          maxLines: baslik ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: solBaslik ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: const Color(0xff112761),
            fontSize: baslik ? 18 : 28,
            height: 1.0,
            fontWeight: baslik ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Comic Sans MS',
            letterSpacing: baslik ? .3 : .0,
          ),
        ),
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

  bool _gercekOkeyMi(OkeyTasi tas) {
    final okey = _okey;
    return okey != null && !tas.sahteOkeyMi && tas.sayi == okey.sayi && tas.renk == okey.renk;
  }

  int? _tasHesapSayisi(OkeyTasi tas) {
    if (tas.sahteOkeyMi) return _okey?.sayi;
    return tas.sayi;
  }

  TasRengi _tasHesapRengi(OkeyTasi tas) {
    if (tas.sahteOkeyMi) return _okey?.renk ?? TasRengi.sahteOkey;
    return tas.renk;
  }

  int _tasPuanDegeri(OkeyTasi tas) => _tasHesapSayisi(tas) ?? 0;

  int _eldeKalanPuan() => _eldekiTaslar().fold<int>(0, (toplam, tas) => toplam + _tasPuanDegeri(tas));

  int _grupPuani(List<OkeyTasi> grup) {
    if (grup.isEmpty) return 0;
    final jokerSayisi = grup.where(_gercekOkeyMi).length;
    final normal = grup.where((t) => !_gercekOkeyMi(t)).toList();
    if (jokerSayisi == 0) {
      return normal.fold<int>(0, (toplam, tas) => toplam + _tasPuanDegeri(tas));
    }
    final normalSayilar = normal.map(_tasHesapSayisi).whereType<int>().toList();
    if (normalSayilar.isEmpty) return jokerSayisi * (_okey?.sayi ?? 0);

    final ayniSayi = normalSayilar.toSet().length == 1;
    if (ayniSayi) {
      final deger = normalSayilar.first;
      return normalSayilar.fold<int>(0, (a, b) => a + b) + (jokerSayisi * deger);
    }

    final renkler = normal.map(_tasHesapRengi).toSet();
    if (renkler.length == 1) {
      final sayilar = normalSayilar.toSet().toList()..sort();
      var toplam = sayilar.fold<int>(0, (a, b) => a + b);
      var kalanJoker = jokerSayisi;
      for (var beklenen = sayilar.first; beklenen <= sayilar.last && kalanJoker > 0; beklenen++) {
        if (!sayilar.contains(beklenen)) {
          toplam += beklenen;
          kalanJoker--;
        }
      }
      var sonraki = sayilar.last + 1;
      while (kalanJoker > 0) {
        toplam += sonraki > 13 ? 13 : sonraki;
        sonraki++;
        kalanJoker--;
      }
      return toplam;
    }

    return normalSayilar.fold<int>(0, (a, b) => a + b) + (jokerSayisi * (normalSayilar.isEmpty ? 0 : normalSayilar.reduce(max)));
  }

  int _tasSirala(OkeyTasi a, OkeyTasi b) {
    if (_gercekOkeyMi(a) && !_gercekOkeyMi(b)) return 1;
    if (!_gercekOkeyMi(a) && _gercekOkeyMi(b)) return -1;
    final renkKarsilastir = _tasHesapRengi(a).index.compareTo(_tasHesapRengi(b).index);
    if (renkKarsilastir != 0) return renkKarsilastir;
    final sayiKarsilastir = (_tasHesapSayisi(a) ?? 99).compareTo(_tasHesapSayisi(b) ?? 99);
    if (sayiKarsilastir != 0) return sayiKarsilastir;
    return a.kopyaNo.compareTo(b.kopyaNo);
  }

  void _puanlariGuncelle() {
    // Üst gösterge artık gizli otomatik motora göre değil, oyuncunun ıstakada
    // gerçekten oluşturduğu/dizdiği perlere göre çalışır. Böylece desteden
    // veya soldan alınan taş tek başına puanı yükseltmez.
    final seriler = _istakadakiManuelSeriGruplari();
    _seriToplam = seriler.fold<int>(0, (toplam, grup) => toplam + _grupPuani(grup));
    _ciftSayisi = _istakadakiManuelCiftGruplari().length;
  }

  List<List<OkeyTasi>> _guncelSeriGruplari() {
    return _istakadakiManuelSeriGruplari();
  }

  List<List<OkeyTasi>> _istakadakiManuelCiftGruplari() {
    final sonuc = <List<OkeyTasi>>[];

    void satiriTara(int bas, int son) {
      var i = bas;
      while (i < son) {
        final ilk = _istaka[i];
        if (ilk == null) {
          i++;
          continue;
        }
        if (i + 1 < son) {
          final ikinci = _istaka[i + 1];
          if (ikinci != null && _manuelCiftGecerliMi(ilk, ikinci)) {
            sonuc.add(<OkeyTasi>[ilk, ikinci]);
            i += 2;
            continue;
          }
        }
        i++;
      }
    }

    satiriTara(0, _istakaSiraKapasite);
    satiriTara(_istakaSiraKapasite, _istakaKapasite);
    return sonuc;
  }

  bool _manuelCiftGecerliMi(OkeyTasi a, OkeyTasi b) {
    if (_gercekOkeyMi(a) && _gercekOkeyMi(b)) return true;
    if (a.sahteOkeyMi && b.sahteOkeyMi) return true;
    if (_gercekOkeyMi(a) || _gercekOkeyMi(b)) return true;
    return _tasHesapSayisi(a) != null &&
        _tasHesapSayisi(a) == _tasHesapSayisi(b) &&
        _tasHesapRengi(a) == _tasHesapRengi(b);
  }

  List<List<OkeyTasi>> _istakadakiManuelSeriGruplari() {
    final sonuc = <List<OkeyTasi>>[];

    void satiriTara(int bas, int son) {
      var grup = <OkeyTasi>[];
      void grubuKapat() {
        if (grup.length >= 3 && _manuelSeriGecerliMi(grup)) {
          sonuc.add(List<OkeyTasi>.from(grup));
        }
        grup = <OkeyTasi>[];
      }

      for (var i = bas; i < son; i++) {
        final tas = _istaka[i];
        if (tas == null) {
          grubuKapat();
        } else {
          grup.add(tas);
        }
      }
      grubuKapat();
    }

    satiriTara(0, _istakaSiraKapasite);
    satiriTara(_istakaSiraKapasite, _istakaKapasite);
    return sonuc;
  }

  bool _manuelSeriGecerliMi(List<OkeyTasi> grup) {
    if (grup.length < 3 || grup.length > 13) return false;
    return _manuelAyniSayiPeriMi(grup) || _manuelSiraliPerMi(grup);
  }

  bool _manuelAyniSayiPeriMi(List<OkeyTasi> grup) {
    if (grup.length < 3 || grup.length > 4) return false;
    final normal = grup.where((t) => !_gercekOkeyMi(t)).toList();
    if (normal.isEmpty) return true;
    final sayilar = normal.map(_tasHesapSayisi).whereType<int>().toSet();
    if (sayilar.length != 1) return false;
    final renkler = normal.map(_tasHesapRengi).toList();
    if (renkler.toSet().length != renkler.length) return false;
    return true;
  }

  bool _manuelSiraliPerMi(List<OkeyTasi> grup) {
    if (grup.length < 3 || grup.length > 13) return false;
    final normal = grup.where((t) => !_gercekOkeyMi(t)).toList();
    if (normal.isEmpty) return true;
    final renkler = normal.map(_tasHesapRengi).toSet();
    if (renkler.length != 1) return false;
    final renk = renkler.first;

    bool yonuDene(int yon) {
      for (var baslangic = yon == 1 ? 1 : grup.length; baslangic <= 13; baslangic++) {
        var uygun = true;
        for (var i = 0; i < grup.length; i++) {
          final beklenen = yon == 1 ? baslangic + i : baslangic - i;
          if (beklenen < 1 || beklenen > 13) {
            uygun = false;
            break;
          }
          final tas = grup[i];
          if (_gercekOkeyMi(tas)) continue;
          if (_tasHesapRengi(tas) != renk || _tasHesapSayisi(tas) != beklenen) {
            uygun = false;
            break;
          }
        }
        if (uygun) return true;
      }
      return false;
    }

    return yonuDene(1) || yonuDene(-1);
  }

  List<List<OkeyTasi>> _seriGruplari() {
    final eldeki = _eldekiTaslar();
    final jokerler = eldeki.where(_gercekOkeyMi).toList();
    final normalTaslar = eldeki.where((t) => !_gercekOkeyMi(t) && _tasHesapSayisi(t) != null).toList();
    final idIndex = <String, int>{};
    for (var i = 0; i < eldeki.length; i++) {
      idIndex[eldeki[i].id] = i;
    }

    int maske(List<OkeyTasi> taslar) {
      var sonuc = 0;
      for (final tas in taslar) {
        final index = idIndex[tas.id];
        if (index != null) sonuc |= (1 << index);
      }
      return sonuc;
    }

    List<List<OkeyTasi>> jokerSecimleri(int adet) {
      if (adet == 0) return <List<OkeyTasi>>[<OkeyTasi>[]];
      if (adet > jokerler.length) return <List<OkeyTasi>>[];
      if (adet == 1) return jokerler.map((j) => <OkeyTasi>[j]).toList();
      final sonuc = <List<OkeyTasi>>[];
      void tara(int start, List<OkeyTasi> secilen) {
        if (secilen.length == adet) {
          sonuc.add(List<OkeyTasi>.from(secilen));
          return;
        }
        for (var i = start; i < jokerler.length; i++) {
          secilen.add(jokerler[i]);
          tara(i + 1, secilen);
          secilen.removeLast();
        }
      }
      tara(0, <OkeyTasi>[]);
      return sonuc;
    }

    Iterable<List<T>> kombinasyonlar<T>(List<T> liste, int adet) sync* {
      if (adet <= 0) {
        yield <T>[];
        return;
      }
      if (adet > liste.length) return;
      Iterable<List<T>> rec(int start, int kalan, List<T> secilen) sync* {
        if (kalan == 0) {
          yield List<T>.from(secilen);
          return;
        }
        for (var i = start; i <= liste.length - kalan; i++) {
          secilen.add(liste[i]);
          yield* rec(i + 1, kalan - 1, secilen);
          secilen.removeLast();
        }
      }
      yield* rec(0, adet, <T>[]);
    }

    final adaylar = <_PerAdayi>[];

    void adayEkle(List<OkeyTasi> taslar, int puan) {
      if (taslar.length < 3) return;
      final m = maske(taslar);
      if (m == 0) return;
      if (adaylar.any((a) => a.mask == m && a.puan == puan)) return;
      adaylar.add(_PerAdayi(List<OkeyTasi>.from(taslar), puan, m));
    }

    // Aynı sayı, farklı renk perleri. 4'lü grup varsa tüm 3'lü alt seçenekler de denenir;
    // böylece örneğin mavi 3 başka daha değerli seri için gerekiyorsa 4'lüye kilitlenmez.
    for (var sayi = 13; sayi >= 1; sayi--) {
      final ayniSayi = normalTaslar.where((t) => _tasHesapSayisi(t) == sayi).toList();
      final renkSecilen = <TasRengi, OkeyTasi>{};
      for (final tas in ayniSayi) {
        renkSecilen.putIfAbsent(_tasHesapRengi(tas), () => tas);
      }
      final secilen = renkSecilen.values.toList()..sort(_tasSirala);

      for (var adet = 3; adet <= min(4, secilen.length); adet++) {
        for (final komb in kombinasyonlar(secilen, adet)) {
          adayEkle(komb, sayi * adet);
        }
      }

      if (secilen.length == 2) {
        for (final js in jokerSecimleri(1)) {
          adayEkle(<OkeyTasi>[...secilen, ...js], sayi * 3);
        }
      }
      if (secilen.length == 1) {
        for (final js in jokerSecimleri(2)) {
          adayEkle(<OkeyTasi>[secilen.first, ...js], sayi * 3);
        }
      }
    }

    // Aynı renk sıralı perler. Tüm olası aralıklar adaydır; seçim toplam puanı maksimize eder.
    // ÖNEMLİ: Aynı renk/sayıdan iki fiziksel taş varsa ikisi de ayrı aday olarak denenir.
    // Eski mantık her sayı için firstWhere ile tek taşı seçtiği için, örneğin iki tane siyah 11 varsa
    // sadece ilk siyah 11 adaylara giriyor, ikinci siyah 11 başka bir serde kullanılamıyordu.
    void siraliKombinasyonlariEkle({
      required TasRengi renk,
      required int bas,
      required int bitis,
      required List<int> sayilar,
      required Map<int, List<OkeyTasi>> normalSecenekler,
      required List<OkeyTasi> jokerSecimi,
      required int puan,
    }) {
      final sirali = <OkeyTasi>[];
      var jokerIndex = 0;

      void tara(int sayiIndex) {
        if (sayiIndex == sayilar.length) {
          adayEkle(sirali, puan);
          return;
        }

        final sayi = sayilar[sayiIndex];
        final normalListe = normalSecenekler[sayi] ?? <OkeyTasi>[];
        if (normalListe.isEmpty) {
          if (jokerIndex >= jokerSecimi.length) return;
          final joker = jokerSecimi[jokerIndex];
          jokerIndex++;
          sirali.add(joker);
          tara(sayiIndex + 1);
          sirali.removeLast();
          jokerIndex--;
          return;
        }

        for (final tas in normalListe) {
          if (sirali.any((secili) => secili.id == tas.id)) continue;
          sirali.add(tas);
          tara(sayiIndex + 1);
          sirali.removeLast();
        }
      }

      tara(0);
    }

    for (final renk in [TasRengi.mavi, TasRengi.sari, TasRengi.kirmizi, TasRengi.siyah]) {
      for (var bas = 1; bas <= 13; bas++) {
        for (var bitis = bas + 2; bitis <= 13; bitis++) {
          final sayilar = List<int>.generate(bitis - bas + 1, (index) => bas + index);
          final normalSecenekler = <int, List<OkeyTasi>>{};
          final eksikSayilar = <int>[];
          var puan = 0;

          for (final sayi in sayilar) {
            puan += sayi;
            final bulunanlar = normalTaslar
                .where((t) => _tasHesapRengi(t) == renk && _tasHesapSayisi(t) == sayi)
                .toList()
              ..sort(_tasSirala);
            if (bulunanlar.isEmpty) {
              eksikSayilar.add(sayi);
            } else {
              normalSecenekler[sayi] = bulunanlar;
            }
          }

          if (eksikSayilar.length > jokerler.length) continue;
          if (sayilar.length < 3) continue;

          for (final js in jokerSecimleri(eksikSayilar.length)) {
            siraliKombinasyonlariEkle(
              renk: renk,
              bas: bas,
              bitis: bitis,
              sayilar: sayilar,
              normalSecenekler: normalSecenekler,
              jokerSecimi: js,
              puan: puan,
            );
          }
        }
      }
    }

    adaylar.sort((a, b) {
      final puan = b.puan.compareTo(a.puan);
      if (puan != 0) return puan;
      return b.taslar.length.compareTo(a.taslar.length);
    });

    final skorByMask = <int, int>{0: 0};
    final tasSayisiByMask = <int, int>{0: 0};
    final secimByMask = <int, List<_PerAdayi>>{0: <_PerAdayi>[]};

    for (final aday in adaylar) {
      final mevcutMaskeler = List<int>.from(skorByMask.keys);
      for (final mask in mevcutMaskeler) {
        if ((mask & aday.mask) != 0) continue;
        final yeniMask = mask | aday.mask;
        final yeniSkor = (skorByMask[mask] ?? 0) + aday.puan;
        final yeniTasSayisi = (tasSayisiByMask[mask] ?? 0) + aday.taslar.length;
        final eskiSkor = skorByMask[yeniMask];
        final eskiTasSayisi = tasSayisiByMask[yeniMask] ?? 0;
        if (eskiSkor == null || yeniSkor > eskiSkor || (yeniSkor == eskiSkor && yeniTasSayisi > eskiTasSayisi)) {
          skorByMask[yeniMask] = yeniSkor;
          tasSayisiByMask[yeniMask] = yeniTasSayisi;
          secimByMask[yeniMask] = <_PerAdayi>[...?secimByMask[mask], aday];
        }
      }
    }

    var enIyiMask = 0;
    for (final entry in skorByMask.entries) {
      final mask = entry.key;
      final skor = entry.value;
      final enIyiSkor = skorByMask[enIyiMask] ?? 0;
      final tasSayisi = tasSayisiByMask[mask] ?? 0;
      final enIyiTasSayisi = tasSayisiByMask[enIyiMask] ?? 0;
      if (skor > enIyiSkor || (skor == enIyiSkor && tasSayisi > enIyiTasSayisi)) {
        enIyiMask = mask;
      }
    }

    return (secimByMask[enIyiMask] ?? <_PerAdayi>[]).map((a) => a.taslar).toList();
  }

  List<List<OkeyTasi>> _ciftGruplari() {
    final taslar = _eldekiTaslar().toList()..sort(_tasSirala);
    final sonuc = <List<OkeyTasi>>[];
    final kullanilan = <String>{};

    final sahteOkeyler = taslar.where((t) => t.sahteOkeyMi).toList();
    if (sahteOkeyler.length >= 2) {
      sonuc.add([sahteOkeyler[0], sahteOkeyler[1]]);
      kullanilan.add(sahteOkeyler[0].id);
      kullanilan.add(sahteOkeyler[1].id);
    }

    for (final tas in taslar.where((t) => !_gercekOkeyMi(t) && _tasHesapSayisi(t) != null)) {
      if (kullanilan.contains(tas.id)) continue;
      final esIndex = taslar.indexWhere((t) =>
          !kullanilan.contains(t.id) &&
          t.id != tas.id &&
          !_gercekOkeyMi(t) &&
          _tasHesapSayisi(t) == _tasHesapSayisi(tas) &&
          _tasHesapRengi(t) == _tasHesapRengi(tas));
      if (esIndex != -1) {
        final es = taslar[esIndex];
        sonuc.add([tas, es]);
        kullanilan.add(tas.id);
        kullanilan.add(es.id);
      }
    }

    // Gerçek okey elde kalırsa, en yüksek değerli tek taşı tamamlayacak çift jokeri gibi kullanılır.
    final bosJokerler = taslar.where((t) => _gercekOkeyMi(t) && !kullanilan.contains(t.id)).toList();
    for (final joker in bosJokerler) {
      final adaylar = taslar
          .where((t) => !kullanilan.contains(t.id) && t.id != joker.id && !_gercekOkeyMi(t) && _tasHesapSayisi(t) != null)
          .toList()
        ..sort((a, b) => (_tasPuanDegeri(b)).compareTo(_tasPuanDegeri(a)));
      if (adaylar.isEmpty) break;
      final tas = adaylar.first;
      sonuc.add([tas, joker]);
      kullanilan.add(tas.id);
      kullanilan.add(joker.id);
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

class _PerAdayi {
  final List<OkeyTasi> taslar;
  final int puan;
  final int mask;

  const _PerAdayi(this.taslar, this.puan, [this.mask = 0]);
}

class _YirtikDefterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 22);
    for (double x = 0; x <= size.width; x += 22) {
      final y = 12 + sin(x * .13) * 5 + sin(x * .037) * 7 + ((x ~/ 22).isEven ? -3 : 4);
      path.lineTo(x, y.clamp(2, 26).toDouble());
    }

    for (double y = 22; y <= size.height; y += 24) {
      final x = size.width - 12 + sin(y * .12) * 6 + ((y ~/ 24).isEven ? 5 : -4);
      path.lineTo(x.clamp(size.width - 24, size.width).toDouble(), y);
    }

    for (double x = size.width; x >= 0; x -= 22) {
      final y = size.height - 12 + sin(x * .11) * 5 + sin(x * .031) * 6 + ((x ~/ 22).isEven ? 3 : -4);
      path.lineTo(x, y.clamp(size.height - 28, size.height).toDouble());
    }

    for (double y = size.height; y >= 22; y -= 24) {
      final x = 13 + sin(y * .14) * 6 + ((y ~/ 24).isEven ? -6 : 5);
      path.lineTo(x.clamp(0, 28).toDouble(), y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _KareliDefterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Kağıt ana zemini. Bunu CustomPainter içinde çiziyoruz ki kareler ve delikler
    // Container rengi tarafından kapanmasın.
    final paper = Paint()..color = const Color(0xfff4f0dc);
    canvas.drawRect(Offset.zero & size, paper);

    // Kağıt dokusu: çok hafif sarımsı lekeler.
    final texture = Paint()..color = const Color(0xffe0d4aa).withOpacity(.16);
    for (var i = 0; i < 28; i++) {
      final dx = (i * 79.0 + 31) % size.width;
      final dy = (i * 47.0 + 19) % size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: 150, height: 58), texture);
    }

    // Kareli defter çizgileri: hedef görseldeki gibi belirgin mavi.
    final gridPaint = Paint()
      ..color = const Color(0xff84a2d4).withOpacity(.46)
      ..strokeWidth = .9;
    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Sol defter payı, kırmızı margin çizgisi ve spiral delikleri.
    final redLine = Paint()
      ..color = const Color(0xffcf5555).withOpacity(.42)
      ..strokeWidth = 1.35;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), redLine);

    final holeDark = Paint()..color = const Color(0xff19221d).withOpacity(.86);
    final holeEdge = Paint()..color = Colors.black.withOpacity(.22);
    final tear = Paint()..color = const Color(0xffded6bd).withOpacity(.72);
    for (double y = 44; y < size.height - 30; y += 35) {
      canvas.drawCircle(Offset(23, y + 1.5), 7.0, holeEdge);
      canvas.drawCircle(Offset(22, y), 5.9, holeDark);
      canvas.drawPath(
        Path()
          ..moveTo(0, y - 12)
          ..lineTo(11, y - 8)
          ..lineTo(5, y + 1)
          ..lineTo(15, y + 9)
          ..lineTo(0, y + 13)
          ..close(),
        tear,
      );
    }

    // Başlık altındaki elde çizilmiş çift dalga çizgi.
    final titlePaint = Paint()
      ..color = const Color(0xff112761).withOpacity(.96)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final offset in [0.0, 5.0]) {
      final y = 83.0 + offset;
      final startX = size.width / 2 - 62;
      final path = Path()..moveTo(startX, y);
      for (double x = 0; x <= 124; x += 5) {
        path.lineTo(startX + x, y + sin(x * .36) * 2.0);
      }
      canvas.drawPath(path, titlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ElleCizilmisYazbozTabloPainter extends CustomPainter {
  final int sutunSayisi;
  final int satirSayisi;
  final double solBaslikGenislik;
  final double baslikYukseklik;
  final double satirYukseklik;

  const _ElleCizilmisYazbozTabloPainter({
    required this.sutunSayisi,
    required this.satirSayisi,
    required this.solBaslikGenislik,
    required this.baslikYukseklik,
    required this.satirYukseklik,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cizgi = Paint()
      ..color = const Color(0xff112761).withOpacity(.98)
      ..strokeWidth = 2.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void dalgaliCizgi(Offset a, Offset b, {double genlik = 1.6, double faz = 0}) {
      final path = Path()..moveTo(a.dx, a.dy);
      final yatay = (b.dy - a.dy).abs() < (b.dx - a.dx).abs();
      const adim = 8.0;
      final uzunluk = yatay ? (b.dx - a.dx).abs() : (b.dy - a.dy).abs();
      final isaret = yatay ? (b.dx >= a.dx ? 1 : -1) : (b.dy >= a.dy ? 1 : -1);
      for (double t = adim; t <= uzunluk; t += adim) {
        final dalga = sin(t * .20 + faz) * genlik + sin(t * .055 + faz) * (genlik * .65);
        if (yatay) {
          path.lineTo(a.dx + t * isaret, a.dy + dalga);
        } else {
          path.lineTo(a.dx + dalga, a.dy + t * isaret);
        }
      }
      path.lineTo(b.dx, b.dy);
      canvas.drawPath(path, cizgi);
    }

    final contentTop = 10.0;
    final contentBottom = size.height - 12;
    final contentLeft = 0.0;
    final contentRight = size.width;

    dalgaliCizgi(Offset(solBaslikGenislik, contentTop + 6), Offset(solBaslikGenislik, contentBottom - 2), genlik: 1.45, faz: .3);

    final oyuncuAlanGenislik = size.width - solBaslikGenislik;
    for (var i = 1; i < sutunSayisi; i++) {
      final x = solBaslikGenislik + oyuncuAlanGenislik * i / sutunSayisi;
      dalgaliCizgi(Offset(x, contentTop + (i.isEven ? 0 : 5)), Offset(x, contentBottom - (i.isEven ? 3 : 0)), genlik: 1.35, faz: i * .8);
    }

    var y = contentTop + baslikYukseklik;
    dalgaliCizgi(Offset(contentLeft, y), Offset(contentRight, y + 1), genlik: 1.55, faz: .5);
    for (var i = 0; i < satirSayisi - 1; i++) {
      y += satirYukseklik;
      dalgaliCizgi(Offset(contentLeft, y + (i.isEven ? 0 : 1)), Offset(contentRight, y), genlik: i.isEven ? 1.7 : 1.35, faz: i * .55);
    }
  }

  @override
  bool shouldRepaint(covariant _ElleCizilmisYazbozTabloPainter oldDelegate) {
    return oldDelegate.sutunSayisi != sutunSayisi ||
        oldDelegate.satirSayisi != satirSayisi ||
        oldDelegate.solBaslikGenislik != solBaslikGenislik ||
        oldDelegate.baslikYukseklik != baslikYukseklik ||
        oldDelegate.satirYukseklik != satirYukseklik;
  }
}
