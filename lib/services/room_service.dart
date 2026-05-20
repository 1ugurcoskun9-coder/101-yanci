import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  Future<String> odaOlustur({
    required String oyunTuru,
    required String oyunSekli,
    required bool katlamali,
    required bool yardimli,
    required int girisUcreti,
    required bool sifreli,
    required String sifre,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Oda oluşturmak için giriş yapmalısın.');
    }

    final roomRef = _rooms.doc();
    final odaKodu = roomRef.id.substring(0, 6).toUpperCase();

    await roomRef.set({
      'id': roomRef.id,
      'odaKodu': odaKodu,
      'oyunTuru': oyunTuru,
      'oyunSekli': oyunSekli,
      'katlamali': katlamali,
      'yardimli': yardimli,
      'girisUcreti': girisUcreti,
      'sifreli': sifreli,
      'sifre': sifreli ? sifre : '',
      'durum': 'bekliyor',
      'maxOyuncu': 4,
      'oyuncuSayisi': 1,
      'olusturanUid': user.uid,
      'olusturanAd': user.displayName ?? 'Oyuncu',
      'oyuncular': [user.uid],
      'oyuncuAdlari': {
        user.uid: user.displayName ?? 'Oyuncu',
      },
      'botSayisi': 0,
      'oyunBasladi': false,
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

  Future<void> odayaKatil(String roomId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Odaya katılmak için giriş yapmalısın.');
    }

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);

      if (!snap.exists) {
        throw Exception('Oda bulunamadı.');
      }

      final data = snap.data() as Map<String, dynamic>;

      final List oyuncular = List.from(data['oyuncular'] ?? []);
      final Map<String, dynamic> oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});
      final int maxOyuncu = data['maxOyuncu'] ?? 4;
      final String durum = data['durum'] ?? 'bekliyor';

      if (durum != 'bekliyor') {
        throw Exception('Bu oda artık katılıma açık değil.');
      }

      if (oyuncular.contains(user.uid)) {
        return;
      }

      if (oyuncular.length >= maxOyuncu) {
        throw Exception('Bu oda dolu.');
      }

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

      if (!snap.exists) {
        throw Exception('Oda bulunamadı.');
      }

      final data = snap.data() as Map<String, dynamic>;

      final List oyuncular = List.from(data['oyuncular'] ?? []);
      final Map<String, dynamic> oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});
      final int maxOyuncu = data['maxOyuncu'] ?? 4;
      final int botSayisi = data['botSayisi'] ?? 0;

      if (oyuncular.length >= maxOyuncu) {
        throw Exception('Oda zaten dolu.');
      }

      final yeniBotNo = botSayisi + 1;
      final botId = 'bot_$yeniBotNo';

      if (!oyuncular.contains(botId)) {
        oyuncular.add(botId);
      }

      oyuncuAdlari[botId] = 'Bot-$yeniBotNo';

      transaction.update(ref, {
        'oyuncular': oyuncular,
        'oyuncuAdlari': oyuncuAdlari,
        'oyuncuSayisi': oyuncular.length,
        'botSayisi': yeniBotNo,
        'durum': oyuncular.length >= maxOyuncu ? 'dolu' : 'bekliyor',
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> oyunuBaslat(String roomId) async {
    final ref = _rooms.doc(roomId);

    await ref.update({
      'oyunBasladi': true,
      'durum': 'oyunda',
      'guncellenmeTarihi': FieldValue.serverTimestamp(),
    });
  }

  Future<void> masadanCik(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _rooms.doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);

      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      final List oyuncular = List.from(data['oyuncular'] ?? []);
      final Map<String, dynamic> oyuncuAdlari = Map<String, dynamic>.from(data['oyuncuAdlari'] ?? {});

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> odaStream(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }
}
