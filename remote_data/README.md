# Nepal HelpLine Remote Data

This folder is ready to deploy as a static site, for example with Cloudflare Pages.

Current app builds read:

```text
/data/v2/manifest.json
/data/v2/chunks/contacts-<bucket>-<hash>.json.gz
```

Generate fresh files after updating the master CSV:

```sh
python3 scripts/publish_chunked_directory.py --input assets/data/nepal_public_phone_directory.csv --output remote_data/data/v2 --prune
python3 scripts/verify_chunked_directory.py remote_data/data/v2
```

After deployment, build the app with:

```sh
flutter build appbundle --dart-define=REMOTE_DATA_MANIFEST_URL=https://YOUR-DOMAIN.pages.dev/data/v2/manifest.json
```

For local testing:

```sh
cd remote_data
python3 -m http.server 8787
flutter run --dart-define=REMOTE_DATA_MANIFEST_URL=http://127.0.0.1:8787/data/v2/manifest.json
```
