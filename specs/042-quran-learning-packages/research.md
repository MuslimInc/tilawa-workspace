# Research: Quran Learning Packages

## Decision 1 — Prepaid package, manual renewal

**Decision**: Sell one fixed eight-session entitlement and require an explicit new purchase for renewal.  
**Rationale**: Matches the requested product while avoiding recurring billing, dunning, proration, app-store subscription policy, and confusing expiry behavior.  
**Alternatives considered**: Auto-renewing subscription; generic wallet credits; pay-per-session. Auto-renewal is too risky for the Egypt manual-payment pilot, wallet credits weaken product clarity, and pay-per-session does not create the intended commitment.

## Decision 2 — 35-day validity and 12-hour cutoff

**Decision**: Default to eight 30-minute sessions valid for 35 days, with credit restoration for learner cancellation at least 12 hours before start.  
**Rationale**: Supports a twice-weekly cadence plus modest recovery room and creates a simple, publishable policy.  
**Alternatives considered**: Calendar month; 30 days; unlimited carryover; 24-hour cutoff. Calendar months create uneven value, 30 days is brittle, unlimited carryover creates liability, and 24 hours is less suitable for family schedules.

## Decision 3 — Aggregate counters plus immutable movements

**Decision**: Store available/reserved/consumed counters on the package and write deterministic immutable movements atomically.  
**Rationale**: Fast balance reads and bounded cost while preserving audit and reconciliation evidence.  
**Alternatives considered**: Compute balance from all movements; counters without ledger. Full reduction creates unbounded reads; counters alone are not auditable.

## Decision 4 — Package order separated from entitlement

**Decision**: Pending manual payment creates an order; only admin confirmation creates an entitlement.  
**Rationale**: Prevents unpaid credits and makes confirmation/rejection idempotent.  
**Alternatives considered**: Create an inactive package immediately. That complicates ownership, expiry, and duplicate confirmation handling.

## Decision 5 — Existing booking lifecycle remains authoritative

**Decision**: Add an optional package entitlement source to the current individual booking path.  
**Rationale**: Reuses slot locks, authorization, scheduling, cancellation, no-show, completion, notifications, and video delivery.  
**Alternatives considered**: Separate package booking engine. It would duplicate high-risk lifecycle logic.

## Decision 6 — Compatibility meeting is bounded

**Decision**: One short non-credit meeting per learner-teacher pair, with platform-level limits and support review.  
**Rationale**: Reduces teacher-fit risk without creating an unlimited free-learning loophole.  
**Alternatives considered**: Free full lesson; no trial; unlimited interviews.

## Decision 7 — Progress is structured and parent-safe

**Decision**: Store goal/baseline and structured reports; separate safe feedback from private moderation/teacher notes.  
**Rationale**: Makes progress measurable while protecting children and teachers.  
**Alternatives considered**: Free-text notes only; session recordings. Free text is hard to measure, and recordings add disproportionate privacy and storage risk.

## Decision 8 — Curated marketplace before open marketplace

**Decision**: Launch with a teacher whitelist and verified profile evidence.  
**Rationale**: Marketplace liquidity is less important than reliable supply, parent trust, and supportable operations in the pilot.  
**Alternatives considered**: Let every approved teacher sell packages immediately.

## Decision 9 — Groups are a separate gated aggregate

**Decision**: Retain the individual-only guard for MVP; later introduce cohort, enrollment, capacity, schedule, per-learner attendance, and privacy models.  
**Rationale**: A group is not an individual booking with more participant ids.  
**Alternatives considered**: Add a capacity field to bookings. It fails entitlement, privacy, attendance, minimum enrollment, and waitlist needs.

## Decision 10 — Expansion is market-scoped and evidence-gated

**Decision**: Every market owns product, currency, payment, language, legal, teacher, support, and rollout configuration.  
**Rationale**: Prevents Egypt assumptions from leaking globally and aligns with existing market gating.  
**Alternatives considered**: One global catalog and currency conversion.

