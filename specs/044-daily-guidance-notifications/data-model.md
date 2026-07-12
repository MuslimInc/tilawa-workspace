# Data Model: Daily Guidance Notifications

**Branch**: `044-daily-guidance-notifications` | **Date**: 2026-07-12

---

## 1. DailyGuidanceItem

Represents one approved deliverable content item.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `String` | ✅ | Unique identifier (e.g. `quran_002_152`, `hadith_bukhari_6464`) |
| `type` | `DailyGuidanceItemType` | ✅ | `quran` or `hadith` |
| `status` | `ContentPublicationStatus` | ✅ | `draft`, `inReview`, `approved`, `published`, `retired`, `rejected` |
| `originalArabicText` | `String` | ✅ | Full canonical Arabic text |
| `notificationExcerpt` | `String?` | ❌ | Short text safe for notification preview (≤80 chars) |
| `shortExplanation` | `LocalizedGuidanceContent?` | ❌ | Locale-specific approved explanation with stable source ID |
| `translation` | `LocalizedGuidanceContent?` | ❌ | Locale-specific approved translation with stable source ID |
| `topicTags` | `List<String>` | ✅ | e.g. `['mercy', 'patience', 'prayer']` |
| `occasionTags` | `List<String>?` | ❌ | e.g. `['friday', 'ramadan']` |
| `availableLocales` | `List<String>` | ✅ | e.g. `['ar', 'en']` |
| `validFrom` | `DateTime?` | ❌ | Start of valid date window |
| `validUntil` | `DateTime?` | ❌ | End of valid date window |
| `publishedAt` | `DateTime?` | ❌ | Publication timestamp |
| `retiredAt` | `DateTime?` | ❌ | Retirement timestamp |
| `revision` | `int` | ✅ | Content revision number |
| `sourceMetadata` | `QuranSourceMetadata` or `HadithSourceMetadata` | ✅ | Type-specific source info |
| `reviewMetadata` | `ContentReviewMetadata` | ✅ | Editorial review info |

### Validation Rules

- `originalArabicText` must not be empty.
- `status` must be `published` for delivery eligibility.
- `sourceMetadata` must be complete (all required fields populated).
- For hadith: `sourceMetadata.grading` must be `sahih` for MVP.
- `reviewMetadata.sourceValidationComplete` must be true.
- Notification and share reads require their matching review approval.
- Non-Arabic locale reads require a validated translation for that locale.
- Arabic and English locale variants normalize to `ar` and `en`; unsupported locales are ineligible.
- Quran Arabic text and stable item ID must match the bundled `quran_qcf` canonical corpus.
- Hadith item ID, Sahih collection, grading, and grading authority must form an approved stable tuple.
- Every localized explanation or translation crossing into Domain carries a non-empty provenance source ID.
- If `validFrom` and `validUntil` are set, `validFrom` must be before `validUntil`.

---

## 2. QuranSourceMetadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `surahNumber` | `int` | ✅ | 1–114 |
| `surahNameArabic` | `String` | ✅ | e.g. `البقرة` |
| `surahNameLocalized` | `Map<String, String>?` | ❌ | Locale → localized name |
| `ayahStart` | `int` | ✅ | Starting verse number |
| `ayahEnd` | `int?` | ❌ | Ending verse (null = single ayah) |
| `quranTextSourceId` | `String` | ✅ | e.g. `uthmani_hafs` |
| `translationSourceIds` | `Map<String, String>?` | ❌ | Locale → translation source ID |
| `tafsirSourceId` | `String?` | ❌ | Tafsir source for explanation |

### Validation Rules

- `surahNumber` must be 1–114.
- `ayahStart` must be ≥ 1.
- `ayahEnd`, if set, must be ≥ `ayahStart`.

---

## 3. HadithSourceMetadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `collection` | `String` | ✅ | e.g. `Sahih al-Bukhari`, `Sahih Muslim` |
| `book` | `String?` | ❌ | Book/chapter name |
| `chapter` | `String?` | ❌ | Chapter name |
| `referenceNumber` | `String` | ✅ | Hadith number or stable ref |
| `grading` | `HadithGrading` | ✅ | `sahih`, `hasan`, `daif`, `fabricated` |
| `gradingAuthority` | `String` | ✅ | e.g. `Al-Albani`, `Muslim` |
| `sourceEdition` | `String?` | ❌ | Edition identifier |

### Validation Rules

- Only `sahih` and `hasan` are eligible for MVP delivery.
- `collection` must not be empty.
- `referenceNumber` must not be empty.
- `gradingAuthority` must not be empty.

---

## 4. DailyGuidancePreferences

