# Data Model: Android Prayer Notification Hardening

## Device-Protected Storage (DPS) Manifest

This JSON file is stored in `createDeviceProtectedStorageContext()` and is accessible before the user unlocks the phone.

**Filename**: `prayer_adhan_boot`

### Schema

```json
{
  "pending_alarms": [
    {
      "id": "integer",
      "prayer": "string (lowercase name, e.g., 'fajr')",
      "trigger": "long (epoch milliseconds)",
      "sound": "string (resource name, e.g., 'adhan_fajr')"
    }
  ],
  "needs_reschedule_after_boot": "boolean"
}
```

## Credential-Protected Storage (CPS) Data

This data remains in the standard `prayer_adhan_alarms` storage and is only accessed by the Flutter/Dart layer or the native layer after the device is unlocked.

* **`active_ids`**: `Set<String>` - List of notification IDs currently scheduled in `AlarmManager`. Used for batch cancellations.

## Observability Intent Extras

When an alarm fires, the `Intent` delivered to `AdhanReceiver` and passed to `AdhanPlaybackService` will include:

| Key | Type | Description |
| :--- | :--- | :--- |
| `EXTRA_NOTIFICATION_ID` | `Int` | The ID used for the notification. |
| `EXTRA_PRAYER_NAME` | `String` | Human-readable prayer name. |
| `EXTRA_SCHEDULED_MS` | `Long` | The original epoch time the alarm was scheduled for. |
| `EXTRA_SOUND` | `String` | The resource name to play (fallback to `adhan`). |
| `EXTRA_RECEIVER_TIME` | `Long` | Timestamp when the receiver actually triggered. |
