# İş Kuralları ve Kabul Kriterleri

Bu belge, uygulamadaki her modülün **kim, neyi, hangi durumda, hangi kayıt üzerinde**
yapabileceğini tanımlar. Kod ve testler bu kurallara göre yazılır; bir kural değişirse
önce bu belge güncellenir.

> **Not:** Bu kurallar v1 için alınmış kararlardır. Gerçek bir fabrikada kullanıcılarla
> doğrulanması gerekir; bu projede varsayım olarak kabul edilmiştir.

Kod içinde kullanılan İngilizce adlar parantez içinde verilmiştir.

---

## 1. Roller

| Rol | Kod adı | Ne yapar |
| --- | --- | --- |
| Operatör | `Operator` | Duruş bildirir, iyileştirme önerisi verir |
| Şef | `Supervisor` | Önerileri onaylar, 5S denetimi yapar, eskalasyonları görür |
| Bakım Teknisyeni | `Technician` | Duruşları üstlenir ve çözer |
| Yönetici | `Manager` | Fabrika panosunu ve raporları görür |
| Admin | `Admin` | Kullanıcıları ve fabrika yapısını yönetir |

## 2. Rol, işlem ve veri kapsamı matrisi

Her işlem iki kontrolden geçer ve **ikisi de backend'de** yapılır:

- **Rol:** Bu kullanıcı bu işi yapabilir mi?
- **Veri kapsamı:** Bu kayıt onun fabrikasında / hattında mı?

| İşlem | Kim yapabilir | Veri kapsamı |
| --- | --- | --- |
| Duruş açma | Operatör, Şef | Kendi hattındaki makine |
| Duruşu üstlenme ve çözme | Bakım Teknisyeni | Kendi fabrikası; çözmeyi yalnızca üstlenen kişi |
| Duruşu iptal etme | Açan operatör (üstlenilmeden önce), Şef | Kendi hattı; gerekçe zorunlu |
| Öneri oluşturma | Operatör, Şef, Bakım Teknisyeni | Kendi hattı |
| Öneri onaylama / reddetme / revizeye gönderme | Şef | Kendi hattı; kendi önerisini onaylayamaz |
| 5S denetimi yapma | Şef | Kendi fabrikası |
| Tamamlanmış denetimi düzeltme | Şef | Gerekçe zorunlu, audit log'a yazılır |
| Pano ve raporlar | Yönetici; Şef (yalnızca kendi hattı) | Kendi fabrikası |
| Kullanıcı ve organizasyon yönetimi | Admin | Fabrika atanmamış Admin: tüm sistem. Fabrikaya atanmış Admin: yalnızca kendi fabrikası |

**Kapsam dışı kayıt:** Kullanıcı kendi fabrikası dışındaki bir kaydın kimliğiyle istek
yaparsa sunucu **404 Not Found** döner. Kaydın var olduğu bile belli edilmez.


**Hat kapsamı:** Fabrika kapsamı her sorguya otomatik uygulanır. Hat kapsamı ise otomatik
bir filtre değildir: yalnızca tabloda "kendi hattı" yazan işlemlerde (duruş açma, öneri)
o işlemin içinde kontrol edilir. Sebep: Şef 5S denetimini, Bakım Teknisyeni duruş çözmeyi
fabrika genelinde yapar; otomatik bir hat filtresi bu işleri engellerdi.

---

## 3. Andon (duruş bildirimi)

### 3.1 Durumlar

```
Açık (Open) ──► Müdahalede (InProgress) ──► Çözüldü (Resolved)
   │
   └──────────► İptal (Cancelled)
```

- **Çözüldü** ve **İptal** son durumlardır; bu durumlardan başka bir duruma geçilemez.

### 3.2 Kurallar

