# Callable Contracts: Quran Learning Packages

All mutations require authentication, valid session epoch where applicable, App Check according to environment policy, server authorization, normalized typed failures, idempotency, and audit. Clients never write operational documents directly.

## Student / Guardian Commands

### `createQuranPackageOrder`

Input: `planId`, `teacherId`, learner id when guardian acts, compatibility meeting id if present, client idempotency key.  
Output: order id/status, immutable terms, payment reference/instructions, expiry.  
Failures: market/plan/teacher/learner not eligible, guardian required, pricing changed, active-order conflict, trial requirement unmet.

### `cancelQuranPackageOrder`

Input: order id, reason, idempotency key.  
Output: terminal order state. Only owner/guardian may cancel a pending order.

### `createQuranPackageBooking`

Input: package id, teacher slot/start/end, video call/provider fields, note, idempotency key.  
Output: booking/session ids, lifecycle, remaining/reserved balance.  
Failures: package inactive/expired/exhausted/wrong teacher, slot unavailable, participant/market ineligible. Transaction reserves credit and slot atomically or has no effect.

### `requestCompatibilityMeeting`

Input: teacher id, learner id when guardian acts, slot, idempotency key.  
Output: meeting/session status and remaining allowance.  
Failures: allowance exceeded, teacher/learner ineligible, slot unavailable.

### `getQuranPackage`

Input: package id.  
Output: role-safe package summary, balance, plan/teacher snapshot, bounded recent activity, learning plan/summary references.

## Teacher Commands

### `completeCompatibilityMeeting`

Input: meeting id, baseline, proposed goal, cadence, fit outcome, safe note.  
Output: completed recommendation. Assigned teacher only.

### `submitQuranLessonReport`

Input: package/session ids, attendance, covered material, assessment, mistake codes, homework, safe note, optional private note, idempotency key.  
Output: report status and package progress projection. Requires completed/eligible session and assigned teacher.

### `completeQuranPackageSummary`

Input: package id, outcome, remaining work, recommendation.  
Output: terminal summary. Assigned teacher or authorized operator; duplicate submission is safe.

## Admin Commands

### `updateQuranPackagePlan`

Input: full lossless plan contract including market, price, count, duration, validity, cutoff, eligibility, compatibility and extension policy, version.  
Output: authoritative plan and version. Granular package-config admin claim required.

### `resolveQuranPackagePayment`

Input: order id, outcome `confirm|reject`, rationale/note, idempotency key.  
Output: order and optional package id/balance. Confirmation creates one package; rejection creates none.

### `adjustQuranPackageCredit`

Input: package id, signed bounded quantity, reason code, rationale, idempotency key.  
Output: authoritative balance and movement id. Finance/support claim and non-empty rationale required.

### `extendQuranPackageValidity`

Input: package id, bounded days/new expiry, reason, idempotency key.  
Output: authoritative expiry and audit id.

### `transferQuranPackageTeacher` *(post-MVP support gate)*

Input: package id, replacement verified teacher, reason, effective schedule policy.  
Output: updated assignment/version. Must not mutate purchased price or historic reports.

## Existing Lifecycle Integration

Existing cancel, reject, reschedule, no-show, completion, expiry, dispute, and compensation handlers call a shared package-credit service using deterministic event ids. They MUST NOT duplicate package policy in each callable. Existing non-package bookings remain unchanged.

## Typed Failure Families

- Package catalog/market: unavailable, changed, not eligible.
- Order/payment: pending conflict, expired, already resolved, reference mismatch.
- Entitlement: inactive, expired, exhausted, wrong teacher, invariant violation.
- Compatibility: required, limit exceeded, already used.
- Guardian/child: guardian required, unauthorized guardian, child policy violation.
- Reporting: session not eligible, report required, report already terminal.
- Authorization/idempotency/internal: consistent with existing lifecycle mapping.

