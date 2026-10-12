# ADR 0002: Offline-first mobil uygulama ve gönderim kuyruğu (outbox)

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-12

## Bağlam

Fabrika sahasında internet bağlantısı her yerde güvenilir değildir: metal yapılar,
büyük makineler ve geniş alanlar Wi-Fi sinyalini zayıflatır. Bir operatörün makine
duruşunu bildirememesi ya da bildirdiğini sanıp aslında bildirimin hiç gitmemesi,
uygulamanın asıl amacını ortadan kaldırır.

## Karar

Mobil uygulamayı **offline-first** tasarlıyoruz:

1. Her yazma işlemi (duruş bildirme, öneri oluşturma, denetim) **önce telefondaki yerel
   veritabanına** (drift / SQLite) ve bir **gönderim kuyruğuna** (outbox) yazılır.
   İkisi tek bir yerel işlem (transaction) içinde yapılır.
2. Kuyruk, internet olduğunda kayıtları **sırayla** sunucuya gönderir. Başarısız olursa
   artan bekleme süreleriyle tekrar dener (exponential backoff).
3. Her işleme oluşturulduğu anda kalıcı bir **işlem kimliği** (`clientOperationId`) verilir.
   Sunucu aynı kimliği ikinci kez görürse işlemi tekrarlamaz (idempotency).
4. Her kaydın durumu kullanıcıya açıkça gösterilir:

| Yerel durum | Kullanıcıya anlamı |
| --- | --- |
| LocalSaved | Bu cihazda kayıtlı; henüz iletilmedi |
| SyncPending | Gönderim sırasında bekliyor |
| Syncing | Şu an gönderiliyor |
| ServerAccepted | Sunucu onayladı; ilgili kişilere iletildi |
| Conflict / Rejected | Sunucu reddetti; nedeni ve yapılabilecekler gösterilir |

5. "Son yazan kazanır" kullanılmaz. Sunucunun reddettiği eski bir değişiklik (ör. başkasının
   çözdüğü duruşa müdahale) otomatik kabul edilmez; kullanıcıya güncel durum gösterilir.

## Sonuçlar

**Artılar**

- Ağ kesilse bile hiçbir işlem kaybolmaz; kullanıcı çalışmaya devam eder.
- Kullanıcı kaydının gerçekten iletilip iletilmediğini her zaman bilir.
- Zayıf bağlantıda aynı isteğin tekrar gönderilmesi çift kayıt oluşturmaz.

**Eksiler**

- Mobil tarafta ek karmaşıklık: yerel veritabanı, kuyruk, senkronizasyon ve çakışma yönetimi.
- Sunucu tarafında her yazma işleminin idempotent olması gerekir.
- Test edilmesi gereken senaryo sayısı artar (bağlantı kopması, çift gönderim, çakışma).

## Değerlendirilen alternatifler

- **Sadece online çalışma:** En basiti, ama sahada bağlantı yokken uygulama işe yaramaz.
- **Hata olursa kullanıcıya "tekrar dene" göstermek:** Kullanıcıya yük bindirir; operatör meşgulken bildirimi unutabilir.
- **Tam senkronizasyon çerçevesi (ör. CRDT tabanlı):** Bu uygulamanın ihtiyacından çok daha karmaşık; kayıtlar çoğunlukla tek kişi tarafından oluşturuluyor ve çakışmalar durum makineleriyle yönetilebiliyor.
