**Prompt for Cursor**

I'm building a Flutter Android app called **FuelTrack Pro** for tracking vehicle fuel consumption, expenses, and efficiency analytics. I have UI mockups (HTML files and PNG images) exported from Google Stitch in this folder:

`C:\Users\Dell\Documents\Github\fuel_tracker\stitch_fueltrack_pro_analytics_app\`

Use these mockups as the visual and layout reference for every screen — match the spacing, card styles, colors, typography, and component layout shown in the HTML/PNG files as closely as Flutter's Material 3 widgets allow. Do not just describe the screens back to me — actually scaffold the Flutter project and build them.

---

### Tech Stack
* Flutter (latest stable), Dart, Material Design 3
* Local-first architecture: **all data stored on-device** using SQLite (via `sqflite` or `drift` — pick one and use it consistently)
* No mandatory backend or server
* Google Drive integration for **optional encrypted backup/restore only** — same pattern as my other app, Wealth Journal: user signs in with Google OAuth, app data is backed up to the user's own Google Drive (App Data folder, not visible in their regular Drive), restorable on a new device. This is opt-in, not required to use the app.
* State management: Riverpod (or Provider if simpler — your call, but be consistent across the app)
* Charts: `fl_chart` package for line/bar/pie charts on Dashboard and Analytics
* Light and Dark mode support, following system theme by default with manual override in Settings

### Project Setup
1. Scaffold a new Flutter project structure with clean separation: `lib/models`, `lib/screens`, `lib/widgets`, `lib/services` (db, backup, calculations), `lib/providers` (or equivalent state layer), `lib/theme`
2. Set up the SQLite schema for: `vehicles`, `refuel_entries`, `settings` (currency, units, theme preference)
3. Set up Material 3 `ThemeData` for light and dark mode using the green/blue accent palette from the mockups — extract actual hex values from the HTML/CSS where possible rather than guessing

### Screens to Build (reference the mockups folder for each)
1. Onboarding — Welcome
2. Onboarding — Add Vehicle (preset pick or manual entry, with fuel type selection)
3. Onboarding — Region & Currency (with Skip available on every onboarding step)
4. Onboarding — Done
5. Dashboard (vehicle selector, stat cards, monthly spending chart, efficiency trend chart, expandable FAB)
6. Refuel Entry (with the smart auto-calculation logic below)
7. History — list view with search, filters (vehicle/fuel type/date range), swipe-to-edit/delete
8. Analytics (km/L, L/100km, weekly/monthly/yearly spending, line/bar/pie/trend charts, insight cards)
9. Vehicle Management — list of vehicle cards, empty state, add/edit
10. Settings (currency, distance unit, fuel unit, theme mode, manage vehicles, data backup, export, cloud sync)

### Key Logic to Implement
**Smart Refuel Calculation** (Refuel Entry screen):
* If Quantity + Price per Liter are entered → auto-calculate Total Price
* If Quantity + Total Price are entered → auto-calculate Price per Liter
* If Price per Liter + Total Price are entered → auto-calculate Quantity
* Recalculate live as the user types; visually distinguish the auto-filled field from manually entered ones

**FAB Speed-Dial** (Dashboard & History):
* Tapping the "+" FAB expands into two labeled mini-FABs: "New Refuel" and "New Vehicle", with a scrim overlay behind them, collapsing on outside tap or re-tapping the FAB

**Fuel Efficiency Calculations**:
* km/L = distance traveled between consecutive refuels (using odometer readings) ÷ liters used
* L/100km = (liters used ÷ km traveled) × 100
* Cost per km = total fuel cost ÷ total distance over the selected period

**Empty States**: Build proper empty states (with simple illustrations or icons, not just blank screens) for History, Analytics, and Vehicle Management when no data exists yet.

**Export**: CSV export of refuel history (Excel export can use the `excel` package if straightforward, otherwise CSV is fine for v1).

### Build Order
Please work through this incrementally rather than generating everything at once:
1. Project scaffold + theme + DB schema
2. Onboarding flow
3. Vehicle Management + Add/Edit Vehicle
4. Dashboard (with mock/seeded data first if real data isn't flowing yet)
5. Refuel Entry with calculation logic
6. History with filters/search/swipe actions
7. Analytics with charts
8. Settings + Google Drive backup integration
9. Wire everything together end-to-end with real local data, remove seed/mock data

After each step, briefly tell me what was built and flag anything from the mockups that wasn't feasible in Flutter as-is so I can decide on a fallback.

### Sample/Seed Data (for early development only, remove before final wiring)
* Vehicle: Mitsubishi Montero Sport, Diesel
* Currency: OMR, Distance unit: km, Fuel unit: liters
* A handful of refuel entries spanning the last 3 months for realistic chart rendering during development
