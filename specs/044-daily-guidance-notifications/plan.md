# Implementation Plan: Daily Ayah & Hadith Notifications

**Branch**: `044-daily-guidance-notifications` | **Date**: 2026-07-12 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/044-daily-guidance-notifications/spec.md`

## Summary

MeMuslim will add an optional daily notification (Daily Guidance / رسالة اليوم) delivering one curated Quran verse or authentic hadith. The implementation uses local notifications (`flutter_local_notifications`), Hive for content storage and delivery records, `SharedPreferencesAsync` for preferences, BLoC for state management, and GoRouter for notification deep linking — all matching existing project patterns.

## Technical Context

**Language/Version**: Dart 3.x / Flutter (stable channel)

**Primary Dependencies**: `flutter_local_notifications` (existing), `flutter_bloc` (existing), `hive_ce` (existing), `go_router` (existing), `get_it` + `injectable` (existing), `json_annotation` + `json_serializable` (existing), `shared_preferences` (existing), `timezone` (existing)

**Storage**: Hive (local content + delivery records), SharedPreferencesAsync (preferences), bundled JSON assets (content seed)

**Testing**: `flutter_test` (unit + widget), `package:checks`, `mocktail`

**Target Platform**: Android 8+ / iOS 14+

**Project Type**: Mobile app (Flutter)

**Performance Goals**: Cached item opens < 100ms, no startup blocking, no unnecessary network calls

**Constraints**: Offline-capable, no continuous background execution, single notification per local date

**Scale/Scope**: ~120 seed items, 4 new screens (detail, settings, history, home card), 1 new feature module

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Architecture Boundaries | ✅ | Feature-first with domain/data/presentation separation |
| II. Reactive State Management & Routing | ✅ | BLoC (Cubit) for state, GoRouter for deep linking |
| III. Atomic Design & Tilawa UI Kit | ✅ | Will use existing UI Kit components, tokens, l10n |
| IV. Performance-First Delivery | ✅ | No build method I/O, cached access, no startup blocking |
| V. Structured Observability | ✅ | Structured logging, privacy-safe analytics events |
| VI. Safe Refactoring & Delivery | ✅ | Additive feature, minimal cross-feature impact |
| Development Quality Standards | ✅ | SOLID, naming conventions, injectable DI, modern Dart idioms |
| Testing Discipline | ✅ | Unit tests for domain, widget tests for UI, deterministic |

## Project Structure

### Documentation (this feature)

```text
specs/044-daily-guidance-notifications/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── contracts.md
└── tasks.md             # Phase 2 output (via /speckit-tasks)
```

### Source Code

```text
apps/tilawa/lib/features/daily_guidance/
├── data/
│   ├── datasources/
│   │   ├── daily_guidance_local_data_source.dart      # Hive access
│   │   └── daily_guidance_seed_data_source.dart       # Asset JSON loader
│   ├── models/
│   │   ├── daily_guidance_item_model.dart             # JSON serializable
│   │   ├── quran_source_metadata_model.dart
│   │   ├── hadith_source_metadata_model.dart
│   │   ├── content_review_metadata_model.dart
│   │   └── daily_delivery_record_model.dart
│   └── repositories/
│       ├── daily_guidance_repository_impl.dart
│       ├── daily_guidance_preferences_repository_impl.dart
│       └── daily_delivery_record_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── daily_guidance_item.dart
│   │   ├── daily_guidance_preferences.dart
│   │   ├── daily_delivery_record.dart
│   │   └── daily_guidance_enums.dart
│   ├── repositories/
│   │   ├── daily_guidance_repository.dart
│   │   ├── daily_guidance_preferences_repository.dart
│   │   └── daily_delivery_record_repository.dart
│   └── usecases/
│       ├── select_daily_guidance_item_use_case.dart
│       ├── get_today_guidance_use_case.dart
│       ├── schedule_daily_guidance_use_case.dart
│       └── toggle_daily_guidance_use_case.dart
├── di/
│   └── daily_guidance_module.dart                     # get_it registration
├── presentation/
│   ├── bloc/
│   │   ├── daily_guidance_cubit.dart
│   │   ├── daily_guidance_state.dart
│   │   ├── daily_guidance_settings_cubit.dart
│   │   └── daily_guidance_settings_state.dart
│   ├── screens/
│   │   ├── daily_guidance_detail_screen.dart
│   │   ├── daily_guidance_settings_screen.dart
│   │   └── daily_guidance_history_screen.dart
│   └── widgets/
│       ├── daily_guidance_home_card.dart
│       ├── daily_guidance_source_info.dart
│       ├── daily_guidance_actions_bar.dart
│       └── daily_guidance_content_display.dart
└── daily_guidance.dart                                # Barrel file

