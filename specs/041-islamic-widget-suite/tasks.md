---
description: "Implementation tasks for the Islamic home-screen widget suite"
---

# Tasks: Islamic Home Screen Widget Suite (v1)

**Input**: Design documents from `specs/041-islamic-widget-suite/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/widget-bridge.md, quickstart.md

**Tests**: Required by the constitution for domain rules, native lifecycle logic, responsive/RTL presentation, routing, offline behavior, and QCF rendering.

## Phase 1: Existing P1 Baseline

**Purpose**: Record the prayer-widget increment already shipped before this task list.

- [x] T001 [US1] Implement prayer snapshot model/store in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/prayer/widget/`
- [x] T002 [US1] Implement prayer provider, countdown, boundary refresh, and deep link in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/prayer/widget/PrayerTimesWidgetProvider.kt`
- [x] T003 [US1] Add Arabic/English resources and compact prayer layout in `apps/tilawa/android/app/src/main/res/`
- [x] T004 [US1] Add native prayer widget contract tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/prayer/widget/`

## Phase 1.5: P1 Gap Fill (Prayer Widget Requirements)

**Purpose**: Fulfill missing functional requirements for the Prayer Widget (US1).

- [x] T004a [US1] Add expanded size layout and responsive scaling for Prayer widget to meet FR-009 in `apps/tilawa/android/app/src/main/res/`
- [x] T004b [US1] Add non-color visual distinction (e.g. icon/weight) for the next prayer to meet FR-017 in `PrayerTimesWidgetProvider.kt`
- [x] T004c [US1] Implement non-blank first-use setup state (location needed) and setup action deep link to meet FR-022 in `PrayerTimesWidgetProvider.kt`

## Phase 2: Shared Foundation

**Purpose**: Reusable contracts needed by the remaining widget types.

- [x] T005 [US1-5] Define privacy-safe versioned widget envelope and action models in `apps/tilawa/lib/features/islamic_widgets/domain/entities/widget_snapshot_envelope.dart`
- [x] T006 [US1-5] Add native envelope parser and atomic snapshot store tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/widget/WidgetSnapshotStoreTest.kt`
- [x] T007 [US1-5] Implement native envelope parser and atomic last-valid snapshot store in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/widget/WidgetSnapshotStore.kt`
- [x] T008 [US1-5] Implement Flutter-to-native snapshot bridge on the existing channel boundary in `apps/tilawa/lib/features/islamic_widgets/data/widget_snapshot_bridge.dart` and `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/prayer/MethodChannelLogic.kt`
- [x] T009 [US1-5] Add widget analytics names and privacy-safe parameters in `packages/core/lib/constants/analytics_constants.dart` and `apps/tilawa/lib/features/islamic_widgets/data/widget_analytics.dart`
- [x] T010 Add typed widget destination resolution in `apps/tilawa/lib/router/app_router_config.dart` with tests in `apps/tilawa/test/router/widget_deep_link_test.dart`

**Checkpoint**: New providers can persist display-ready snapshots, render a non-blank fallback, emit safe analytics, and deep-link without duplicating domain rules.

## Phase 3: User Story 2 - Ayah of the Day (Priority: P2)

**Goal**: Display one curated daily Ayah in authentic QCF script, offline, with stable daily selection and exact Mushaf navigation.

**Independent Test**: Place the widget, verify QCF glyph fidelity and resize behavior, advance the controlled local date offline, reboot, and tap through to the selected Mushaf page.

