# Quran Image Assets on Cloudflare R2

The Quran line images should be uploaded as PNG. The existing PNG archive is
smaller than the lossless WebP archive for this artwork, while the Surah header
banner remains WebP because it compresses better.

## Bucket

- Account ID: `4c2f8a6943121ef9308e77732c164f98`
- Bucket: `quran`
- Public base URL:
  `https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev`

## Object Layout

Current manual upload:

```text
quran_images.zip
sura_header_banner.webp
```

Public URLs:

```text
https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/quran_images.zip
https://pub-7f6f6686010343899ba5b2f0ac6cb7b3.r2.dev/sura_header_banner.webp
```

## Runtime Cache

The Flutter app does not bundle Quran page images. On startup it:

1. Checks app support storage for a ready `v1` Quran image cache.
2. Downloads `quran_images.zip` from R2 when the cache is missing or stale.
3. Extracts the archive into app storage on a background isolate.
4. Downloads `sura_header_banner.webp` into the same cache.
5. Writes cache metadata only after validation succeeds.
6. Renders Quran lines from `Image.file` using deterministic local paths.

The ready check validates metadata plus sentinel files for page `1/1.png`,
page `604/15.png`, and the Surah header banner. Normal page rendering is O(1)
path construction against the extracted local cache.

Recommended future versioned layout:

```text
v1/
  pages/
    1/
      1.png
      2.png
      ...
      15.png
    ...
    604/
      15.png
  images/
    sura_header_banner.webp
  archives/
    quran_images.zip
  manifest.json
```

## Manual Upload

Through the Cloudflare dashboard, upload the smaller PNG archive:

```text
Local file:
  apps/quran_image/assets/quran_images.zip

R2 object key:
  quran_images.zip

Content-Type:
  application/zip
```

Then upload the Surah header banner:

```text
Local file:
  apps/quran_image/assets/images/sura_header_banner.webp

R2 object key:
  sura_header_banner.webp

Content-Type:
  image/webp
```

If you also want direct per-line CDN loading later, upload the contents of:

```text
apps/quran_image/assets/quran_images/
```

under:

```text
v1/pages/
```

so page 1 line 1 resolves to:

```text
v1/pages/1/1.png
```

Use `Cache-Control: public, max-age=31536000, immutable` for versioned assets.
For root-level files, either replace the object and purge cache, or upload the
next version under a versioned prefix such as `v2/`.

## Scripted Upload

Install the AWS CLI and create a Cloudflare R2 access key with write access to
the `quran` bucket. Then run:

```sh
export R2_ACCESS_KEY_ID="..."
export R2_SECRET_ACCESS_KEY="..."

apps/quran_image/tools/upload_quran_assets_to_r2.sh --dry-run
apps/quran_image/tools/upload_quran_assets_to_r2.sh
```

To publish a new immutable asset version:

```sh
R2_PREFIX=v2 apps/quran_image/tools/upload_quran_assets_to_r2.sh
```

The script sets:

- `Content-Type: image/png` for Quran line images.
- `Content-Type: image/webp` for the Surah header banner.
- `Content-Type: application/zip` for the archive.
- `Cache-Control: public, max-age=31536000, immutable`.

Use a Cloudflare R2 custom domain for production delivery so objects can be
served through Cloudflare cache and normal cache controls.
