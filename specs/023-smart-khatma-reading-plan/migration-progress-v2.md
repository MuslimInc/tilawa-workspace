# Smart Khatma progress v1 to v2 migration

## Decision

Use dual-read/single-write with an explicit pending-confirmation migration.
Never reinterpret v1 `current_page` as verified reading.

## Why v1 cannot be silently promoted

In v1, `current_page` is initialized from global last-read and later advanced
by reader navigation. It is therefore a mixed navigation/position value. Even
`current_page - 1` is only the furthest defensible **suggestion**, not verified
truth: the transitions could have occurred outside Khatma or accidentally.

For a valid legacy plan:

```text
legacySuggestedThrough =
  if current_page > start_page then current_page - 1 else null
verifiedCompletedThrough = start_page - 1
```

For a legacy completed plan, the suggestion may be page 604, but the user must
still confirm completion. No legacy page is silently declared verified.

## Keys and states

- Read v2 first: `smart_khatma.active_plan.v2`.
- If absent, read v1: `smart_khatma.active_plan.v1`.
- Write only v2 plan/session formats after migration starts.
- Keep v1 byte-for-byte during rollout and rollback window.
- Store pending migration as a v2 plan plus a v2 draft marked by application
  state as requiring legacy review; do not expose the old object to normal v2
  calculations before review.
- After rollout stability, deletion of v1 requires a separately approved data
  retention task; it is not part of migration success.

## Migration algorithm

```text
loadActiveKhatma():
  if valid v2 exists:
    return v2

  rawV1 = read(v1Key)
  if rawV1 absent:
    return empty
  if rawV1 malformed or violates v1 invariants:
    preserve rawV1 unchanged
    copy once to local quarantine key with no analytics payload
    return recoverableMigrationFailure

  legacy = parseV1(rawV1)
  proposed = KhatmaPlanV2(
    schedule fields copied without semantic changes,
    verified = legacy.startPage - 1,
    status = active,
    progressSemanticsVersion = 2)
  suggestion = legacy.currentPage > legacy.startPage
    ? legacy.currentPage - 1
    : null
  persist proposed + optional dated migration draft atomically/ordered safely
  return pendingLegacyConfirmation
```

If the user confirms through the suggested page, use the normal v2 confirmation
command. If the user adjusts, apply the selected boundary. If they decline,
retain zero verified pages for this plan and discard only the draft. The screen
must make the consequence clear without guilt.

## Rollback

Old builds continue reading untouched v1. During the controlled rollout, v2
must not back-write v1 because doing so would reintroduce ambiguous semantics
and make rollback corrupt newer confirmations. Rollback therefore restores the
old UI with its last pre-migration snapshot; it may temporarily show stale
progress but cannot destroy v2. Re-enabling v2 resumes from v2.

If product requires rollback builds to display new confirmed progress, that
requires a compatible old-build patch and is outside this migration; dual-write
is explicitly rejected.

## Failure and recovery

- Failure before v2 plan persistence: v1 remains authoritative and untouched.
- Plan persisted but draft write failed: mark migration incomplete and retry;
  never expose the proposed plan as user-confirmed.
- Confirmation write failed: retain the pending draft and v1 backup.
- Malformed v1/v2: preserve raw bytes in their original key and a bounded local
  quarantine copy; surface recovery/reset/export-diagnostics choices. Never
  include raw religious data in telemetry.
- Repeated migration is idempotent: a valid v2 object prevents rebuilding it
  from v1.

## Rollout gates

1. Pure domain boundary and serialization tests pass.
2. Golden migration fixtures cover valid, empty, completed, page-604,
   malformed, unknown-enum, invalid-date, and partial-write states.
3. Internal cohort validates confirmation copy and rollback.
4. Metrics contain only coarse migration outcome and error category.
5. Smart Khatma remains remotely/launch gated; Today Plan, Home progress, and
   widget progress stay gated until they consume v2 summaries.
