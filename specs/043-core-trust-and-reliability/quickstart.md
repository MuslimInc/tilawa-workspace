# Quickstart: Core Trust & Reliability

## Initial Implementation Sequence
1. Start with Phase 1: Location Fallback. It is the most isolated domain and unblocks the most critical prayer-time calculation failures.
2. Proceed to Phase 2: Athan Reliability. Use physical Android devices.
3. Finish with Phase 3: Quran Integrity. Ensure CI scripts run smoothly.

## Validation Commands
**Formatting & Linting:**
```bash
melos run fix:format
melos run analyze
```

**Unit Tests:**
```bash
flutter test test/features/location
flutter test test/features/prayer_times
flutter test test/features/quran
```

**Quran Integrity Validation (Local):**
```bash
dart scripts/generate_quran_manifest.dart --verify
```

## Platform Validation
### Android
- **Exact Alarms**: Install on Android 12+. Manually revoke "Alarms & Reminders" in settings. Open app, ensure Health UI flags it and deep-links back to settings.
- **Boot**: Set an alarm for +5 mins. Reboot device. Wait without opening the app. Alarm must ring.

### iOS
- **Background**: Set location, verify local notifications are scheduled via `flutter_local_notifications` pending list.
- **Audio**: Verify custom `.caf` file plays under 30 seconds.

## Rollback Instructions
- Disable Location Fallback: Set Firebase Remote Config `enable_manual_location` to `false`.
- Disable Quran Integrity: Set `enable_quran_integrity_check` to `false`.
