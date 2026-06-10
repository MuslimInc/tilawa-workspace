# Data Model: Tasbeeh History Grid, Clear All & Reminders

**Spec**: [`spec.md`](./spec.md) | **Phase**: 1 (plan artifact)

## Existing

### `TasbeehDhikr` (Hive: `athkar_tasbeeh_dhikr`)

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID / stable key |
| `text` | `String` | Display + notification title |
| `count` | `int` | Current count |
| `targetCount` | `int` | Goal |
| `targetReachedNotified` | `bool` | Feedback flag |
| `createdAt` | `DateTime` | |
| `updatedAt` | `DateTime` | Sort key for home list |

## Extensions (v1)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `reminderEnabled` | `bool` | `false` | |
| `reminderHour` | `int` | `null` | 0–23 local; null when disabled |
| `reminderMinute` | `int` | `null` | 0–59 |

**Migration**: `TasbeehDhikrModel.fromJson` treats missing keys as disabled / null times.

## Presentation-only

### `TasbeehLayoutMode`

```text
enum TasbeehLayoutMode { list, grid }
```

**Persistence**: `SharedPreferences` key `tasbeeh_saved_layout_mode` → string enum name.

## Notification mapping

| Concept | Value |
|---------|-------|
| Channel ID | `com.tilawa.app.tasbeeh_reminders` |
| Channel name (l10n) | Tasbeeh reminders |
| Notification ID | `13000000 + (dhikrId.hashCode.abs() % 100000)` |
| Payload | `tasbeeh:dhikr:{id}` |

**Collision check**: Prayer IDs &lt; 10000; athkar morning/evening 1001–1002 + dynamic bases 11M/12M; tasbeeh block 13M–13.1M — no overlap.

## Use cases (new)

| Use case | Input | Output |
|----------|-------|--------|
| `ClearAllSavedTasbeehUseCase` | — | `Either<Failure, void>` |
| `SetTasbeehReminderUseCase` | dhikrId, enabled, TimeOfDay? | `Either<Failure, TasbeehDhikr>` |
| `GetTasbeehLayoutModeUseCase` | — | `TasbeehLayoutMode` (optional) |

## Repository additions

```text
TasbeehRepository
  + Future<Result<void>> deleteAllDhikr()
  + Future<Result<TasbeehDhikr>> setReminder({dhikrId, enabled, hour?, minute?})
```
