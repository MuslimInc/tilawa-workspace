# Al-Khatmah release UX tasks

Tasks are ordered by the canonical user journey. Do not start a later group
while an earlier release requirement is incomplete.

## Current verified foundation

- [x] T001 Use one nullable, contiguous user-confirmed page boundary.
- [x] T002 Remove navigation-driven Khatmah mutations from the Quran reader.
- [x] T003 Persist one stable local-day assignment in the v2 plan.
- [x] T004 Open the existing reader at assignment start / first unconfirmed page.
- [x] T005 Bound and make explicit progress confirmation idempotent.
- [x] T006 Derive daily/full completion consistently, including final target.
- [x] T007 Keep Today Plan and Android widget default-off.
- [x] T008 Hide ineffective catch-up and retain reviewed extension behavior.
- [x] T009 Use one contextual Home card and remove duplicate entry/FAB.

## Release blockers

- [x] T010 Add a single Create Khatmah CTA for the No Plan state.
- [x] T011 Add boundary mode: Surah range or Page range.
- [x] T012 Add ordered start/end Surah selectors and resolve them to inclusive
  plan page boundaries using existing Quran metadata.
- [x] T013 Add validated page start/end selectors bounded to 1…604.
- [x] T014 Replace beginning/current/fixed-604 preview inputs with the selected
  explicit boundaries; keep preview non-persisting.
- [x] T015 Update preview to show selected boundaries, total pages, daily target,
  and expected completion date for both modes.
- [x] T016 Add required active-Hub facts: today start/end, assigned, confirmed,
  remaining, overall progress, and expected completion date.
- [x] T017 Add one deliberate Save Progress affordance to the Khatmah reading
  flow; reuse the existing editable confirmation sheet and progress command.
- [x] T018 Add Return to Quran to full completion.
- [x] T019 Add Reset with confirmation to recoverable malformed/error state.

## Release validation

- [x] T020 Add domain tests for arbitrary page boundaries, ordering, total
  pages, daily target, and arbitrary final-page completion; Surah resolution is
  exercised through the creation widget using existing Quran metadata.
- [ ] T021 Add widget tests for all seven canonical states in Arabic/English,
  RTL/LTR, 1.4 text scale, narrow screens, and semantics.
- [ ] T022 Add route/integration coverage for Start, Resume, Save Progress,
  cancellation, restart persistence, daily completion, and full completion.
- [ ] T023 Run formatting, targeted analyzer, Smart Khatma/reader/Home tests,
  Spec Kit validation, and the production App Bundle build.

## Explicitly deferred

- [ ] POST001 Android widget activation/reconciliation.
- [ ] POST002 Reminders and adherence.
- [ ] POST003 Listening-derived progress.
- [ ] POST004 Pause/history/non-linear plans.
- [ ] POST005 Advanced migration/synchronization/refactoring.
