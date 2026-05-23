import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  static final Set<String> _botMotoruCalisanOdalar = <String>{};
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  Future<String> odaOlustur({
    required String oyunTuru,
    required String oyunSekli,
    required bool katlamali,
    required bool yardimli,
    bool cezali = false,
    int elSayisi = 11,
    int girisUcreti = 10000,
    bool sifreli = false,
    String sifre = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Oda oluşturmak için giriş yapmalısın.');

    final roomRef = _rooms.doc();
    final odaKodu = roomRef.id.substring(0, 6).toUpperCase();
    final guvenliElSayisi = elSayisi.clamp(1, 11).toInt();

    await roomRef.set({
      'id': roomRef.id,
      'odaKodu': odaKodu,
      'oyunTuru': oyunTuru,
      'oyunSekli': oyunSekli,
      'katlamali': katlamali,
      'yardimli': yardimli,
      'cezali': cezali,
      'elSayisi': guvenliElSayisi,
      'toplamElSayisi': guvenliElSayisi,
      'mevcutEl': 1,
      'girisUcreti': girisUcreti,
      'sifreli': sifreli,
      'sifre': sifreli ? sifre : '',
      'durum': 'bekliyor',
      'maxOyuncu': 4,
      'oyuncuSayisi': 1,
      'olusturanUid': user.uid,
      'olusturanAd': user.displayName ?? 'Oyuncu',
      'oyuncular': [user.uid],
      'oyuncuAdlari': {user.uid: user.displayName ?? 'Oyuncu'},
      'botSayisi': 0,
      'oyunBasladi': false,
      'aktifOyuncuIndex': 0,
      'eller': <String, dynamic>{},
      'ortaTaslar': [],
      'gostergeTasi': null,
      'okeyTasi': null,
      'atilanTaslar': <String, dynamic>{},
      'acilanGruplar': [],
      'elActiMi': <String, dynamic>{},
      'botMotoruCalisiyor': false,
      'sonHamle': '',
      'olusturulmaTarihi': FieldValue.serverTimestamp(),
      'guncellenmeTarihi': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> acikOdalarStream() {
    return _rooms
        .where('durum', isEqualTo: 'bekliyor')
        .orderBy('olusturulmaTarihi', descending: true)
        .limit(20)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> odaStream(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }

  Future<void> odayaKatil(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Odaya katılmak için giriş yapmalısın.');

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});
      final maxOyuncu = data['maxOyuncu'] ?? 4;

      if (oyuncular.contains(user.uid)) return;
      if (oyuncular.length >= maxOyuncu) throw Exception('Bu oda dolu.');

      oyuncular.add(user.uid);
      oyuncuAdlari[user.uid] = user.displayName ?? 'Oyuncu';

      transaction.update(ref, {
        'oyuncular': oyuncular,
        'oyuncuAdlari': oyuncuAdlari,
        'oyuncuSayisi': oyuncular.length,
        'durum': oyuncular.length >= maxOyuncu ? 'dolu' : 'bekliyor',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> botEkle(String roomId) async {
    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});
      final maxOyuncu = data['maxOyuncu'] ?? 4;
      final botSayisi = data['botSayisi'] ?? 0;

      if (oyuncular.length >= maxOyuncu) throw Exception('Oda zaten dolu.');

      final botNo = botSayisi + 1;
      final botId = 'bot_$botNo';

      oyuncular.add(botId);
      oyuncuAdlari[botId] = 'Bot-$botNo';

      transaction.update(ref, {
        'oyuncular': oyuncular,
        'oyuncuAdlari': oyuncuAdlari,
        'oyuncuSayisi': oyuncular.length,
        'botSayisi': botNo,
        'durum': oyuncular.length >= maxOyuncu ? 'dolu' : 'bekliyor',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> tekOyuncuTestBaslat(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      // Test modu her basışta masayı sıfırdan dağıtır.
      // Böylece önceki bozuk/yarım test durumunda da oyun kilitlenmez.
      final taslar = _standartOkeySetiOlustur();
      _desteyiDogrula(taslar);
      taslar.shuffle(Random());

      final gosterge = _ilkNormalTasiCikar(taslar);
      final okey = _okeyTasiHesapla(gosterge);

      final oyuncular = <String>[user.uid, 'bot_1', 'bot_2', 'bot_3'];
      final oyuncuAdlari = <String, dynamic>{
        user.uid: user.displayName ?? 'Oyuncu',
        'bot_1': 'Bot-1',
        'bot_2': 'Bot-2',
        'bot_3': 'Bot-3',
      };

      final eller = <String, dynamic>{};
      final atilanTaslar = <String, dynamic>{};
      final elActiMi = <String, dynamic>{};

      for (int i = 0; i < oyuncular.length; i++) {
        final oyuncuId = oyuncular[i];
        final adet = i == 0 ? 22 : 21;
        eller[oyuncuId] = taslar.take(adet).toList();
        taslar.removeRange(0, adet);
        atilanTaslar[oyuncuId] = [];
        elActiMi[oyuncuId] = false;
      }

      transaction.update(ref, {
        'oyunBasladi': true,
        'tekOyuncuTestModu': true,
        'durum': 'test',
        'aktifOyuncuIndex': 0,
        'turdaTasCekildiMi': true,
        'oyuncular': oyuncular,
        'oyuncuAdlari': oyuncuAdlari,
        'oyuncuSayisi': oyuncular.length,
        'maxOyuncu': 4,
        'botSayisi': 3,
        'eller': eller,
        'ortaTaslar': taslar,
        'gostergeTasi': gosterge,
        'okeyTasi': okey,
        'atilanTaslar': atilanTaslar,
        'acilanGruplar': [],
        'elActiMi': elActiMi,
        'sonHamle': 'Tek oyunculu test başladı. Taşlar dağıtıldı. İlk hamle sende, önce taş at.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> oyunuBaslat(String roomId) async {
    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);

      if (oyuncular.length < 2) {
        throw Exception('Oyun başlatmak için en az 2 oyuncu/bot olmalı.');
      }
      if (data['oyunBasladi'] == true) return;

      final taslar = _standartOkeySetiOlustur();
      _desteyiDogrula(taslar);
      taslar.shuffle(Random());

      final gosterge = _ilkNormalTasiCikar(taslar);
      final okey = _okeyTasiHesapla(gosterge);

      final eller = <String, dynamic>{};
      final atilanTaslar = <String, dynamic>{};
      final elActiMi = <String, dynamic>{};

      for (int i = 0; i < oyuncular.length; i++) {
        final oyuncuId = oyuncular[i];
        final adet = i == 0 ? 22 : 21;
        eller[oyuncuId] = taslar.take(adet).toList();
        taslar.removeRange(0, adet);
        atilanTaslar[oyuncuId] = [];
        elActiMi[oyuncuId] = false;
      }

      transaction.update(ref, {
        'oyunBasladi': true,
        'durum': 'oyunda',
        'aktifOyuncuIndex': 0,
        'turdaTasCekildiMi': true,
        'eller': eller,
        'ortaTaslar': taslar,
        'gostergeTasi': gosterge,
        'okeyTasi': okey,
        'atilanTaslar': atilanTaslar,
        'acilanGruplar': [],
        'elActiMi': elActiMi,
        'botMotoruCalisiyor': false,
        'sonHamle': 'Oyun başladı. Sıra oyuncuda.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> oyuncuDestedenTasCek(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final aktifIndex = data['aktifOyuncuIndex'] ?? 0;

      if (oyuncular.isEmpty || oyuncular[aktifIndex] != user.uid) {
        throw Exception('Sıra sende değil.');
      }

      final turdaTasCekildiMi = data['turdaTasCekildiMi'] == true;
      if (turdaTasCekildiMi) {
        throw Exception('Bu tur zaten taş çektin. Şimdi taş atmalısın.');
      }

      final ortaTaslar = List.from(data['ortaTaslar'] ?? []);
      if (ortaTaslar.isEmpty) throw Exception('Deste bitti.');

      final eller = Map<String, dynamic>.from(data['eller'] ?? {});
      final el = List.from(eller[user.uid] ?? []);

      if (el.length >= 22) {
        throw Exception('Elinde zaten fazla taş var. Önce taş atmalısın.');
      }

      el.add(ortaTaslar.removeAt(0));
      eller[user.uid] = el;

      transaction.update(ref, {
        'ortaTaslar': ortaTaslar,
        'eller': eller,
        'turdaTasCekildiMi': true,
        'sonHamle': 'Oyuncu desteden taş çekti.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> oyuncuTasAtById(String roomId, String tasId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final aktifIndex = data['aktifOyuncuIndex'] ?? 0;

      if (oyuncular.isEmpty || oyuncular[aktifIndex] != user.uid) {
        throw Exception('Sıra sende değil.');
      }

      final turdaTasCekildiMi = data['turdaTasCekildiMi'] == true;
      if (!turdaTasCekildiMi) {
        throw Exception('Önce desteden taş çekmelisin.');
      }

      final eller = Map<String, dynamic>.from(data['eller'] ?? {});
      final el = List.from(eller[user.uid] ?? []);
      final index = el.indexWhere((e) => Map<String, dynamic>.from(e)['id'] == tasId);
      if (index == -1) throw Exception('Taş elde bulunamadı.');

      final atilan = el.removeAt(index);
      eller[user.uid] = el;

      final atilanTaslar = Map<String, dynamic>.from(data['atilanTaslar'] ?? {});
      final oyuncuAtik = List.from(atilanTaslar[user.uid] ?? []);
      oyuncuAtik.add(atilan);
      atilanTaslar[user.uid] = oyuncuAtik;

      final tekOyuncuTestModu = data['tekOyuncuTestModu'] == true;
      final sonrakiIndex = tekOyuncuTestModu ? aktifIndex : _sonrakiIndex(aktifIndex, oyuncular.length);

      transaction.update(ref, {
        'eller': eller,
        'atilanTaslar': atilanTaslar,
        'aktifOyuncuIndex': sonrakiIndex,
        'turdaTasCekildiMi': false,
        'sonHamle': tekOyuncuTestModu
            ? 'Taş attın. Şimdi desteden taş çekebilirsin.'
            : 'Oyuncu taş attı.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });

    final snap = await _rooms.doc(roomId).get();
    final data = snap.data();
    if (data != null && data['tekOyuncuTestModu'] == true) return;

    await botlariSiraGeldikceOynat(roomId);
  }

  Future<void> oyuncuElAc({
    required String roomId,
    required List<List<Map<String, dynamic>>> gruplar,
    required bool ciftModu,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw Exception('Oda bulunamadı.');

      final data = snap.data() as Map<String, dynamic>;
      final eller = Map<String, dynamic>.from(data['eller'] ?? {});
      final el = List.from(eller[user.uid] ?? []);
      final elActiMi = Map<String, dynamic>.from(data['elActiMi'] ?? {});
      final acilanGruplar = List.from(data['acilanGruplar'] ?? {});

      for (final grup in gruplar) {
        acilanGruplar.add({
          'sahipId': user.uid,
          'ciftModu': ciftModu,
          'taslar': grup,
        });

        for (final tas in grup) {
          final index = el.indexWhere((e) => Map<String, dynamic>.from(e)['id'] == tas['id']);
          if (index != -1) el.removeAt(index);
        }
      }

      eller[user.uid] = el;
      elActiMi[user.uid] = true;

      transaction.update(ref, {
        'eller': eller,
        'elActiMi': elActiMi,
        'acilanGruplar': acilanGruplar,
        'sonHamle': ciftModu ? 'Oyuncu çift açtı.' : 'Oyuncu seri açtı.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> botlariSiraGeldikceOynat(String roomId) async {
    if (_botMotoruCalisanOdalar.contains(roomId)) return;

    _botMotoruCalisanOdalar.add(roomId);

    try {
      for (int i = 0; i < 16; i++) {
        final snap = await _rooms.doc(roomId).get();
        final data = snap.data();
        if (data == null) return;

        final oyunBasladi = data['oyunBasladi'] == true;
        if (!oyunBasladi) return;

        final oyuncular = List<String>.from(data['oyuncular'] ?? []);
        if (oyuncular.isEmpty) return;

        final aktifIndexRaw = data['aktifOyuncuIndex'] ?? 0;
        final aktifIndex = aktifIndexRaw is int ? aktifIndexRaw : 0;
        if (aktifIndex < 0 || aktifIndex >= oyuncular.length) return;

        final aktifOyuncu = oyuncular[aktifIndex];

        if (!aktifOyuncu.startsWith('bot_')) return;

        await Future<void>.delayed(const Duration(milliseconds: 700));

        final hamleYapildi = await _botHamlesiYap(roomId, aktifOyuncu);
        if (!hamleYapildi) return;
      }
    } finally {
      _botMotoruCalisanOdalar.remove(roomId);
    }
  }

  Future<bool> _botHamlesiYap(String roomId, String botId) async {
    final ref = _rooms.doc(roomId);
    bool hamleYapildi = false;

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final aktifIndexRaw = data['aktifOyuncuIndex'] ?? 0;
      final aktifIndex = aktifIndexRaw is int ? aktifIndexRaw : 0;

      if (oyuncular.isEmpty || aktifIndex < 0 || aktifIndex >= oyuncular.length) return;
      if (oyuncular[aktifIndex] != botId) return;

      final ortaTaslar = List.from(data['ortaTaslar'] ?? []);
      final eller = Map<String, dynamic>.from(data['eller'] ?? {});
      final el = List.from(eller[botId] ?? []);
      final okey = data['okeyTasi'] == null ? null : Map<String, dynamic>.from(data['okeyTasi']);

      bool tasCekti = false;
      final turdaTasCekildiMi = data['turdaTasCekildiMi'] == true;

      // Botun eli 21 ise çekmeli, 22 ise direkt atmalı.
      if (!turdaTasCekildiMi && ortaTaslar.isNotEmpty && el.length < 22) {
        el.add(ortaTaslar.removeAt(0));
        tasCekti = true;
      }

      if (el.isEmpty) return;

      final atilacakIndex = _botAtilacakTasIndexSec(el, okey);
      if (atilacakIndex < 0 || atilacakIndex >= el.length) return;

      final atilan = el.removeAt(atilacakIndex);
      eller[botId] = el;

      final atilanTaslar = Map<String, dynamic>.from(data['atilanTaslar'] ?? {});
      final botAtik = List.from(atilanTaslar[botId] ?? []);
      botAtik.add(atilan);
      atilanTaslar[botId] = botAtik;

      final sonrakiIndex = _sonrakiIndex(aktifIndex, oyuncular.length);
      final atilanMap = Map<String, dynamic>.from(atilan);
      final atilanText = _tasText(atilanMap);
      final cektiText = tasCekti ? 'taş çekti ve ' : '';

      transaction.update(ref, {
        'ortaTaslar': ortaTaslar,
        'eller': eller,
        'atilanTaslar': atilanTaslar,
        'aktifOyuncuIndex': sonrakiIndex,
        'turdaTasCekildiMi': false,
        'sonHamle': '$botId ${cektiText}$atilanText attı.',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });

      hamleYapildi = true;
    });

    return hamleYapildi;
  }

  int _botAtilacakTasIndexSec(List el, Map<String, dynamic>? okey) {
    if (el.isEmpty) return 0;

    int enDusukSkor = 999999;
    int secilenIndex = 0;

    for (int i = 0; i < el.length; i++) {
      final tas = Map<String, dynamic>.from(el[i]);
      final skor = _tasBotDegerSkoru(tas, el, okey);

      if (skor < enDusukSkor) {
        enDusukSkor = skor;
        secilenIndex = i;
      }
    }

    return secilenIndex;
  }

  int _tasBotDegerSkoru(Map<String, dynamic> tas, List el, Map<String, dynamic>? okey) {
    // Yüksek skor = elde tutulur. Düşük skor = atılır.
    if (tas['sahteOkey'] == true) return 9000;
    if (_tasOkeyMi(tas, okey)) return 10000;

    final id = tas['id'];
    final renk = tas['renk'];
    final sayi = tas['sayi'];
    if (sayi == null) return 0;

    int skor = 0;

    final ayniRenkSayilar = <int>{};
    final ayniSayiFarkliRenkler = <String>{};
    int ayniTasKopya = 0;

    for (final item in el) {
      final diger = Map<String, dynamic>.from(item);
      if (diger['id'] == id) continue;
      if (diger['sahteOkey'] == true) continue;

      final dRenk = diger['renk'];
      final dSayi = diger['sayi'];
      if (dSayi == null) continue;

      if (dRenk == renk) {
        ayniRenkSayilar.add(dSayi);
        if (dSayi == sayi - 1 || dSayi == sayi + 1) skor += 35;
        if (dSayi == sayi - 2 || dSayi == sayi + 2) skor += 14;
      }

      if (dSayi == sayi && dRenk != renk) {
        ayniSayiFarkliRenkler.add(dRenk.toString());
        skor += 32;
      }

      if (dSayi == sayi && dRenk == renk) {
        ayniTasKopya++;
        skor += 45;
      }
    }

    // Hazır/aday seri koruması.
    if (ayniRenkSayilar.contains(sayi - 1) && ayniRenkSayilar.contains(sayi + 1)) {
      skor += 120;
    }
    if (ayniRenkSayilar.contains(sayi + 1) && ayniRenkSayilar.contains(sayi + 2)) {
      skor += 80;
    }
    if (ayniRenkSayilar.contains(sayi - 1) && ayniRenkSayilar.contains(sayi - 2)) {
      skor += 80;
    }

    // Hazır grup koruması.
    if (ayniSayiFarkliRenkler.length >= 2) skor += 110;
    if (ayniTasKopya >= 1) skor += 90;

    // Uç sayıları ve bağlantısız yüksek taşları biraz daha atılabilir yap.
    if (sayi == 1 || sayi == 13) skor -= 8;
    if (skor == 0) skor = sayi;

    return skor;
  }

  String _tasText(Map<String, dynamic> tas) {
    if (tas['sahteOkey'] == true) return 'sahte okey';
    return '${tas['renk']} ${tas['sayi']}';
  }

  bool _tasOkeyMi(Map<String, dynamic> tas, Map<String, dynamic>? okey) {
    return okey != null && tas['sayi'] == okey['sayi'] && tas['renk'] == okey['renk'];
  }

  int _sonrakiIndex(int aktifIndex, int oyuncuSayisi) {
    if (oyuncuSayisi <= 0) return 0;
    return (aktifIndex + 1) % oyuncuSayisi;
  }

  Future<void> masadanCik(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final oyuncular = List<String>.from(data['oyuncular'] ?? []);
      final oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});

      oyuncular.remove(user.uid);
      oyuncuAdlari.remove(user.uid);

      if (oyuncular.isEmpty) {
        transaction.delete(ref);
      } else {
        transaction.update(ref, {
          'oyuncular': oyuncular,
          'oyuncuAdlari': oyuncuAdlari,
          'oyuncuSayisi': oyuncular.length,
          'durum': 'bekliyor',
          'guncellenmeTarihi': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Map<String, dynamic> _ilkNormalTasiCikar(List<Map<String, dynamic>> taslar) {
    final index = taslar.indexWhere((t) => t['sahteOkey'] != true && t['sayi'] != null);
    if (index == -1) throw Exception('Gösterge taşı bulunamadı.');
    return taslar.removeAt(index);
  }

  Map<String, dynamic> _okeyTasiHesapla(Map<String, dynamic> gosterge) {
    final sayi = gosterge['sayi'] as int;
    return {
      'id': 'okey_${gosterge['renk']}_${sayi == 13 ? 1 : sayi + 1}',
      'sayi': sayi == 13 ? 1 : sayi + 1,
      'renk': gosterge['renk'],
      'kopyaNo': 0,
      'sahteOkey': false,
      'okey': true,
    };
  }

  void _desteyiDogrula(List<Map<String, dynamic>> taslar) {
    if (taslar.length != 106) {
      throw Exception('Deste hatalı: ${taslar.length} taş var, 106 olmalı.');
    }

    final sayac = <String, int>{};

    for (final tas in taslar) {
      final sahte = tas['sahteOkey'] == true;
      final key = sahte ? 'sahte_okey' : '${tas['renk']}_${tas['sayi']}';
      sayac[key] = (sayac[key] ?? 0) + 1;
    }

    if (sayac['sahte_okey'] != 2) {
      throw Exception('Deste hatalı: sahte okey 2 adet olmalı.');
    }

    for (final renk in ['mavi', 'sari', 'kirmizi', 'siyah']) {
      for (int sayi = 1; sayi <= 13; sayi++) {
        final key = '${renk}_$sayi';
        if (sayac[key] != 2) {
          throw Exception('Deste hatalı: $key taşından ${sayac[key] ?? 0} adet var, 2 olmalı.');
        }
      }
    }
  }

  List<Map<String, dynamic>> _standartOkeySetiOlustur() {
    final taslar = <Map<String, dynamic>>[];

    for (final renk in ['mavi', 'sari', 'kirmizi', 'siyah']) {
      for (int kopya = 1; kopya <= 2; kopya++) {
        for (int sayi = 1; sayi <= 13; sayi++) {
          taslar.add({
            'id': '${renk}_${sayi}_$kopya',
            'sayi': sayi,
            'renk': renk,
            'kopyaNo': kopya,
            'sahteOkey': false,
          });
        }
      }
    }

    taslar.add({'id': 'sahte_okey_1', 'sayi': null, 'renk': 'sahteOkey', 'kopyaNo': 1, 'sahteOkey': true});
    taslar.add({'id': 'sahte_okey_2', 'sayi': null, 'renk': 'sahteOkey', 'kopyaNo': 2, 'sahteOkey': true});

    assert(taslar.length == 106);
    return taslar;
  }
}
