# Tasks: Tasbeeh History Grid, Clear All & Reminders

**Input**: [`spec.md`](./spec.md), [`plan.md`](./plan.md)
**Prerequisites**: Spec approved; branch `020-tasbeeh-history-reminders`

**Organization**: Phased by user story (US1 → US2 → US3). Each phase is independently testable.

---

## Phase 1: Setup

- [ ] T001 Create feature branch `020-tasbeeh-history-reminders`
- [ ] T002 [P] Add ARB keys scaffold in `apps/tilawa/lib/l10n/app_en.arb` and `app_ar.arb` (grid toggle, clear all, reminder strings)
- [ ] T003 [P] Document notification ID block in `specs/020-tasbeeh-history-reminders/data-model.md` (create during plan)

---

## Phase 2: User Story 1 — Grid view (P1)

**Goal**: Persisted list/grid toggle on Tasbeeh home hub.

- [ ] T010 [US1] Add `TasbeehLayoutMode` enum + `TasbeehLayoutPreferenceLocalDataSource` under `apps/tilawa/lib/features/athkar/data/datasources/`
- [ ] T011 [US1] Extend `TasbeehCubit` / `TasbeehState` with `layoutMode`; load/save preference in `loadSavedDhikr` / `toggleLayoutMode`
- [ ] T012 [US1] Extract shared `_TasbeehSavedDhikrTileContent` from `tasbeeh_saved_dhikr_list.dart`
- [ ] T013 [US1] Create `tasbeeh_saved_dhikr_grid.dart` with responsive column count
- [ ] T014 [US1] Update `tasbeeh_home_view.dart` to switch list vs grid; add app bar toggle in `tasbeeh_screen.dart`
- [ ] T015 [US1] Widget test: `test/features/athkar/presentation/screens/tasbeeh_grid_view_test.dart`
- [ ] T016 [US1] Cubit test: layout preference round-trip in `tasbeeh_cubit_test.dart`

**Checkpoint**: Grid/list toggle works; preference survives restart; tap opens counting.

---

## Phase 3: User Story 2 — Clear all (P2)

**Goal**: Bulk delete all saved dhikr with confirmation.

- [ ] T020 [US2] Add `deleteAllDhikr()` to `TasbeehRepository` + `TasbeehRepositoryImpl`
- [ ] T021 [US2] Add `ClearAllSavedTasbeehUseCase` in `domain/usecases/`
- [ ] T022 [US2] Add `clearAllSavedDhikr()` to `TasbeehCubit` (emit home, clear selection)
- [ ] T023 [US2] Add overflow menu + `TasbeehClearAllConfirmationDialog` in presentation
- [ ] T024 [US2] Repository test: `tasbeeh_repository_impl_test.dart` — delete all
- [ ] T025 [US2] Cubit test: clear all empties state

**Checkpoint**: Clear all with cancel/confirm; empty state shown; hidden when count = 0.

---

## Phase 4: User Story 3 — Daily reminders (P3)

**Goal**: Per-dhikr daily local notification with deep link.

- [ ] T030 [US3] Extend `TasbeehDhikr` entity + `TasbeehDhikrModel` with reminder fields; migration defaults in `fromJson`
- [ ] T031 [US3] Add `SetTasbeehReminderUseCase` + repository `updateReminder(...)`
- [ ] T032 [US3] Create `TasbeehReminderNotificationService` in `apps/tilawa/lib/core/services/`
- [ ] T033 [US3] Register channel, notification IDs, startup `ensure` in `notification_startup_service.dart`
- [ ] T034 [US3] Extend `DeepLinkResolver` + `TasbeehRoute` for `dhikrId` query/extra
- [ ] T035 [US3] Build `tasbeeh_reminder_sheet.dart` (enable toggle + `TimePicker`)
- [ ] T036 [US3] Wire reminder actions on `TasbeehSavedDhikrCountingView` app bar / overflow
- [ ] T037 [US3] Cancel reminders on `removeDhikr` and `clearAllSavedDhikr` in cubit
- [ ] T038 [US3] Permission-denied UX (settings deep link)
- [ ] T039 [P] [US3] Unit tests: `test/core/services/tasbeeh_reminder_notification_service_test.dart`
- [ ] T040 [US3] Cubit tests: set reminder persists + schedules (fake scheduler)

**Checkpoint**: QA on Android device — notification fires, tap opens correct dhikr.

---

## Phase 5: Polish & release

- [ ] T050 [P] `dart analyze` + `flutter test test/features/athkar/`
- [ ] T051 Update `specs/002-product-growth-roadmap/spec.md` athkar gap line (tasbeeh reminders)
- [ ] T052 Manual QA checklist in `specs/020-tasbeeh-history-reminders/checklists/requirements.md`
- [ ] T053 Screenshot refresh for Play Console athkar/tasbeeh if marketing needs grid shot

---

## Dependencies

```text
Phase 1 → Phase 2 (US1) → Phase 3 (US2) → Phase 4 (US3) → Phase 5
US2 may start after US1 cubit patterns land (no hard dep on grid)
US3 depends on US2 for clear-all cancel-all-notifications behavior
```

## Parallel Opportunities

- T002 l10n can run parallel to T010–T014
- T039 notification service tests parallel to T035 UI once interface (T032) is defined
