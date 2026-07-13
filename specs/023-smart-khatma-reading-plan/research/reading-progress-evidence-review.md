# Smart Khatma reading-progress evidence review

**Date:** 2026-07-12  
**Decision:** use a hybrid contiguous verified model  
**Disposition:** historical research; the simplified implemented release
contract in `../amendment-production-readiness.md` is normative. Persisted
session drafts described here are deferred.  
**Confidence:** high  
**Implementation status:** blocked pending acceptance of this decision and the
v2 migration contract

## Executive verdict

The current implementation is inaccurate as a record of completed reading.
`QuranImageReaderScreen._recordReadingProgress` forwards every newly loaded page
from the general reader to `UpdateKhatmaProgressUseCase`. That use case persists
an exact `currentPage + 1` transition without knowing how the reader was opened,
whether the previous page was read, or whether the transition was accidental.
The same persisted field drives plan, daily Wird, Home, Today Plan, completion,
and Android-widget summaries.

The proposed arbitrary page-range ledger solves a possible future non-linear
plan, not a current requirement. Smart Khatma currently schedules one linear
range from `startPage` through page 604. A range set, bitset, event history,
confidence score, and optimistic revision would add storage and migration
states without making the central assertion—"the user read this"—knowable.

Adopt **candidate + contiguous verified progress**:

- `visiblePage` is transient navigation state.
- `suggestedCompletedThroughPage` is an optional, persisted session draft.
- `verifiedCompletedThroughPage` is the sole source of reading progress.
- Only an explicit user confirmation mutates verified progress.
- Confirmation is offered at daily completion and on a meaningful partial
  exit, never after every page.
- Generic Quran reading never silently advances a Khatma. A later, explicit
  “Count this toward my Khatma” action may reuse the same confirmation command.

Implementation should not begin until product and engineering accept this
policy. The current feature must not be called production-ready before the v2
migration and dependent surfaces are reconciled.

## Repository evidence

### Current source of truth

| Concern | Repository evidence | Current effect |
|---|---|---|
| Plan semantics | `apps/tilawa/lib/features/smart_khatma/domain/entities/khatma_plan.dart`, `KhatmaPlan.completedPages`, `remainingPages`, `isCompleted` | `currentPage` ambiguously means a position while calculations treat it as a completion boundary. |
| Creation | `create_khatma_plan_use_case.dart`, `CreateKhatmaPlanUseCase.call` | Copies global last-read page into both `startPage` and `currentPage`; page 604 creates an active, zero-complete plan. |
| Mutation | `update_khatma_progress_use_case.dart`, `UpdateKhatmaProgressUseCase.call` | Ignores backward and multi-page jumps; persists exactly `plan.currentPage + 1`; no entry-source or reading evidence. |
| Reader hook | `quran_image_reader_screen.dart`, `_ReaderShell` and `_recordReadingProgress` | Every first `NavigationLoaded` and every changed loaded page saves global last-read, then calls Khatma progress when enabled. |
| Entry scope | `smart_khatma_plan_actions.dart`, `openKhatmaReader`; `today_plan_card.dart`; `app_router_config.dart`, `QuranLastReadRoute` | Khatma and Today Plan open the same global last-read route; no plan/session identity is passed. |
| Global resume | `reader_settings_datasource.dart`, `saveLastReadPosition`; `get_khatma_today_target_use_case.dart` | Index/jump/backward reading can change global resume independently of the plan; today target may start from global last-read instead of plan progress. |
| Daily summary | `get_wird_progress_summary_use_case.dart`, `_completedPagesForToday` | Daily completed pages are derived from `currentPage - progressStartPage`; false navigation progress propagates. |
| Catch-up | `select_khatma_catch_up_use_case.dart`, `SelectKhatmaCatchUpUseCase.call` | Records adjustment/date only; it does not change duration or verified pages. |
| Extension | `extend_khatma_plan_use_case.dart`, `ExtendKhatmaPlanUseCase.call` | Adds missed days to duration and records adjustment/date; it does not alter progress. |
| Persistence | `khatma_plan_local_datasource.dart`, `SharedPreferencesKhatmaPlanLocalDataSource` | One JSON object under `smart_khatma.active_plan.v1`; malformed or invalid data returns `null` and is not recoverable through the app. |
| Today Plan | `generate_today_plan_use_case.dart`; `today_plan_bloc.dart`, `_onTaskToggled` | Target metadata can come from Khatma, but task completion is manually toggled in a separate store and can contradict Khatma. |
| Home | `home_screen_scope.dart`; `smart_khatma_home_entry_card.dart` | Home reacts to `plan.currentPage`; it does not own progress. |
| Widget | `smart_khatma_dependencies.dart`, `syncWirdWidget`; `WirdProgressWidgetProvider.kt` | Flutter derives and writes a presentation payload. Native code decodes/renders it and does not write the plan. |
| Analytics | `update_khatma_progress_use_case.dart`, `khatmaProgressUpdated` | Logs exact current page and plan ID, retaining more religious-activity detail than rollout monitoring requires. |
| Flags | `smart_khatma_feature_flags.dart` | Domain/UI and widget have separate launch gates; a flag does not correct already-persisted semantics. |

