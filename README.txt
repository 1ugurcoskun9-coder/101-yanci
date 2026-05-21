101Yancı v1.4.9 - Cezalı / Cezasız Masa Ayarı

Eklenen:
1. create_room_page.dart içine Cezalı/Cezasız seçimi eklendi.
2. room_service.dart odaOlustur parametresine cezali eklendi.
3. Firestore oda kaydına 'cezali': true/false yazılır.
4. game_table_page.dart üst barda Cezalı/Cezasız etiketi gösterir.
5. Ceza kuralları henüz çalışmaz; sadece oyun başında seçim alınır.

Kurulum:
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