apps/tilawa/lib/core/services/
└── daily_guidance_notification_service.dart            # Local notification scheduling

apps/tilawa/assets/
└── daily_guidance_seed.json                           # Bundled content seed

apps/tilawa/lib/l10n/
├── app_ar.arb                                         # Arabic strings (additions)
└── app_en.arb                                         # English strings (additions)

apps/tilawa/test/features/daily_guidance/
├── domain/
│   ├── usecases/
│   │   ├── select_daily_guidance_item_use_case_test.dart
│   │   └── get_today_guidance_use_case_test.dart
│   └── entities/
├── data/
│   ├── repositories/
│   └── datasources/
└── presentation/
    ├── bloc/
    └── widgets/
```

### Modified Existing Files

- `apps/tilawa/lib/router/app_router_config.dart` — Add `DailyGuidanceDetailRoute`, `DailyGuidanceSettingsRoute`
- `apps/tilawa/lib/router/deep_link_resolver.dart` — Add `daily_guidance` case to `resolveLocation` switch + `notificationDataFromPayload`
- `apps/tilawa/lib/core/di/injection.dart` — Register `DailyGuidanceModule`
- `apps/tilawa/lib/features/home/presentation/widgets/` — Add or integrate `DailyGuidanceHomeCard`
- `apps/tilawa/lib/features/settings/presentation/` — Add Daily Guidance entry in notification settings
- `apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart` — Register Hive boxes, restore scheduled notifications
- `apps/tilawa/lib/l10n/app_ar.arb` — Add Arabic strings
- `apps/tilawa/lib/l10n/app_en.arb` — Add English strings
- `apps/tilawa/pubspec.yaml` — Add seed asset path

## Implementation Phases

### Integrity correction (implemented)

Use one Data-layer validator/mapper as the only aggregate DTO-to-Domain path.
The active UI locale flows into selection, and both list and ID repository reads
carry explicit locale and capability. Parsing
fails atomically with a typed failure, while integrity-invalid records are
excluded without mutating lifecycle state. Presentation renders only the
locale-filtered maps returned by the repository.

### Phase 1: Domain Layer + Data Models (Foundation)

Build the domain entities, enums, repository contracts, and use cases. Create the data models with JSON serialization. No UI, no notifications — purely the business logic backbone.

**Files**: All `domain/` files, all `data/models/` files, `daily_guidance_enums.dart`

### Phase 2: Data Layer + Content Seed (Storage)

Implement repository implementations backed by Hive and SharedPreferencesAsync. Create the asset seed JSON file with ~120 curated items. Implement the seed loader. Register Hive boxes.

**Files**: All `data/datasources/` and `data/repositories/` files, `daily_guidance_seed.json`, DI module, Hive box registration

### Phase 3: Notification Scheduling + Deep Linking (Delivery)

Implement `DailyGuidanceNotificationService` for local notification scheduling. Extend `DeepLinkResolver` with `daily_guidance` type. Add GoRouter routes. Register notification channel.

**Files**: `daily_guidance_notification_service.dart`, router modifications, deep link resolver modifications

### Phase 4: Presentation Layer — Screens + BLoC (UI)

Build the detail screen, settings screen, and history screen. Create the Cubits. Implement the Home card integration. Add all l10n strings.

**Files**: All `presentation/` files, l10n additions, home card integration

### Phase 5: Testing + Polish (Quality)

Write unit tests for use cases and repositories. Write widget tests for screens. Run `melos run fix:format`, `melos run analyze`, targeted `flutter test`. Verify RTL/LTR, accessibility, text scaling.

**Files**: All `test/` files, any fixes from analysis

## Complexity Tracking

No constitution violations. The feature is additive with no cross-feature breaking changes.
