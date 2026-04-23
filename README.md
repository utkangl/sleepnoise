# SleepingNoise

**SleepingNoise**, daha iyi odaklanma, rahatlama ve uyku için tasarlanmis bir Flutter white-noise uygulamasidir.  
Kullanici; doga seslerini tekli oynatabilir, birden fazla sesi katmanlayarak kendi karisimini olusturabilir ve favori mikslerini kaydedebilir.

## Neler Sunuyor?

- **Tekli oynatma ve hizli baslatma:** Okyanus, yagmur, kus sesleri, ates gibi sesleri tek tikla cal.
- **Mixer deneyimi:** Birden fazla sesi ayni anda seviyeleriyle karistir.
- **Kaydedilebilir karisimlar:** Olusturdugun karisimlari kutuphaneye kaydet ve tekrar kullan.
- **Remote katalog + indirme:** Uzak katalogdaki sesleri cihaza indir, sonra mixer icinde de kullan.
- **Video destekli Now Playing:** Oynayan/kullanilan ses kategorisine uygun arka plan video gecisleri.
- **Sleep timer:** Uygulamayi belirlenen sure sonunda otomatik durdur.

## Teknoloji Yigini

- **Framework:** Flutter (Dart 3)
- **State management:** Riverpod (`flutter_riverpod`)
- **Routing:** `go_router`
- **Audio engine:** `just_audio` + `audio_session`
- **Video backdrop:** `video_player`
- **Remote data:** Supabase REST benzeri endpoint entegrasyonu (`http`)
- **Local persistence/cache:** `shared_preferences`, `path_provider`

## Proje Yapisi (Ozet)

```text
lib/
  core/                 # Tema, routing, genel utility ve config
  features/
    player/             # Tekli oynatma, now playing, audio source/caching
    mixer/              # Katmanli karisim motoru ve mixer UI
    library/            # Favoriler, kayitli miksler, indirilen icerikler
    catalog/            # Uzak katalog fetch ve uygulama katmani
```

## Kurulum

### 1) Gereksinimler

- Flutter SDK (3.x)
- Android Studio veya VS Code + Flutter eklentileri
- Android/iOS toolchain (hedef platforma gore)

### 2) Bagimliliklar

```bash
flutter pub get
```

### 3) Calistirma

```bash
flutter run
```

## Remote Katalog Konfigurasyonu

Uygulamadaki uzak katalog ozelligi icin `lib/core/config/remote_catalog_config.dart` dosyasindaki degerleri doldur:

- `kRemoteCatalogBaseUrl`
- `kRemoteCatalogAnonKey`
- `kRemoteCatalogTable`

Bu alanlar bos kalirsa uygulama sadece yerel katalogla calismaya devam eder.

## Build

```bash
flutter build apk --release
```

> Not: Repoda yer alan imza dosyalari/anahtarlar (`.jks` vb.) guvenlik acisindan ozel tutulmalidir.

## Yol Haritasi Fikirleri

- Kategori bazli mixer filtreleme ve arama
- Daha fazla remote katalog metadatasi (etiket, BPM, mood)
- Cloud senkron favoriler / cihazlar arasi tasima

## Katki

PR ve issue acmadan once degisiklik kapsamini kisaca yazmaniz ve ilgili ekran kaydini eklemeniz cok faydali olur.

## Lisans

Bu proje su an icin ozel/kapali kullanim odakli gelistirilmektedir. Lisans bilgisi netlestirildiginde bu bolum guncellenecektir.
