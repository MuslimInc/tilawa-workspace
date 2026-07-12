# Contract: Quran Integrity Manifest

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Public / Non-PII

## Purpose
Defines the schema for the build-time integrity manifest used to guarantee that the bundled Quran data has not been mutated, corrupted, or tampered with before runtime consumption.

## Schema
```json
{
  "version": "1.0.0-qcf4",
  "source": "King Fahd Complex QCF v4",
  "riwayah": "hafs",
  "total_surahs": 114,
  "total_ayahs": 6236,
  "bundled_files": {
    "apps/tilawa/assets/data/quran.json": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "packages/quran_image/assets/data/ayahinfo_markers.json": "…"
  },
  "downloaded_fonts": {
    "archive_sha256": "…",
    "note": "QCF page fonts fetched at runtime by quran_font_service.dart; verified post-download (FR-001a)."
  }
}
```

## Fields
- `version` (String, Required): Format `{schema_version}-{source_identifier}`. Triggers cache invalidation if the structure changes.
- `source` (String, Required): Human-readable identifier of the canonical source.
- `riwayah` (String, Required): e.g. `hafs`. `total_ayahs` is riwayah-specific — a future riwayah changes it (do not hard-assert 6236 across riwayat).
- `total_surahs` (Int, Required): Must strictly equal 114.
- `total_ayahs` (Int, Required): 6236 for Hafs/QCF-v4.
- `bundled_files` (Map, Required): Relative paths to **actual** bundled assets (`apps/tilawa/assets/data/quran.json`, `packages/quran_image/assets/data/*.json`). **There is no `quran.db` / `assets/quran/` in this repo.**
- `downloaded_fonts` (Map, Required): Expected hash(es) for the CDN-delivered QCF page-font archive, verified post-download before first render (FR-001a).

## Invariants
- Manifest MUST be generated at build time; it CANNOT be dynamically fetched at runtime as the primary source of truth (a remote manifest may drive force-upgrades).
- Runtime SHA-256 calculation must be performed asynchronously (off the UI thread).
- The downloaded font archive MUST be verified after download and before first render; on mismatch the renderer falls back to the bundled Uthmanic text style (fail-closed).

## Error Behavior (aligns with FR-002 failure matrix)
- `hashMismatch` / `structuralGap`: safely degrade the Mushaf view and log a **non-fatal** Crashlytics event with expected/actual hashes. Do NOT hard-crash or force reinstall.
- `manifestMissing` / `ioError`: log and continue with existing readable data (not treated as corruption).