The first loaded reader state is deliberately included by `_ReaderShell.listenWhen`
when the prior state is not `NavigationLoaded`. Rotation/rebuild does not
necessarily create a duplicate if the same Bloc/state instance is retained, but
a recreated reader that emits a first loaded state does invoke the hook again.
Sequential duplicate callbacks are mostly idempotent because the second read
sees the updated plan; overlapping unawaited calls are not transactional.

### User-visible high-severity defects

1. **False completion progress:** with plan `currentPage = 20`, any general
   reader transition that loads page 21 persists 21. Daily/Home/widget progress
   then increases although reading is unproven. This is high severity because it
   corrupts the worship plan's central claim; it is a release blocker, not a
   crash/data-loss P0.
2. **Final-page inconsistency:** transitioning 603→604 sets status completed,
   while `remainingPages` remains 1 and numeric progress remains below 100%.
   Consumers that inspect status and consumers that inspect amounts can disagree.
3. **Page-604 creation dead end:** global last-read 604 creates an active plan
   with `completedPages = 0`, `remainingPages = 1`; no valid +1 transition exists
   to complete it.

## Current-behavior truth table

“Persisted” below means the v1 plan unless noted. Severity uses release impact:
blocker, high, medium, low, or none.

| Scenario | Current persisted/calculated state | Expected policy | Defect, severity, confidence |
|---|---|---|---|
| Create from page 1 | `start=current=1`; 0/604 completed, 604 remaining | Start with 0 verified; resume page 1 | Ambiguous field but displayed math is plausible; medium, high |
| Create from page 604 | active; 0/1 completed, 1 remaining; cannot advance | Ask whether page 604 belongs in this Khatma; allow confirmation | Confirmed blocker, high |
| Page visible, unread | First/changed loaded page saves global position; exact next page advances plan | Visibility changes neither candidate nor verified progress by itself | Confirmed high, high |
| Sequential 20→21 | If plan is at 20, persists 21; daily completion +1 | May suggest through 20 in a plan session; confirmation required | Confirmed high, high |
| Rapid 20→21 | Same as normal; no reading-speed evidence exists | Same suggestion at most; never auto-verify | Confirmed high, high |
| Jump 20→100 | Global last-read becomes 100; Khatma stays 20 because jump is >+1 | No verified change; preserve Khatma resume independently | Partial correctness plus resume contamination; high, high |
| Backward 30→29 | Global last-read becomes 29; Khatma does not decrease | No verified change; Khatma resume remains first unverified | Resume contamination; medium, high |
| Open from index | Loaded page is indistinguishable from swipe; exact +1 advances | No automatic Khatma progress | Confirmed when destination is +1; high, high |
| Open bookmark | Same shared reader hook; exact +1 advances | No automatic Khatma progress | Confirmed when destination is +1; high, high |
| Programmatic restore | First `NavigationLoaded` invokes hook; exact +1 can advance | Restore visible/resume only | Confirmed conditional defect; high, high |
| Leave app on page | No exit commit, but the settle mutation already occurred | Offer partial confirmation only when a real suggestion exists | Confirmed high, high |
| Process death | Already persisted visible-page progress survives; no unconfirmed state exists | Verified unchanged; restore pending suggestion | Confirmed recovery gap; high, high |
| Complete final page | 603→604 marks status completed but leaves 1 remaining numerically | Explicit confirmation through 604 makes all derived values complete | Confirmed blocker, high |
| Revisit completed page | `visited <= current` is ignored | No mutation | No defect for monotonicity; none, high |
| Read outside Khatma | Shared reader hook can advance exact next page | No silent advance; optional explicit count action | Confirmed high, high |
| Duplicate callback | Sequential retry becomes no-op; overlapping calls can race reads/writes | Idempotent monotonic commit | Low-count risk but no atomicity; medium, medium-high |
| Rebuild/rotation | Recreated first loaded state invokes hook; usually no-op unless it is exact next | Rebuild never verifies progress | Conditional defect; medium, medium-high |

