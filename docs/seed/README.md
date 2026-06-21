# Firestore seed data — Quran Sessions market configs

MVP markets: **EG**, **SA**, **AE** with curated cities.

| File | Purpose |
|------|---------|
| [`quran_session_market_configs.json`](quran_session_market_configs.json) | 3 country docs + 19 city docs (22 total) |

## Quick seed (production / dev)

```sh
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
npm run seed:market-configs:apply
```

## Console import checklist

1. Firebase Console → Firestore → **Import data**.
2. Target collection: `quran_session_market_configs`.
3. Upload `quran_session_market_configs.json`.
4. Verify root documents `EG`, `SA`, `AE` each have a `cities` subcollection.
5. Hot restart the Tilawa app; open Profile Completion — countries should appear.

## Keeping in sync

When editing `packages/quran_sessions/lib/src/data/seed/default_market_catalog.dart`,
update this JSON and re-run the Admin script. Field names must match
`_countryDoc` / `_cityDoc` in
`apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_market_config_repository.dart`.
