# Quran Sessions — Admin Configuration & Operations

**Last updated:** 2026-07-10 (Spec 039 — supported fields aligned with callable contracts)

## Overview
This document outlines the administrative configuration capabilities for Quran Sessions. Operations and settings are managed through the Tilawa Admin Panel (Angular) and backed by secure Firebase Cloud Functions.

## Write ownership

All operational writes are **server-authorized callables**; the Admin Panel
never writes these Firestore documents directly (rules deny it, and admin
components go through the domain use-case/gateway layers — the single runtime
binding is `SESSION_MODERATION_GATEWAY` → `FirebaseSessionModerationGateway`
in `apps/tilawa_admin/src/app/app.config.ts`):

| Operation | Callable | Owner of side effects |
|---|---|---|
| Global policy save | `updatePlatformConfig` | Server: validation + audit event |
| Market policy save | `updateMarketPricingConfig` | Server: validation, city overrides, audit event |
| Report triage/closure | `resolveSessionReport` | Server: terminal metadata, idempotency, audit event |
| Dispute resolution | `resolveSessionDispute` | Server: lifecycle, refund/compensation records, idempotency, audit, notifications |

## Configuration Hierarchy

Configurations flow through a hierarchy from Global → Market → Teacher:

1. **Global Platform Settings** (`quran_session_platform_config/global`)
   - Feature flags: Enable/disable core modules (Quran Sessions, Student Entry, Booking) and tutor-application entry.
   - Global defaults: `bookingMode`, `defaultJoinWindowLeadMs`, `defaultTutorApprovalSlaMs`, `defaultMinBookingNoticeMs`, `defaultMaxUpcomingPerStudent`, `childAgeThreshold`, and market availability (`enableForAllMarkets` / `enabledMarketCodes`).
   - `sessionMode` is fixed to `videoOnly` platform-wide; the callable rejects any other value.
   - `childAgeThreshold` round-trips through the Global Settings form — saving unrelated fields preserves a non-default threshold (Spec 039 US1).
   - Modifiable via the **Global Settings** page in the Admin Panel.

2. **Market Config Overrides** (`quran_session_market_configs/{countryCode}`)
   - Pricing bounds (base `minSessionPrice`) and `currencyCode`, plus per-city price overrides.
   - Market-specific policies accepted by `updateMarketPricingConfig`: `isEnabled`, `studentBookingEnabled`, `teacherDiscoveryEnabled`, `bookingMode`, `minBookingNoticeMs`, `maxConcurrentUpcomingPerStudent`, `joinWindowLeadMs`, `tutorApprovalSlaMs`, `genderMatchingEnabled`, `teacherWhitelist`, `paymentProviderEnabled`, `manualPaymentEnabled`.
   - **There is no market-level `sessionMode`.** Delivery is video-only everywhere; the Market Pricing page renders this as fixed guidance, not an editable control (Spec 039 US1).
   - Modifiable via the **Market Pricing** page in the Admin Panel.
   - **Important:** Payment is fail-closed. If `paymentProviderEnabled` is false for a market, users cannot initiate checkout flows for teachers in that market. Do not enable until Stripe/Paymob accounts are properly linked and verified.

3. **Teacher Pricing Preferences** (`quran_teacher_profiles/{teacherId}/pricing/{countryCode}`)
   - Teacher-specific rate within the market's min/max bounds.
   - Inherits policies from Market and Global config.

## Admin Tools

### 1. Global Settings Page
Located at `/quran-sessions/global-settings`.
Use this to manage the master kill-switches and platform-wide defaults.

### 2. Market Pricing Page
Located at `/quran-sessions/market-pricing`.
Use this to configure individual countries (e.g., EG, SA, AE) and their cities. You can enable payments here and specify unique policy overrides for that market.

### 3. Resolved Config Inspector
Located at `/quran-sessions/resolved-config-inspector`.
A diagnostic tool to determine exactly which policies apply to a specific Student and Teacher interaction. It calls the `getResolvedSessionConfig` Firebase function to output the merged configuration tree (Global → Market → Teacher), resolving feature flags and payment provider status securely on the backend.

### 4. Create Test Session
Located at `/quran-sessions/create-test-session`.
Allows QA and Admins to bypass normal scheduling constraints to instantly create sessions between specified students and teachers. Extremely useful for verifying video infrastructure and report workflows in Staging.

### 5. Session Reports (triage and closure)
Located at `/quran-sessions/reports`; each report opens a detail page.
Open reports can be set **under review** (confirmation dialog) or closed as
**resolved**/**dismissed** — terminal closures require a rationale, which the
server stores with the resolver id and timestamp. Terminal reports render
read-only. All transitions go through `resolveSessionReport` (idempotent,
audited); the UI refreshes authoritative state after each action.

### 6. Session Disputes (resolution)
Located at `/quran-sessions/disputes`; each dispute opens a detail page.
Open disputes accept one of five outcomes: favor student (creates one
manual-pending refund record), with compensation (creates one manual-pending
compensation record), favor teacher, rejected, or closed (no financial
record). Every outcome requires a rationale; the effect of the selected
outcome is shown before confirmation. The server owns lifecycle, financial
records, idempotency, and audit via `resolveSessionDispute`; resolved
disputes render read-only.