- [x] T011 [P] [US2] Add deterministic no-repeat daily selection tests in `apps/tilawa/test/features/islamic_widgets/domain/daily_ayah_selector_test.dart`
- [x] T012 [US2] Implement curated Ayah entry and deterministic selector in `apps/tilawa/lib/features/islamic_widgets/domain/entities/curated_ayah.dart` and `apps/tilawa/lib/features/islamic_widgets/domain/services/daily_ayah_selector.dart`
- [x] T013 [P] [US2] Add curated launch pool fixture and validation test in `apps/tilawa/assets/data/widget_daily_ayahs.json` and `apps/tilawa/test/features/islamic_widgets/data/curated_ayah_catalog_test.dart`
- [x] T014 [P] [US2] Add bounded QCF artifact renderer tests in `packages/quran_qcf/test/widget_ayah_artifact_renderer_test.dart`
- [x] T015 [US2] Implement bounded QCF artifact rendering and atomic PNG output in `packages/quran_qcf/lib/src/presentation/services/widget_ayah_artifact_renderer.dart`
- [ ] T016 [US2] Implement daily selection persistence and snapshot composition in `apps/tilawa/lib/features/islamic_widgets/data/daily_ayah_widget_repository.dart`
- [ ] T017 [P] [US2] Add native Ayah snapshot parsing/state tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/widget/ayah/AyahWidgetLogicTest.kt`
- [ ] T018 [US2] Implement native Ayah snapshot, store, and state resolution in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/widget/ayah/`
- [ ] T019 [US2] Add compact/expanded Ayah widget layouts, resources, and picker previews in `apps/tilawa/android/app/src/main/res/`
- [ ] T020 [US2] Implement Ayah provider lifecycle, resize handling, fallback, midnight refresh, and Mushaf deep link in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/widget/ayah/AyahOfDayWidgetProvider.kt`
- [ ] T021 [US2] Register the Ayah provider and metadata in `apps/tilawa/android/app/src/main/AndroidManifest.xml` and `apps/tilawa/android/app/src/main/res/xml/ayah_of_day_widget_info.xml`
- [ ] T022 [US2] Wire Ayah snapshot refresh at startup/date/locale changes in `apps/tilawa/lib/features/islamic_widgets/app/ayah_widget_sync_service.dart`
- [ ] T023 [US2] Add Ayah provider Robolectric lifecycle/deep-link tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/widget/ayah/AyahOfDayWidgetProviderTest.kt`

**Checkpoint**: The Ayah widget works offline, remains stable for a local day, survives restart, resizes without clipping, and opens the exact Mushaf page.

## Phase 4: User Story 3 - Morning/Evening Athkar (Priority: P3)

**Goal**: Show the applicable Athkar set, advance per widget instance, persist progress, and open the matching in-app flow.

**Independent Test**: Control time across morning/evening windows, advance two instances independently, restart the launcher, and tap through to the matching category.

