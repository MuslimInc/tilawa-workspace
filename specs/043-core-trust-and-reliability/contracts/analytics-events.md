# Contract: Analytics Events

**Status**: Active
**Version**: 1.0.0
**Privacy Classification**: Non-PII

## Events Definition

### 1. `adhan_scheduled`
- **Trigger**: When the alarm manager or local notification center registers a prayer time.
- **Payload**:
  - `prayer_name` (String): fajr, dhuhr, asr, maghrib, isha.
  - `time_offset_mins` (Int): Time from now until scheduled trigger.

### 2. `adhan_delivered`
- **Trigger**: Fired immediately when the exact alarm receiver executes in the background.
- **Payload**:
  - `prayer_name` (String)
  - `latency_ms` (Int): Difference between expected trigger time and actual execution time (measures OEM throttling).

### 3. `adhan_health_check_viewed`
- **Trigger**: User opens the diagnostics UI.
- **Payload**:
  - `battery_opt_status` (Boolean)
  - `alarm_perm_status` (Boolean)

### 4. `location_manual_selected`
- **Trigger**: User overrides GPS and selects a city manually.
- **Payload**:
  - `country_code` (String)
  - *No specific city IDs or names to preserve privacy.*

### 5. `quran_error_reported`
- **Trigger**: User submits a textual error report via the Mushaf UI.
- **Payload**:
  - `surah_number` (Int)
  - `ayah_number` (Int)
  - `app_version` (String)
