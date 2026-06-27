# Changelog

All notable changes to FuelTrack Pro are documented here. GitHub Releases use the section for each version.

## [1.18.1] - 2026-06-27

### Fixed
- GitHub Actions release APK now embeds `GOOGLE_OAUTH_SERVER_CLIENT_ID` so Google Drive sign-in works on CI-built installs

## [1.18.0] - 2026-06-27

### Added
- PDF reports: monthly spend bar chart, station comparison table, best/worst fill highlights, notes column, landscape refuel history pages
- Share PDF report from Reports screen
- Registration plates on all PDF vehicle sections; unique report ID and timestamped filenames

### Fixed
- Local backup restore rejects non-`.json` files even when the system file picker shows all files

### Changed
- GitHub release notes list features and fixes instead of install instructions
- README: centered download badges, GPL v3 license

## [1.17.0] - 2026-06-27

### Added
- PDF fuel reports with period and vehicle filters
- Local JSON backup and restore (same format as Google Drive sync)
- Plain Google Drive sync without passphrase or encryption

### Removed
- CSV refuel export (replaced by PDF reports)
