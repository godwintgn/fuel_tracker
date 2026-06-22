# FuelTrack Pro — AI Agent Context

> **Purpose:** Cross-reference this file at the start of new Cursor/agent sessions to avoid confusion about what exists, what’s pending, and how the project is organized.  
> **Original spec:** [`fueltrack-pro-cursor-prompt.md`](fueltrack-pro-cursor-prompt.md)  
> **Mockups:** [`stitch_fueltrack_pro_analytics_app/`](stitch_fueltrack_pro_analytics_app/) (HTML + PNG + `DESIGN.md`)  
> **GitHub:** https://github.com/godwintgn/fuel_tracker  
> **Flutter app root:** `fueltrack_pro/`

---

## 1. What this app is

**FuelTrack Pro** is a local-first Flutter Android app for tracking vehicle fuel consumption, expenses, and efficiency analytics. No mandatory backend. Optional Google Drive backup is planned (Wealth Journal pattern) but **not implemented yet**.

| Item | Value |
|------|--------|
| Dart package name | `fueltrack_pro` |
| Android `applicationId` | `com.fuel.tracker` |
| Android namespace | `com.fuel.tracker` |
| Display name | FuelTrack Pro |
| Current version | `1.11.3+18` (see `fueltrack_pro/pubspec.yaml`) |

---

## 2. Tech stack (decided — do not change without user ask)

| Layer | Choice |
|-------|--------|
| Framework | Flutter **3.44.2** (stable), Material 3 |
| Dart SDK | **3.12.2** (`pubspec.yaml`: `sdk: ^3.12.2`) |
| State | `flutter_riverpod` |
| Database | `sqflite` (SQLite on-device) |
| Charts | `fl_chart` |
| Fonts | `google_fonts` — **Manrope** (headings) + **Inter** (body), aligned with Wealth Journal |
| Intl | `intl` |

**Not chosen / deferred:** drift, Provider-only, mandatory backend.

---

## 3. Repository layout

```
fuel_tracker/                          # Git repo root
├── AGENT_CONTEXT.md                   # This file
├── fueltrack-pro-cursor-prompt.md     # Original build spec & order
├── .cursor/rules/
│   ├── commit-push-build-apk.mdc      # Auto rule: commit → push → clean APK
│   └── update-agent-context.mdc       # Auto rule: keep this file updated every change
├── stitch_fueltrack_pro_analytics_app/  # Stitch mockups (reference only)
└── fueltrack_pro/                     # Flutter project
    ├── lib/
    │   ├── app.dart                   # Root widget + onboarding vs home routing
    │   ├── main.dart
    │   ├── data/                      # regions, onboarding draft types
    │   ├── models/                    # Vehicle, RefuelEntry, AppSettings, DashboardStats
    │   ├── providers/                 # Riverpod
    │   ├── screens/                   # … settings, analytics, vehicles
    │   ├── services/                  # db, backup, drive, analytics, calculations
    │   ├── config/                    # google_oauth_config.dart
    │   ├── theme/                     # WJ-aligned theme (app_theme, app_palette, fuel_chart_style, theme_x)
    │   ├── widgets/common/            # AppCard, SectionHeader, EmptyState
    └── android/
        ├── app/build.gradle.kts
        ├── key.properties             # GITIGNORED
        └── app/melmidalam-release.jks # GITIGNORED
```

(`adi-registration.properties` removed in Step 9 after Play ownership verification.)

---

## 4. Build order — progress

Incremental build per original prompt. **Do not generate everything at once.**

| Step | Status | Summary |
|------|--------|---------|
| 1 | ✅ Done | Scaffold, M3 theme, SQLite schema (`vehicles`, `refuel_entries`, `settings`) |
| 2 | ✅ Done | Onboarding (4 screens, Skip on each), persistence |
| 3 | ✅ Done | Vehicle list, add/edit, empty state, selected vehicle in settings |
| 4 | ✅ Done | Dashboard, charts, FAB speed-dial |
| 5 | ✅ Done | Refuel Entry + smart quantity/price/total calculation |
| 6 | ✅ Done | History (search, filters, swipe edit/delete) |
| 7 | ✅ Done | Analytics (charts, insight cards, period selector) |
| 8 | ✅ Done | Settings + Google Drive backup + CSV export |
| 9 | ✅ Done | Final wiring — real data only, seed removed, Play ownership file removed |

