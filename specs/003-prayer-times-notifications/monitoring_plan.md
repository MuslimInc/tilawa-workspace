# Prayer Notifications Monitoring Plan

## Release Events

The Android release must emit these operational events:

| Event | Source | Purpose |
|---|---|---|
| `prayer_notification_schedule_started` | Native schedule MethodChannel | Scheduling attempt started |
| `prayer_notification_triggered` | Native alarm receiver | Alarm fired |
| `native_adhan_schedule_success` | Native scheduler | AlarmManager schedule succeeded |
| `native_adhan_schedule_failed` | Native scheduler | AlarmManager schedule failed |
| `adhan_fallback_used` | Dart scheduler | Native Adhan unavailable or failed; FLN fallback used |
| `native_adhan_playback_started` | Native playback logic | Adhan playback intent accepted |
| `native_adhan_playback_failed` | Native playback service | Playback startup/runtime failure |
| `duplicate_audio_guard_triggered` | Native playback service | Duplicate ACTION_PLAY suppressed |
| `permission_revoked_cleanup_completed` | Dart scheduler | POST_NOTIFICATIONS denial cleanup completed |
| `watchdog_triggered` | Native WorkManager worker | Watchdog started |
| `watchdog_completed` | Native WorkManager worker | Watchdog completed successfully |
| `watchdog_failed` | Native WorkManager worker | Watchdog failed |
| `watchdog_timeout_occurred` | Native WorkManager worker | Watchdog timed out and requested retry |
| `boot_receiver_triggered` | Native boot receiver | Reboot/time/package-change recovery started |

## Release Thresholds

Do not advance rollout when any threshold is exceeded:

| Metric | Block Threshold |
|---|---|
| Native scheduling failure | More than 5% |
| Native playback failure | More than 2% |
| Watchdog failure | More than 5% |
| Duplicate playback reports | More than 0.5% |
| Permission cleanup failure | Any confirmed failure |

## Privacy

Prayer notification events are operational telemetry. They must not include raw device location, contacts, messages, or prayer calculation inputs. Allowed context includes event name, prayer label, permission state, notification ID, fallback reason, timeout state, and device manufacturer when needed for OEM reliability triage.
