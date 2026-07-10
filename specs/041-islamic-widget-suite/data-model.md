# Data Model: Islamic Home Screen Widget Suite (v1)

## WidgetInstance

Represents one launcher placement.

| Field | Type | Rules |
|---|---|---|
| appWidgetId | integer | Positive; host-assigned; never sent to analytics |
| type | enum | `prayer`, `ayah`, `athkar`, `hijri` |
| sizeClass | enum | `compact`, `expanded`; derived from current host bounds |
| theme | enum | `light`, `dark`, `automatic` |
| localeTag | string | Supported Arabic or English locale |
| createdAt | instant | Required |
| lastRenderedAt | instant? | Updated only after successful host render |

**Lifecycle**: configured → active → resized/reconfigured → deleted. Deletion removes per-instance progress and cached references but not shared settings.

## WidgetSnapshotEnvelope

Versioned boundary object persisted atomically for native rendering.

| Field | Type | Rules |
|---|---|---|
| schemaVersion | integer | Reject unsupported versions without deleting last valid snapshot |
| widgetType | enum | Must match payload |
| generatedAt | instant | Used for freshness |
| validUntil | instant? | Boundary after which refresh is requested |
| localeTag | string | Determines localized labels |
| payload | typed snapshot | Display-ready; no precise coordinates or reading history |

## PrayerScheduleSnapshot

| Field | Type | Rules |
|---|---|---|
| locationLabel | string | Human-readable only; no coordinates |
| settingsFingerprint | string | Opaque change detector |
| days | list of PrayerDay | Today plus enough future data for offline rollover |
| staleAfter | instant | At most one day after the relevant schedule window |

`PrayerDay` contains local date and Fajr, Dhuhr, Asr, Maghrib, and Isha instants. Sunrise may remain internal but is not a displayed prayer row.

## DailyAyahSelection

| Field | Type | Rules |
|---|---|---|
| localDate | date | Unique per installation/day |
| poolVersion | integer | Required for deterministic migration |
| surahNumber | integer | 1–114 |
| ayahStart | integer | Valid within Surah |
| ayahEnd | integer | Equal to start for widget v1 |
| pageNumber | integer | 1–604; deep-link target |
| accessibleReference | string | Localized Surah/Ayah reference |
| artifacts | map of ArtifactVariant | Required supported size/theme variants |

`ArtifactVariant` contains size class, theme, relative app-private path, width, height, byte size, checksum, and creation instant. Publish only after the file exists, decodes, is within the byte budget, and has non-zero dimensions.

## AthkarSetProgress

| Field | Type | Rules |
|---|---|---|
| appWidgetId | integer | Per-instance key |
| period | enum | `morning`, `evening` |
| periodDate | date | Resets when period identity changes |
| categoryId | integer/string | Existing Athkar category identity |
| itemIndex | integer | `0 <= index < itemCount` |
| itemCount | integer | Positive |
| lastInteractionAt | instant? | Diagnostic/reset support |

**Transition**: resolve current applicable period → reuse matching progress or reset to index 0 → advance modulo item count → persist → render. Between configured windows, retain the most recently applicable period and label it.

## HijriAdjustment

| Field | Type | Rules |
|---|---|---|
| offsetDays | integer | Inclusive range −2…+2 |
| updatedAt | instant | Required |

One app-wide value feeds every Hijri surface. Local midnight and the device timezone define rollover.

## ShareCardDraft

| Field | Type | Rules |
|---|---|---|
| surahNumber | integer | 1–114 |
| ayahStart | integer | First selected Ayah |
| ayahEnd | integer | Consecutive; one-to-five total |
| backgroundStyle | enum | At least three curated styles |
| localeTag | string | Controls surrounding labels |
| attributionEnabled | boolean | Always true in v1 |
| status | enum | `editing`, `rendering`, `ready`, `sharing`, `completed`, `cancelled`, `failed` |
| artifact | ArtifactVariant? | Present only from `ready` onward |

**Transition**: editing → rendering → ready → sharing → completed. Editing/ready may move to cancelled; rendering/sharing may move to failed. Cancelled, failed, and expired artifacts enter cleanup.

## Relationships and Ownership

- One widget type has zero or more `WidgetInstance` records.
- Shared prayer, Ayah, and Hijri snapshots may serve many instances; Athkar progress remains per instance.
- A `DailyAyahSelection` owns its current artifact variants and replaces them atomically when theme/size content changes.
- A `ShareCardDraft` owns one transient artifact and never mutates Quran text.
- Flutter repositories own domain entities; the native store owns only serialized envelope copies and host configuration.
