# Al-Khatmah release UX tasks

Tasks ordered by canonical user journey. Status verified 2026-07-13.

## Foundation

- [x] T001 One nullable contiguous user-confirmed page boundary.
- [x] T002 No navigation-driven Khatmah mutations in Quran reader.
- [x] T003 Frozen local-day assignment in v2 plan.
- [x] T004 Reader opens at assignment start / first unconfirmed page.
- [x] T005 Idempotent bounded progress confirmation.
- [x] T006 Derived daily/full completion including final target page.
- [x] T007 Today Plan and Android widget default-off.
- [x] T008 Hide ineffective catch-up; retain extension.
- [x] T009 One contextual Home card; no duplicate entry/FAB.

## Creation & boundaries

- [x] T010 Single Create Khatmah CTA for No Plan state.
- [x] T011 Boundary mode: Surah range or Page range.
- [x] T012 Start/end Surah with Ayah selectors → inclusive Mushaf pages.
- [x] T013 Validated page start/end selectors (1…604).
- [x] T014 Preview uses selected boundaries only (non-persisting).
- [x] T015 Preview shows boundaries, total, daily target, completion date.
- [x] T016 Schedule by duration presets OR target completion date.

## Active hub & reading

- [x] T017 Active hub facts: today range, assigned/confirmed/remaining, progress, completion date.
- [x] T018 Save Progress affordance with editable confirmation sheet.
- [x] T019 Return to Quran on full completion.
- [x] T020 Edit plan duration/schedule with preview (progress preserved).
- [x] T021 Delete plan via confirmed reset.
- [x] T022 Recoverable malformed/error state with Retry and Reset.

## Tests

- [x] T030 Domain: Surah/Ayah and page range creation, invalid ranges, plan allocation.
- [x] T031 Domain: persistence, resume page, edit duration, delete/reset.
- [x] T032 Domain: daily and final completion semantics.
- [x] T033 Widget: hub canonical states, narrow screen, 1.4 text scale.
- [x] T034 Widget: Home entry card EN/AR.
- [ ] T035 Route/integration: KhatmaReaderRoute + Save Progress return path (manual QA covered; automated deferred).

## Release gates

- [x] T040 `melos run fix:format` + `dart analyze` on smart_khatma.
- [x] T041 `flutter test test/features/smart_khatma/` (43 tests).
- [ ] T042 Production App Bundle build on release lane.
- [ ] T043 Physical-device smoke (create → read → save → rollover).

## Explicitly deferred

- [ ] POST001 Android widget activation.
- [ ] POST002 Reminders and adherence.
- [ ] POST003 Listening-derived progress.
- [ ] POST004 Pause/history/non-linear plans.
- [ ] POST005 Today Plan Khatma reconciliation.