## Epistemic limit

The application can distinguish these claims, from weakest to strongest:

1. **Displayed:** pixels for a page were shown.
2. **Navigated:** the reader moved between page positions.
3. **Likely read:** interaction context supports a suggestion, but remains an
   inference.
4. **User-confirmed:** the user declared completion through a page.
5. **Spiritually/cognitively completed:** unknowable to software.

The recommended model stores claim 4. It must label it “confirmed” or
“completed,” not “verified by the app.” Dwell time, swipe speed, audio position,
or confidence scoring cannot establish claim 5.

## Does the product need non-contiguous progress?

No current approved flow requires it. A plan is a contiguous journey from a
start page to 604; daily assignment, catch-up debt, resume, and completion all
need the first unread boundary. Out-of-order Quran reading is valid worship, but
it need not silently alter this specific linear plan. Users can explicitly
confirm a later boundary only if they also assert that the intervening pages
were completed.

- **Page granularity** matches existing schedules and reader data. Ayah-level
  proof is unsupported and would complicate Mushaf-page boundaries.
- **Range sets** and **604-bit bitsets** support arbitrary holes but create
  states the current UX cannot explain or schedule.
- A bitset is compact and fast, but opaque in JSON/debugging. Interval ranges
  are readable but normalization/migration heavy. Neither improves truth.
- If a future approved non-linear plan requires holes, introduce a separate
  progress-ledger specification and migrate from the contiguous boundary then.

## Options comparison

Scores are 1 (poor) to 5 (strong). For “complexity” and “migration risk,” 5
means simplest/lowest risk. UX friction 5 means least friction.

| Criterion | 1 Current | 2 Next unread | 3 Confirm only | 4 Hybrid contiguous | 5 Range set | 6 Bitset | 7 Ayah |
|---|---:|---:|---:|---:|---:|---:|---:|
| Accuracy | 1 | 3 | 5 | 5 | 5 | 5 | 4 |
| Accidental-navigation resistance | 1 | 2 | 5 | 5 | 5 | 5 | 5 |
| UX friction | 5 | 5 | 2 | 4 | 3 | 3 | 1 |
| Implementation complexity | 5 | 4 | 4 | 4 | 2 | 2 | 1 |
| Migration risk | 1 | 3 | 3 | 3 | 2 | 2 | 1 |
| Testability | 4 | 5 | 5 | 5 | 4 | 4 | 2 |
| Privacy | 3 | 5 | 5 | 4 | 3 | 3 | 1 |
| Performance | 5 | 5 | 5 | 5 | 4 | 5 | 3 |
| Debuggability | 4 | 5 | 5 | 5 | 4 | 2 | 2 |
| Offline reliability | 5 | 5 | 5 | 5 | 5 | 5 | 4 |
| Process-death recovery | 2 | 3 | 3 | 5 | 5 | 5 | 4 |
| Existing-reader compatibility | 5 | 4 | 4 | 5 | 3 | 3 | 2 |
| Today Plan compatibility | 2 | 5 | 5 | 5 | 4 | 4 | 2 |
| Android widget compatibility | 2 | 5 | 5 | 5 | 4 | 4 | 3 |
| Catch-up/extension support | 2 | 5 | 5 | 5 | 4 | 4 | 3 |
| Future non-linear support | 1 | 1 | 2 | 2 | 5 | 5 | 5 |
| **Total / 80** | **48** | **64** | **68** | **76** | **63** | **61** | **43** |

Architectural judgment: option 4 wins because it retains low-friction reader
suggestions while the single confirmed boundary makes every downstream
calculation deterministic. Option 3 is trustworthy but unnecessarily manual.
Option 2 still mistakes navigation for evidence unless paired with confirmation.

## UX and policy recommendation

### Entry and reading

