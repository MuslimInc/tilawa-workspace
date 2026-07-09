# Implementation Plan: Learn Quran Admin and Backend Completion

**Branch**: `039-learn-quran-admin-backend` | **Date**: 2026-07-10 | **Spec**: [spec.md](spec.md)

## Summary

Complete only the verified operational gaps: make global and market policy
editing lossless and truthful, connect existing report/dispute resolution
callables to the admin detail screens, and define App Check staging evidence.
The admin remains a client of server-authorized callables; direct Firestore
writes remain denied.

## Technical Context

**Admin**: Angular 21.2, TypeScript 5.9, AngularFire 21, Firebase Web SDK 12.  
**Backend**: Node 22, TypeScript 5.7, Firebase Functions v2, Admin SDK 13,
Cloud Firestore.  
**Testing**: Angular/Vitest unit and component tests; Node test runner; Firestore
emulator integration and rules tests.  
**Performance target**: no global scans or unbounded reads; a resolution is a
single callable mutation followed by a targeted detail/current-page refresh.  
**Constraints**: video-only delivery, Arabic/English localization, existing
paginated queries, no direct operational writes, no device/payment/mobile scope.

## Current-State Findings

| Verified area | Current behavior | Planned completion |
|---|---|---|
| Global policy editor | It omits `childAgeThreshold`; the callable writes a fallback when omitted. | Round-trip the field and test unchanged values. |
| Market policy editor | It renders `sessionMode`; the market callable accepts no such field. | Represent video-only as fixed, not editable. |
| Report detail | Queue and route exist, but the detail is read-only. | Add a typed resolution boundary, confirmation UI, and state refresh. |
| Dispute detail | The callable/gateway exist, but the detail is read-only. | Expose allowed outcomes with terminal-state protection. |
| App Check | Enforcement is controlled by `QURAN_SESSIONS_ENFORCE_APP_CHECK` and defaults off. | Define staging evidence, rollback, and production promotion criteria. |

## Constitution Check

*Gate reviewed before and after design: PASS.*

- **Clean Architecture**: admin components use facade/use-case/gateway layers;
  callable invocation remains in data repositories.
- **Reactive state and routing**: existing routes and signal-based facades are
  retained; no route or state-management migration is needed.
- **UI Kit and localization**: reuse existing admin cards, dialogs, loading/error
  states, ARB files, and RTL document handling.
- **Responsive UI**: test narrow desktop, RTL, and increased text scale; hide
  actions for terminal states.
- **Performance**: retain bounded pagination; do not add collection listeners or
  reload every page after a mutation.
- **Diagnostics**: preserve server audit events; surface callable failures
  without logging sensitive report text client-side.
- **Testing**: include component, gateway/use-case, integration, authorization,
  and staging-evidence tasks.
- **Safe delivery**: changes are additive at the admin boundary, with Hosting
  rollback and explicit App Check rollback.

## Performance Impact Analysis

### Backend / Firebase

- **Queries**: existing direct detail reads and existing resolution callables.
- **Reads/writes**: one targeted callable mutation plus its existing audit write.
- **Indexes**: none anticipated; existing paginated query contracts remain.
- **Global scans / unbounded queries**: No / No.
- **Complexity**: detail resolution remains O(1); queue rendering remains O(page
  size).
- **Cost**: no material added Firestore cost; do not reload historical pages.

### Admin UI

- Refresh the affected detail and reconcile only the current bounded page.
- Add one ephemeral pending-action/dialog state; do not duplicate the queue cache.
- No repeated computations or new hot rendering path.

### Audio/Video Provider

- No provider change. Video-only is displayed accurately; join/provider work is
  explicitly out of scope.

### Verdict

Performance safe if implementation retains the existing paginated list and
authoritative detail fetch rather than adding a full-collection subscription.

## Design Decisions

1. **Reuse existing resolution callables.** `resolveSessionReport` and
   `resolveSessionDispute` already enforce authorization, validation,
   idempotency, lifecycle effects, and audit. Do not recreate that logic.
2. **Match UI to accepted configuration contracts.** Add the age threshold to
   the global round trip. Remove the market-level editable session-mode control
   instead of adding unsupported policy schema.
3. **Require rationale for terminal results.** Disable UI submission while
   pending; refresh from server after success. Server idempotency remains the
   duplicate-effect protection.
4. **Treat App Check as operations work.** Do not change its default in source.
   Require staging results, a named owner, observed rejection metrics, and a
   rollback before production enforcement.

## Project Structure

```text
apps/tilawa_admin/
├── l10n/app_{en,ar}.arb
└── src/app/
    ├── app.config.ts
    ├── core/{application/facades,data/repositories,domain/{repositories,usecases}}/
    └── features/quran-sessions/
        ├── global-settings/
        ├── market-pricing/
        ├── session-report-detail/
        └── session-dispute-detail/

functions/src/quranSessions/
├── updatePlatformConfig.ts
├── updateMarketPricingConfig.ts
├── sessionReportCallables.ts
├── sessionDisputeCallables.ts
└── sessionCallableOptions.ts

specs/039-learn-quran-admin-backend/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/admin-callable-contracts.md
└── tasks.md
```

**Structure Decision**: retain the existing Angular feature/facade/domain/data
layers and Firebase callable boundary. No new app, collection, or route is
required.

## Delivery and Rollback

- Admin rollback: deploy the prior Hosting artifact; no data migration exists.
- Callable rollback: preserve backward-compatible callable contracts and test in
  the emulator before deployment.
- App Check rollback: redeploy with the prior enforcement environment value; do
  not mutate booking/session data.
- Stop promotion if configuration round-trip, terminal resolution,
  authorization-negative, or attestation critical-flow evidence fails.

## Complexity Tracking

No constitutional violation or waiver is required.
