# Contract: Smart Khatma reading progress v2

This contract implements the decision in
`research/reading-progress-evidence-review.md`. It describes architecture only;
the repository does not yet implement it.

## Ownership and source of truth

| Object | Persisted? | Owns |
|---|---|---|
| `KhatmaPlanV2` | Yes, one active plan | Schedule and the sole verified completion boundary |
| `KhatmaReadingSessionDraft` | Yes, at most one, separately | Unconfirmed suggestion and session resume only |
| `KhatmaDailyAssignment` | No | Derived local-day work range |
| `WirdProgressSummary` | No | Domain-facing derived facts for presentation |
| `WirdProgressWidgetPayload` | Yes, replaceable snapshot | Localized/formatted native presentation only |
| Home view state | No | Presentation derived from `WirdProgressSummary` |

There is no `KhatmaProgressLedger` in v2. `KhatmaPlanV2` owns one contiguous
verified boundary. Global Quran last-read remains a separate Quran-reader
preference and MUST NOT be used as Khatma progress or Khatma resume.

## Domain model

```dart
final class KhatmaPlanV2 {
  String id;
  DateTime createdAt;
  LocalDate startDate;
  int durationDays;
  int startPage;
  int targetPage;
  int verifiedCompletedThroughPage;
  KhatmaPlanStatus status;
  KhatmaPlanAdjustment adjustment;
  LocalDate? adjustmentDate;
  int progressSemanticsVersion; // exactly 2
}

final class KhatmaReadingSessionDraft {
  String sessionId;
  String planId;
  LocalDate assignmentDate;
  QuranPageRange assignmentRange;
  int visiblePage;
  int? suggestedCompletedThroughPage;
  DateTime startedAt;
  DateTime updatedAt;
}

final class KhatmaDailyAssignment {
  String planId;
  LocalDate date;
  QuranPageRange range;
  int verifiedAtStartOfDay;
}
```

`LocalDate` means a calendar date interpreted in the device time zone at the
time the assignment/session is created. It is serialized as `YYYY-MM-DD`, not a
UTC instant.

### Invariants

- Quran pages are inclusive and bounded to 1…604.
- `1 <= startPage <= targetPage <= 604`.
- `startPage - 1 <= verifiedCompletedThroughPage <= targetPage`.
- New plans start at `verifiedCompletedThroughPage = startPage - 1`.
- `status == completed` if and only if
  `verifiedCompletedThroughPage == targetPage`.
- Completed pages are
  `verifiedCompletedThroughPage - startPage + 1`, clamped to 0…total.
- Remaining pages are `targetPage - verifiedCompletedThroughPage`.
- A session draft references the active plan and snapshots one derived daily
  assignment. Its suggestion is null or within
  `verified+1…assignmentRange.endPage`.
- Candidate/suggested progress never enters plan calculations.
- At most one active draft exists. Replacing it requires confirming or
  discarding the old draft.

## Serialization

Active plan key: `smart_khatma.active_plan.v2`

```json
{
  "schema_version": 2,
  "progress_semantics_version": 2,
  "id": "local_...",
  "created_at": "2026-07-12T10:00:00.000",
  "start_date": "2026-07-12",
  "duration_days": 30,
  "start_page": 1,
  "target_page": 604,
  "verified_completed_through_page": 0,
  "status": "active",
  "adjustment": "none",
  "adjustment_date": null
}
```

Draft key: `smart_khatma.reading_session_draft.v2`

```json
{
  "schema_version": 2,
  "session_id": "...",
  "plan_id": "...",
  "assignment_date": "2026-07-12",
  "assignment_start_page": 1,
  "assignment_end_page": 21,
  "visible_page": 8,
  "suggested_completed_through_page": 7,
  "started_at": "2026-07-12T10:00:00.000",
  "updated_at": "2026-07-12T10:20:00.000"
}
```

No page event list, confidence value, localized text, Android field, detailed
history, or analytics identifier belongs in either object.

## Mutation contract

Only `ConfirmKhatmaProgress` mutates
`verifiedCompletedThroughPage`. Creation, navigation, session restore,
suggestion, catch-up, extension, Home, Today Plan, and widget synchronization do
not.

The repository serializes local commands. A confirmation must:

1. Load the active v2 plan.
2. Reject if `planId` does not match.
3. Validate the confirmed page is between the stored verified boundary and the
   session assignment end.
4. Persist `max(stored, confirmed)` and derive status from the result.
5. Remove the draft only after plan persistence succeeds.
6. Return the unchanged plan for an exact duplicate.

No partial write may clear a draft before the plan is durable.

