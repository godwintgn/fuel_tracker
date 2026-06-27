# FuelTrack Pro

**Local-first fuel and vehicle expense tracking for Android.**

Track refuels, measure efficiency, compare stations, and manage a multi-vehicle fleet — all on your phone. No account required. Data stays in SQLite on device unless you export or back up.

[![Version](https://img.shields.io/badge/version-1.16.0-blue)](fueltrack_pro/pubspec.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)](https://github.com/godwintgn/fuel_tracker/releases/latest)

## Install

| Method | Link |
|--------|------|
| **Obtainium** (recommended) | [Add to Obtainium](https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/https://github.com/godwintgn/fuel_tracker) |
| **Direct APK** | [Download latest APK](https://github.com/godwintgn/fuel_tracker/releases/latest/download/FuelTrack-Pro.apk) |
| **All releases** | [GitHub Releases](https://github.com/godwintgn/fuel_tracker/releases) |

Obtainium checks GitHub Releases automatically — no need to reinstall manually after each update.

**Website:** [FuelTrack Pro landing page](https://github.com/godwintgn/wealth-journal/tree/main/website/public/fueltrack) (deployed with [Wealth Journal site](https://github.com/godwintgn/wealth-journal))  
**Privacy:** `/fueltrack/privacy/` on the shared marketing site.

## Screenshots

| Dashboard | History |
|-----------|---------|
| ![Dashboard](screenshots/01-dashboard.png) | ![History](screenshots/02-history.png) |

| Analytics | Vehicle details |
|-----------|-----------------|
| ![Analytics](screenshots/03-analytics.png) | ![Vehicle details](screenshots/04-vehicle-details.png) |

## Features

- **Multi-vehicle garage** — photo, make/model, registration, fuel type (petrol, diesel, EV, CNG, LPG, hybrid)
- **Smart refuel logging** — enter any two of quantity / price-per-unit / total; the third is auto-calculated
- **Timeline validation** — odometer and date checked against neighbors for consistent history
- **Dashboard** — odometer, avg efficiency, monthly spend, efficiency and spend charts
- **History** — searchable list with stable per-vehicle colors, view / edit / delete
- **Analytics** — 7d / 30d / 3M / 1Y / All periods; best/worst fill, station comparison, cost-per-fill chart, multi-vehicle efficiency overlay
- **Fuel cards** — fleet-wide or vehicle-specific limits (price or quantity), reset periods, expiry
- **Service reminders** — due by date or odometer, in-app warnings, local notifications
- **Country & currency** — independent world country and ISO 4217 currency pickers
- **Backups** — CSV export, encrypted `.ftbak`, optional Google Drive sync
- **Theming** — Material 3 light/dark, Wealth Journal–aligned palette

## Tech stack

Flutter · Riverpod · sqflite · fl_chart · Material 3

## Developers

```bash
cd fueltrack_pro
flutter pub get
flutter run
```

Release APK:

```bash
cd fueltrack_pro
flutter build apk --release
```

Output: `fueltrack_pro/build/app/outputs/flutter-apk/app-release.apk`

Every push to `master` runs CI: analyze, test, signed APK build, [GitHub Release](https://github.com/godwintgn/fuel_tracker/releases), and sync of `/fueltrack/` pages to the shared [Wealth Journal website](https://github.com/godwintgn/wealth-journal).

Version lives in `fueltrack_pro/pubspec.yaml` (`version: <name>+<build>`). The `+build` number is the Android `versionCode` and must increase for every published update.

## License

Private project — see repository owner for terms.
