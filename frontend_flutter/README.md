# Frontend (Flutter)

Flutter client for the warehouse management system. Targets Android, iOS, web, and desktop as enabled in the project.

## Prerequisites

- Flutter 3.x SDK (with matching Dart SDK)
- Android Studio / Xcode for device tooling
- Device or emulator/simulator, or Chrome for web

# Frontend Flutter (Offline-first WMS)

Aplikasi Flutter untuk Warehouse Management System (WMS) dengan pendekatan offline-first. Data disimpan di SQLite lokal dan disinkronkan ke backend CodeIgniter 4 melalui REST API.

## Prasyarat

- Flutter 3.x (Dart 3)
- Android Studio / Xcode untuk perangkat/emulator
- Perangkat/emulator/simulator atau Chrome (untuk web)

## Setup cepat

```bash
flutter pub get
```

Jika build Android gagal karena path SDK, set `ANDROID_HOME`/`ANDROID_SDK_ROOT` dan pastikan `local.properties` menunjuk ke SDK dengan benar.

## Jalankan

```bash
flutter run
```

Contoh:
- Android: `flutter run -d emulator-5554`
- iOS: `flutter run -d ios`
- Web: `flutter run -d chrome`

## Konfigurasi Base URL API

- Set Base URL backend dari layar Settings aplikasi (disimpan via `shared_preferences`).
- Gunakan IP LAN host, misal `http://192.168.78.2:8080/api` saat mengakses dari emulator/perangkat.
- Default Base URL bisa diubah di `lib/data/remote/api_service.dart`.

## Fitur offline-first

- Data disimpan lokal di SQLite (sqflite) sehingga aplikasi tetap berfungsi saat offline.
- Alur sinkron: push perubahan lokal (pending) ke REST API, lalu pull data terkini dari server.
- Health check dan pesan error ramah di UI; detail raw disimpan di Riwayat Error Log.

## Build

- Android APK (debug): `flutter build apk`
- Android AppBundle (release): `flutter build appbundle`
- Web: `flutter build web`
- Windows: `flutter build windows` (butuh dukungan desktop diaktifkan)

Artefak hasil build berada di folder `build/`.

## Pengujian & analisis

```bash
flutter test
flutter analyze
```

## Dokumentasi

- Panduan memulai: lihat [../docs/getting-started.md](../docs/getting-started.md)
- Arsitektur & alur: lihat [../docs/architecture.md](../docs/architecture.md)
- Testing API (curl/PowerShell): lihat [../docs/testing.md](../docs/testing.md)
- Troubleshooting: lihat [../docs/troubleshooting.md](../docs/troubleshooting.md)

## Catatan

- Simpan host API dan rahasia aplikasi di lapisan konfigurasi yang aman (hindari hardcode di source).
- Perbarui pengaturan native (ikon, permission, signing) di `android/` dan `ios/` sebelum rilis.
- Base URL dapat dikonfigurasi oleh pengguna via Settings; default ada di `lib/data/remote/api_service.dart`.
flutter test
flutter analyze
```

## Notes

- Keep app secrets and API hosts in a secure config layer (do not hardcode in source).
- Update native platform settings (icons, permissions, signing) under `android/` and `ios/` before releasing.
 - Base URL is user-configurable via Settings; default lives in `lib/data/remote/api_service.dart`.
