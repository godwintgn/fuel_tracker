# FuelTrack Pro — AI Agent Context

> **Purpose:** Cross-reference this file at the start of new Cursor/agent sessions to avoid confusion about what exists, what’s pending, and how the project is organized.  
> **Original spec:** [`fueltrack-pro-cursor-prompt.md`](fueltrack-pro-cursor-prompt.md)  
> **Mockups:** [`stitch_fueltrack_pro_analytics_app/`](stitch_fueltrack_pro_analytics_app/) (HTML + PNG + `DESIGN.md`)  
> **GitHub:** https://github.com/godwintgn/fuel_tracker  
> **Flutter app root:** `fueltrack_pro/`

---

## 1. What this app is

**FuelTrack Pro** is a local-first Flutter Android app for tracking vehicle fuel consumption, expenses, and efficiency analytics. No mandatory backend. Optional Google Drive sync (plain JSON backup) is implemented.

| Item | Value |
|------|--------|
| Dart package name | `fueltrack_pro` |
| Android `applicationId` | `com.fuel.tracker` |
| Android namespace | `com.fuel.tracker` |
| Display name | FuelTrack Pro |
| Current version | `1.17.0+27` (see `fueltrack_pro/pubspec.yaml`) |

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
| PDF reports | `pdf` |

**Not chosen / deferred:** drift, Provider-only, mandatory backend.

---

## 3. Repository layout