- [ ] T024 [P] [US3] Add Athkar period/progress domain tests in `apps/tilawa/test/features/islamic_widgets/domain/athkar_widget_period_test.dart`
- [ ] T025 [US3] Implement applicable-period and reset rules in `apps/tilawa/lib/features/islamic_widgets/domain/services/athkar_widget_period_resolver.dart`
- [ ] T026 [US3] Compose localized display snapshots from existing Athkar repositories in `apps/tilawa/lib/features/islamic_widgets/data/athkar_widget_repository.dart`
- [ ] T027 [P] [US3] Add native per-instance progress tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/widget/athkar/AthkarWidgetLogicTest.kt`
- [ ] T028 [US3] Implement Athkar provider, store, advance action, period reset, and deep link in `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/widget/athkar/`
- [ ] T029 [US3] Add Athkar layouts, localized resources, metadata, and manifest registration in `apps/tilawa/android/app/src/main/res/` and `apps/tilawa/android/app/src/main/AndroidManifest.xml`

## Phase 5: User Story 4 - Hijri Date (Priority: P4)

**Goal**: Display adjusted Hijri and Gregorian dates consistently across app and widget with local-midnight rollover.

**Independent Test**: Apply every offset from −2 to +2, cross midnight/timezone boundaries, restart, and compare widget with the in-app date.

- [ ] T030 [P] [US4] Add shared adjustment and rollover tests in `apps/tilawa/test/features/islamic_widgets/domain/hijri_adjustment_test.dart`
- [ ] T031 [US4] Implement app-wide Hijri adjustment repository/use case in `apps/tilawa/lib/features/islamic_widgets/domain/` and `apps/tilawa/lib/features/islamic_widgets/data/`
- [ ] T032 [US4] Update existing in-app Hijri surfaces to consume the shared use case in `apps/tilawa/lib/features/`
- [ ] T033 [P] [US4] Add native Hijri snapshot/rollover tests in `apps/tilawa/android/app/src/test/kotlin/com/tilawa/app/widget/hijri/HijriWidgetLogicTest.kt`
- [ ] T034 [US4] Implement Hijri provider, midnight refresh, layouts, metadata, localization, and manifest registration in `apps/tilawa/android/app/src/main/`

## Phase 6: User Story 5 - Shareable QCF Ayah Cards (Priority: P5)

**Goal**: Preview and share one-to-five consecutive Ayat in QCF script on three curated backgrounds with attribution and bounded cleanup.

**Independent Test**: Generate minimum/maximum valid cards, reject invalid selections, share externally, cancel, and verify artifacts are cleaned up.

- [ ] T035 [P] [US5] Add range-validation and draft-state tests in `apps/tilawa/test/features/share/domain/share_card_draft_test.dart`
- [ ] T036 [US5] Implement share-card range validation and draft entity in `apps/tilawa/lib/features/share/domain/`
- [ ] T037 [P] [US5] Add QCF card renderer fidelity/bounds tests in `packages/quran_qcf/test/share_card_renderer_test.dart`
- [ ] T038 [US5] Implement three-style QCF card renderer with required attribution in `packages/quran_qcf/lib/src/presentation/services/share_card_renderer.dart`
- [ ] T039 [US5] Add preview/cancel/share Cubit flow and temporary cleanup in `apps/tilawa/lib/features/share/presentation/`
- [ ] T040 [US5] Add localized responsive share-card preview UI using Tilawa tokens in `apps/tilawa/lib/features/share/presentation/widgets/`
- [ ] T041 [US5] Integrate share-as-card entry from Ayah options and widget detail routes in `apps/tilawa/lib/features/quran_reader/` and `apps/tilawa/lib/router/app_router_config.dart`

## Phase 7: Polish and Release Gates

- [ ] T042 [P] Add Arabic/English widget accessibility and 200% text-scale coverage in `apps/tilawa/android/app/src/test/` and `apps/tilawa/test/features/islamic_widgets/`
- [ ] T043 [P] Add QCF curated-pool visual corpus harness in `packages/quran_qcf/integration_test/widget_ayah_corpus_test.dart`
- [ ] T044 Bound artifact cache and verify active-reference-safe eviction in `apps/tilawa/lib/features/islamic_widgets/data/widget_artifact_store.dart`
- [ ] T045 Add widget performance/refresh structured diagnostics in `apps/tilawa/lib/features/islamic_widgets/` and `apps/tilawa/android/app/src/main/kotlin/com/tilawa/app/widget/`
- [ ] T046 Run all automated commands and record results in `specs/041-islamic-widget-suite/quickstart.md`
- [ ] T047 Execute Xiaomi/Redmi, Samsung, API 24, and target-API manual matrix from `specs/041-islamic-widget-suite/quickstart.md`

## Dependencies & Execution Order

- T001–T004 are complete and establish the P1 reference implementation.
- T005–T010 form the shared foundation and precede native integration for US2–US4.
- US2 domain work T011–T016 can begin immediately while the shared native foundation is completed; T017–T023 depend on T005–T010 and the generated artifact contract.
- US3 and US4 depend only on the shared foundation and may proceed after it independently of US2.
- US5 reuses QCF artifact concepts from US2; begin T035–T036 independently, but T037–T041 follow the finalized QCF renderer contract.
- T042–T047 follow completion of all stories selected for release.

## Parallel Opportunities

- T006 and T009 can proceed in parallel with Flutter envelope modeling.
- Within US2, T011, T013, T014, and T017 touch independent domain/catalog/renderer/native test surfaces.
- US3 and US4 can proceed in parallel after the shared foundation.
- T035 and T037 can proceed in parallel once the QCF artifact contract is stable.

## Implementation Strategy

1. Preserve the shipped P1 increment and use it as the native lifecycle reference.
2. Complete the smallest shared contract required by the next provider.
3. Deliver US2 as the next acquisition-focused increment and validate it independently.
4. Add US3, US4, and US5 sequentially by priority, keeping each independently testable.
5. Run cross-cutting accessibility, privacy, performance, and OEM lifecycle gates before release.