| Kural | Açıklama |
| --- | --- |
| Tek aktif duruş | Bir makinede aynı anda yalnızca bir aktif (Açık veya Müdahalede) duruş olabilir. Veritabanında kısmi benzersiz indeksle de korunur. İkinci bildirim mevcut duruşa yönlendirilir. |
| Eşzamanlı üstlenme | İki teknisyen aynı duruşu aynı anda üstlenirse yalnızca biri başarılı olur (optimistic concurrency). Diğeri **409 Conflict** ve güncel durumu alır. |
| Geçersiz geçiş | Çözülmüş duruşa gelen "müdahaleye başla" isteği durumu değiştirmez; sunucu güncel durumla açıklayıcı bir hata döner. |
| Eskalasyon | Açılıştan itibaren fabrika ayarındaki süre (varsayılan **10 dk**) içinde üstlenilmezse şefe **bir kez** bildirim gider; iki katı sürede yöneticiye. İş çalıştığında durum yeniden kontrol edilir; duruş üstlenilmiş veya kapanmışsa bildirim üretilmez. |
| İptal | Gerekçe zorunludur. Açan operatör yalnızca duruş üstlenilmeden önce iptal edebilir. |
| Zaman | Tüm zamanlar sunucuda **UTC** olarak tutulur; kullanıcıya yerel saatle gösterilir. |

### 3.3 Süre tanımları

| Ölçü | Formül |
| --- | --- |
| Müdahale gecikmesi | üstlenme zamanı − açılış zamanı |
| Onarım süresi | çözüm zamanı − üstlenme zamanı |
| Toplam duruş süresi | çözüm zamanı − açılış zamanı |
| **MTTR** | Çözülmüş duruşların ortalama onarım süresi |

İptal edilen ve hâlâ açık olan duruşlar MTTR hesabına **girmez**.

**Örnek:** Bir makinede iki duruş çözülmüş olsun.

| Duruş | Açılış | Üstlenme | Çözüm | Onarım süresi |
| --- | --- | --- | --- | --- |
| A | 08:00 | 08:05 | 08:35 | 30 dk |
| B | 10:00 | 10:12 | 10:22 | 10 dk |

MTTR = (30 + 10) / 2 = **20 dk**

### 3.4 Sonraki sürüme kalanlar (v1.1)

Duruşu beklemeye alma (ör. parça bekleniyor), çözülmüş duruşu yeniden açma (v1'de yeni
duruş açılır), vardiya devri, eskalasyonda vardiya ve tatil takvimi.

### 3.5 Kabul kriterleri

- [ ] Aynı duruş için eşzamanlı iki "üstlen" isteğinde tam olarak bir başarılı geçiş olur.
- [ ] Aynı makine için ikinci aktif duruş oluşturulamaz.
- [ ] Eskalasyon işi çalıştığında duruş üstlenilmişse şefe bildirim gitmez.
- [ ] Offline açılan duruş arayüzde "cihazda kayıtlı" görünür; sunucu onayı gelmeden "bakım ekibine iletildi" yazmaz.
- [ ] MTTR, yukarıdaki örnek veriyle 20 dk olarak hesaplanır.

---

## 4. Kaizen (iyileştirme önerisi)

### 4.1 Durumlar ve geçişler

```
Taslak (Draft) ──► Onay Bekliyor (PendingApproval) ──► Onaylandı (Approved) ──► Uygulanıyor (InProgress) ──► Tamamlandı (Completed)
                          │        ▲
                          │        │
                          ├──► Revize (RevisionRequested)
                          │
                          └──► Reddedildi (Rejected)
```

| Geçiş | Kim | Zorunlu alanlar |
| --- | --- | --- |
| Taslak → Onay Bekliyor | Öneri sahibi | Başlık, açıklama, kategori, hat, en az bir fotoğraf, beklenen kazanım |
| Onay Bekliyor → Onaylandı | Hattın şefi (öneri sahibi değilse) | Sorumlu kişi, hedef tarih |
| Onay Bekliyor → Reddedildi | Hattın şefi | Ret gerekçesi |
| Onay Bekliyor → Revize | Hattın şefi | Revize notu |
| Revize → Onay Bekliyor | Öneri sahibi | Güncellenmiş açıklama |
| Onaylandı → Uygulanıyor | Sorumlu kişi | — |
| Uygulanıyor → Tamamlandı | Sorumlu kişi, şef onayıyla | "Sonra" fotoğrafı, gerçekleşen kazanım |

