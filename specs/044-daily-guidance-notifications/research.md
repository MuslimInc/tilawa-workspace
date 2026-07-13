# Research: Daily Guidance Notifications

**Branch**: `042-daily-guidance-notifications` | **Date**: 2026-07-12

## 1. Local Notification Scheduling — flutter_local_notifications

### Decision
Use `flutter_local_notifications` (already in the project) for scheduling daily local notifications. The existing `AthkarNotificationService` and `TasbeehReminderNotificationService` provide the established pattern.

### Rationale
- The app already uses `flutter_local_notifications` for Athkar morning/evening and Tasbeeh reminders with the same scheduling semantics (daily, user-selected time, local timezone).
- The `NotificationDispatcher` already handles cold-start routing from local notification payloads.
- Creating a dedicated Android notification channel for "Daily Guidance" / "نفحة اليوم" follows the same pattern as existing prayer/athkar channels.

### Alternatives Considered
- **Firebase Cloud Messaging (FCM)**: Rejected for MVP — daily guidance is local content, no server push needed. FCM adds server dependency, latency, and unreliability for time-sensitive daily delivery.
- **WorkManager / Background Fetch**: Overkill — `flutter_local_notifications` `zonedSchedule` handles the use case directly.

---

## 2. Content Storage — Firestore + Local JSON Seed

### Decision
- **MVP**: Ship a bundled JSON seed file in assets with ~120 curated items (60 Quran + 60 Hadith). Load into a Hive box on first run.
- **Future**: Firestore collection `dailyGuidanceItems` for remote content updates, editorial administration, and content refresh.

### Rationale
- Bundled content ensures offline-first delivery on day 1 (no network dependency for core feature).
- Hive is already used for local persistence in the project (athkar, preferences, bookmarks).
- Firestore path is consistent with existing admin patterns (Angular admin app + Firestore collections).
- The 90-day anti-repetition window with ~120 items gives comfortable margin.

### Alternatives Considered
- **SQLite/Drift**: More complex for the simple key-value + list pattern. Hive is already in the project.
- **Pure Firestore**: Requires network for first delivery — violates offline requirement.

---

## 3. User Preferences Storage — SharedPreferencesAsync

### Decision
Store `DailyGuidancePreferences` using `SharedPreferencesAsync` (already the project standard via `tilawaSharedPreferencesOptions`).

### Rationale
- Simple key-value preferences (enabled, time, days, content mode).
- Consistent with how settings, prayer notification configs, and feature flags are stored.
- No account required — preferences are device-local per MVP scope.

---

## 4. State Management — BLoC

### Decision
Create `DailyGuidanceCubit` for the feature's presentation state.

### Rationale
- Constitution mandates BLoC for feature state management.
- Other notification features (athkar, prayer) use Cubit pattern.
- States: loading → loaded (with today's item) → error / empty / offline.

---

## 5. Deep Link / Notification Tap Resolution

### Decision
Extend `DeepLinkResolver` with a `daily_guidance` type case, and add a `DailyGuidanceRoute` to `app_router_config.dart`.

### Rationale
- The `DeepLinkResolver.resolveLocation` switch already handles `reciter`, `athkar`, `quran`, `tasbeeh`, etc.
- Adding `daily_guidance` follows the exact same pattern.
- The notification payload will be a simple JSON `{"type": "daily_guidance", "itemId": "<id>", "localDate": "2026-07-12"}`.

---

## 6. Anti-Repetition Strategy

### Decision
Maintain a Hive-persisted list of recently delivered item IDs with their delivery dates. On selection, exclude IDs in the list. When corpus is exhausted, reuse the oldest.

### Rationale
- Simple, efficient, no server dependency.
- 90 entries × ~50 bytes = negligible storage.
- Deterministic: same local date always maps to the same item after commitment.

---

## 7. Content Selection Determinism

### Decision
Use a seeded PRNG (seed = `userId_hash XOR localDate.hashCode`) to deterministically select from eligible candidates, then persist the selection for the day.

### Rationale
- Reopening the app, restarting, or re-running scheduling always produces the same item for the same day.
- Persistence in Hive as `DailyDeliveryRecord` provides a stable cache for the committed daily item.

---

## 8. Notification Channel

### Decision
Register a dedicated Android notification channel:
- Channel ID: `daily_guidance`
- Arabic name: `نفحة اليوم`
- English name: `Daily Guidance`
- Importance: Default (not high/urgent)

### Rationale
- Spec requires separation from prayer, athkar, and other channels.
- Default importance avoids alarm-style interruption.

---

## 9. Feature Architecture Layers

### Decision
Follow the existing feature-based Clean Architecture:
```
features/daily_guidance/
├── data/
│   ├── datasources/     # Hive local, asset seed loader, (future: Firestore)
│   ├── models/           # Data models with JSON serialization
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # DailyGuidanceItem, Preferences, DeliveryRecord
│   ├── repositories/     # Abstract contracts
│   └── usecases/         # SelectDailyItem, GetTodayGuidance, etc.
└── presentation/
    ├── bloc/             # DailyGuidanceCubit + states
    ├── screens/          # Detail screen, settings screen
    └── widgets/          # Home card, notification template
```

### Rationale
- Matches every other feature's structure in the project.
- Satisfies Clean Architecture constitution principle.
- Domain entities have no Flutter/data dependency.
