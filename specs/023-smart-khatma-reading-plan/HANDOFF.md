# Khatmah MVP — Agent Handoff

**Branch:** `feature/khatmah`  
**Working tree:** clean  
**Latest Khatmah commit:** `d6f3e5085` — feat: update Khatma plan use case, editing, boundary validation  
**Verdict last session:** feature-complete + test-green; **NOT READY FOR PRODUCTION** until T042/T043

---

## Goal

Ship competitive Al-Khatmah MVP on Tilawa:

- User picks **Surah/Ayah range** or **Mushaf page range**
- User picks **duration (7/15/30/60)** or **target completion date**
- **Preview → confirm → persist**
- **Today’s assignment → Start/Resume reader → Save Progress**
- **Edit duration**, **delete plan**, **complete → start another**

Do **not** clone competitor branding, redesign unrelated screens, or do v2 work (widget, Today Plan, reminders, pause/history).

---

## Spec Kit (source of truth)

| File | Role |
|---|---|
| [`specs/023-smart-khatma-reading-plan/spec.md`](spec.md) | Product spec |
| [`specs/023-smart-khatma-reading-plan/plan.md`](plan.md) | Architecture + flow |
| [`specs/023-smart-khatma-reading-plan/tasks.md`](tasks.md) | Task checklist |
| [`specs/023-smart-khatma-reading-plan/amendment-production-readiness.md`](amendment-production-readiness.md) | Normative release UX |
| [`specs/023-smart-khatma-reading-plan/flow-to-implementation-map.md`](flow-to-implementation-map.md) | UX → code map |
| [`docs/reviews/khatmah_competitive_audit_2026-07-12.md`](../../docs/reviews/khatmah_competitive_audit_2026-07-12.md) | Competitor audit |
| [`screenshots/khatmah_app/`](../../screenshots/khatmah_app/) | Reference screenshots |

---

## What’s done

### Core flow (implemented)
- Home entry: `SmartKhatmaHomeEntryCard`
- Hub: 7 states (no plan, create, active, today done, full done, error, creation review)
- Boundaries: Surah + Ayah **or** page 1…604 via `KhatmaPlanBoundaries`
- Schedule: duration presets **or** target date
- Preview before persist; explicit confirm
- Frozen daily assignment; user-confirmed progress only
- Reader: `KhatmaReaderRoute(initialPage: plan.resumePage)`
- Save Progress bottom sheet after reader return
- Edit plan (duration/date, progress kept)
- Delete = confirmed reset
- Extend when behind; catch-up hidden

### Key files

```
apps/tilawa/lib/features/smart_khatma/
├── domain/
│   ├── entities/khatma_plan.dart          # progress invariant, resumePage, isTodayCompleted
│   ├── khatma_plan_boundaries.dart        # NEW: Surah/Ayah→page, validation, target-date→days
│   └── usecases/
│       ├── create_khatma_plan_use_case.dart
│       ├── update_khatma_plan_use_case.dart   # NEW: edit duration
│       ├── update_khatma_progress_use_case.dart
│       ├── get_khatma_today_target_use_case.dart
│       ├── extend_khatma_plan_use_case.dart
│       └── reset_khatma_plan_use_case.dart
├── presentation/
│   ├── screens/smart_khatma_hub_screen.dart   # creation + all hub states
│   ├── widgets/smart_khatma_plan_actions.dart # reader, save, edit sheet, reset
│   ├── widgets/smart_khatma_home_entry_card.dart
│   └── bloc/khatma_plan_bloc.dart
├── data/datasources/khatma_plan_local_datasource.dart  # smart_khatma.active_plan.v2
└── smart_khatma_feature_flags.dart
```

### Routes
- `/smart-khatma` → `SmartKhatmaHubRoute`
- `/khatma-reader/:initialPage` → `KhatmaReaderRoute`

### Flags (`app_launch_config.dart`)
- `TILAWA_LAUNCH_SMART_KHATMA_ENABLED` → default **true**
- `TILAWA_LAUNCH_TODAY_PLAN_ENABLED` → default **false**
- `TILAWA_LAUNCH_WIRD_WIDGET_ENABLED` → default **false**

### Tests — **43/43 pass**
```sh
cd apps/tilawa && flutter test test/features/smart_khatma/
```

New/extended:
- `domain/khatma_plan_boundaries_test.dart`
- `domain/khatma_lifecycle_test.dart`
- `domain/usecases/update_khatma_plan_use_case_test.dart`
- extended `create_khatma_plan_use_case_test.dart`
- widget: `smart_khatma_hub_screen_test.dart`, `smart_khatma_home_entry_card_test.dart`

