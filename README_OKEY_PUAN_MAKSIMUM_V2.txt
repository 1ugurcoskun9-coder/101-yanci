101-yanci okey puan maksimum v2

Bu patchte sadece okey/per seçme algoritması yeniden düzenlendi.

Düzeltme:
- Gerçek okey artık tek bir en uzun per ya da ilk bulunan per için harcanmaz.
- Tüm olası seri/aynı sayı per adayları çıkarılır.
- Okeyin her olası temsil ettiği taş denenir.
- Aynı fiziksel taş iki defa kullanılmadan en yüksek TOPLAM puanı veren per kombinasyonu seçilir.
- Eşit puanda daha çok taş kullanan kombinasyon tercih edilir.

Örnek hedef:
- Eldeki taşlarda siyah 11 + siyah 12 varsa ve okey siyah 13 olarak daha yüksek toplam üretiyorsa,
  sistem okeyi düşük puanlı başka bir boşluğa harcamak yerine siyah 13 olarak değerlendirmelidir.