**All 9 build steps complete.**

---

## 5. What is implemented (detail)

### 5.1 Database (`lib/services/database_service.dart`)

- **vehicles** — name, make, model, year, fuel_type, license_plate, notes, timestamps  
- **refuel_entries** — vehicle_id FK, date, odometer, quantity, price_per_liter, total_price, fuel_type, station_name, notes  
- **settings** — single row (id=1): currency, units, theme_mode, onboarding_completed, selected_vehicle_id  

### 5.2 Onboarding (`lib/screens/onboarding/`)

1. Welcome → 2. Add Vehicle → 3. Region & Currency → 4. Done  
- Skip on every step completes onboarding (may skip saving vehicle).  
- `onboarding_completed` in settings gates `app.dart` → `OnboardingFlow` vs `HomeShell`.

### 5.3 Main shell (`lib/screens/home/home_shell.dart`)

Bottom nav (4 tabs):

| Index | Tab | Status |
|-------|-----|--------|
| 0 | Dashboard | ✅ Live |
| 1 | Vehicles | ✅ Live |
| 2 | History | ✅ Live |
| 3 | Analytics | ✅ Live |

- **FAB** on Dashboard (0) and History (2): single tap → **New Refuel** (no speed-dial).  
- Vehicles tab uses simple `+` FAB to add vehicle.

### 5.4 Dashboard (`lib/screens/dashboard/dashboard_screen.dart`)

- Vehicle selector in header  
- Hero metric tiles (`AppCard`), quick overview, cost/km row  
- Last refuel card — tap **Details** or card → edit refuel  
- Monthly spend bar chart (`FuelChartStyle.horizontalGrid`, thin `spaceBetween` bars, `pal.spend`)  
- Efficiency trend line chart (`FuelChartStyle.primarySeries`, `pal.efficiency`)  
- Data via `dashboardProvider` → `DashboardStats` + `FuelCalculations`

### 5.5 Vehicle management (`lib/screens/vehicles/`)

- List with `VehicleCard`, empty state, add-another dashed card  
- **Details** → `VehicleDetailScreen` (read-only profile + photo); **Edit** in app bar → `AddEditVehicleScreen`  
- Add/Edit form; delete blocked if refuel history exists  
- **Fuel Log** opens `AddRefuelScreen` for that vehicle (vehicle + fuel type locked)  

### 5.6 Refuel entry (`lib/screens/refuel/add_refuel_screen.dart`)

- Form: date/time, vehicle, odometer, quantity, price/L, total, station, notes  
- **Smart calc:** any 2 of quantity / price-per-liter / total → derives third (`refuel_calculation.dart`)  
- Auto-calc fields highlighted with green tint + “AUTO” badge on total  
- Prefills price/L from last refuel; odometer hint shows valid range from timeline neighbors  
- **Timeline validation** (`refuel_timeline_validation.dart`): date not in future; odometer must sit between chronological neighbors (supports backdated history inserts)  
- Vehicle + fuel type **locked** when opened from vehicle Fuel Log or when editing an entry  
- Wired: FAB **New Refuel**, vehicle **Fuel Log**; invalidates `dashboardProvider` on save  
- `refuelsProvider.updateEntry` for edit flow; `refuelsProvider.deleteEntry` for history swipe-delete  

### 5.6b Refuel detail (`lib/screens/refuel/refuel_detail_screen.dart`)

- Read-only refuel view; **Edit** opens `AddRefuelScreen` in edit mode (vehicle/fuel locked)  
- History tap → detail; swipe right → edit  

### 5.7 History (`lib/screens/history/history_screen.dart`)

