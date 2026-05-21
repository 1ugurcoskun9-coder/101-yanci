101Yancı v1.4.9 oda test toparlama patch

Düzeltilen ana noktalar:
- Test başlat butonu gerçek ElevatedButton yapısına alındı; hit-test/Stack tıklama sorunu azaltıldı.
- Çıkış ve Ayarlar butonları aynı şekilde aktif buton yapısına alındı.
- Oda açılınca 3 bot masada bekler.
- Test başlat lokal motoru çalıştırır: oyuncuya 22 taş, botlara 21 taş dağıtır.
- Alt sağa Seri diz / Çift diz / Seri aç / Çift aç / Taş işle butonları sabit konumlandı.
- Oyuncu ıstakası taş/slot ölçüsü küçültülerek sağdaki atılan taş alanı ve butonların üstüne taşması engellendi.
- Mesaj yazısı tıklamaları engellemesin diye IgnorePointer içine alındı.

Kopyalama:
Bu zip içindeki lib klasörünü mevcut projenin üstüne kopyala.
Sonra:
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
