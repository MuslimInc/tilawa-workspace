# Quran Sessions — Product Decision Checklist

**Purpose:** Block implementation of business logic that depends on unresolved product decisions.  
**Rule:** Do not guess. Check one option per question; product owner signs off.  
**Last updated:** 2026-07-03 — **All 42 questions answered** (product owner sign-off)

---

## How to use

1. Product owner reviews each question in order of section priority (Booking → Lifecycle → Fees → Video).
2. Check **exactly one** option (A/B/C/D) per question.
3. When all **P0** questions in a section are answered, engineering may implement that section's blocked flows.
4. Link resolved answers in `production-domain-model.md` § Decisions log.

---

## Booking flow

### Q-BK-01: Default booking confirmation path for production

- [ ] **A.** Auto-confirm → `scheduled` immediately after slot lock (no tutor step)
- [ ] **B.** Always `pendingTutorApproval` until teacher accepts
- [x] **C.** Platform default from Admin Panel; overridable per market
- [ ] **D.** Per-teacher setting (each teacher chooses auto vs approval)

**Recommended default:** C — code already has `QuranTutorBookingMode` + CF branching; staging uses `autoConfirm`, `play_production` hint uses `requiresTutorApproval`.

**Production impact:** Controls CF `createSessionBooking` initial lifecycle, student confirmation copy, slot lock duration, and whether pending requests consume `maxConcurrentUpcomingPerStudent`.

---

### Q-BK-02: Where should `pendingTutorApproval` sessions appear for students?

- [x] **A.** Separate "Pending" tab (not Upcoming)
- [ ] **B.** Upcoming tab with "Awaiting teacher" badge
- [ ] **C.** Notifications only; hidden from session lists until accepted/rejected
- [ ] **D.** Booking history screen only (not My Sessions)

**Recommended default:** A — satisfies "rejected/expired never in Upcoming" while keeping visibility.

**Production impact:** List queries, `GetStudentSessionsUseCase` reclassification, push notification templates.

---

### Q-BK-03: Slot hold TTL while `pendingPayment`

- [x] **A.** 15 minutes (platform default BK-05)
- [ ] **B.** 30 minutes
- [ ] **C.** Market-configurable only (no code fallback)
- [ ] **D.** No soft hold — hard lock only after payment capture

**Recommended default:** C with A as documented emergency fallback in `StandardSchedulingPolicy`.

**Production impact:** `expirePendingReservations` CF schedule, double-booking risk, wallet UX.

---

### Q-BK-04: Idempotency key scope for booking creation

- [ ] **A.** Client-generated UUID per submit tap (retry-safe)
- [ ] **B.** Server-generated from `(studentId, slotId, callType)` hash
- [x] **C.** Both client idempotency key + server dedupe window (24h)
- [ ] **D.** No idempotency in MVP production (accept duplicate risk)

**Recommended default:** C — spec BK-10 requires idempotency; duplicates are a support cost.

**Production impact:** CF `createSessionBooking`, Firestore unique indexes, client retry UX.

---

### Q-BK-05: Gender matching rule enforcement

- [ ] **A.** Hard block at booking (current eligibility chain)
- [ ] **B.** Warn only; student may override once per account
- [x] **C.** Market-configurable (some markets off)
- [ ] **D.** Remove gender rule entirely for production v1

**Recommended default:** C — safety policy varies by market; must be admin-configured not hardcoded.

**Production impact:** `ValidateBookingEligibilityUseCase`, admin policy editor, support escalations.

---

## Teacher approval

### Q-TA-01: Tutor approval SLA before auto-expire

- [ ] **A.** 24 hours → `expired` + slot released
- [ ] **B.** 48 hours
- [ ] **C.** Until slot start time (no auto-expire)
- [x] **D.** Admin-configurable per market

**Recommended default:** D with A as global default — transition `expireTutorApproval` exists but TTL is unset in product spec.

**Production impact:** Scheduled CF job, student refund/compensation on expiry, teacher notification cadence.

---

### Q-TA-02: Can teacher partially accept (counter-propose slot)?

- [ ] **A.** Accept or reject only
- [ ] **B.** Reject with suggested alternate slots (new booking flow)
- [ ] **C.** Redirect to reschedule request from pending state
- [x] **D.** Post-v1 feature — reject only for now

**Recommended default:** D — reschedule from `pendingTutorApproval` is not in transition table today.