User-controlled notification behavior (stored in SharedPreferencesAsync).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | `bool` | `false` | Feature enabled state |
| `preferredLocalTime` | `TimeOfDay` | `07:00` | Notification time |
| `enabledWeekdays` | `Set<int>` | `{1,2,3,4,5,6,7}` | 1=Mon, 7=Sun |
| `contentMode` | `DailyGuidanceContentMode` | `mixed` | `quranOnly`, `hadithOnly`, `mixed` |
| `preferredTopics` | `List<String>` | `[]` | Explicit topic selections |
| `preferredLocale` | `String?` | `null` | Null = app default |
| `pausedUntil` | `DateTime?` | `null` | Pause end date |
| `lastTimezone` | `String?` | `null` | Last known timezone name |
| `updatedAt` | `DateTime` | `now` | Last preference update |

### Serialization Keys (SharedPreferences)

Prefix: `daily_guidance_`

- `daily_guidance_enabled`
- `daily_guidance_time_hour`, `daily_guidance_time_minute`
- `daily_guidance_weekdays` (comma-separated ints)
- `daily_guidance_content_mode`
- `daily_guidance_topics` (JSON string list)
- `daily_guidance_locale`
- `daily_guidance_paused_until` (ISO 8601)
- `daily_guidance_timezone`
- `daily_guidance_updated_at` (ISO 8601)

---

## 5. DailyDeliveryRecord

Prevents duplication and preserves item stability for a given local date.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `localDate` | `String` | ✅ | ISO date `YYYY-MM-DD` |
| `itemId` | `String` | ✅ | Selected item ID |
| `itemRevision` | `int` | ✅ | Item revision at selection time |
| `scheduledAt` | `DateTime?` | ❌ | When notification was scheduled |
| `deliveredAt` | `DateTime?` | ❌ | When notification was delivered |
| `openedAt` | `DateTime?` | ❌ | When user opened the detail screen |
| `deliveryStatus` | `DeliveryStatus` | ✅ | `selected`, `scheduled`, `delivered`, `opened`, `cancelled`, `skipped`, `failed` |
| `selectionReason` | `String?` | ❌ | e.g. `normal`, `occasion`, `fallback` |
| `timezoneAtSelection` | `String?` | ❌ | Timezone name at selection |

### Storage

Stored in a Hive box `daily_guidance_delivery_records`. Keyed by `localDate`.

Rolling window: keep last 120 records, prune older entries.

---

## 6. ContentReviewMetadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reviewerId` | `String?` | ❌ | Reviewer identifier |
| `reviewAuthority` | `String?` | ❌ | e.g. `Editorial Team` |
| `reviewedAt` | `DateTime?` | ❌ | Review timestamp |
| `notes` | `String?` | ❌ | Review notes |
| `sourceValidationComplete` | `bool` | ✅ | Source verified |
| `translationValidationComplete` | `bool` | ✅ | Translations verified |
| `approvedForNotification` | `bool` | ✅ | Excerpt approved for notification |
| `approvedForSharing` | `bool` | ✅ | Content approved for sharing |

---

## 7. Enumerations

### DailyGuidanceItemType
- `quran`
- `hadith`

### DailyGuidanceContentMode
- `quranOnly`
- `hadithOnly`
- `mixed`

### ContentPublicationStatus
- `draft`
- `inReview`
- `approved`
- `published`
- `retired`
- `rejected`

### HadithGrading
- `sahih` (authentic)
- `hasan` (good)
- `daif` (weak — excluded from MVP)
- `fabricated` (excluded permanently)

### DeliveryStatus
- `selected`
- `scheduled`
- `delivered`
- `opened`
- `cancelled`
- `skipped`
- `failed`

### FeatureState
- `disabled`
- `permissionRequired`
- `permissionDenied`
- `enabled`
- `paused`
- `temporarilyUnavailable`

---

## 8. State Transitions

### Content Publication
```
draft → inReview → approved → published → retired
                 ↘ rejected → draft (explicit revision)
```

### Delivery
```
selected → scheduled → delivered → opened
                     ↘ failed
         ↘ cancelled
         ↘ skipped
```

### Feature
```
disabled → permissionRequired → enabled
                              ↘ permissionDenied
enabled → paused → enabled
enabled → disabled
```

---

## 9. Relationships

```
DailyGuidanceItem
  ├── QuranSourceMetadata (1:1, when type == quran)
  ├── HadithSourceMetadata (1:1, when type == hadith)
  └── ContentReviewMetadata (1:1)

DailyDeliveryRecord
  └── references DailyGuidanceItem by itemId (N:1)

DailyGuidancePreferences (singleton per device)
```
