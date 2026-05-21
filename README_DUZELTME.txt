101Yancı v1.4.9 oda test acil düzeltme

Bu patch özellikle game_table_page.dart üzerinde hazırlandı.
Yapılanlar:
- Oda açılır açılmaz 3 bot masada bekler.
- Test başlat butonu tamamen lokal çalışır; Firestore/oda doluluk kontrolü beklemez.
- Test başlat basınca oyuncuya 22 taş, 3 bota 21'er taş dağıtılır.
- Seri diz, Çift diz, Seri aç, Çift aç, Taş işle butonları oyuncu ıstakasının sağında görünür.
- Oyuncunun atılan taş alanı ıstakanın sağında butonların yanında durur.
- Çıkış butonu ana menüye döner.
- Ayarlar butonu oyundan çıkarmadan ayarlar dialogunu oyun üstünde açar.

Kopyalama:
Bu zip içindeki lib klasörünü mevcut projenin lib klasörünün üstüne yazdır.
Sonra:
flutter clean
flutter pub get
flutter run -d chrome