**Production impact:** New actions in `SessionTransitionTable`, teacher dashboard UI scope.

---

### Q-TA-03: Student cancel while `pendingTutorApproval`

- [x] **A.** Allowed anytime → `cancelledByStudent` + slot released
- [ ] **B.** Allowed only before teacher opens request
- [ ] **C.** Blocked until teacher responds
- [ ] **D.** Allowed with reason; counts toward student cancel metric

**Recommended default:** A + D — transition table already allows `cancelByStudent` from `pendingTutorApproval`.

**Production impact:** Cancellation policy side effects (refund none for free), analytics.

---

## Availability

### Q-AV-01: Minimum booking notice (`minNoticeMinutes`)

- [ ] **A.** 60 minutes global default
- [ ] **B.** 24 hours for production quality
- [x] **C.** Market-configurable only (admin panel)
- [ ] **D.** Per-teacher override allowed

**Recommended default:** C with A as platform fallback — never hardcode in app.

**Production impact:** Slot generator filter, teacher override UI, timezone edge cases.

---

### Q-AV-02: Teacher blocks slot after partial bookings same day

- [ ] **A.** Block removes slot from availability immediately
- [x] **B.** Block creates override doc; incremental delete (perf-first)
- [ ] **C.** Block only affects future generated slots in weekly template
- [ ] **D.** Admin-only block (teachers request via support)

**Recommended default:** B — aligns with performance-first override model in `docs/quran_sessions/baseline_performance_audit.md`.

**Production impact:** Firestore write patterns, dashboard refresh latency.

---

### Q-AV-03: Concurrent upcoming session cap per student

- [ ] **A.** 3 (BK-03 default)
- [ ] **B.** 1 for production simplicity
- [x] **C.** Market-configurable
- [ ] **D.** Unlimited for v1

**Recommended default:** C with A as default — prevents queue abuse without blocking power users in some markets.

**Production impact:** Eligibility validation, error copy, admin policy schema.

---

## Cancellations

### Q-CN-01: Student late-cancel refund fraction (paid sessions)

- [ ] **A.** 0% refund within 24h (CN-03 default)
- [ ] **B.** 50% within 24h
- [x] **C.** Market-configurable tiers only
- [ ] **D.** Always full refund to wallet (goodwill v1)

**Recommended default:** C — `ConfigurableCancellationPolicy` exists; amounts must not be hardcoded.

**Production impact:** Wallet ledger, CF compensation executor, dispute volume.

---

### Q-CN-02: Block cancel within N minutes of start

- [ ] **A.** 60 minutes (CN-05 default)
- [ ] **B.** 120 minutes
- [ ] **C.** Disabled for free sessions; enabled for paid only
- [x] **D.** Market-configurable

**Recommended default:** D with A as platform default.

**Production impact:** `canStudentCancelQuranSession` policy wiring (partially client today — must be server-authoritative).

---

### Q-CN-03: Teacher cancel compensation to student

- [x] **A.** Auto session credit restore always (CN-06)
- [ ] **B.** Wallet credit + session credit
- [ ] **C.** Admin chooses per incident
- [ ] **D.** Free sessions: apology notification only

**Recommended default:** A for free; B for paid — compensation type array from admin config.

**Production impact:** `TransitionSideEffect.autoCompensateStudent`, financial ledger.

---

## Fees / pricing

### Q-FE-01: Production pricing model for v1

- [ ] **A.** Free only (beta continuation)
- [x] **B.** Fixed per-session from admin market config
- [ ] **C.** Teacher sets price within admin min/max band
- [ ] **D.** Subscription-only (no per-session)

**Recommended default:** B — `MarketConfig.minSessionPrice/maxSessionPrice` + teacher listing price already modeled.

**Production impact:** Payment CF activation, wallet UI, Play Store listing copy.

---

### Q-FE-02: Who sets session price shown at booking?

- [x] **A.** Admin market config only (single price per market)
- [ ] **B.** Teacher profile price within admin band
- [ ] **C.** Dynamic quote at booking time (server CF)
- [ ] **D.** Free with optional tip (post-session)

**Recommended default:** B — matches `QuranTeacher.price` resolved from market context.

**Production impact:** No hardcoded amounts in Flutter; admin panel price editor required.

---

### Q-FE-03: Egypt manual payment pilot handling

