# Research: Learn Quran Admin and Backend Completion

## Decision: Reuse existing privileged resolution callables

**Rationale**: `resolveSessionReport` already requires admin authorization and
a reason for terminal outcomes, then writes state and audit data.
`resolveSessionDispute` already validates the dispute state, resolution and
reason, and owns its idempotent lifecycle/financial effects.

**Alternatives considered**:

- Direct Firestore writes — rejected because operational writes are
  server-authorized and rules deny direct client writes.
- A new combined moderation callable — rejected because it duplicates existing
  validation, audit, and idempotency behavior.

## Decision: Correct the admin configuration contract before schema changes

**Rationale**: The platform callable accepts `childAgeThreshold` and falls back
to 14 when omitted. The global form does not round-trip it. The market callable
does not accept `sessionMode`, although the market UI shows an editable control.
The smallest safe change is to round-trip the age field and display video-only
as fixed market capability.

**Alternatives considered**:

- Persist market-level session mode — rejected because video-only is the approved
  scope and a configurable no-op would be misleading.
- Document the existing limitation — rejected because it permits a lossy write.

## Decision: Preserve bounded reads after moderation

**Rationale**: Existing report/dispute facades use paginated repositories. A
successful mutation refreshes the current detail and reconciles or reloads only
the current page, never a historical full queue.

**Alternatives considered**:

- Live subscribe to every work item — rejected due to unbounded reads.
- Invent a terminal result optimistically — rejected because server state and
  financial/lifecycle effects are authoritative.

## Decision: Keep App Check deployment-controlled

**Rationale**: Learn Quran callable options read
`QURAN_SESSIONS_ENFORCE_APP_CHECK` and default to false. The remaining work is
staging evidence and governance, not an admin-panel switch or unconditional
source change.

## Verified Sources

- `apps/tilawa_admin/src/app/features/quran-sessions/global-settings/global-settings.component.ts`
- `apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/market-pricing.component.ts`
- `apps/tilawa_admin/src/app/features/quran-sessions/market-pricing/market-pricing.facade.ts`
- `apps/tilawa_admin/src/app/features/quran-sessions/session-report-detail/session-report-detail.component.html`
- `apps/tilawa_admin/src/app/features/quran-sessions/session-dispute-detail/session-dispute-detail.component.html`
- `apps/tilawa_admin/src/app/core/data/repositories/firebase-session-moderation.gateway.ts`
- `functions/src/quranSessions/updatePlatformConfig.ts`
- `functions/src/quranSessions/updateMarketPricingConfig.ts`
- `functions/src/quranSessions/sessionReportCallables.ts`
- `functions/src/quranSessions/sessionDisputeCallables.ts`
- `functions/src/quranSessions/sessionCallableOptions.ts`

