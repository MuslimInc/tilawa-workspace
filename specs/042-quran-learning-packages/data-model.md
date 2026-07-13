# Data Model: Quran Learning Packages

## PackagePlan

Market-scoped product configuration.

Fields: `planId`, `marketCode`, localized name/description, `sessionCount=8`, `sessionDurationMinutes=30`, `validityDays=35`, `cancellationCutoffHours=12`, EGP price, currency, sale status, compatibility allowance, eligible teacher ids/rules, child policy, extension policy, policy version, audit fields.

Validation: positive price; eight sessions for MVP; supported duration/validity; Egypt/EGP only while MVP gate is active; video-only; no auto-renew flag.

State: `draft → active → paused → retired`. Purchased snapshots survive plan change.

## PackageOrder

Pre-activation purchase request.

Fields: `orderId`, `planId`, learner/guardian/teacher ids, market/city, immutable terms snapshot, payment instruction snapshot/version, unique payment reference, status, expiry, rejection reason, confirmed/rejected actor/time, resulting `packageId`, idempotency key, audit fields.

State: `pending_payment → confirmed | rejected | expired | cancelled`. Terminal decisions are idempotent.

## StudentPackage

Authoritative entitlement aggregate.

Fields: `packageId`, order/plan/learner/guardian/teacher ids, market, snapshot, `availableCredits`, `reservedCredits`, `consumedCredits`, `restoredCredits`, `expiredCredits`, adjustment totals, activation/expiry/completion times, status, version, last movement, policy version, audit fields.

Invariant: initial credits + restorations + positive adjustments = available + reserved + consumed + expired + negative adjustments. All values are non-negative. Sum of available/reserved/consumed/expired is bounded by net issued credits.

State: `active → completed | expired | cancelled | suspended`; temporary operational hold is represented separately from terminal state.

## PackageCreditMovement

Immutable child record keyed by deterministic event id.

Fields: `movementId`, package id, type (`issue`, `reserve`, `consume`, `restore`, `expire`, `adjust_positive`, `adjust_negative`), quantity, booking/session/order reference, reason code, actor/system event, idempotency key, policy version, created time.

Rules: never updated/deleted by clients; one movement per semantic event; adjustments require privileged actor and rationale.

## Booking/Session Additions

Optional fields: `packageId`, `packagePlanId`, `packageOrderId`, `packageCreditReservationMovementId`, `packageCreditFinalMovementId`, entitlement source snapshot. Absence preserves existing pay-per-session behavior.

## CompatibilityMeeting

Fields: learner/guardian/teacher, slot/session, status, duration, allowance key, baseline, proposed goal, recommended cadence, fit outcome, teacher safe note, timestamps.

State: `requested → scheduled → completed | declined | cancelled | no_show`.

## LearningPlan

One per package: goal type, baseline, target surah/ayah/range, memorization and review strategy, cadence, teacher/learner agreement, status, outcome summary, recommended next step.

## LessonReport

One per completed package session: attendance, covered material, memorization/recitation assessment, recurring mistake codes, homework, safe note, private teacher/admin note boundary, submission time, revision history.

## GuardianLink

Existing or extended verified relationship: guardian user, child user, verification/status, scopes, creation/revocation audit. Package reads require active oversight scope.

## TeacherVerificationProfile Additions

Verified subjects, languages, ijazah evidence status, child-teaching eligibility, compatibility eligibility, package market eligibility, verified review summary, response/cadence metadata. Public projection excludes private evidence files.

## PackageOperationAudit

Append-only privileged operation: target ids, operation, before/after bounded summary, actor/role, reason, request id, timestamp, outcome. No payment proof or lesson content.

## Future CohortPlan / CohortEnrollment

Cohort defines teacher, curriculum, level, age band, gender policy, capacity 4–6, minimum enrollment, fixed schedule, market price, dates, and state. Enrollment links one learner entitlement/guardian and tracks per-learner attendance/credit. Cohort data is not stored on `StudentPackage` during MVP.

## Index and Query Intent

- Plans: market + status.
- Orders: status + created time; payment reference exact lookup; learner + created time.
- Packages: learner/guardian/teacher + status + expiry.
- Movements/reports: parent id + created/session time with bounded pagination.
- Compatibility: learner+teacher allowance key; teacher + scheduled time.
- All proposed composite indexes require emulator/query validation before deploy.