- [ ] **A.** Keep as presentation-only notice; booking still free server-side
- [ ] **B.** Block booking until off-app payment confirmed manually by admin
- [x] **C.** Remove pilot before production
- [ ] **D.** Integrate local PSP before any paid launch

**Recommended default:** C for production Go — `ManualPaymentPrice` is presentation-only and bypasses payment engine.

**Production impact:** Legal/compliance, booking confirmation semantics, support load.

---

### Q-FE-04: Platform commission settlement

- [ ] **A.** Deduct at booking capture (`platformCommissionPercent`)
- [x] **B.** Deduct at payout to teacher
- [ ] **C.** Invoice model (post-session)
- [ ] **D.** Zero commission v1

**Recommended default:** B — defers payout CF complexity; field exists on `MarketConfig`.

**Production impact:** Ledger schema, teacher statements, tax reporting.

---

## Admin configuration

### Q-AD-01: Policy edit workflow

- [ ] **A.** Admin panel live edit with audit trail
- [ ] **B.** Firestore console only until panel ships
- [x] **C.** Versioned policy docs with effective date
- [ ] **D.** GitOps — deploy policy JSON via CI

**Recommended default:** C — production needs rollback; panel UI is 🔴 per audit.

**Production impact:** CF policy resolver cache TTL, accidental misconfiguration risk.

---

### Q-AD-02: Market enable/disable granularity

- [ ] **A.** Country-level only
- [ ] **B.** City-level within country
- [x] **C.** Country + teacher whitelist during rollout
- [ ] **D.** Global on/off only

**Recommended default:** B — `CityConfig.isEnabled` already exists.

**Production impact:** Teacher discovery queries, eligibility failures, SEO/regional launch.

---

### Q-AD-03: Session fee configuration ownership

- [x] **A.** Tilawa Admin Panel exclusively (no client defaults)
- [ ] **B.** Admin + emergency JSON fallback in CF
- [ ] **C.** Bundled in app release (deprecated)
- [ ] **D.** Teacher self-service without admin band

**Recommended default:** A — user requirement: fees from admin panel, not hardcoded.

**Production impact:** Client must never display price without server field; offline cache rules.

---

## Video call behavior

### Q-VC-01: Production call modality exposure

- [x] **A.** In-app video only (no voice, no external links)
- [ ] **B.** Video + external meeting (teacher choice)
- [ ] **C.** Video + voice in-app; no external
- [ ] **D.** External only until WebRTC certified

**Recommended default:** A — matches user critical requirement "VIDEO CALL ONLY for now".

**Production impact:** `SessionModePolicy`, booking UI segments, teacher profile meeting link field, privacy policy.

---

### Q-VC-02: RTC provider for production video

- [ ] **A.** LiveKit (staging default)
- [ ] **B.** Agora
- [x] **C.** Provider-agnostic; server picks from enabled list
- [ ] **D.** Mock provider until SDK certified

**Recommended default:** C — `SessionCallProviderKind` + CF `enabledCallProviders`; prod currently `external,mock`.

**Production impact:** App binary size, token minting CF, Play compliance, call quality SLA.

---

### Q-VC-03: Join window — when may participants open call?

- [ ] **A.** Anytime from `scheduled` status
- [x] **B.** 15 minutes before `startsAt` until `endsAt`
- [ ] **C.** From `startsAt` − grace through `endsAt` + grace
- [ ] **D.** Teacher starts call; student joins after notification

**Recommended default:** B — reduces no-show noise; aligns with reminder policy.

**Production impact:** `canJoinSession` extension, join button UX, no-show detection timing.

---

### Q-VC-04: Teacher external meeting URL field

- [ ] **A.** Remove from production UI entirely
- [x] **B.** Keep in profile but hidden when video-only policy active
- [ ] **C.** Keep as fallback when in-app RTC fails
- [ ] **D.** Required for all teachers until RTC live

**Recommended default:** B — data may exist for migration; UI must not expose if Q-VC-01 = A.

**Production impact:** Profile screens, booking call-type picker, privacy disclosures.

---

## Session lifecycle

### Q-SL-01: Canonical status field during migration

- [ ] **A.** `lifecycleStatus` only; drop legacy `status` enums
- [x] **B.** Dual-write both fields until backfill complete
- [ ] **C.** Keep legacy for list queries; lifecycle for actions
- [ ] **D.** Server-only lifecycle; client maps to simplified UI enum

