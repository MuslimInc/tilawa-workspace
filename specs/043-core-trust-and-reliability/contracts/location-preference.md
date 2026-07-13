# Contract: Location Preference

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Pii-Sensitive

## Purpose
Defines how manual location overrides interact with the automated GPS resolution system.

## Schema
```json
{
  "mode": "manual",
  "manual_city_id": 12345,
  "country_code": "EG",
  "timezone": "Africa/Cairo"
}
```

## Fields
- `mode` (String, Required): Either `gps` or `manual`.
- `manual_city_id` (Int, Optional): Required if `mode == 'manual'`. Maps to the bundled `cities.db` ID.
- `country_code` (String, Optional): Required if `mode == 'manual'`. Used for default calculation method resolution.
- `timezone` (String, Optional): Required if `mode == 'manual'`. Used to offset prayer calculation.

## Invariants
- If `mode == 'manual'`, the system MUST NOT request OS location permissions or trigger `geolocator` requests.
- Manual location ALWAYS takes precedence over cached GPS location.
- Only City IDs are persisted to avoid storing precise, identifying Lat/Lng coordinates.

## Privacy & Migration
- PII constraint: Exact coordinates are resolved at runtime from `cities.db` using the ID. Coordinates are never sent to external servers or analytics.
- Missing key falls back to `mode: gps`.
