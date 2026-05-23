101-yanci v1.4.9 masa ve el geçiş fix

Bu patch iki ana düzeltme içerir:

1) 101 Odaları ekranı metinleri:
- Sağ üst: Oda Aç -> Masa Aç
- Boş liste: "101 için açık oda yok" -> "Açık masa bulunamadı"
- Buton: Oda Oluştur -> Masa Aç

2) Çok elli oyun akışı:
- Tur kutusu artık 1. El / 2. El / ... şeklinde gösterir.
- Deste bittikten sonra oyuncu taşını atınca el sonu tetiklenir.
- Seçilen el sayısı bitmediyse yeni el başlatılır.
- Yeni elde deste tekrar oluşturulur/karıştırılır.
- Yeni gösterge ve okey belirlenir.
- Taşlar tekrar dağıtılır.
- Başlayan oyuncu yeniden rastgele seçilir.
- Son el bittiyse oyun durur ve yazboz/toplam aşamasına geçilecek mesajı gösterilir.

Not: Bu patch puan hesaplamasını tam kurallara bağlamaz; sadece el geçiş mekanizmasını çalışır hale getirir.