**Recommended default:** B short-term → A — dual enum (`QuranSessionStatus` vs `SessionLifecycleStatus`) causes mapper bugs today.

**Production impact:** Firestore indexes, list filters, admin panel, analytics.

---

### Q-SL-02: Is `confirmed` status required distinct from `scheduled`?

- [ ] **A.** Yes — both parties must acknowledge
- [x] **B.** No — merge into `scheduled` for v1
- [ ] **C.** Auto-confirm to `confirmed` 24h before start
- [ ] **D.** Admin-configurable

**Recommended default:** B for v1 simplicity — reduces student/teacher friction; acknowledge action rarely used.

**Production impact:** Transition table simplification, reminder CF, join eligibility.

---

### Q-SL-03: Auto `inProgress` transition trigger

- [ ] **A.** System at `startsAt` regardless of join
- [ ] **B.** First participant join via RTC webhook
- [ ] **C.** Teacher manual start only
- [x] **D.** At `startsAt` only if at least one join event logged

**Recommended default:** D — balances no-show detection with false positives.

**Production impact:** CF scheduled jobs, `markBothNoShow` timing, join telemetry.

---

### Q-SL-04: Post-session terminal state for ambiguous attendance

- [x] **A.** `incomplete` when call < minimum duration
- [ ] **B.** `completed` unless dispute opened
- [x] **C.** `bothNoShow` if neither joined within grace
- [ ] **D.** Admin manual review queue only

**Recommended default:** C + A — use call tracking calculator thresholds from admin config.

**Production impact:** Teacher payout eligibility, student review prompt, dispute window.

---

## Notifications

### Q-NT-01: Push notification provider for session events

- [x] **A.** FCM only (current gateway)
- [ ] **B.** FCM + email for paid bookings
- [ ] **C.** In-app inbox only until FCM device epoch stable
- [ ] **D.** SMS for booking confirmation (MENA markets)

**Recommended default:** A for v1 — single-device FCM design exists in spec 037.

**Production impact:** CF `deliverSessionNotification`, device epoch edge cases.

---

### Q-NT-02: Reminder schedule before session

- [ ] **A.** 24h + 1h (default reminder policy)
- [ ] **B.** 24h + 15m
- [x] **C.** Admin-configurable only
- [ ] **D.** Opt-in per user

**Recommended default:** C with A as platform default.

**Production impact:** `sessionReminders.ts` cron, notification fatigue, timezone correctness.

---

## Backend / persistence

### Q-BE-01: Source of truth for session mutations

- [ ] **A.** Cloud Functions callables only (current design)
- [ ] **B.** Firestore triggers + callables
- [ ] **C.** Allow client writes to `quran_sessions` with rules validation
- [x] **D.** Hybrid — reads from Firestore, writes CF only

**Recommended default:** D — rules already deny client writes on sessions/bookings.

**Production impact:** Security audit, offline behavior, optimistic UI limits.

---

### Q-BE-02: Fake MVP backend in developer builds

- [ ] **A.** Keep for UI dev; never in staging/production builds
- [ ] **B.** Remove entirely; Firebase emulator only
- [x] **C.** Keep but require explicit `--dart-define` opt-in
- [ ] **D.** Snapshot tests only

**Recommended default:** C — `TILAWA_QURAN_SESSIONS_BACKEND=fake` already exists; default firebase when Firebase init on.

**Production impact:** Accidental fake wiring in release, test fidelity.

---

### Q-BE-03: Booking aggregate vs session document split

- [x] **A.** Separate `quran_bookings` + `quran_sessions` (current)
- [ ] **B.** Single session aggregate doc only
- [ ] **C.** Booking embedded in session subcollection
- [ ] **D.** Event-sourced log only

**Recommended default:** A — matches existing Firestore schema and CF.

**Production impact:** Query indexes, list performance, migration cost if changed.

---

## Security / rules

### Q-SR-01: App Check enforcement on session callables

- [x] **A.** Enforce on staging first; prod after 2 weeks stable
- [ ] **B.** Enforce everywhere at production Go
- [ ] **C.** Never enforce (rely on auth only)
- [ ] **D.** Enforce on paid callables only

**Recommended default:** A — P1-1 in production blockers; default off today.

**Production impact:** Emulator testing, sideloaded builds, support debugging.

---

### Q-SR-02: Client-side cancellation eligibility

