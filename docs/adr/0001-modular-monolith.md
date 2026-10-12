# ADR 0001: Mikroservis yerine modüler monolit

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-12

## Bağlam

Uygulamada beş iş alanı var: kimlik, organizasyon yapısı, Andon, Kaizen ve 5S.
Bunları ayrı ayrı servisler (mikroservis) olarak ya da tek bir uygulama içinde
geliştirebiliriz.

Kısıtlarımız:

- Proje tek geliştirici tarafından, sınırlı sürede geliştiriliyor.
- Beklenen kullanıcı sayısı bir fabrika ölçeğinde (birkaç bin kişi).
- Modüller arasında sıkı ilişkiler var (ör. 5S bulgusundan Kaizen önerisi açılıyor).

## Karar

Backend'i **tek bir ASP.NET Core uygulaması** olarak geliştiriyoruz, ancak içini
birbirinden net çizgilerle ayrılmış **beş modüle** bölüyoruz (modüler monolit).

- Her modül yalnızca kendi verisinin sahibidir.
- Modüller birbirinin tablolarına doğrudan erişmez; arayüz veya olay üzerinden konuşur.
- Bu sınırlar mimari testlerle korunur; ihlal CI'ı kırar.

## Sonuçlar

**Artılar**

- Tek uygulama, tek veritabanı, tek dağıtım: geliştirmesi, test etmesi ve çalıştırması çok daha basit.
- Modüller arası çağrılar ağ üzerinden değil bellek içinde; daha hızlı ve hata noktası daha az.
- Veritabanı işlemleri (transaction) tek yerde yönetilebiliyor.
- Modül sınırları baştan net olduğu için, ileride bir modül gerçekten ayrı ölçeklenmesi gerekirse ayrı bir servise taşınabilir.

**Eksiler**

- Tüm uygulama birlikte dağıtılır; bir modüldeki değişiklik tüm uygulamanın yeniden başlatılmasını gerektirir.
- Bir modül tek başına ölçeklenemez; ölçeklemek için tüm uygulamanın kopyası çalıştırılır.
- Modül sınırlarına uyulması disiplin ister; bu yüzden mimari testler zorunludur.

## Değerlendirilen alternatifler

- **Mikroservisler:** Her modül ayrı servis. Bu ölçekte getirdiği karmaşıklık (servisler arası iletişim, dağıtık işlemler, birden çok dağıtım hattı, izleme) faydasından fazla.
- **Katmanlı tek uygulama (modülsüz):** En basit seçenek, ama zamanla her şeyin birbirine bağlandığı ve değiştirilmesi zor bir yapıya dönüşme riski yüksek.
