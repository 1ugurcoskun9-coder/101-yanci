101-yanci v1.4.9 Yazboz El Çizimi UI Patch

Bu patch sadece yazboz popup görünümünü değiştirir.
Oyun akışına, taş dağıtımına, masa yerleşimine veya kural motoruna dokunulmadı.

Yapılanlar:
- Yazboz popup kareli defter yaprağı görünümüne alındı.
- Kenarlar yırtılmış sayfa hissi için ClipPath ile düzensiz kesildi.
- Tablo çizgileri düz TableBorder yerine CustomPainter ile elle çizilmiş/dalgalı çizgilere çevrildi.
- Yazılar lacivert kalem rengi ve el yazısı hissi verecek stile alındı.
- Başlık altında elle çizilmiş dalgalı çizgi eklendi.
- Cezalı mod kapalıysa Ceza satırı gizli kalır.
- Eşli modda 2 sütun, tek modda 4 sütun korunur.
- El sayısı 1-11 arası dinamik satır üretmeye devam eder.
- Siler satırı eklenmedi.

Not: Bu ortamda Flutter SDK bulunmadığı için flutter analyze çalıştırılamadı. Dart dosyasında süslü/parantez dengesi kontrol edildi.