- Search bar (stations, fuel type, vehicle name, notes)  
- Filter bottom sheet: vehicle, fuel type, date range (7d / 30d / 3mo / custom)  
- Summary chip: entry count + total spend for active filters  
- `RefuelHistoryCard` list matching mockup layout  
- Swipe right → edit (`AddRefuelScreen` edit mode); swipe left → delete with confirm  
- Tap card → `RefuelDetailScreen` (view); empty states for no data / no matches  
- FAB **New Refuel** on History tab  

### 5.8 Analytics (`lib/screens/analytics/analytics_screen.dart`)

- Period selector: weekly / monthly / yearly  
- Efficiency line chart (`FuelChartStyle.primarySeries`, peak km/L badge)  
- Insight cards (`AppCard` + `pal.gain`/`pal.loss`/`pal.spend`)  
- Monthly spending bar chart (WJ thin bars, `pal.spend`)  
- Vehicle fuel-share pie chart (`AppPalette` semantic slice colours) + period summary  
- Per-vehicle profile cards (`AppCard` + `pal.fuel` icon tile)  
- `AnalyticsService` + `analyticsProvider`; empty states when no refuels  

### 5.9 Settings (`lib/screens/settings/settings_screen.dart`)

- Currency, distance/fuel units, theme mode  
- Manage vehicles shortcut  
- Export refuel history CSV (unencrypted)  
- Local encrypted `.ftbak` backup / restore (PBKDF2 + AES-GCM)  
- Google Drive: sign in, manual backup/restore to app data folder  
- OAuth: `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=...` + release SHA-1  
- Opened from Dashboard / Vehicles gear icons  

### 5.10 Fuel efficiency logic (`lib/services/fuel_calculations.dart`)

- **km/L** = distance between consecutive refuels (odometer delta) ÷ liters at later refuel  
- **L/100km** = (liters ÷ km) × 100  
- **Cost per km** = total fuel cost ÷ total distance over period  
- Monthly spending aggregation for charts  

---

## 6. Design system

Visual language aligned with **Wealth Journal** (`Assets/wealth_journal/`). Stitch mockups remain reference for layout only; colours/typography/charts follow WJ.

### Colour & theme (v1.10.0)

| Mode | Scaffold | Primary | Secondary |
|------|----------|---------|-----------|
| Light | `#f4f6fa` | Blue `#1e40af` | Teal `#0d9488` |
| Dark | `#0f1117` | Amber `#d97706` | Teal `#0d9488` |

- **Theme:** `lib/theme/app_theme.dart` — Manrope + Inter, M3 `ColorScheme`, `AppPalette` extension  
- **Semantic palette:** `lib/theme/app_palette.dart` — `gain`/`loss`/`efficiency`/`spend`/`fuel`/`neutral`; access via `context.palette`  
- **Charts:** `lib/theme/fuel_chart_style.dart` — curved lines, gradient area fill, line glow, horizontal grid (mirrors WJ `PortfolioLineChartStyle`)  
- **Cards:** `lib/widgets/common/app_card.dart` — 20px radius, blended border, dark primary glow shadow  
- **Section titles:** `lib/widgets/common/section_header.dart` — w800 Manrope  
- **Spacing:** `app_spacing.dart` — `cardRadius = 20`, `cardPadding = 20`  
- **Extensions:** `theme_x.dart` — `context.cs`, `context.tt`, `context.isDark`, `context.palette`  
- **Legacy:** `app_colors.dart` retained but unused in UI; all screens use `ColorScheme` + `AppPalette`

### Dark/light theming rule

- **All screens must source theme-variant colours from `ColorScheme` and `AppPalette`**, not static light constants.
- Shared component themes (cards, inputs, nav bar, bottom sheets, dialogs, snackbars, chips, list tiles) styled centrally in `app_theme.dart`.

### Known mockup fallbacks (user accepted)

