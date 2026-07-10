# Tasks: Learn Quran Home Entry Strategy (ADR-007)

## Batch 1: Cubit, State, and Preference Store
- [x] T001 Implement `HomeLearningPreferenceStore` abstraction.
- [x] T002 Implement `HomeLearningState` union.
- [x] T003 Implement `HomeLearningCubit` logic with session priority sorting.
- [x] T004 Define fallback logic when fetching sessions fails.
- [x] T005 Write unit tests for `HomeLearningCubit` and `HomeLearningPreferenceStore`.

## Batch 2: UI Cards and Widget Tests
- [x] T006 Implement `HomeLearningInterestCard` UI.
- [x] T007 Implement `HomeLearningNextSessionCard` UI.
- [x] T008 Implement `HomeLearningRevisionCard` UI.
- [x] T009 Write widget tests for each card state verifying correct labels, timers, and tap actions.

## Batch 3: Integration, Analytics, Localization, and Verification
- [x] T010 Add English and Arabic localization strings for the new cards in `apps/tilawa/lib/l10n/app_en.arb` and `app_ar.arb`.
- [x] T011 Run localization code-generation: `melos run gen:l10n`.
- [x] T012 Integrate `HomeLearningCubit` and the new cards into `HomeFeaturedTutorCardScope` inside `home_featured_tutor_card.dart`.
- [x] T013 Implement view and tap event analytics in `home_learn_quran_analytics.dart` with deduplication protection.
- [x] T014 Run full static analysis and unit tests: `melos run analyze` and targeted Flutter tests inside `apps/tilawa`.
- [x] T015 Verify `git diff --check HEAD` is clean and no admin, backend, rules, or payments code was touched.
