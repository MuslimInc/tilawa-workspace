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
  "total_surahs": 114,
  "total_ayahs": 6236,
  "files": {
    "quran.db": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
}
```

## Fields
- `version` (String, Required): Format `{schema_version}-{source_identifier}`. Used to trigger cache invalidations if the structure changes.
- `source` (String, Required): Human-readable identifier of the canonical source.
- `total_surahs` (Int, Required): Must strictly equal 114.
- `total_ayahs` (Int, Required): Must strictly equal 6236.
- `files` (Map<String, String>, Required): Keys are relative paths to assets within `assets/quran/`. Values are SHA-256 hex digests computed at build time.

## Invariants
- Manifest MUST be generated at build time; it CANNOT be dynamically fetched at runtime as the primary source of truth (though a remote manifest can be used for force-upgrades).
- Runtime SHA-256 calculation must be performed asynchronously to prevent blocking the UI thread during app startup.
- If validation fails, the `QuranRepository` MUST throw a `DataIntegrityException` rather than serving corrupted data.

## Error Behavior
If `DataIntegrityException` is thrown:
- The UI gracefully degrades to an error screen ("Data corruption detected. Please update or reinstall the app").
- A non-fatal exception is logged to Crashlytics including the expected and actual hashes.
