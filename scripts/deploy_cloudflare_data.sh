#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${1:-${CLOUDFLARE_PAGES_PROJECT:-nepal-helpline-data}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_URL="https://${PROJECT_NAME}.pages.dev/data/manifest.json"

cd "$ROOT_DIR"

echo "Generating legacy remote JSON data for already-published app versions..."
dart run tool/generate_remote_data.dart \
  assets/data/nepal_public_phone_directory.csv \
  remote_data/data \
  "$(date -u +contacts-%Y-%m-%d-%H-%M-%S)" \
  remote_data/docs

echo "Generating chunked v1 remote data for current and future app versions..."
python3 scripts/publish_chunked_directory.py \
  --input assets/data/nepal_public_phone_directory.csv \
  --output remote_data/data/v2 \
  --prune
python3 scripts/verify_chunked_directory.py remote_data/data/v2

cp Privacy_Policy.md remote_data/docs/privacy_policy.md
cp Terms_of_Use.md remote_data/docs/terms_of_use.md

if [[ -n "${WRANGLER_BIN:-}" ]]; then
  WRANGLER_CMD=("$WRANGLER_BIN")
elif command -v wrangler >/dev/null 2>&1; then
  WRANGLER_CMD=("wrangler")
else
  WRANGLER_CMD=("npx" "wrangler")
fi

echo "Checking Cloudflare login..."
if ! "${WRANGLER_CMD[@]}" whoami >/dev/null; then
  echo "Wrangler is not logged in. Run this first:"
  echo "  ${WRANGLER_CMD[*]} login"
  exit 1
fi

echo "Creating Cloudflare Pages project if it does not already exist..."
set +e
"${WRANGLER_CMD[@]}" pages project create "$PROJECT_NAME" --production-branch main
CREATE_EXIT=$?
set -e
if [[ "$CREATE_EXIT" -ne 0 ]]; then
  echo "Project create did not complete. Continuing in case the project already exists..."
fi

echo "Deploying remote_data to Cloudflare Pages project: $PROJECT_NAME"
"${WRANGLER_CMD[@]}" pages deploy remote_data \
  --project-name "$PROJECT_NAME" \
  --branch main

echo ""
echo "Remote data is deployed."
echo "Manifest URL:"
echo "  $MANIFEST_URL"
echo ""
echo "For builds with chunked incremental sync enabled, use:"
echo "  --dart-define=REMOTE_DATA_MANIFEST_URL=https://${PROJECT_NAME}.pages.dev/data/v2/manifest.json"
echo ""
echo "Android release bundle:"
echo "  flutter build appbundle --release --dart-define=REMOTE_DATA_MANIFEST_URL=https://${PROJECT_NAME}.pages.dev/data/v2/manifest.json"
