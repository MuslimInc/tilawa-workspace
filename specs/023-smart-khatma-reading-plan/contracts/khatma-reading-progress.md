# Contract: Al-Khatmah confirmed progress release MVP

**Status:** normative release contract  
**Schema:** `smart_khatma.active_plan.v2`

## Source of truth

One active `KhatmaPlan` owns user-selected boundaries, schedule, a frozen
local-day assignment, and one
nullable contiguous confirmation boundary:

```text
confirmedCompletedThroughPage = null
  → no plan page is confirmed

confirmedCompletedThroughPage = N
  → every plan page from startPage through N is user-confirmed
```

No other value is progress. Global Quran last-read, visible page, navigation,
Today Plan tasks, Home state, and Android widget snapshots are not progress
stores.

## Persisted fields

```json
{
  "schema_version": 2,
  "id": "local_...",
  "created_at": "2026-07-13T09:00:00.000",
  "start_date": "2026-07-13T00:00:00.000",
  "duration_days": 30,
  "start_page": 1,
  "target_page": 604,
  "confirmed_completed_through_page": null,
  "assignment_date": "2026-07-13T00:00:00.000",
  "assignment_start_page": 1,
  "assignment_end_page": 21,
  "adjustment": "none",
  "adjustment_date": null
}
```

Invariants:

- Pages are within 1…604 and `startPage <= targetPage`.
- Confirmation is null or within `startPage…targetPage`.
- Confirmation never moves backward.
- Confirmation cannot exceed today’s frozen assignment end.
- Completion is derived only from confirmation reaching `targetPage`.
- Completed + remaining equals total and full completion ratio is exactly 1.
- Today’s assignment start/end do not change after partial confirmation.
- A new local day derives and persists one new assignment from the first
  unconfirmed page.

## Commands and derivations

Only `UpdateKhatmaProgressUseCase(confirmedThroughPage: N)` mutates progress.
It rejects out-of-assignment pages and treats duplicates/backward values as an
unchanged success.

Plan creation accepts either an ordered Surah range resolved to page boundaries
or an ordered page range. Plan preview does not persist.
`CreateKhatmaPlanUseCase.confirm` persists only after the user reviews start,
end, total pages, duration, daily pages, and expected completion date.

Start/Resume opens the existing reader using `KhatmaReaderRoute` at the first
unconfirmed page inside today’s assignment.

After returning, the visible/global reader page is only an editable suggestion.
The user must select and confirm “completed through page N.” Reader callbacks,
jumps, restoration, and lifecycle events never call the progress command.

Catch-up is hidden because its prior implementation only wrote metadata.
Extension increases duration and future schedule calculations without changing
today’s assignment or confirmed progress.

## Derived consumers

- `KhatmaTodayTarget`: frozen range and its confirmed/remaining counts.
- `WirdProgressSummary`: locale-free semantic summary.
- Home: one contextual card derived from the plan/target.
- Today Plan: release-default off until manual task completion is reconciled.
- Android widget: release-default off; Flutter summary only, native rendering
  only.

## Privacy and failure

Analytics uses coarse creation/confirmation/completion/failure signals without
page, range, plan ID, text, dwell time, or reading history. Malformed v2 JSON is
not overwritten; loading fails into the recoverable localized error state.

## Deferred

Range sets, bitsets, Ayah progress, event/candidate histories, persisted session
drafts, confidence scoring, listening progress, pause, adherence, detailed
history, reminders, non-linear plans, cloud synchronization, and general
migration infrastructure are post-release.