---

## What’s left (release gates)

From [`tasks.md`](tasks.md):

| Task | Status | Action |
|---|---|---|
| **T035** | Open | Automated test: `KhatmaReaderRoute` → reader → Save Progress → bloc update |
| **T042** | Open | Production App Bundle build on release lane |
| **T043** | Open | Physical-device smoke: create → read → save → next-day rollover |

Optional polish:
- Arabic hub widget matrix at 1.4 text scale (all 7 states)
- Dark mode pass on creation/edit sheets

**Explicitly out of scope:** POST001–POST005 (widget, reminders, Today Plan reconciliation, pause/history)

---

## Architecture decisions (don’t undo)

1. **Progress invariant:** `confirmedCompletedThroughPage` = last user-confirmed page (nullable). Reader navigation never writes progress.
2. **Daily assignment:** frozen per local day in v2 plan; rollover in `GetKhatmaTodayTargetUseCase`.
3. **Resume:** `(confirmedCompletedThroughPage ?? assignmentStartPage - 1) + 1`, clamped to today’s range.
4. **Boundaries:** plan math uses only selected `startPage`…`targetPage`; Surah/Ayah resolved via `quran_qcf`.
5. **Edit:** duration only — boundaries fixed after creation; change boundaries = delete + recreate.
6. **Analytics:** duration buckets only; no raw page/plan ids in shipped events.

---

## Verify before any new work

```sh
# workspace root
melos run fix:format
melos run analyze

# apps/tilawa
dart analyze lib/features/smart_khatma/
flutter test test/features/smart_khatma/
```

---

## Suggested next-agent prompt

Paste this into a fresh agent:

```
Continue Khatmah production release on branch feature/khatmah.

Read first:
- specs/023-smart-khatma-reading-plan/plan.md
- specs/023-smart-khatma-reading-plan/tasks.md

Remaining gates:
1. T042 — run production App Bundle build; fix failures
2. T043 — physical-device smoke: create Khatmah (Surah/Ayah range) → Start → Save Progress → verify hub → simulate next-day assignment rollover
3. T035 (optional) — integration test for KhatmaReaderRoute + Save Progress return path

Rules:
- Use existing architecture (bloc, get_it, GoRouter, Either, UI Kit, context.l10n)
- No unrelated refactors; no POST001–POST005 scope
- Update tasks.md when gates pass
- Final answer: READY FOR PRODUCTION or NOT READY with blockers
```

---

## Manual QA checklist (T043)

1. Home → Khatma card → Create
2. Surah mode: Al-Baqarah 142 → Al-An'am 94 (competitor ref range)
3. Duration 5 days → preview totals → confirm
4. Hub shows pages 22–139 range (or resolved pages), Start today’s Wird
5. Start → reader opens correct page → back → Save Progress → confirm partial then full day
6. Today completed card appears; assignment range unchanged
7. Edit plan → extend to 45 days → preview → save; progress unchanged
8. Delete plan → confirm → empty state
9. Repeat in **Arabic RTL** + **dark mode**
10. Change device date → next day → new assignment from first unconfirmed page

---

## Competitive reference (MVP only)

From [`screenshots/khatmah_app/`](../../screenshots/khatmah_app/) + audit:

- Show exact today range (Surah/Ayah + pages)
- Boundary before schedule; preview before create
- Separate Start/Resume vs explicit completion
- Calm copy (no “ahead by N days” evaluative tone)
- Skip: competitor branding, Juz/Rub’ units, previous/upcoming session ledger (post-MVP)

---

## Pitfalls for next agent

- `KhatmaPlanBloc` constructor now needs **8 deps** including `UpdateKhatmaPlanUseCase` — update any test fakes.
- `KhatmaPlanCreationReview` has `isEditing` flag — edit confirm uses `KhatmaPlanEditConfirmed`, not `KhatmaPlanCreationConfirmed`.
- Feature flag test expects `AppLaunchConfig()` → `smartKhatmaEnabled: false`; env default is `true` via `fromEnvironment`.
- Don’t enable Today Plan / Wird widget without reconciliation work in specs 022/041.
- `melos run gen:l10n` after arb edits.

---

## Status summary

| Area | State |
|---|---|
| MVP feature flow | Done |
| Domain + persistence | Done |
| UI (EN/AR strings) | Done |
| Unit + widget tests | 43 pass |
| Spec Kit sync | Done |
| AAB build | **Not run** |
| Device smoke | **Not run** |
| **Production ready?** | **NO** — run T042 + T043 |
