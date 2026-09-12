# Chunked Directory Sync

The CSV remains the source of truth and bundled first-install fallback. Remote updates use 32 deterministic gzip JSON chunks in `remote_data/data/v2`.

Run `./scripts/deploy_cloudflare_data.sh` after each CSV update. It generates, validates, and deploys v2 data alongside the temporary legacy endpoint for older app versions.

Each `Entry_ID` is assigned by the first unsigned 64 bits of its SHA-256 hash modulo 32. Do not change the chunk count in v2. A future format version may use a different count.

The app compares remote chunk hashes to SQLite metadata, downloads only changed chunks, validates compressed and decompressed SHA-256 hashes plus record bucket assignments, then replaces affected SQLite buckets in one transaction. Any failed download, validation, or transaction leaves the offline directory unchanged.

Publish chunks before the manifest. Do not rename generated chunk files.