- **Start today’s Wird / Resume today’s Wird:** open a plan-scoped session at
  `resumePage`, not global last-read. Explain once that progress is saved when
  the user confirms where they stopped.
- **Sequential reading:** a settled sequential transition may raise the local
  suggestion to the page just left, only inside the assignment and foreground.
- **Jump/index/bookmark/restore:** update visible page only. Show a calm note if
  the destination is outside today’s assignment; never auto-complete gaps.
- **Outside Khatma:** ordinary reading remains ordinary reading. A future
  contextual action may say “Count completed pages toward my Khatma” and open
  the same confirmation selector.

### Confirmation cadence

- At assignment end, show one primary declaration: **“I completed today’s
  Wird”** / **“أتممت ورد اليوم”**. It commits only when the confirmed boundary
  covers the assignment.
- On exit/background after meaningful suggested progress, persist the draft
  silently. On the next Khatma entry, present a non-blocking “Save progress?”
  sheet. Do not interrupt on every app background or every page.
- The sheet offers: **Save through page N**, **Adjust**, **Not now/discard**, and
  **Continue reading**. The selector is bounded from current verified+1 through
  the assignment end.
- If no suggestion exists, exit without a prompt.
- After accidental jumps, retain the prior contiguous suggestion.
- After process death or midnight, label the draft by its original local date
  and ask the same neutral question before starting a new session.

### Copy principles

- English uses declarative, non-judgmental verbs: “Save,” “Continue,” “Adjust,”
  “Not now.” Avoid “failed,” “behind,” and moral scoring.
- Arabic uses clear Modern Standard Arabic and worship-appropriate calm:
  “حفظ التقدّم حتى الصفحة …”، “تعديل”، “ليس الآن”، “متابعة القراءة”. Avoid
  guilt-heavy “تأخرت” or “فشلت”.
- Copy must say “suggested” for inferred progress and “saved/completed” only
  after confirmation. RTL changes layout direction, not page-number semantics.

## Global-reading policy

| Policy | Correctness | Surprise | Complexity | Decision |
|---|---|---|---|---|
| Only plan-scoped sessions count | Strong | Low after onboarding | Low | Baseline |
| Any sequential reading in assignment counts | Weak; source remains inference | High | Medium | Reject |
| Explicit “count toward Khatma” | Strong | Low | Medium | Defer as extension |
| Mixed automatic/manual | Hard to explain | High | High | Reject |

## Concurrency decision

There is no evidence of distributed writers. The widget is presentation-only,
no background service updates the plan, and the current progress write is local.
Do not add a revision counter, range union, or persistent event log.

Use one repository-level serialized local commit command. The command validates
plan ID and assignment bounds, then sets:

```text
verifiedCompletedThroughPage =
  max(storedVerifiedCompletedThroughPage, confirmedThroughPage)
```

This makes duplicate commits and retries idempotent. A stable session ID is
useful for draft identity and diagnostics but is not a second progress source.
A commit for an inactive/replaced plan fails without mutation. If cloud sync or
multiple plan writers are later approved, concurrency must be re-specified.

## Risks and rejected/deferred parts

- Reject automatic verification from page visibility, settle, dwell, highest
  page, global last-read, listening position, or confidence score.
- Reject arbitrary candidate/verified range sets, bitsets, Ayah tracking,
  unbounded event logs, and optimistic revisions for v2.
- Defer non-linear plans, listening-derived progress, reminders, and adherence
  until the contiguous reading contract has production evidence.
- Candidate draft persistence retains a small amount of religious-activity
  data. Store only one active draft locally, no page-by-page history, expire it
  after seven local days, and never emit page numbers in analytics.

## Production-readiness impact

Blocked until the v2 contract is implemented and verified:

- Core Smart Khatma calculations and completion.
- Today Plan completion reconciliation.
- Home progress claims.
- Android widget rollout beyond internal/testing cohorts.
- Reminders and adherence, because their inputs would be untrustworthy.
- Listening integration, because Spec 023A’s high-water-mark proposal conflicts
  with this decision.

## First implementation slice

Implement exactly one bounded, platform-independent slice first: the pure Dart
v2 domain and persistence migration—`verifiedCompletedThroughPage`, derived
assignment/summary calculations, pending legacy migration state, serialized
idempotent confirmation command, and unit/serialization tests. Do not connect
the reader, Home, Today Plan, widget, reminders, adherence, or listening in that
slice.
