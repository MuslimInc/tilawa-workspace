# ADR-005: Quran Sessions lifecycle legacy bridge

## Status

Accepted

## Context

Quran Sessions domain introduced `SessionLifecycleStatus` as canonical state
machine, while existing app/UI paths still depend on legacy
`BookingStatus` and `QuranSessionStatus`.

Directly replacing legacy enums in one step risks breaking read paths before
Cloud Functions migration (Phase 3) and UI wiring (Phase 4).

## Decision

Adopt additive compatibility bridge in package domain:

1. Keep legacy enums for current read/write paths.
2. Add optional `lifecycleStatus` to `QuranBooking` and `QuranSession`.
3. Expose `effectiveLifecycleStatus` getter that prefers `lifecycleStatus` and
   falls back to deterministic mapping from legacy enums.
4. Route new orchestration logic through `SessionAggregate` + lifecycle guard;
   legacy entities remain read-compatible.

## Consequences

- Safe incremental migration without immediate UI breakage.
- Ambiguous legacy states (`cancelled`, `noShow`) require fallback assumptions
  until lifecycle backfill completes.
- Backfill and Phase M3 cleanup stay mandatory to remove ambiguity.

## Follow-up

- Phase 3 migration script must backfill `lifecycleStatus` for all legacy rows.
- Phase 4+ should stop consuming raw legacy enums in mutation paths.
