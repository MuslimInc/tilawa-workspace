#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Upload Quran Image Flutter assets to Cloudflare R2.

Defaults:
  R2 bucket:     quran
  R2 account:    4c2f8a6943121ef9308e77732c164f98
  R2 key prefix: v1

Required credentials:
  R2_ACCESS_KEY_ID or AWS_ACCESS_KEY_ID
  R2_SECRET_ACCESS_KEY or AWS_SECRET_ACCESS_KEY

Options:
  --dry-run  Print upload actions without writing objects.
  --delete   Delete remote PNG page-line objects missing locally.
  --help     Show this message.

Environment overrides:
  R2_ACCOUNT_ID
  CLOUDFLARE_ACCOUNT_ID
  R2_BUCKET
  R2_PREFIX
  R2_ENDPOINT_URL
  R2_CACHE_CONTROL
  UPLOAD_ARCHIVE=0
USAGE
}

dry_run=0
delete_remote=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      dry_run=1
      ;;
    --delete)
      delete_remote=1
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 64
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_dir="$(cd "$script_dir/.." && pwd)"

account_id="${R2_ACCOUNT_ID:-${CLOUDFLARE_ACCOUNT_ID:-4c2f8a6943121ef9308e77732c164f98}}"
bucket="${R2_BUCKET:-quran}"
prefix="${R2_PREFIX:-v1}"
endpoint_url="${R2_ENDPOINT_URL:-https://${account_id}.r2.cloudflarestorage.com}"
cache_control="${R2_CACHE_CONTROL:-public, max-age=31536000, immutable}"
upload_archive="${UPLOAD_ARCHIVE:-1}"

quran_images_dir="$app_dir/assets/quran_images"
header_banner="$app_dir/assets/images/sura_header_banner.webp"
archive="$app_dir/assets/quran_images.zip"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required. Install it first, then rerun this script." >&2
  exit 69
fi

export AWS_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID:-${AWS_ACCESS_KEY_ID:-}}"
export AWS_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:-${AWS_SECRET_ACCESS_KEY:-}}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-auto}"

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Missing R2 credentials. Set R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY." >&2
  exit 65
fi

if [[ ! -d "$quran_images_dir" ]]; then
  echo "Missing Quran PNG image directory: $quran_images_dir" >&2
  exit 66
fi

if [[ ! -f "$header_banner" ]]; then
  echo "Missing Surah header banner: $header_banner" >&2
  exit 66
fi

dry_run_args=()
if [[ "$dry_run" == "1" ]]; then
  dry_run_args=(--dryrun)
fi

delete_args=()
if [[ "$delete_remote" == "1" ]]; then
  delete_args=(--delete)
fi

echo "Uploading Quran assets to R2 bucket '$bucket' under prefix '$prefix'."

aws --endpoint-url "$endpoint_url" s3 sync \
  "$quran_images_dir" "s3://$bucket/$prefix/pages" \
  --exclude "*" \
  --include "*.png" \
  --content-type "image/png" \
  --cache-control "$cache_control" \
  "${delete_args[@]}" \
  "${dry_run_args[@]}"

aws --endpoint-url "$endpoint_url" s3 cp \
  "$header_banner" "s3://$bucket/$prefix/images/sura_header_banner.webp" \
  --content-type "image/webp" \
  --cache-control "$cache_control" \
  "${dry_run_args[@]}"

if [[ "$upload_archive" == "1" ]]; then
  if [[ ! -f "$archive" ]]; then
    echo "Skipping archive upload; file not found: $archive" >&2
  else
    aws --endpoint-url "$endpoint_url" s3 cp \
      "$archive" "s3://$bucket/$prefix/archives/quran_images.zip" \
      --content-type "application/zip" \
      --cache-control "$cache_control" \
      "${dry_run_args[@]}"
  fi
fi

manifest_file="$(mktemp "${TMPDIR:-/tmp}/quran-r2-manifest.XXXXXX.json")"
trap 'rm -f "$manifest_file"' EXIT

cat >"$manifest_file" <<JSON
{
  "version": "$prefix",
  "bucket": "$bucket",
  "pageCount": 604,
  "lineCount": 15,
  "lineImage": {
    "root": "$prefix/pages",
    "extension": "png",
    "contentType": "image/png"
  },
  "surahHeaderBanner": {
    "key": "$prefix/images/sura_header_banner.webp",
    "contentType": "image/webp"
  },
  "archive": {
    "key": "$prefix/archives/quran_images.zip",
    "contentType": "application/zip"
  }
}
JSON

aws --endpoint-url "$endpoint_url" s3 cp \
  "$manifest_file" "s3://$bucket/$prefix/manifest.json" \
  --content-type "application/json" \
  --cache-control "$cache_control" \
  "${dry_run_args[@]}"

echo "R2 upload command completed."
