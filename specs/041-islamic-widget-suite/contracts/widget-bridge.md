# Contract: Flutter ↔ Android Widget Bridge

## Purpose

Define the versioned, one-way snapshot contract used to hand display-ready state from Flutter to Android widget providers. Host actions travel back as narrow commands; religious calculations never cross into native code.

## Channel Operations

The existing prayer channel may be extended or a dedicated widget channel may be introduced, but operation semantics are fixed:

| Operation | Direction | Input | Result |
|---|---|---|---|
| `saveWidgetSnapshot` | Flutter → Android | `WidgetSnapshotEnvelope` | `{accepted: bool, schemaVersion: int}` |
| `deleteWidgetSnapshot` | Flutter → Android | `{widgetType}` | `{deleted: bool}` |
| `refreshWidgets` | Flutter → Android | `{widgetTypes: [...]}` | `{requestedCount: int}` |
| `getWidgetInstances` | Flutter ← Android | none | privacy-safe type/size/theme records |
| `widgetAction` | Android → Flutter | `WidgetAction` | acknowledged after route/action dispatch |

Calls must be idempotent. A failed or unsupported write must retain the last valid snapshot.

## Snapshot Envelope

```json
{
  "schemaVersion": 1,
  "widgetType": "ayah",
  "generatedAtMs": 1783728000000,
  "validUntilMs": 1783814400000,
  "localeTag": "ar",
  "payload": {}
}
```

Payload contracts:

- `prayer`: location label, settings fingerprint, ordered day/prayer instants, staleness boundary.
- `ayah`: local date, pool version, Surah/Ayah/page reference, accessible reference, validated artifact variants.
- `athkar`: applicable period/date, category identity, localized display body, item count, period label. Per-instance index stays native and is reconciled against item count.
- `hijri`: Gregorian local date, adjusted Hijri day/month/year labels, offset, next rollover instant.

Unknown payload fields are ignored. Missing required fields or invalid ranges reject the new envelope. Native storage keeps a checksum and writes atomically.

## Artifact Reference

```json
{
  "sizeClass": "compact",
  "theme": "dark",
  "relativePath": "widgets/ayah/2026-07-11_compact_dark.png",
  "widthPx": 720,
  "heightPx": 360,
  "byteSize": 148320,
  "sha256": "..."
}
```

Paths must resolve inside the app's private widget directory. Native code rejects absolute paths, traversal, missing files, checksum mismatch, zero dimensions, or artifacts above the configured budget.

## Widget Actions

```json
{
  "action": "openAyah",
  "widgetType": "ayah",
  "appWidgetId": 42,
  "arguments": {"pageNumber": 1, "surahNumber": 1, "ayahNumber": 1}
}
```

Allowed actions are `openPrayerTimes`, `openAyah`, `openAthkar`, `openHijriSettings`, `advanceAthkar`, and `openWidgetSetup`. `appWidgetId` is used locally for instance state and omitted from analytics.

## Failure Contract

Providers render in this order:

1. Valid current snapshot.
2. Last valid snapshot plus localized stale cue.
3. Localized setup/error state with a direct setup action.

They never render a blank frame. Failures use stable categories: `missing_snapshot`, `unsupported_schema`, `invalid_payload`, `missing_artifact`, `artifact_decode`, `storage`, and `schedule_rejected`.

## Analytics Contract

Allowed parameters: widget type, size class, theme, action, freshness bucket, result, failure category, and app version. Forbidden parameters: Quran/Athkar content or reference, precise location, raw widget ID, reading history, and artifact path.
