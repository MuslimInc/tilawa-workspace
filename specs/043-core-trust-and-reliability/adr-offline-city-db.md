# Architecture Decision Record: Offline City Database

**Status**: Proposed (Pending Approval)
**Context**: MeMuslim requires a manual location fallback for users who deny GPS permissions or experience failures. This requires an offline city database to resolve coordinates and timezones locally.

## Candidates Evaluated

### Option 1: Bundled SQLite Database (e.g., GeoNames 50k cities)
- **Licensing**: GeoNames is CC-BY. Requires attribution.
- **Size**: ~2-3 MB compressed.
- **Performance**: High query performance via `sqflite`.
- **Maintenance**: Requires periodic script updates to sync with upstream timezone/DST changes.

### Option 2: Compressed Indexed JSON
- **Size**: ~4-5 MB compressed.
- **Performance**: Must load entirely into memory or use complex chunking. Slower than SQLite.

### Option 3: Country-Specific Reduced Dataset
- **Size**: < 1 MB.
- **Performance**: Fast.
- **Coverage**: Omits minority Muslim populations in non-core countries. (Unacceptable for a global app).

## Prototype Measurements (GeoNames 50k Subset)
- **Raw SQLite DB Size**: 3.34 MB
- **Compressed Size (APK contribution)**: 0.78 MB
- **Query Latency (English, LIKE match)**: ~1.94 ms
- **Query Latency (Arabic, LIKE match)**: ~2.50 ms
- **Coverage**: Supports full 50,000 cities with Arabic/English names, country codes, lat/lng, and timezone.

## Decision Criteria Needed
1. **Commercial Redistribution Rights**: GeoNames is CC-BY 4.0. This is generally acceptable for commercial apps provided attribution is given.
2. **Attribution Location**: Open-source notices screen and `cities.db` metadata table.
3. **Install Size Budget**: Prototype proves that a 50k city database compressed adds < 1 MB to the APK. This is well within the 3 MB budget.

## Recommendation
**Option 1 (SQLite + GeoNames)** is recommended. It provides sub-3ms lookups, adds only ~0.78MB to the APK, and supports required features.
