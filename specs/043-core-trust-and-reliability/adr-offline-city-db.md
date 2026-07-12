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

## Decision Criteria Needed
1. **Commercial Redistribution Rights**: Is CC-BY acceptable for MeMuslim?
2. **Install Size Budget**: Can we allocate 3MB to the APK size for this feature?

## Recommendation
**Option 1 (SQLite + GeoNames)** is recommended. It provides O(1) lookups, fits within a reasonable size budget, and supports complex queries (Arabic + English names).

**Next Steps**: Approve this ADR to unblock Task T-L02.
