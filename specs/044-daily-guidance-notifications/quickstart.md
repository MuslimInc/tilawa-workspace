# Quickstart: Daily Guidance Notifications

**Branch**: `042-daily-guidance-notifications` | **Date**: 2026-07-12

## Prerequisites

- Flutter SDK (stable channel)
- Melos workspace set up (`melos bootstrap`)
- Android/iOS emulator or device with notification permissions

## Validation Scenarios

### Scenario 1: Feature Opt-In

1. Open MeMuslim → Settings → Notifications → Daily Guidance
2. Toggle "Enable Daily Guidance" ON
3. **Expected**: OS notification permission dialog appears (if not already granted)
4. Grant permission
5. **Expected**: Settings screen shows time picker defaulting to 07:00, all weekdays selected, content mode "Mixed"
6. Save settings
7. **Expected**: Confirmation message: "Daily Guidance is ready. Your next reminder will arrive at the selected time."

### Scenario 2: Receive Notification & Tap

1. Set notification time to 1 minute from now
2. Wait for notification
3. **Expected**: Notification arrives with title "نفحة اليوم 🌿" (Arabic) or "Daily Guidance 🌿" (English) and a short excerpt
4. Tap the notification
5. **Expected**: App opens to the Daily Guidance detail screen showing the full item with source info

### Scenario 3: Item Stability

1. After receiving today's item, close and reopen the app
2. Navigate to Home → Daily Guidance card
3. **Expected**: Same item as the notification
4. Kill and restart the app
5. **Expected**: Same item persists

### Scenario 4: Anti-Repetition

1. Enable Daily Guidance for 3+ consecutive days
2. **Expected**: Each day shows a different item
3. Check that no item repeats within the first 90 days (when corpus ≥ 90 items)

### Scenario 5: Content Mode

1. Set content mode to "Quran Only"
2. Wait for next notification
3. **Expected**: Item is a Quran verse with surah name, number, and verse number
4. Switch to "Hadith Only"
5. Wait for next notification
6. **Expected**: Item is a hadith with collection, reference, and authenticity grade

### Scenario 6: Disable Feature

1. Go to Settings → Notifications → Daily Guidance
2. Toggle OFF
3. **Expected**: Future notifications are cancelled
4. Verify no notification arrives at the previously set time

### Scenario 7: Cold-Start Navigation

1. Force-stop the app
2. Tap a pending Daily Guidance notification
3. **Expected**: App launches and navigates directly to the detail screen for the correct item

### Scenario 8: Offline Viewing

1. Receive a Daily Guidance notification while online
2. Enable airplane mode
3. Tap the notification
4. **Expected**: Detail screen loads the cached item with full source information

## Test Commands

```bash
# From workspace root
cd apps/tilawa

# Unit tests for daily guidance domain
flutter test test/features/daily_guidance/

# Widget tests
flutter test test/features/daily_guidance/presentation/

# Full test suite
melos run test

# Static analysis
melos run analyze
```

## Verification Checklist

- [ ] Feature disabled by default on fresh install
- [ ] Notification permission requested contextually
- [ ] One notification per local date maximum
- [ ] Item stable across app restarts
- [ ] Source information visible on detail screen
- [ ] Deep link works from cold start
- [ ] Dedicated notification channel created
- [ ] No repetition within 90-day window
- [ ] Save and share actions work
- [ ] Settings accessible from Settings → Notifications
- [ ] Arabic RTL layout correct
- [ ] English LTR layout correct
- [ ] Screen reader labels present on all controls
