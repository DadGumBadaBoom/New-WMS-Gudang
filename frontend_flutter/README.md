# Frontend (Flutter)

Flutter client for the warehouse management system. Targets Android, iOS, web, and desktop as enabled in the project.

## Prerequisites

- Flutter 3.x SDK (with matching Dart SDK)
- Android Studio / Xcode for device tooling
- Device or emulator/simulator, or Chrome for web

## Setup

```bash
flutter pub get
```

If Android builds fail because of missing SDK paths, set `ANDROID_HOME`/`ANDROID_SDK_ROOT` and ensure `local.properties` points to the SDK.

## Run

```bash
flutter run
```

Examples:
- Android: `flutter run -d emulator-5554`
- iOS: `flutter run -d ios`
- Web: `flutter run -d chrome`

## Build

- Android APK (debug): `flutter build apk`
- Android appbundle (release): `flutter build appbundle`
- Web: `flutter build web`
- Windows: `flutter build windows` (requires desktop support enabled)

Artifacts are output to the `build/` directory.

## Testing & lint

```bash
flutter test
flutter analyze
```

## Notes

- Keep app secrets and API hosts in a secure config layer (do not hardcode in source).
- Update native platform settings (icons, permissions, signing) under `android/` and `ios/` before releasing.
