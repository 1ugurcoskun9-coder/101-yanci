101-yanci v1.4.9 - Taş Görsel + Sahte Okey + Okey Hesap Fix

Bu patch sadece şu dosyalara dokunur:
- lib/pages/game_table_page.dart
- lib/pages/rooms_page.dart önceki patchten aynen korunmuştur.

Yapılanlar:
1) Taş görseli güçlendirildi:
   - Taş zemini daha opak/açık yapıldı.
   - Rakam fontu büyütüldü ve kalınlaştırıldı.
   - Renkler daha doygun hale getirildi.

2) Sahte okey hesaplaması eklendi:
   - Gösterge siyah 10 ise okey siyah 11 kabul edilir.
   - Sahte okey hesaplamada siyah 11 gibi davranır.
   - Per/seri ve elde kalan taş puanı hesaplarında bu değer kullanılır.

3) Gerçek okey taşı joker olarak eklendi:
   - Gerçek okey taşı per oluştururken en yüksek puanlı uygun per adayına yerleştirilmeye çalışılır.
   - Örnek: elde 2 tane 10, 2 tane 13 ve okey varsa okey 13 grubuna öncelik verir.

Not:
- Bu ortamda flutter analyze çalıştırılamadı çünkü Flutter SDK yok.
- Dosyada süslü parantez/parantez dengesi kontrol edildi.