| Mockup | Flutter fallback |
|--------|------------------|
| Roboto Flex variable axes | Manrope + Inter (WJ pattern) |
| Material Symbols | `Icons.*` |
| Vehicle/station photos | `AppCard` + icon placeholders (no green gradient heroes) |
| Dark card gradients | Flat WJ-style `surfaceContainer` cards |
| Confetti on onboarding done | Static success illustration |
| Tank capacity / maintenance alerts on add vehicle | Omitted (not in DB) |
| Efficiency format picker (L/100km, km/L, MPG) on region screen | Omitted for now |

---

## 7. Android signing & Play Console

### Release signing

- Keystore copied from **Wealth Journal**: `C:\Users\Dell\Documents\Github\Assets\wealth_journal\`  
- Files (gitignored): `android/key.properties`, `android/app/melmidalam-release.jks`  
- Config: `android/app/build.gradle.kts` loads `key.properties` for `release` builds  

### Fingerprints (release keystore, alias `key0`)

| Type | Value |
|------|--------|
| SHA-256 | `C8:9A:3B:5F:C0:A3:85:46:18:58:09:4B:56:5F:7F:A3:17:0E:01:19:F6:A1:39:22:C4:40:B8:04:1C:69:9A:44` |
| SHA-1 | `FF:47:7D:10:BC:08:E6:89:A7:E7:17:ED:AC:1E:5D:08:8C:E1:44:07` |

Use SHA-1 when adding `com.fuel.tracker` to Google Cloud OAuth (Drive backup, Step 8).

### Play package ownership verification

- ~~`adi-registration.properties`~~ **Removed** (Step 9) after Play ownership verified  
- APK path: `fueltrack_pro/build/app/outputs/flutter-apk/app-release.apk`  

---

## 8. Agent workflow rules

Both rules are **alwaysApply: true** in `.cursor/rules/`:

| Rule | Purpose |
|------|---------|
| `commit-push-build-apk.mdc` | Bump version → analyze/test → commit → push → clean release APK |
| `update-agent-context.mdc` | Update **this file** after every substantive change (version, steps, providers, commits, next work) |

After substantive code changes:

1. Bump `pubspec.yaml` version (`+build` must increase for installs)  
2. `flutter analyze` (+ `flutter test` when logic changes)  
3. **Update `AGENT_CONTEXT.md`** (see `update-agent-context.mdc`)  
4. Commit (Conventional Commits)  
5. `git push origin master`  
6. Clean release APK:
   ```bash
   cd fueltrack_pro
   flutter clean && flutter pub get && flutter build apk --release
   ```

**Never commit:** `key.properties`, `*.jks`, `*.p12`, passwords.

**User rule:** Only commit when user asks — but user also requested this auto workflow rule; follow the rule for feature work unless user says “don’t commit.”

---

## 9. Git commit history (high level)

| Commit | Message |
|--------|---------|
| `d72fe72` | Initial scaffold + theme + SQLite |
| `6320907` | App icon, onboarding, release workflow rule |
| `acca27b` | Vehicle management + nav shell |
| `94cb08c` | Package `com.fuel.tracker` |
| `f18a120` | Play ownership `adi-registration.properties` |
| `55fd3c0` | Dashboard, charts, seed data, FAB speed-dial |
| `c304c33` | AGENT_CONTEXT rule + handoff doc |
| `b2a3c59` | Refuel entry screen + smart calculation |
| `cd04522` | History list, filters, swipe edit/delete |
| `7dd8e09` | Analytics screen + charts + insight cards |
| `c2ece6c` | Settings, CSV export, Drive backup |
| `9b1eea4` | feat: theme-aware dark/light UI overhaul |
| *(pending)* | feat: Wealth Journal UI alignment — WJ colours, Manrope/Inter, AppPalette, FuelChartStyle, AppCard across dashboard/analytics/history/refuel/onboarding |

---

## 10. Riverpod providers (quick map)

| Provider | Role |
|----------|------|
| `databaseServiceProvider` | SQLite singleton |
| `databaseInitProvider` | Await DB open |
| `settingsProvider` | App settings row |
| `vehiclesProvider` | CRUD list |
| `refuelsProvider` | All refuel entries |
| `onboardingDraftProvider` | Transient onboarding form state |
| `dashboardProvider` | Seed if empty + stats for selected vehicle |
| `analyticsProvider` | Fleet analytics for period (weekly/monthly/yearly) |
| `analyticsPeriodProvider` | Selected analytics timeframe |
| `backupServiceProvider` | Encrypted backup + CSV export |
| `driveBackupServiceProvider` | Google Sign-In + Drive app-data upload/download |
| `driveBackupPrefsProvider` | Drive backup metadata (initialized in `main.dart`) |

---

## 11. Screens & navigation flow

```
main.dart → ProviderScope → FuelTrackApp (app.dart)
    │
    ├─ settings.onboarding_completed == false → OnboardingFlow (PageView)
    │
    └─ true → HomeShell
            ├─ [0] DashboardScreen
            ├─ [1] VehicleListScreen
            ├─ [2] HistoryScreen
            └─ [3] AnalyticsScreen