## Algorithms

### Session creation

```text
startSession(plan, localDate):
  require plan.active
  if valid draft exists for plan:
    return restoreDraft(draft)
  assignment = deriveAssignment(plan, localDate)
  draft = new session(
    assignment snapshot,
    visiblePage = resumePage(plan, assignment),
    suggestion = null)
  persist draft
  return draft
```

This mutates only the draft, never verified progress.

### Visible page

```text
onPageVisible(page, source):
  draft.visiblePage = clamp(page, 1, 604)
  persist debounced draft resume state
  // verified progress unchanged
```

### Sequential transition

```text
onSettledTransition(from, to, source, foreground):
  if not foreground: return
  if source != sequentialSwipe or to != from + 1: return
  if from not in draft.assignmentRange: return
  candidate = min(from, draft.assignmentRange.endPage)
  draft.suggested = max(draft.suggested ?? verified, candidate)
  persist draft
  // verified progress unchanged
```

No dwell-time threshold is required for correctness. Product research may tune
when a suggestion is displayed, but never when verified progress is written.

### Jump/index/bookmark/deep link/restore

```text
onJump(destination, source):
  draft.visiblePage = destination
  persist resume state
  do not create or bridge a suggestion
  // verified progress unchanged
```

### Background and exit

```text
onBackgroundOrExit():
  persist draft if it has resume or suggestion value
  do not show repeated system-background prompts
  do not commit
```

The next explicit Khatma entry may show one pending confirmation sheet.

### Explicit confirmation

```text
confirmThrough(planId, sessionId, page):
  serialize repository command
  plan = loadV2()
  require active plan.id == planId
  draft = loadDraft()
  require draft.sessionId == sessionId and draft.planId == planId
  require page >= plan.verifiedCompletedThroughPage
  require page <= draft.assignmentRange.endPage
  next = max(plan.verifiedCompletedThroughPage, page)
  persist plan with verified=next and status=(next == target ? completed : active)
  clear draft
  return plan
```

This is the only verified mutation.

### Duplicate commit

```text
repeat confirmThrough(..., page):
  if draft is absent and stored verified >= page:
    return stored plan unchanged
  otherwise apply normal validation
```

No double count and no session-ID history are needed.

### Process-death restore

```text
restore():
  load plan and draft independently
  if draft malformed or references another plan: quarantine draft; ignore it
  if draft older than seven local dates: offer discard/review; never commit
  if draft date != today: show dated pending confirmation before new session
  // verified progress unchanged
```

### Derived calculations

```text
completedPages(plan) = verified - start + 1, clamped 0...total
remainingPages(plan) = target - verified
entirePlanComplete(plan) = verified == target
resumePage(plan, assignment) =
  min(max(verified + 1, assignment.start), assignment.end)

dailyComplete(plan, assignment) =
  verified >= assignment.end

catchUpDebt(plan, today) =
  max(0, expectedCompletedThrough(today) - verified)
```

Daily assignment is derived from the verified boundary, remaining pages,
remaining schedule days, and the selected catch-up/extension policy. It is not
derived from global last-read and is not persisted as a second plan.

### Catch-up and extension

- Catch-up may alter the assignment policy/metadata for the selected local day;
  it never inserts completed pages.
- Extension changes `durationDays` and therefore future assignment sizes/end
  date; it never changes the verified boundary.
- Missed-day debt is recalculated from schedule expectation minus contiguous
  verified pages.
- Completion is impossible until the user confirms through `targetPage`.

## Failure and stale behavior

- A failed draft write leaves verified progress unchanged and shows a retryable
  local-save message on the next Khatma surface.
- A failed plan commit retains the draft and leaves the previous plan intact.
- Malformed v2 plan data is quarantined and does not fall back to treating v1
  as verified.
- A midnight rollover does not rewrite an open draft’s assignment. The dated
  draft must be confirmed or discarded, then today’s assignment is re-derived.
- Device time-zone changes follow the same stale-draft rule; no automatic
  progress is inferred.
- Analytics may emit coarse events (`session_started`, `confirmation_offered`,
  `confirmation_saved`, `confirmation_discarded`, `migration_outcome`) without
  plan ID, page number, range, Quran text, or reading duration.

## Reader event boundary

Presentation may produce typed navigation events (`sessionStart`,
`sequentialSwipe`, `index`, `scrubber`, `bookmark`, `deepLink`, `restore`,
`programmatic`). These events update navigation/suggestion state only. The
domain confirmation command accepts a confirmed boundary, not raw reader
events. This keeps the model unit-testable without Flutter widgets.
