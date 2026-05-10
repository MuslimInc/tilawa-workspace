# Implementation Plan: Prayer Times Screen Stability and Refactor

**Branch**: `stable` | **Last Updated**: 2026-05-10 | **Spec**: [spec.md](spec.md)
**Status**: Implemented in codebase — visual QA/goldens pending

## Summary

The Prayer Times screen has been refactored toward a stable, polished Today-first
experience. The current code keeps BLoC/domain ownership intact while moving UI
decisions into feature-scoped presentation models, mappers, and widgets.

The screen now prioritizes the Next Prayer hero, contextual alert state chips,
compact location, readable prayer rows, and lightweight utility actions. Prayer
Settings are immediate-apply. Time Adjustments are intentionally frozen and
hidden until a later UX pass.

## Technical Context

**Language/Version**: Flutter 3.x / Dart 3.x
**Primary Dependencies**: `flutter_bloc`, `freezed_annotation`, `intl`, `tilawa_ui_kit`
**Architecture**: Feature-scoped Clean Architecture with BLoC state, domain
entities/use cases, presentation mappers/formatters, and UI Kit tokens.
**Targets**: Android and iOS UI, with Android-first notification scheduling.

## Current Codebase Architecture

### Entry Points

- `apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart`
  renders the Prayer Times Today and Monthly surfaces.
- `apps/tilawa/lib/screens/main_screen.dart` provides lazy shell BLoC instances
  and defers initial Prayer Times load until the Prayer Times tab is selected.
- `apps/tilawa/lib/router/app_router_config.dart` provides the standalone
  `/prayer-times` route with its own BLoC providers.

### State Management

- `PrayerTimesBloc` owns loading today/monthly prayer times, location, settings
  persistence, and notification scheduling triggers.
- `PrayerPermissionsCubit` owns notification/exact alarm/battery capability and
  permission request state.
- The 1-second countdown is UI-owned by `_CountdownTicker`; the BLoC does not
  emit every second.
- The Today list uses a low-frequency timer to refresh current/next row status.

### Presentation Models and Formatters

- `PrayerRowViewData` represents one Today row.
- `PrayerAlertViewData` represents row/hero alert chip state:
  - `Off`
  - `Notify only`
  - `Adhan`
- `PrayerRowViewDataMapper` maps domain prayer/settings state into row view
  data, including which prayers support alerts and which support Adhan.
- `PrayerTimeLabelFormatter` formats prayer times consistently for 12-hour and
  24-hour display using `intl`.
- `PrayerLocationLabelFormatter` formats geocoded addresses into compact,
  privacy-safe labels.

### Feature-Scoped Widgets

- `NextPrayerCountdownCard` renders the hero and alert chip.
- `PrayerAlertStatusChip` renders readable alert state chips using Tilawa UI Kit
  `TilawaStatusChip`.
- `_TodayPrayerListRow` renders compact tap targets for prayer rows.
- `_PrayerAlertQuickSheet` provides focused per-prayer alert controls.
- `_BottomUtilitiesCard` exposes Qibla and Manage Alerts in a single lightweight
  utility card.
- `PrayerSettingsSheet` is a capped-height modal body, not an internal
  `DraggableScrollableSheet`.

## Current UX Decisions

### Today Layout

1. App bar with settings.
2. Today/Monthly segmented control.
3. Compact location utility card.
4. Next Prayer hero.
5. Grouped Today schedule card.
6. Compact utility card with Qibla and Manage Alerts.

### Prayer Rows

- Rows remain compact inside one schedule card.
- `Column.spacing` uses `tokens.spaceExtraSmall` between rows so splash feedback
  has breathing room.
- Current/next row keeps a subtle `primaryContainer` background to connect it to
  the hero.
- Row tap opens a focused alert bottom sheet for supported rows.

### Alert Control Model

- Row chips are read-only indicators.
- Prayer rows open a focused bottom sheet rather than exposing inline toggles.
- Five prayers support `Off`, `Notify only`, and `Adhan`.
- Sunrise supports only `Off` and `Notify only`.
- If notification is disabled, Adhan is disabled/unavailable.
- Adhan is never available for Sunrise.

### Prayer Settings

- Settings apply immediately through `PrayerTimesBloc.updateSettings`.
- There is no Save button and no unsaved draft state.
- Header action is `Done`.
- Time Adjustments are hidden and intentionally frozen with a TODO.
- The 24-hour format setting applies consistently across hero, Today rows,
  Monthly table rows, and legacy prayer card widgets.

## Codebase Files

### Presentation

- `apps/tilawa/lib/features/prayer_times/presentation/screens/prayer_times_screen.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/models/prayer_row_view_data.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/mappers/prayer_row_view_data_mapper.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/formatters/prayer_time_label_formatter.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/next_prayer_countdown_card.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_alert_status_chip.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_notification_settings_sheet.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_settings_sheet.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/monthly_prayer_times_view.dart`
- `apps/tilawa/lib/features/prayer_times/presentation/widgets/prayer_time_card.dart`

### Domain / Scheduling

- `apps/tilawa/lib/features/prayer_times/domain/entities/prayer_settings_entity.dart`
- `apps/tilawa/lib/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case.dart`
- `apps/tilawa/lib/core/services/prayer_adhan_notification_service.dart`

### Localization

- `apps/tilawa/lib/l10n/app_en.arb`
- `apps/tilawa/lib/l10n/app_ar.arb`
- Generated localization files under `apps/tilawa/lib/l10n/generated/`

### Tests

- `apps/tilawa/test/features/prayer_times/presentation/mappers/prayer_row_view_data_mapper_test.dart`
- `apps/tilawa/test/features/prayer_times/presentation/widgets/prayer_notification_settings_sheet_test.dart`
- `apps/tilawa/test/features/prayer_times/presentation/widgets/prayer_settings_sheet_notification_test.dart`
- `apps/tilawa/test/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case_test.dart`
- `apps/tilawa/test/features/prayer_times/presentation/goldens/prayer_times_screen_golden_test.dart`

## Verification Run During Current Refactor

- `flutter analyze` on touched Prayer Times files: passed.
- `flutter test test/features/prayer_times/presentation/mappers/prayer_row_view_data_mapper_test.dart`: passed.
- `flutter test test/features/prayer_times/domain/usecases/ensure_prayer_notifications_scheduled_use_case_test.dart`: passed.
- `flutter test test/features/prayer_times/presentation/widgets/prayer_notification_settings_sheet_test.dart test/features/prayer_times/presentation/widgets/prayer_settings_sheet_notification_test.dart`: passed.

## Remaining Work

- Update Prayer Times golden baselines after visual approval.
- Manually QA English and Arabic layouts.
- Manually QA light and dark themes.
- Manually QA Sunrise row with Show Sunrise enabled:
  - Off chip visible by default.
  - Row sheet shows only Off and Notify only.
  - Manage Alerts shows Sunrise without an Adhan control.
  - Scheduling creates a standard notification only.
- Decide later whether Time Adjustments should return as an advanced settings
  sub-sheet.

## Risks

- Adding persisted `sunriseNotification` changes serialized settings shape.
  Generated JSON defaults keep old stored settings compatible.
- Golden tests will need baseline updates because hero, rows, chips, settings,
  and utility layout changed.
- Prayer notification scheduling now includes Sunrise when enabled; manual
  Android notification QA should include Sunrise.