- [ ] **A.** UI hints only; CF rejects illegal cancels
- [ ] **B.** Duplicate policy in client for UX (must match server)
- [x] **C.** Server returns allowed actions list per session
- [ ] **D.** Client is authoritative (reject)

**Recommended default:** C — best UX + single source of truth; partial today via lifecycle guard server-side.

**Production impact:** `SessionActionPolicy`, tampering risk, support tickets.

---

## Edge cases

### Q-EC-01: Child student (minor) booking

- [x] **A.** Block all bookings until guardian linked
- [ ] **B.** Allow free sessions; block paid
- [ ] **C.** Market-specific age threshold
- [ ] **D.** No age gate v1

**Recommended default:** A — guardian failure exists in eligibility; legal risk if wrong.

**Production impact:** Profile completion, guardian approval repository, CF validation.

---

### Q-EC-02: Teacher suspended mid-session lifecycle

- [ ] **A.** Admin cancels all upcoming sessions automatically
- [x] **B.** Existing sessions run; no new bookings
- [ ] **C.** Case-by-case admin review
- [ ] **D.** Immediate force-cancel including in-progress

**Recommended default:** B + admin tool for mass cancel — spec SU suspension rules.

**Production impact:** CF moderation hooks, compensation batch jobs.

---

### Q-EC-03: Clock skew / timezone for slot boundaries

- [x] **A.** All slots stored UTC; display in market timezone
- [ ] **B.** Store in teacher local timezone
- [ ] **C.** Store UTC + `timezone` field on slot
- [ ] **D.** Client computes; server trusts

**Recommended default:** A — `GeneratedSlot.parseStartUtc` pattern; server authoritative.

**Production impact:** DST bugs, reminder timing, no-show grace windows.

---

## Teacher dashboard

### Q-TD-01: Pending approval requests section placement

- [x] **A.** Top of dashboard above upcoming sessions
- [ ] **B.** Separate "Requests" tab
- [ ] **C.** Badge on dashboard + push only
- [ ] **D.** Email digest only

**Recommended default:** A — time-sensitive; reduces expired approvals.

**Production impact:** Dashboard query (second list), empty states, performance.

---

### Q-TD-02: Teacher mark student no-show

- [ ] **A.** Enabled after grace period (NS-03)
- [x] **B.** Admin/system only for v1
- [ ] **C.** Enabled with mandatory evidence upload
- [ ] **D.** Disabled entirely; webhook only

**Recommended default:** A — CF exists; mobile UI 🔴 missing per audit.

**Production impact:** Dispute rate, student fairness, teacher trust.

---

## Student experience

### Q-ST-01: My Sessions tab structure

- [ ] **A.** Upcoming / Past / Cancelled (current)
- [x] **B.** Upcoming / Pending / Past / Cancelled
- [ ] **C.** Upcoming / Past only (cancelled merged into past)
- [ ] **D.** Calendar view primary

**Recommended default:** B if Q-BK-02 = A; else keep A.

**Production impact:** Navigation IA, empty states, analytics funnels.

---

### Q-ST-02: Show completed sessions in Past with review prompt

- [ ] **A.** Yes — review CTA for 7 days (current eligibility)
- [x] **B.** Yes — review window admin-configurable
- [ ] **C.** Separate "History" with reviews
- [ ] **D.** No reviews v1

**Recommended default:** B — review policy should not be hardcoded.

**Production impact:** `canReviewSession`, storage of reviews, teacher ranking future.

---

### Q-ST-03: Learn Quran entry when booking disabled

- [ ] **A.** Hide entry entirely
- [x] **B.** Show hub read-only (browse teachers, no book CTA)
- [ ] **C.** Show with waitlist CTA
- [ ] **D.** Current: entry visible with kill-switch redirect

**Recommended default:** B — production_readiness uses booking flag separate from feature flag.

**Production impact:** Home dashboard card, router guards, user expectations.

---

## Priority summary

| Priority | Questions | Blocked until answered |
|----------|-----------|------------------------|
| **P0** | Q-BK-01, Q-FE-01, Q-VC-01, Q-AD-03, Q-SL-01 | Booking confirm path, pricing, call modality, fee ownership, status model |
| **P1** | Q-CN-01–03, Q-TA-01, Q-VC-02–03 | Cancellation/refund/compensation, approval SLA, RTC provider |
| **P2** | Remaining | UX polish, notifications tuning, edge cases |

**Total questions:** 42
