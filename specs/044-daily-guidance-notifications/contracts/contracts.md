# Contracts: Daily Guidance Feature

**Branch**: `042-daily-guidance-notifications` | **Date**: 2026-07-12

This feature is internal to the MeMuslim Flutter app. The contracts below define the domain-layer interfaces that the data layer implements and the presentation layer consumes.

---

## 1. DailyGuidanceRepository (Domain Contract)

```dart
/// Domain contract for Daily Guidance content and delivery.
abstract class DailyGuidanceRepository {
  /// Returns all published and eligible items for the given [contentMode]
  /// and [locale].
  Future<List<DailyGuidanceItem>> getEligibleItems({
    required DailyGuidanceContentMode contentMode,
    required String locale,
  });

  /// Returns a single item by [id], or null if not found.
  Future<DailyGuidanceItem?> getItemById(String id);

  /// Refreshes the local content cache from the remote source (if available).
  /// Returns the number of items updated.
  Future<int> refreshContent();
}
```

---

## 2. DailyGuidancePreferencesRepository (Domain Contract)

```dart
/// Domain contract for user preference persistence.
abstract class DailyGuidancePreferencesRepository {
  /// Loads the current preferences.
  Future<DailyGuidancePreferences> getPreferences();

  /// Saves updated preferences.
  Future<void> savePreferences(DailyGuidancePreferences preferences);

  /// Clears all preferences (reset to defaults).
  Future<void> clearPreferences();
}
```

---

## 3. DailyDeliveryRecordRepository (Domain Contract)

```dart
/// Domain contract for delivery record persistence (anti-repetition + stability).
abstract class DailyDeliveryRecordRepository {
  /// Returns the delivery record for the given [localDate], or null.
  Future<DailyDeliveryRecord?> getRecordForDate(String localDate);

  /// Saves or updates a delivery record.
  Future<void> saveRecord(DailyDeliveryRecord record);

  /// Returns all item IDs delivered within the last [days] calendar days.
  Future<Set<String>> getRecentlyDeliveredItemIds({required int days});

  /// Returns all delivery records, ordered by date descending.
  Future<List<DailyDeliveryRecord>> getRecentRecords({int limit = 30});

  /// Prunes records older than [keepDays] calendar days.
  Future<void> pruneOldRecords({required int keepDays});
}
```

---

## 4. DailyGuidanceNotificationService (Domain Contract)

```dart
/// Domain contract for scheduling and cancelling local notifications.
abstract class DailyGuidanceNotificationService {
  /// Schedules the next Daily Guidance notification at the given [localTime]
  /// for the given [date]. Returns true if scheduling succeeded.
  Future<bool> scheduleNotification({
    required DateTime date,
    required TimeOfDay localTime,
    required DailyGuidanceItem item,
    required String locale,
  });

  /// Cancels all pending Daily Guidance notifications.
  Future<void> cancelAllPendingNotifications();

  /// Cancels a specific notification for the given [localDate].
  Future<void> cancelNotificationForDate(String localDate);
}
```

---

## 5. SelectDailyGuidanceItemUseCase (Domain Use Case)

```dart
/// Selects (or retrieves the already-committed) daily guidance item for
/// the given local date.
///
/// Selection contract:
/// 1. If a delivery record exists for today → return the committed item.
/// 2. Otherwise, select from eligible candidates using the policy:
///    - Filter by content mode, locale, date window, occasion.
///    - Exclude recently delivered IDs (90-day window).
///    - Apply deterministic selection.
///    - Persist the selection as committed.
/// 3. Returns null if no eligible content exists.
class SelectDailyGuidanceItemUseCase {
  Future<DailyGuidanceItem?> call({
    required String localDate,
    required DailyGuidancePreferences preferences,
  });
}
```

---

## 6. Notification Payload Contract

The notification payload is a JSON map with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `type` | `String` | Always `"daily_guidance"` |
| `itemId` | `String` | The committed item ID |
| `localDate` | `String` | ISO date `YYYY-MM-DD` |

Example:
```json
{
  "type": "daily_guidance",
  "itemId": "quran_039_053",
  "localDate": "2026-07-12"
}
```

---

## 7. Deep Link / Route Contract

| Route | Path | Parameters |
|-------|------|------------|
| `DailyGuidanceDetailRoute` | `/daily-guidance/:itemId` | `itemId: String`, optional `localDate: String` query param |
| `DailyGuidanceSettingsRoute` | `/settings/daily-guidance` | — |

Navigation from notification tap:
1. `DeepLinkResolver` maps `type: "daily_guidance"` → `DailyGuidanceDetailRoute(itemId: data['itemId'])`.
2. GoRouter navigates to the detail screen.
3. The detail screen loads the item from the repository by ID.

---

## 8. Analytics Event Contract

All events use the prefix `daily_guidance_` and include only the permitted properties defined in the spec (content item identifier, content type, locale, delivery status — never full religious text).

See [spec.md § Analytics Events](./spec.md#analytics-events) for the complete list.
