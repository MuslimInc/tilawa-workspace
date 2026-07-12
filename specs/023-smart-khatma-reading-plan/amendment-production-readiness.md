# Amendment: Smart Khatma progress correctness and release gates

**Status:** proposed; blocks production-readiness claims  
**Depends on:** `research/reading-progress-evidence-review.md`,
`contracts/khatma-reading-progress.md`, `migration-progress-v2.md`

## Spec 023 reconciliation

The following requirements supersede conflicting progress language in Spec 023
and `amendment-review-insights.md`:

- The feature is implemented but **not production-ready** because v1 equates
  navigation with progress and has final-page inconsistencies.
- Progress means the contiguous page boundary explicitly confirmed by the user.
- Page visibility, highest page, global last-read, listening position, time,
  and confidence are not completion evidence.
- The proposed high-water mark in FR-023A1.1 is rejected. Listening integration
  must wait for a separate confirmation-compatible contract.
- The v2 plan owns scheduling and verified progress. Daily assignment and Wird
  summary are derived. A single bounded draft owns unconfirmed suggestion.
- Only a plan-scoped reading session may create suggestions. Generic reading
  cannot silently update the plan.
- Catch-up changes assignment policy/metadata; extension changes schedule
  duration. Neither mutates verified progress.
- Entire-plan and daily completion derive solely from the verified boundary.
- v1 migration requires explicit confirmation and preserves original/malformed
  data for recovery and rollback.
- Analytics must not contain page numbers, page ranges, plan IDs, Quran text,
  dwell time, or detailed reading history.

Required tests before release:

- Domain invariants, assignment, debt, completion, duplicate confirmation, and
  replaced-plan rejection.
- v1/v2 serialization, corruption, migration, rollback, partial-write, and
  process-death fixtures.
- Reader entry-source and lifecycle tests proving navigation never commits.
- Widget tests for partial confirmation, stale draft, midnight, large text,
  Arabic RTL, English LTR, screen-reader labels, and page-604 completion.
- Integration tests for create→read→confirm→Home/Today Plan/widget summary,
  process death, offline persistence, migration, catch-up, extension, and reset.

## Spec 041 reconciliation

Spec 041 depends on the finalized Spec 023 v2 summary contract:

- Android performs no progress, assignment, debt, completion, or migration
  calculation.
- Flutter maps `WirdProgressSummary` into a localized, versioned
  `WirdProgressWidgetPayload`; native code validates/decodes/renders only.
- Every successful confirmation, catch-up, extension, reset, migration, local
  day rollover, locale change, and feature-gate change reconciles the snapshot.
- Stale or malformed snapshots render a safe “Open MeMuslim to refresh” state;
  they never infer progress or reuse an incompatible schema.
- Deep links open the Khatma hub or plan-scoped resume route. A widget tap never
  commits progress.
- Widget activation requires both Smart Khatma v2 and widget flags. Rollback
  disables provider exposure/refresh and clears or invalidates the snapshot
  without deleting plan data.
- External rollout stays blocked until v2 migration, in-app confirmation, Home,
  and Today Plan reconciliation pass end-to-end tests.

## Spec 043 roadmap order

Spec 043 must use this dependency order:

1. Progress correctness.
2. Reading-evidence model acceptance.
3. v1→v2 migration and rollback.
4. Daily assignment from verified progress.
5. Plan-scoped reader integration.
6. In-app daily completion/partial confirmation.
7. Home and Today Plan reconciliation.
8. Android widget payload reconciliation and controlled rollout.
9. Reminders, adherence, and listening integration.

No later item may be used to justify shipping an earlier untrusted dependency.

## Release and rollback gates

| Gate | Pass condition | Rollback action |
|---|---|---|
| Domain | All v2 calculations use one verified boundary | Disable v2 surfaces; retain v1/v2 data |
| Migration | Fixtures and internal cohort show no silent reinterpretation | Stop migration flag; old build reads untouched v1 |
| Reader | All navigation sources proven non-mutating | Disable plan-scoped session entry |
| UX | Confirmation is accessible, localized, and not repeatedly interruptive | Disable confirmation rollout; retain drafts |
| Dependents | Today Plan, Home, and widget consume one v2 summary | Hide affected surface independently |
| Privacy | Telemetry contains coarse outcomes only | Disable events remotely/configurationally |

Monitoring uses counts/rates only: migration success/failure category,
confirmation offered/saved/discarded, save failure, stale draft recovery, summary
mapping failure, and widget payload decode failure. It must not log pages,
ranges, plan IDs, reading duration, text, or exact activity timestamps.

## Task status and implementation sequence

- [x] Audit current progress mutation, storage, reader, Today Plan, Home, widget,
  flags, analytics, tests, and Specs 023/041/043.
- [x] Select the smallest evidence model and document rejected alternatives.
- [x] Define v2 domain, algorithms, migration, privacy, rollout, and rollback.
- [ ] Product/architecture approval of confirmation semantics and copy.
- [ ] Implement and test pure Dart v2 domain and migration (first slice only).
- [ ] Integrate plan-scoped reader and pending-draft recovery.
- [ ] Implement accessible Arabic/English confirmation UX.
- [ ] Reconcile Today Plan and Home with the v2 summary.
- [ ] Reconcile and gate Android widget payload/native stale behavior.
- [ ] Run full regression, migration, lifecycle, accessibility, native, and
  rollback validation before any production-readiness claim.

Reminders, adherence, listening progress, and UI polish remain deferred until
all preceding correctness gates pass.
