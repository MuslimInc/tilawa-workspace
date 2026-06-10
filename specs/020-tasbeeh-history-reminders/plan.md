# Implementation Plan: Tasbeeh History Grid, Clear All & Reminders

**Branch**: `020-tasbeeh-history-reminders` | **Date**: 2026-06-10
**Spec**: [`spec.md`](./spec.md)

## Summary

Extend the Tasbeeh home hub with a persisted **list/grid toggle**, a **clear all**
bulk delete with confirmation, and **per-dhikr daily local reminders** via a
dedicated notification service patterned after `AthkarNotificationService`. All
changes stay inside `apps/tilawa/lib/features/athkar/` plus `core/services/` and
router/deep-link glue.

Recommended delivery order: **US1 grid → US2 clear all → US3 reminders**
(increasing risk and platform surface).

## Technical Context

**Language/Version**: Flutter 3.x+, Dart 3.x+
**Primary Dependencies**: existing `TasbeehCubit`, Hive, `flutter_local_notifications`, `timezone`, `get_it`
**Storage**: Hive box `athkar_tasbeeh_dhikr` (schema bump for reminder fields); `SharedPreferences` for layout mode
**Testing**: `flutter test test/features/athkar/` + notification service unit tests
**Target Platform**: Android first (v1); iOS follow-up
**Constraints**: TilawaCard delete pattern; theme tokens; `Either<Failure, T>` at domain boundaries

## Constitution Check (preliminary)

| Gate | Status | Notes |
|------|--------|-------|
| Clean Architecture | PASS | New use cases + repository methods; no BuildContext in domain |
| BLoC / GoRouter | PASS | `TasbeehCubit` owns view mode + clear-all; router handles reminder deep link |
| UI Kit / tokens | PASS | Grid cells reuse `TilawaCard`; toggle uses `TilawaIconActionButton` or segmented control |
| RTL / responsive | PASS | Grid column count from `LayoutBuilder` / breakpoints |
| Testing | PASS | Cubit tests per story; widget test for grid toggle; fake notification service |
| Logging | PASS | Schedule/cancel failures logged via `AppLogger` |

## Project Structure

```text
apps/tilawa/lib/features/athkar/
├── domain/
│   ├── entities/tasbeeh_dhikr.dart              # + reminder fields
│   ├── repositories/tasbeeh_repository.dart       # + clearAll, watch helpers
│   ├── usecases/
│   │   ├── clear_all_saved_tasbeeh_use_case.dart
│   │   ├── set_tasbeeh_reminder_use_case.dart
│   │   └── get_tasbeeh_layout_preference_use_case.dart  # optional thin wrapper
│   └── services/tasbeeh_reminder_scheduler.dart   # interface
├── data/
│   ├── models/tasbeeh_dhikr_model.dart            # JSON migration
│   └── repositories/tasbeeh_repository_impl.dart
├── presentation/
│   ├── cubit/tasbeeh_cubit.dart                 # layout mode, clearAll, reminder draft
│   ├── widgets/tasbeeh/
│   │   ├── tasbeeh_home_view.dart                 # toggle + grid/list switch
│   │   ├── tasbeeh_saved_dhikr_grid.dart          # new
│   │   ├── tasbeeh_saved_dhikr_list.dart         # extract shared tile
│   │   └── tasbeeh_reminder_sheet.dart            # time picker + enable toggle
│   └── screens/tasbeeh_screen.dart                # app bar actions
apps/tilawa/lib/core/services/
└── tasbeeh_reminder_notification_service.dart     # zonedSchedule, cancel, ensure
apps/tilawa/lib/router/
├── app_router_config.dart                         # query param dhikrId
└── deep_link_resolver.dart                        # payload prefix tasbeeh:
```

## Phase Breakdown

### Phase A — Grid view (US1)

1. Add `TasbeehLayoutMode` enum + prefs datasource.
2. `TasbeehCubit.toggleLayoutMode()` / load preference on `loadSavedDhikr`.
3. `TasbeehSavedDhikrGrid` — 2/3 columns, shared tile content widget.
4. App bar: `Icons.grid_view` / `Icons.view_list` toggle.
5. Widget tests: toggle persists; grid tap opens counting.

### Phase B — Clear all (US2)

1. `TasbeehRepository.deleteAllDhikr()` + use case.
2. Cubit `clearAllSavedDhikr()` → home, clear `activeSavedDhikrId`.
3. App bar overflow → confirm dialog (reuse delete dialog patterns).
4. Cubit + repository tests.

### Phase C — Reminders (US3)

1. Extend Hive model (default `reminderEnabled: false`).
2. `ITasbeehReminderScheduler` + `TasbeehReminderNotificationService`.
3. Register channel + dispatcher IDs; startup `ensure` in `NotificationStartupService`.
4. `setTasbeehReminder` use case: persist + schedule/cancel.
5. UI: reminder bottom sheet on counting screen; optional bell on tiles (OQ-004).
6. Deep link: `tasbeeh:dhikr:{id}` → `TasbeehRoute` with extra/state.
7. Permission gate UI (mirror prayer notification permission copy patterns).
8. Unit tests: ID mapping, cancel on delete, clear-all cancels all.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Notification ID collision | Dedicated ID block; unit test collision matrix |
| Hive migration breaks existing users | Default reminder fields in `fromJson` |
| Grid + delete hit-testing | Long-press for delete in grid; keep list strip pattern |
| Battery / exact alarm policy | Use inexact daily schedule unless plan adopts `SCHEDULE_EXACT_ALARM` waiver |

## Next Spec Kit Steps

1. Run `/speckit.plan` to generate `research.md`, `data-model.md`, `contracts/`.
2. Run `/speckit.tasks` to produce dependency-ordered `tasks.md`.
3. Run `/speckit.analyze` for cross-artifact consistency.