```

Add vehicle: pushed route from Vehicles `+` FAB or onboarding.  
Vehicle **Details** → `VehicleDetailScreen`; **Edit** from detail app bar.  
Add refuel: `AddRefuelScreen` from FAB or vehicle **Fuel Log** (locks vehicle).  
View refuel: tap card in History → `RefuelDetailScreen`; edit from app bar or swipe right.  
Settings: gear icon on Dashboard / Vehicles → `SettingsScreen`.

---

## 12. Post-v1 maintenance (optional)

- Commit + push + release APK for v1.10.0 WJ UI alignment (when user requests)  
- Register Google OAuth web client + Android client for Drive on release builds (`GOOGLE_OAUTH_SERVER_CLIENT_ID` dart-define)  
- Scheduled Drive backups (Wealth Journal has daily auto-upload)  
- Efficiency format picker (km/L vs L/100km vs MPG) in settings  

---

## 13. Testing notes

- Widget tests mock Riverpod providers (no SQLite in test env).  
- `test/widget_test.dart` — expects Dashboard “Quick Overview” with overridden `dashboardProvider`.  
- `test/refuel_calculation_test.dart` — unit tests for smart refuel math (all 3 derive paths).  
- `test/refuel_history_filter_test.dart` — filter/search/date-range unit tests.  
- `test/analytics_service_test.dart` — period filter, fuel share, monthly spend.  
- `test/refuel_timeline_validation_test.dart` — odometer/date neighbor bounds for new and historical refuels.  
- `test/backup_crypto_test.dart` — encrypt/decrypt roundtrip.  
- Use `pump()` + short delay, not always `pumpAndSettle()` (can timeout on async DB).

---

## 14. Commands cheat sheet

```bash
# Run app
cd fueltrack_pro && flutter run

# Analyze + test
cd fueltrack_pro && flutter analyze && flutter test

# Release APK (signed)
cd fueltrack_pro && flutter clean && flutter pub get && flutter build apk --release

# Signing report (SHA fingerprints)
cd fueltrack_pro/android && ./gradlew signingReport

# Regenerate launcher icons
cd fueltrack_pro && dart run flutter_launcher_icons
```

---

## 15. Related projects

| Project | Path | Reuse |
|---------|------|--------|
| Wealth Journal | `C:\Users\Dell\Documents\Github\Assets\wealth_journal\` | Release keystore, Google Drive backup pattern (Step 8) |
| Mockups | `stitch_fueltrack_pro_analytics_app/` | Visual reference for every screen |

---

## 16. How to use this file in a new session

Tell the agent:

> Read `AGENT_CONTEXT.md` and `fueltrack-pro-cursor-prompt.md`, then continue from **Step N**.

Or attach:

```
@AGENT_CONTEXT.md @fueltrack-pro-cursor-prompt.md
```

**Do not** re-scaffold the project or change package name / DB / state library without explicit user request.

---

*Last updated: Vehicle view-only detail + edit, refuel timeline validation, locked vehicle on Fuel Log. Version `1.11.3+18`.*