### 4.2 Kurallar

- **Reddedildi** ve **Tamamlandı** son durumlardır; v1'de onay geri alınmaz.
- Revize edilen öneri **aynı kayda** döner; önceki açıklamalar ve kararlar geçmişte korunur.
- **Kategoriler:** Güvenlik, Kalite, Verimlilik, Maliyet.
- **Kazanım modeli:** değer + birim (dakika/gün, TL/ay, adet/ay, kaza riski azaltma). Beklenen ve gerçekleşen kazanım ayrı tutulur.
- İki şef aynı öneriyi aynı anda onaylarsa yalnızca biri başarılı olur (**409 Conflict**).
- Zaman çizelgesi audit log'dan beslenir, ancak kullanıcıya yalnızca iş olayları gösterilir (IP adresi gibi teknik bilgiler gösterilmez).

### 4.3 Kabul kriterleri

- [ ] Tamamlandı'ya geçiş, "sonra" fotoğrafı ve gerçekleşen kazanım olmadan reddedilir.
- [ ] Revizeye dönen önerinin önceki açıklamaları ve kararları geçmişte görünür.
- [ ] Başka fabrikanın şefi, öneri kimliğini değiştirerek onay veremez.
- [ ] Şef kendi önerisini onaylayamaz.

---

## 5. 5S Denetimi

### 5.1 Şablon versiyonlama

- Denetim şablonu: şablon → 5 başlık (Ayıkla, Düzenle, Temizle, Standartlaştır, Sürdür) → sorular.
- **Yayımlanmış bir şablon değiştirilemez.** Her değişiklik yeni bir versiyon oluşturur.
- Her denetim, kullandığı şablon versiyonunun kimliğini saklar. Böylece eski denetimler yeni şablondan etkilenmez.

### 5.2 Puanlama

- Her soru **1–5** arası puanlanır ya da **Uygulanamaz (N/A)** seçilir.
- N/A seçilen sorular hesaba katılmaz (paydadan düşer). Boş cevapla denetim tamamlanamaz.
- **Başlık puanı** = o başlıktaki cevaplanan soruların ortalaması.
- **Toplam puan** = beş başlık puanının ortalaması, yüzdeye çevrilir (5 üzerinden 5 = %100).
- v1'de tüm başlıkların ağırlığı eşittir; sonuç tek ondalığa yuvarlanır.
- Puanı **backend hesaplar**; mobil uygulama önizlemede aynı formülü kullanır ve aynı test vakalarıyla doğrulanır.

**Örnek:** "Ayıkla" başlığında üç soru var: 4, 2, N/A.
Başlık puanı = (4 + 2) / 2 = **3,0**

### 5.3 Diğer kurallar

| Kural | Açıklama |
| --- | --- |
| Kanıt zorunluluğu | 2 ve altı puan alan maddede fotoğraf ve not zorunludur; sunucu da kontrol eder. |
| Bulgudan öneri | Bir bulgudan en fazla bir Kaizen önerisi açılabilir. |
| Tamamlanmış denetim | Kilitlenir. Yalnızca şef, gerekçeyle düzeltebilir; düzeltme audit log'a yazılır. |
| Offline denetim | Başlatıldığı şablon versiyonuyla gönderilir ve kabul edilir. Arada yeni versiyon yayımlanmış olması denetimi geçersiz kılmaz. |

### 5.4 Kabul kriterleri

- [ ] Şablon v1 ile tamamlanan denetim, v2 yayımlandıktan sonra da aynı sorular ve aynı puanla görüntülenir.
- [ ] Kanıt gerektiren madde fotoğrafsız tamamlanmış sayılmaz.
- [ ] N/A içeren bir denetimin puanı mobilde ve backend'de aynıdır.
- [ ] Aynı bulgudan ikinci öneri açılamaz.
