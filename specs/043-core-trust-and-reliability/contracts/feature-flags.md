# Contract: Feature Flags

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Internal

## Flags

### 1. `enable_quran_integrity_check`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enables the SHA-256 runtime validation of the Quran assets (`assets/data/quran.json` + `quran_image` JSON + downloaded QCF fonts — there is no `quran.db`). Can be set to `false` via Firebase Remote Config if a false-positive blocks users globally.

### 2. `enable_adhan_health_ui`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enables visibility of the Adhan Diagnostics UI in the settings menu.

### 3. `use_exact_alarms`
- **Type**: Boolean
- **Default**: `true`
- **Description**: If true, Android scheduling uses `setExactAndAllowWhileIdle`. If false, uses `setAndAllowWhileIdle`. Used as a rollback mechanism if exact alarms cause OS policy violations or unexpected crashes on specific OEMs.

### 4. `enable_manual_location`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Enables the "Set Location Manually" fallback button during onboarding and in settings.
