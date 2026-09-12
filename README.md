# Nepal HelpLine

Nepal HelpLine is a lightweight Flutter app for iOS and Android. It provides an offline-first Nepal public phone directory with emergency numbers, public offices, hospitals, utilities, tourism, ward offices, and other public service contacts.

## Project Type

- Flutter app: one codebase for iOS and Android
- State management: Riverpod
- Local storage: SQLite through `sqflite`
- Seed data: bundled CSV at `assets/data/nepal_public_phone_directory.csv`
- Remote sync: versioned, hash-validated gzip JSON chunks, suitable for Cloudflare Pages

## Run

Install Flutter, then run:

```sh
flutter pub get
flutter run
```

Run iOS:

```sh
flutter run -d ios
```

Run Android:

```sh
flutter run -d android
```

## NepAll embedded mode

The reusable `NepalHelplineApp` accepts an optional `onExit` callback. NepAll supplies this callback when it hosts the complete HelpLine flow as a full-screen nested application. In embedded mode, Home and Settings display `EXIT` in the top-right app bar; it returns to NepAll. Standalone launches leave `onExit` null, so the operating-system app is never forcibly terminated.

The embedded snapshot is maintained inside NepAll at `packages/nepal_helpline`. After changing reusable source or the seed CSV here, deliberately synchronise that package and run analysis/tests in both projects.

## Data Flow

1. The app opens SQLite immediately.
2. On first launch, it imports the bundled CSV seed into SQLite.
3. Screens read from SQLite, so search and browsing work offline.
4. On launch or manual refresh, `ContactSyncService` checks a remote static `manifest.json` when configured.
5. New builds use the v2 manifest: only changed gzip chunks are downloaded, hash-validated, and applied to SQLite atomically.
6. The first v2 sync validates every chunk before replacing the old cache; later syncs replace only changed buckets.
7. If remote sync fails or is disabled, the app keeps using cached SQLite data.
8. If no cache exists, the bundled CSV seed is imported again.

Remote sync is disabled unless `REMOTE_DATA_MANIFEST_URL` is provided at build/run time:

```sh
flutter run --dart-define=REMOTE_DATA_MANIFEST_URL=https://YOUR-DOMAIN.pages.dev/data/v2/manifest.json
```

For Play Store builds with incremental sync:

```sh
flutter build appbundle --release --dart-define=REMOTE_DATA_MANIFEST_URL=https://YOUR-DOMAIN.pages.dev/data/v2/manifest.json
```

## Visual Design

The app uses a Blue Liquid Glass theme in normal/light mode and a Dark Liquid Glass theme in dark mode. The theme is designed for readability, emergency use, and cross-platform performance.

Heavy blur is limited to high-impact surfaces such as the home search area, emergency panels, category cards, bottom navigation, and contact detail headers. Long search and contact lists use lightweight translucent cards instead of expensive blur so scrolling stays smooth on iOS and Android.

## Expected CSV Schema

The importer accepts missing fields and keeps phone numbers as text. Recommended columns:

```text
id, category, subcategory, organisation_name, name_nepali, description,
province, district, palika, ward, address, latitude, longitude,
primary_phone, secondary_phone, hotline_code, fax, email, website,
key_persons, department, working_hours, is_24_7, is_emergency,
source_url, source_type, verification_status, confidence_level,
last_checked, notes
```

The current seed also supports existing exported headers such as `Entry_ID`, `Organisation`, `Data_Source_URL`, and `Source_Name`.

## Updating Seed Data

1. Export the master Excel sheet as CSV.
2. Replace `assets/data/nepal_public_phone_directory.csv`.
3. Keep phone columns formatted as text in Excel before exporting.
4. Run:

```sh
flutter pub get
flutter test
flutter analyze
```

Optional CSV to JSON utility:

```sh
dart run tool/csv_to_seed_json.dart assets/data/nepal_public_phone_directory.csv assets/data/nepal_public_phone_directory.json
```

The app currently imports CSV directly, so JSON output is only for future pipelines or inspection.

## Updating Remote Contact Data

The recommended no-sleep free remote setup is Cloudflare Pages static JSON.

To generate and deploy in one step after logging in to Cloudflare Wrangler:

```sh
./scripts/deploy_cloudflare_data.sh
```

Use a different Cloudflare Pages project name if needed:

```sh
./scripts/deploy_cloudflare_data.sh your-pages-project-name
```

1. Update the master CSV at `assets/data/nepal_public_phone_directory.csv`.
2. Generate remote data files:

```sh
dart run tool/generate_remote_data.dart assets/data/nepal_public_phone_directory.csv remote_data/data
```

3. Deploy the `remote_data` folder to Cloudflare Pages.
4. The app checks:

```text
https://YOUR-DOMAIN.pages.dev/data/manifest.json
```

5. If `data_version` is newer than local SQLite, the app downloads:

```text
https://YOUR-DOMAIN.pages.dev/data/contacts.json
```

6. The app validates the contact count, imports into SQLite, and keeps using cached data if the download fails.

The generated manifest looks like:

```json
{
  "format": "nepal-helpline-csv-json-v1",
  "data_version": "contacts-2026-07-11-06-29-44",
  "published_at": "2026-07-11T06:29:44.000Z",
  "contacts_url": "contacts.json",
  "contacts_count": 1059
}
```

## Local Corrections

The Suggest Correction screen saves corrections locally in SQLite with `Pending Review` status. Corrections do not automatically update the public contact database.

## Disclaimer

Contact details are collected from public sources and may change. For urgent emergencies, call national emergency numbers first. Please verify critical services where possible.