```
fuel_tracker/                          # Git repo root
├── README.md                          # Public GitHub readme (features, build, CI)
├── AGENT_CONTEXT.md                   # This file
├── fueltrack-pro-cursor-prompt.md     # Original build spec & order
├── .github/workflows/build-apk.yml    # CI: fueltrack_pro/** only — analyze + test + APK + Release + sync release.json
├── .github/workflows/sync-website.yml # CI: website/** only — sync to wealth-journal (no APK build)
├── website/                           # FuelTrack marketing site source (synced to godwintgn/wealth-journal)
├── screenshots/                       # README + website screenshots (01–04)
├── .cursor/rules/
│   ├── commit-push-build-apk.mdc      # Auto rule: commit → push → clean APK
│   └── update-agent-context.mdc       # Auto rule: keep this file updated every change
├── stitch_fueltrack_pro_analytics_app/  # Stitch mockups (reference only)
└── fueltrack_pro/                     # Flutter project
    ├── lib/
    │   ├── app.dart                   # Root widget + onboarding vs home routing
    │   ├── main.dart
    │   ├── data/                      # regions, onboarding draft types
    │   ├── models/                    # Vehicle, RefuelEntry, AppSettings, ReportFilters, …
    │   ├── providers/                 # Riverpod
    │   ├── screens/                   # … settings, analytics, reports, vehicles
    │   ├── services/                  # db, backup, drive, analytics, fuel_report, calculations
    │   ├── config/                    # google_oauth_config.dart
    │   ├── theme/                     # WJ-aligned theme (app_theme, app_palette, fuel_chart_style, theme_x)
    │   ├── widgets/common/            # AppCard, SectionHeader, EmptyState, SummaryHeaderCard, SummaryStat
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

- **DB version 3**
- **vehicles** — name, make, model, year, fuel_type, license_plate, notes, photo_path, timestamps  
- **refuel_entries** — vehicle_id FK, date, odometer, quantity, price_per_liter (nullable), total_price, fuel_type, station_name, notes  
- **settings** — single row (id=1): currency_code, currency_symbol, **country_code** (new v3), units, theme_mode, onboarding_completed, selected_vehicle_id  
- **fuel_cards** (new v3) — name, provider, company_name, card_number, scope (fleet|vehicle), vehicle_id FK nullable, limit_type, limit_value, reset_period, reset_day, expiry_date, is_active  
- **service_records** (new v3) — vehicle_id FK, title, notes, trigger_type (date|odometer|both), due_date, due_odometer, notify_before_days, notify_before_km, is_completed, completed_date, next_due_date, next_due_odometer  

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

- **`SummaryHeaderCard`** hero at top (speed icon, current odometer headline, avg efficiency + 30d spend + trend `SummaryStat` pills; `ActiveVehicleBar` inlined as trailing)
- Compact stat tiles (`_StatTile` — no fixed height, `titleSmall` w700 values, `labelSmall` labels, 12px vertical padding)
- Cost-per-km row: plain 20px icon + `labelMedium` label + `titleSmall` w700 value (replaces CircleAvatar)
- **`_LastRefuelCard`** icon block shrunk to 52×52; station label in `labelLarge`, time/qty in `labelSmall`
- Monthly spend bar chart: **200px** height, left Y-axis `labelSmall` ticks, reserved 40px
- Efficiency trend line chart: **200px**, left Y-axis ticks
- `_ChartEmpty` uses `bodySmall` text (was `bodyMedium`); 100px height container
- Skeleton updated to match new layout proportions
- Section headers via `SectionHeader` (now `titleMedium` w800)

### 5.5 Vehicle management (`lib/screens/vehicles/`)

- **`VehicleListScreen`**: `SummaryHeaderCard` hero (garage icon, vehicle count headline, active count `SummaryStat`); `_EfficiencyOverviewCard` heading `titleMedium` w800 + `bodySmall` text
- **`VehicleCard`**: title `titleMedium` w700 (was `titleLarge`); subtitle `labelMedium` (was `bodyMedium`); fuel icon 20px; `_MetaChip` label `labelSmall` (was `labelLarge`)
- **`VehicleDetailScreen`**: vehicle name `titleMedium` w700 (was `titleLarge`); fuel type `labelSmall` (was `bodyMedium`); `_StatTile` value `titleSmall` w700 (was `titleMedium`); recent activity date `labelLarge` w600 (was `bodyLarge`); cost `labelLarge` w700 (was `titleMedium`); empty text `bodySmall`
- Add/Edit form requires **Manufacturer, Model, Vehicle Number** (mandatory); year optional  
- List → `VehicleCard` (tap photo → Details; Set active + Fuel Log buttons; no duplicate fuel-type chip), empty state, add-another dashed card  
- **Details** → `VehicleDetailScreen` (read-only profile + photo, Hero transition): stats strip (distance tracked, total spend, avg efficiency, last odometer), recent activity list (last 5, tap → `RefuelDetailScreen`), bottom-docked **Log refuel** button; **Edit** in app bar → `AddEditVehicleScreen`  
- **Fuel Log** opens `AddRefuelScreen` for that vehicle (vehicle + fuel type locked)  

### 5.6 Refuel entry (`lib/screens/refuel/add_refuel_screen.dart`)

- Form: date/time, vehicle, odometer, quantity, price/L, total, station, notes  
- **Smart calc:** any 2 of quantity / price-per-liter / total → derives third (`refuel_calculation.dart`)  
- Auto-calc fields highlighted with green tint + “AUTO” badge on total  
- Prefills price/L from last refuel; odometer hint shows valid range from timeline neighbors  
- **Timeline validation** (`refuel_timeline_validation.dart`): date not in future; odometer must sit between chronological neighbors (supports backdated history inserts)  
- Vehicle + fuel type **locked** when opened from vehicle Fuel Log or when editing an entry  
- **Station name autocomplete** suggests previously-used stations (`RawAutocomplete` over distinct `refuelsProvider` station names)  
- Wired: FAB **New Refuel**, vehicle **Fuel Log**; invalidates `dashboardProvider` on save  
- `refuelsProvider.updateEntry` for edit flow; `refuelsProvider.deleteEntry` for history swipe-delete  

### 5.6b Refuel detail (`lib/screens/refuel/refuel_detail_screen.dart`)

- **Cost hero** card at top (large total + quantity/price subtitle)  
- Spec rows incl. **Efficiency (this fill)** = distance since previous refuel ÷ quantity  
- Read-only view; bottom action bar with **Edit** + **Delete** (delete confirms, removes entry, invalidates dashboard + vehicle refuels)  
- History tap → detail; swipe right → edit  
- Shared `DetailRow` (`lib/widgets/common/detail_row.dart`) used here + vehicle detail  

### 5.7 History (`lib/screens/history/history_screen.dart`)

- **`SummaryHeaderCard`** hero: total entries as headline, total spend + filtered count as `SummaryStat` pills; `ActiveVehicleBar` inlined as trailing
- "Refuel History" section heading: `titleMedium` w800 (was `titleLarge`); total spend pill uses toStringAsFixed(2)
- Search bar (stations, fuel type, vehicle name, notes)  
- Filter bottom sheet: vehicle, fuel type, date range (7d / 30d / 3mo / custom)  
- Summary chip: entry count + total spend for active filters  
- `RefuelHistoryCard`: icon well uses **stable `vehicleAccentColor(vehicleId)`** (palette of 6) — replaces old `alternateAccent: isOdd` index-based colouring; station title `labelLarge` w600; cost `titleSmall` w700; qty 1dp; icon well 40×40 radius-12
- Swipe right → edit (`AddRefuelScreen` edit mode); swipe left → delete with confirm  
- Tap card → `RefuelDetailScreen` (view); empty states for no data / no matches  

### 5.8 Fuel Cards (`lib/screens/fuel_cards/`, `lib/widgets/fuel_cards/`, `lib/models/fuel_card.dart`)

- **FuelCardScope**: fleet (all vehicles) | vehicle (specific)
- **FuelCardLimitType**: none | price | quantity  
- **FuelCardResetPeriod**: none | weekly | monthly | yearly  
- `FuelCardListScreen` — grouped list (Fleet / Vehicle-specific); accessible from Settings → Vehicles → Fuel Cards, and from VehicleDetailScreen
- `AddEditFuelCardScreen` — name, provider, company, scope toggle, vehicle picker, limit, reset period, expiry date, active toggle
- `FuelCardWidget` — compact card with scope/limit/reset/expiry chips, toggle, edit, delete actions
- Provider: `fuelCardsProvider` (all cards CRUD) + `vehicleFuelCardsProvider(vehicleId)` (fleet + vehicle-specific)

### 5.9 Service Reminders (`lib/screens/vehicles/service_records_screen.dart`, `add_edit_service_record_screen.dart`)

- `ServiceRecord` model: trigger_type (date | odometer | both), due_date, due_odometer, notify_before_days, notify_before_km, is_completed, next_due fields
- `VehicleDetailScreen` now shows **Upcoming Service** section (overdue badge, date/odo due) above Recent Refuels; + "All services" + "Fuel cards" action buttons
- `ServiceRecordsScreen` — grouped Upcoming / Completed list per vehicle; mark-complete dialog schedules next service
- `AddEditServiceRecordScreen` — title, notes, trigger type, due date picker, due odometer, notify-before settings
- **Dashboard warning banner** — shown when active vehicle has overdue service records; taps through to `ServiceRecordsScreen`
- Provider: `vehicleServiceRecordsProvider(vehicleId)` (FamilyAsyncNotifier with `add`, `save`, `remove`, `complete`) + `activeServiceRecordsProvider` (all active)

### 5.10 Notifications (`lib/services/notification_service.dart`)

- `flutter_local_notifications ^18.0.1` + `timezone ^0.9.4` added to `pubspec.yaml`
- `NotificationService.instance.initialize()` called from `main.dart`
- `scheduleServiceReminder(record, vehicle)` — schedules OS notification for date-based services
- `cancelServiceReminder(serviceId)` — cancels scheduled notification
- Odometer-based reminders: checked in-app via Dashboard provider on each load (banner shown)

### 5.11 Country & Currency

- **`lib/data/countries.dart`** — 180 `CountryOption(code, name, flag)` entries; `defaultCurrencyFor(countryCode)` mapping
- **`lib/data/currencies.dart`** — 150 ISO 4217 `CurrencyOption(code, symbol, name)` entries  
- `AppSettings.countryCode` added (DB v3 migration); defaults to `'OM'`
- **Onboarding** `OnboardingRegionCurrencyScreen` refactored: independent Country + Currency pickers (searchable bottom sheets); selecting a country pre-fills currency but allows independent override
- **Settings** has separate Country + Currency rows, both using searchable picker sheets (`_SearchPickerSheet`)
- `OnboardingDraft` in `regions.dart` extended: `countryCode`, `currencyCode`, `currencySymbol` fields  
- FAB **New Refuel** on History tab  

### 5.8 Analytics (`lib/screens/analytics/analytics_screen.dart`)

- **`SummaryHeaderCard`** hero: avg efficiency headline, spend + fill count + change% + **avg/fill prediction** `SummaryStat` pills; `ActiveVehicleBar` as trailing
- **Period selector chips**: 7d / 30d / 3M / 1Y / All (all-time uses no date filter)
- **Best / Worst Fill row**: two tappable tiles (cheapest + most expensive price/L) → open `RefuelDetailScreen`
- Efficiency trend line chart: **220px**, tappable points → `RefuelDetailScreen`; **multi-vehicle overlay** (one color-coded line per vehicle using `vehicleAccentColor`) with legend
- **Cost per Fill-up bar chart** (`_FillCostTrendCard`): tap bar → `RefuelDetailScreen`; highlight on hover
- `_EfficiencyInsightCard` / `_CostInsightCard`: 44×44 rounded-14 icon wells, `titleSmall` w700 values
- Monthly spending bar chart: shows last 3–6 months depending on selected period; currency label in subtitle
- **Station Comparison card** (`_StationComparisonCard`): ranked list (cheapest avg price/L first), progress bar scaling, visit count — only shown when station names are logged
- `_MetricRow`: `labelMedium` label, `labelLarge` w700 value
- `_VehicleProfileCard`: now uses `vehicleAccentColor(vehicleId)` for stable color; shows total liters used in trailing column
- Vehicle Profiles section header uses `SectionHeader`
- `AnalyticsService`: new data models `StationStat`, `FillCostPoint`, `VehicleEfficiencyData`; new computed fields `bestFill`, `worstFill`, `stationStats`, `fillCostTrend`, `vehicleEfficiencyData`, `nextRefuelPredictionKm`

### 5.9 Settings (`lib/screens/settings/settings_screen.dart`)

- Currency, distance/fuel units, theme mode  
- Manage vehicles shortcut  
- **Reports** → `ReportsScreen` (PDF export by period + vehicle)  
- **Local backup & restore**: save/restore plain JSON (same schema as Drive sync)  
- Google Drive: sign in, **Sync to Drive** / **Restore from Drive** (plain JSON in app data folder — no passphrase)  
- **Donate** screen (`lib/features/donate/`) — UPI, PayPal, crypto (Wealth Journal pattern, shared `DonateConfig`)  
- OAuth: `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=...` + release SHA-1  
- Opened from Dashboard / Vehicles gear icons  

### 5.10 Reports (`lib/screens/reports/reports_screen.dart`)

- Period chips: 7d, 30d, 3M, 6M, 1Y, All time, Custom (date range picker)  
- Vehicles: all, or multi-select individual vehicles  
- Live preview: period label, fill count, total spent  
- **Export PDF** via `FuelReportService` — summary stats, per-vehicle breakdown, monthly spending table, refuel history table  
- Opened from Settings → Fuel reports  

### 5.11 Fuel efficiency logic (`lib/services/fuel_calculations.dart`)

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
- **Section titles:** `lib/widgets/common/section_header.dart` — `titleMedium` w800 Manrope (was `titleLarge`); subtitle `bodySmall`
- **Header card:** `lib/widgets/common/summary_header_card.dart` — 40px icon well, `titleMedium` w700 title, `headlineSmall` w800 metric, `SummaryStat` pill row
- **Stat chip:** `lib/widgets/common/summary_stat.dart` — `surfaceContainerHigh` pill, `labelSmall` accent label + `titleSmall` w700 value  
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
| `625a705` | feat: WJ UI, active vehicle scoping, fuel-type metrics, FAB polish |
| `a9ea23d` | feat: vehicle detail view, refuel timeline validation, single FAB (v1.11.3+18) |
| `89bd5bd` | feat: UI polish — vehicle card, refuel cost hero, dashboard skeletons, haptics (v1.11.4+19) |
| `2c0eb39` | feat: refuel edit/delete bar, active chip fuel+number, station autocomplete, mandatory vehicle fields (v1.12.0+20) |
| `8c4427b` | feat: Donate screen, remove local save encrypted backup (v1.12.1+21) |
| `ad9b1f6` | feat: Dashboard & Analytics UI rewrite — compact typography, SummaryHeaderCard, Y-axis charts (v1.13.0+22) |
| `f0a89d7` | feat: History & Vehicles UI optimisation — compact typography, SummaryHeaderCard headers (v1.13.1+23) |
| *(pending)* | feat: Feature Batch 3 — fuel entry 3-way calc, Fuel Cards, Service Reminders, stable vehicle colors, country/currency separation (v1.14.0+24) |
| *(pending)* | feat: Analytics enhancement — Best/Worst fill, cost-per-fill chart, station comparison, multi-vehicle overlay, tappable charts, next-refuel prediction (v1.15.0+25) |
| *(pending)* | feat: shared website /fueltrack/, GitHub Releases, Obtainium, README screenshots (v1.16.0+26) |

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
| `backupServiceProvider` | Plain JSON backup/restore (local file + Drive payload builder) |
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
Reports: Settings → Fuel reports → `ReportsScreen`.

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

*Last updated: PDF Reports + local JSON backup/restore (CSV removed). Version `1.17.0+27`.*
