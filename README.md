# FuelTrack Pro

A local-first Flutter Android app for tracking vehicle fuel consumption, expenses, and efficiency analytics. No mandatory backend — your data stays on device, with optional encrypted local and Google Drive backups.

## Features

- **Multi-vehicle garage** — add vehicles with photo, make/model, registration, and fuel type (petrol, diesel, EV, CNG, LPG, hybrid).
- **Smart refuel logging** — enter any two of quantity / price-per-unit / total and the third is auto-calculated.
- **Timeline validation** — odometer and date are checked against neighboring entries so historical and future fills stay consistent.
- **Station autocomplete** — suggests stations you've used before.
- **Dashboard** — current odometer, average efficiency, monthly spend, and efficiency-trend charts.
- **History** — searchable, filterable list with view / edit / delete.
- **Analytics** — weekly/monthly/yearly efficiency, spending, and per-vehicle fuel share.
- **Fuel-type-aware metrics** — km/L, km/kWh, or km/kg depending on the vehicle.
- **Backups** — CSV export, encrypted `.ftbak` (PBKDF2 + AES-GCM), and Google Drive sync.
- **Theming** — Wealth Journal-aligned light/dark themes.

## Tech stack

- **Flutter** (Dart SDK `^3.12.2`)
- **Riverpod** for state management
- **sqflite** for local persistence
- **fl_chart** for charts
- **Material 3** with custom `AppPalette` / `AppTheme`

## Getting started

```bash
cd fueltrack_pro
flutter pub get
flutter run
```

## Build a release APK

```bash
cd fueltrack_pro
flutter build apk --release
```

Output: `fueltrack_pro/build/app/outputs/flutter-apk/app-release.apk`

> Release builds are signed with a keystore referenced by `android/key.properties`. When that file is absent (e.g. in CI), the build falls back to debug signing. Signing secrets are never committed.

## Continuous integration

Every push triggers the [Build APK workflow](.github/workflows/build-apk.yml), which runs `flutter analyze`, `flutter test`, and builds a release APK. The APK is uploaded as a downloadable build artifact.

## Project structure

```
fuel_tracker/
├── README.md
├── AGENT_CONTEXT.md            # Living status / architecture doc
├── .github/workflows/          # CI
└── fueltrack_pro/              # Flutter app
    ├── lib/
    │   ├── models/             # Vehicle, RefuelEntry, AppSettings, ...
    │   ├── providers/          # Riverpod providers
    │   ├── screens/            # Dashboard, vehicles, refuel, history, analytics, settings
    │   ├── services/           # db, backup, drive, calculations, validation
    │   ├── theme/              # palette, theme, chart styles
    │   └── widgets/            # shared UI components
    └── test/                   # unit + widget tests
```

## Versioning

App version lives in `fueltrack_pro/pubspec.yaml` (`version: <name>+<build>`). The `+build` number maps to the Android `versionCode` and must increase for every published update.
