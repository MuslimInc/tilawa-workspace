# Quran Sessions — Admin Config Completion Plan

Status: **Proposed (2026-07-06).** Extends the SHIPPED
[pricing admin plan](quran_sessions_pricing_admin_plan.md); closes the remaining
gaps so the Admin Panel is the full operational control center. No production
code beyond this plan until tasks begin.

Goal: admins control rollout, markets, teachers, pricing, booking behavior,
video policy, payment availability, and QA — from `apps/tilawa_admin`, with the
backend (Cloud Functions) remaining the enforced source of truth.

## Already shipped (do NOT rebuild)

- Resolution hierarchy + fail-closed: `bookingEligibilityService.ts`
  (`resolvePricingWithOverride`, `assertBookingEligible`),
  `sessionPolicyResolver.ts` (`assertBookingPolicyConfigured`,
  `loadEffectiveMarketPolicy`).
- Teacher price override (free/fixed/inherit): `setTeacherSessionPricing`
  callable + `TeacherPricingPanelComponent` + ops script
  `quran-sessions:set-teacher-pricing`.
- Market pricing (enable + minSessionPrice + per-city): `market-pricing/` +
  `updateMarketPricingConfig`.
- Teacher approve/discoverable/active/whitelist: `teachers/` +
  `moderateTeacherProfile`.
- Audit (`quran_session_events`), teacher-can't-self-price rule, server quote
  consumed by Flutter (no client pricing decisions).

## Decisions (settled 2026-07-06)

1. **Per-market payment availability toggle.** Backend reads a market-config
   field `paymentProviderEnabled` (fallback to the `QURAN_SESSIONS_PAYMENT_
   PROVIDER_ENABLED` env when the field is absent). Admin edits it, but with a
   **hard confirmation** and a blocking warning: enabling paid booking while no
   real PSP is wired is dangerous (no wallet work in scope) — sandbox stays the
   only safe paid path. Fail-closed: absent/invalid ⇒ treated as disabled.
2. **Full build incl. QA inspector**, phased below.

Non-goals (reaffirmed): no wallet/PSP implementation, no voice/external meeting,
no guardian/parent logic, Flutter never source of truth.

## Config resolution (documented, already enforced)

- **Pricing:** teacher `sessionPriceOverride` (enabled) → market
  `minSessionPrice`/policy-version overlay → else fail closed. `0 ⇒ free`.
  `pricingSource` stamped on `feeSnapshot`.
- **Booking mode:** market `bookingMode` → platform default → fail closed.
- **Feature availability:** platform global flag → market `isEnabled` → teacher
  active/approved/discoverable/whitelisted → student eligibility → backend
  allowed actions.
- **Session mode:** platform/market `videoOnly` → teacher compatibility →
  backend rejects unsupported. (Voice/external stay disabled.)
- **Payment availability:** market `paymentProviderEnabled` → env fallback →
  fail closed (disabled).

## Firestore schema (additions)

```
quran_session_platform_config/global      # admin-writable via updatePlatformConfig
  quranSessionsEnabled, studentEntryEnabled, bookingEnabled: bool
  sessionMode: "videoOnly"
  defaultBookingMode: "requiresTutorApproval" | "autoConfirm"
  defaultJoinWindowLeadMs, defaultTutorApprovalSlaMs,
  defaultMinBookingNoticeMs, defaultMaxUpcomingPerStudent: number
  childAgeThreshold, globalAllow*TeacherStudent: (existing)
  updatedBy, updatedAt

quran_session_market_configs/{country}     # extended write surface
  isEnabled, minSessionPrice, currencyCode        (existing)
  studentBookingEnabled, teacherDiscoveryEnabled: bool
  bookingMode, minBookingNoticeMs, maxConcurrentUpcomingPerStudent,
  joinWindowLeadMs, tutorApprovalSlaMs, genderMatchingEnabled,
  teacherWhitelist: string[]|null,
  paymentProviderEnabled: bool                    (decision #1)
  updatedBy, updatedAt
```

All new fields are Cloud-Functions-only writes (firestore.rules); admins write
through callables, never direct client Firestore writes.

## Phased checklist

**Backend (source of truth):**
- **AC-B1** `updatePlatformConfig` callable (admin) — validate + write global
  doc + audit; fail-closed reads already exist.
- **AC-B2** Extend market write: `updateMarketConfig` (or extend
  `updateMarketPricingConfig`) for all policy fields + `paymentProviderEnabled`;
  resolver reads per-market payment flag (env fallback). Audit.
- **AC-B3** `getResolvedSessionConfig` callable (admin) — effective config +
  warnings for teacher/student/market (reuses `loadBookingEligibilityContext`);
  staging-only extras (verify slots, verify eligibility) guarded so QA overrides
  never run in production.
- **AC-B4** firestore.rules + rules tests for the new CF-only fields.

**Admin Panel (Angular):**
- **AC-A1** Global Settings page + facade/gateway/usecase → `updatePlatformConfig`.
- **AC-A2** Extend Market config page: full policy fields + per-market payment
  toggle with confirm-dialog + warning.
- **AC-A3** Resolved-config inspector (teacher/market): market price, override,
  effective price, booking enabled, discoverable, free/paid, warning banners
  ("paid but payment disabled", "market disabled", "teacher hidden",
  "no slots").
- **AC-A4** QA/Staging Tools page (staging-gated; hidden in production): verify
  slots, verify eligibility, resolved-config, mark-free shortcut.
- **AC-A5** Routes/nav/i18n wiring for the new pages.

**Tests:**
- **AC-T1** Backend vitest: override wins; override 0 ⇒ free; market fallback;
  paid blocked when payment disabled; free not blocked when payment disabled;
  missing config fails closed; teacher hidden/disabled cannot book; market
  disabled blocks; videoOnly enforced; QA overrides blocked in production;
  per-market payment flag read + env fallback.
- **AC-T2** Admin vitest: read/update platform + market config; resolved
  effective price; mark teacher free; QA controls hidden in prod; validation.
- **AC-T3** Flutter: booking UI reflects quote; free copy; paid+disabled blocked
  copy; no hardcoded pricing (extend existing).

**Docs & rollout:**
- **AC-D1** Update admin config docs, hierarchy, schema, CF enforcement, admin
  usage, staging QA guide, production rollout checklist, "make a teacher free"
  guide.

## Immediate use case (works today, no code)

Make `mu7ammadkamel@hotmail.com` free: Admin Panel → Teachers → Pricing → Free
(`setTeacherSessionPricing {enabled:true, amount:0}`), or
`npm run quran-sessions:set-teacher-pricing:apply -- --teacherId=<id> --mode=free`.
Backend resolves free; quote free; booking unblocks; `feeSnapshot=0`; other EG
teachers keep market pricing.
