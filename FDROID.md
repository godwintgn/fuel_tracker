# F-Droid submission guide — FuelTrack Pro

Package: `com.fuel.tracker`  
Source: [github.com/godwintgn/fuel_tracker](https://github.com/godwintgn/fuel_tracker)  
Flutter app path: `fueltrack_pro/`

## Prerequisites (done in this repo)

- [x] GPL-3.0 license (`LICENSE`)
- [x] Bundled fonts (Manrope + Inter) — no runtime font download
- [x] Fastlane store metadata under `fueltrack_pro/fastlane/metadata/android/en-US/`
- [x] Draft build metadata at `fdroid/metadata/com.fuel.tracker.yml`
- [x] Tagged releases (`v1.19.0+31`, etc.)

## Optional Google Drive on F-Droid builds

Drive sync uses Google Sign-In (Anti-feature: **NonFreeNet**). Core app works offline without it.

To enable Drive in F-Droid APKs, create `fueltrack_pro/fdroid/oauth_client_id` with your **Web application** OAuth client ID before tagging, or add `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=…` in the fdroiddata build recipe.

See `fueltrack_pro/fdroid/oauth_client_id.example`.

## Submit to F-Droid

### 1. Tag a release

```bash
git tag v1.19.0+31
git push origin v1.19.0+31
```

### 2. Fork fdroiddata

1. Fork https://gitlab.com/fdroid/fdroiddata  
2. Clone your fork  
3. Create branch: `com.fuel.tracker`

### 3. Add metadata

Copy [`fdroid/metadata/com.fuel.tracker.yml`](../fdroid/metadata/com.fuel.tracker.yml) to `metadata/com.fuel.tracker.yml` in your fdroiddata fork.

Adjust Flutter version / ABI blocks if CI lint fails. Add `armeabi-v7a` and `x86_64` build blocks as separate `Builds` entries if required.

### 4. Test locally (optional)

Install [fdroidserver](https://f-droid.org/docs/Build_Server_Setup/):

```bash
fdroid readmeta
fdroid lint com.fuel.tracker
fdroid build -v -l com.fuel.tracker
```

### 5. Open merge request

- Push branch to your fdroiddata fork  
- MR: https://gitlab.com/fdroid/fdroiddata/-/merge_requests  
- Title: `com.fuel.tracker: FuelTrack Pro`  
- Wait for CI + reviewer (days to weeks)

### 6. After acceptance

App page: `https://f-droid.org/packages/com.fuel.tracker/`

Update README badge to point to the real F-Droid URL.

## Faster alternative: IzzyOnDroid

https://apt.izzysoft.de/docs.php — lighter review, useful while waiting for main F-Droid.

## References

- [F-Droid Quick Start](https://f-droid.org/docs/Submitting_to_F-Droid_Quick_Start_Guide/)
- [Build metadata reference](https://f-droid.org/docs/Build_Metadata_Reference/)
- [Flutter build template](https://gitlab.com/fdroid/fdroiddata/-/blob/master/templates/build-flutter.yml)
