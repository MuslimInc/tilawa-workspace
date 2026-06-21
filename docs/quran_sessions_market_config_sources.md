# Quran Sessions — Market Config Data Sources

> **Architecture rationale:** why enabled markets in Firestore (not runtime geo APIs or
> global import) — [quran_sessions_market_config_architecture.md](quran_sessions_market_config_architecture.md).

## Decision (MVP)

**App runtime source of truth:** Firestore collection
`quran_session_market_configs/{countryCode}/cities/{cityId}`.

External APIs are **not** called from the Flutter app. They may be used only for
one-off seeding or admin import jobs behind data-layer abstractions.

## External dataset evaluation

| Source | Use for | Pros | Limitations |
|--------|---------|------|-------------|
| [REST Countries](https://restcountries.com/) | Country metadata (names, flags, phone codes, currencies) | Free, no key, stable ISO codes | No cities; not suitable for city pickers |
| [GeoNames](http://www.geonames.org/) | City lists by country | Large coverage, admin codes | Free tier ~1k credits/day; attribution required; noisy for MVP (too many cities) |
| [GeoDB Cities API](https://rapidapi.com/wirefreethought/api/geodb-cities) | City search/list | REST, filterable | RapidAPI quota; third-party uptime; licensing per plan |
| Curated in-repo catalog | MVP enabled markets only | Full control, Arabic labels, pricing fields | Manual maintenance |

**MVP choice:** Curated catalog in
`packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart`, uploaded
to Firestore via `FirestoreMarketConfigSeeder` / `seed_market_configs.dart`.

Future expansion can import REST Countries + GeoNames into Firestore using an
admin script without changing domain or presentation layers.

## Firestore document layout

### `quran_session_market_configs/{countryCode}`

Document ID = ISO 3166-1 alpha-2 (`EG`, `SA`, `AE`).

| Field | Type | Notes |
|-------|------|-------|
| `countryCode` | string | Same as document ID |
| `countryName` / `countryNameAr` | string | Arabic display |
| `countryNameEn` | string? | English display |
| `currencyCode` | string | ISO 4217 |
| `timezone` | string | IANA |
| `phoneCode` | string? | E.164 prefix |
| `flagEmoji` | string? | UI only |
| `minimumStudentAgeYears` | int | Market override |
| `minimumTeacherAgeYears` | int | Market override |
| `defaultCityId` | string | Default picker value |
| `minSessionPrice`, `maxSessionPrice` | number | Pricing bounds |
| `platformCommissionPercent` | number | Platform fee |
| `isEnabled` | bool | Listed only when `true` |
| `sortOrder` | int | Ascending list order |
| `updatedAt` | timestamp | Server time on seed |

### Subcollection `cities/{cityId}`

Document ID = stable slug (`cairo`, `riyadh`).

| Field | Type |
|-------|------|
| `cityId` | string |
| `cityName` / `cityNameAr` | string |
| `cityNameEn` | string? |
| `timezone`, `currencyCode` | string |
| `isEnabled` | bool |
| `sortOrder` | int |
| `updatedAt` | timestamp |

## Query patterns

| Operation | Pattern |
|-----------|---------|
| List enabled countries | `collection.where(isEnabled==true).orderBy(sortOrder)` |
| Get country | `doc(countryCode).get()` |
| List enabled cities | `doc(countryCode)/cities.where(isEnabled==true).orderBy(sortOrder)` |
| Get city | `doc(countryCode)/cities.doc(cityId).get()` |

## Composite indexes

Required before Profile Completion country/city queries work in Firebase mode.
See [`firestore.indexes.json`](../../firestore.indexes.json) and deploy:

```sh
firebase deploy --only firestore:indexes
```

Index build can take a few minutes on first deploy.

## Seeding

Canonical seed payload: [`docs/seed/quran_session_market_configs.json`](seed/quran_session_market_configs.json)
(3 countries, 19 cities — **22 documents** total). Mirrors
`DefaultMarketCatalog` and `FirestoreMarketConfigSeeder` field names.

`firestore.rules` sets `allow write: if false` on `quran_session_market_configs`
(and `cities`). Client SDK writes are blocked in production; use Admin SDK or
Console import below.

### Recommended — Admin SDK script (production / dev)

From `functions/` with a service account or Application Default Credentials:

```sh
# One-time: download a key from Firebase Console → Project settings →
# Service accounts → Generate new private key, then:
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Or use gcloud ADC (must have Firestore write on the project):
# gcloud auth application-default login

npm run seed:market-configs          # dry run — lists EG/SA/AE + city counts
npm run seed:market-configs:apply    # merge-writes all docs (idempotent)
```

Equivalent:

```sh
npx ts-node scripts/seedMarketConfigs.ts --apply
```

Targets project `quran-playera-app` (see `functions/src/github.ts`). Merge writes
match the Dart seeder; safe to re-run after catalog updates.

### Backup — Firebase Console import

1. Open [Firestore](https://console.firebase.google.com/project/quran-playera-app/firestore)
   → **Import data** (or create collection `quran_session_market_configs` and
   import into it).
2. Select [`docs/seed/quran_session_market_configs.json`](seed/quran_session_market_configs.json).
   The file uses Firestore’s `__collections__` shape for nested `cities`.
3. Confirm document IDs: `EG`, `SA`, `AE` at the collection root; city slugs
   (`cairo`, `riyadh`, …) under each country’s `cities` subcollection.
4. After import, add `updatedAt` timestamps manually if desired (optional —
   the app does not require them for reads).

See [`docs/seed/README.md`](seed/README.md) for a short checklist.

### Emulator / local only — Dart client script

From `apps/tilawa` (works when rules allow writes, e.g. Firestore emulator):

```sh
dart run lib/scripts/seed_market_configs.dart
```

### Verify in the app

1. Ensure composite indexes are deployed: `firebase deploy --only firestore:indexes`
2. Seed with Admin SDK (above).
3. **Hot restart** the app (signed-in user required for market config reads).
4. Profile Completion should list Egypt, Saudi Arabia, and UAE with city pickers.

If the collection is empty, Profile Completion shows `MarketCatalogEmptyFailure`
(not an empty dropdown) until seed data exists.

## Security rules (summary)

- Authenticated users: **read** enabled market/country/city docs only.
- Clients: **no writes** to market config.
- Admin/server: writes via Admin SDK or Cloud Functions.

See [quran_sessions_firestore_security_rules.md](quran_sessions_firestore_security_rules.md).

## Remaining limitations

- Only EG, SA, AE seeded for MVP; other countries require admin seeding.
- City lists are curated, not exhaustive.
- Disabled markets are excluded from list queries but direct doc reads depend on
  rules enforcement.
- No automatic sync from external APIs; catalog changes require a seed/deploy step.
