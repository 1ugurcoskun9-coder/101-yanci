101-yanci v1.4.9 - Kurallar 2 test fix

Eklenen / düzenlenen test kuralları:
- El açmış oyuncuda 21 taş altına düşme kontrolü aranmaz.
- Sıra akışı saat yönünün tersine sabit: Sen -> Bot3 -> Bot2 -> Bot1 -> Sen.
- Destenin son taşını çeken oyuncu taşını attığında el biter; atılan son taş alınamaz.
- Deste bittiğinde kimse el açmamışsa herkese 202 yazılır ve elde kazanan olmaz.
- Seri açan oyuncuda deste biterse elde kalan taş toplamı puan yazılır.
- Çift açan oyuncuda deste biterse elde kalan taş toplamının 2 katı yazılır.
- Oyuncu tek hamlede tüm taşları açıp son taşı atarsa siler alır; diğer oyunculara 404 yazılır.
- Oyuncu önce el açıp bitiremez, sonraki turda işleyip son taşı atarsa siler alır; diğer oyunculara 202 yazılır.
- Yazboz popup 1. El ve Toplam satırlarında test puanlarını göstermeye başlar.

Not:
- Çift açma, kafa, ceza, katlamalı/katlamasız ve tam yazboz toplam formülü sonraki kural belgesiyle bağlanacak.
- Bu patch sadece lib/pages/game_table_page.dart dosyasını içerir.
