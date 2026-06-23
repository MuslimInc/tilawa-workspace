# Beta Testing Plan — Quran Sessions

**Sprint:** 8 (after Sprint 7 QA sign-off)  
**Scope:** Free Beta only — no paid sessions  
**Related:** [qa-test-plan.md](./qa-test-plan.md), [google-play-release-plan.md](./google-play-release-plan.md)

---

## Phases

| Phase | Track | Audience | Duration | Goal |
|-------|-------|----------|----------|------|
| 1 | Internal QA | Core team + eng | Sprint 7 | Smoke + device matrix |
| 2 | Play internal | Core team (5–10) | 3 days | Install/update from Play |
| 3 | Play closed | Trusted teachers + students | 7–14 days | 20+ E2E flows |
| 4 | Play staged | Public subset | 7+ days | 5% → 100% rollout |

---

## Phase 1 — Internal QA (Sprint 7)

**Participants:** Engineers, product, ops with staging builds.

**Activities:**
- Execute full [qa-test-plan.md](./qa-test-plan.md) device matrix
- Staging smoke 10/10
- Rollback drill on staging
- File P0 defects — must be zero before Phase 2

**Exit:** QA sign-off document.

---

## Phase 2 — Play internal track

**Participants:** Core team with Play internal tester emails.

**Activities:**
- Upload signed AAB per [google-play-release-plan.md](./google-play-release-plan.md)
- Verify install, update, and sessions feature against **production Firebase** with booking flag per rollout plan
- Confirm FCM on production project tokens
- Validate feature flags / Remote Config propagation

**Exit:** 5+ successful book→join flows on prod config.

---

## Phase 3 — Closed Beta (trusted cohort)

### Recruitment

| Cohort | Target n | Role |
|--------|----------|------|
| Trusted teachers | 5–8 | Approved, active availability, external meeting link |
| Trusted students | 15–25 | Mix adults; include 2+ female/male for gender rules |
| Guardian scenario | 1–2 families | Parent + child account (child blocked until guardian deferred — document expected block) |
| Ops/admin | 1 | Dispute/report resolution |

**Recruitment channels:** Direct outreach, mosque/community partners, existing MeMuslim power users.

### Tester onboarding packet

1. Play closed testing opt-in link
2. Google Sign-In requirement
3. Profile completion instructions (country Egypt, city selection)
4. How to join session via meeting link
5. Feedback form link (Google Form or in-app if available)
6. Support contact (WhatsApp/email) for P0 issues
7. Explicit: **sessions are free** in Beta; no payment

### Scenarios to complete (each tester minimum)

| ID | Scenario | Actor |
|----|----------|-------|
| BT-01 | Apply as teacher → admin approve → set schedule | Teacher |
| BT-02 | Browse → book → receive confirm push | Student |
| BT-03 | Join session via meeting link at scheduled time | Both |
| BT-04 | Student cancel >24h with reason | Student |
| BT-05 | Teacher cancel with reason | Teacher |
| BT-06 | Reschedule request + accept | Both |
| BT-07 | Report safety concern | Student |
| BT-08 | Complete session + submit review | Student |
| BT-09 | Open dispute on completed session | Student |
| BT-10 | Admin resolves dispute | Admin |

**Target:** ≥20 testers complete BT-02 + BT-03.

---

## Guardian scenario (Beta)

**Expected Beta behavior:** Child profile without `guardianId` receives `GuardianApprovalRequiredFailure` at booking — **no guardian linking UI**.

**Test:**
- Parent creates child account (DOB under threshold)
- Verify booking blocked with clear message
- Document as known limitation — not Beta blocker
- Production: guardian flow required before child marketing

---

## Feedback collection

| Channel | Frequency | Owner |
|---------|-----------|-------|
| Google Form (NPS + free text) | After first session | Product |
| Play Console feedback | Continuous | Product |
| WhatsApp support group | Daily standup during closed Beta | Ops |
| Sentry user feedback | Automatic | Eng |
| Analytics funnel | Daily dashboard | Eng |

**Form prompts (AR):**
- هل نجح الحجز من أول محاولة؟
- هل وصلتك إشعارات التأكيد والتذكير؟
- هل رابط الجلسة عمل؟
- تقييم 1–5 للتجربة العامة
- ما الذي يجب تحسينه؟

---

## Monitoring during Beta

| Metric | Source | Alert threshold |
|--------|--------|-----------------|
| CF `createSessionBooking` error rate | Sentry / Cloud Logging | >2% over 1h |
| Booking success rate | Custom metric / Firestore count | <95% |
| FCM delivery failures | `deliverSessionNotification` logs | >10% |
| Crash-free sessions users | Play Console / Sentry | <99% |
| Dispute count | Firestore | >3% of completions |
| Teacher cancel rate | metrics aggregation | >10% |
| Median dispute resolution time | Admin timestamps | >48h |

**Dashboard v0:** Firebase console + spreadsheet until A-14 metrics dashboard built.

---

## Success metrics (Beta close)

| Metric | Target | Measurement window |
|--------|--------|-------------------|
| Completed book→join flows | ≥20 users | Closed Beta |
| Booking success rate | >95% | Excl. user errors |
| Session completion rate | >80% | Of non-cancelled |
| Teacher cancel rate | <10% | Beta period |
| Dispute rate | <3% | Of completed |
| Median dispute resolution | <48h | Admin SLA |
| Crash-free rate | >99% | Play Console |
| NPS baseline | Record | Form average |

---

## Stop conditions (halt Beta / trigger rollback)

Execute [rollback-plan.md](./rollback-plan.md) if any:

1. **P0 security:** cross-user data visible, rules bypass, unauthorized session access
2. **Booking failure rate >5%** (excluding user validation errors) for 24h
3. **CF error spike** blocking all bookings >30 min
4. **Safety incident** requiring immediate feature hide (report of harm with credible evidence)
5. **Crash-free rate <97%** on closed track
6. **Payment accidentally charged** — immediate halt (should not occur in Beta)
7. **Ops unable to resolve disputes** within 72h backlog >10 open

**Halt procedure:** Disable `quranSessionsBookingEnabled` → hide entry card → notify cohort → postmortem within 48h.

---

## Beta close activities

1. Collect metrics vs success table
2. Free Beta Go/No-Go meeting — update [README.md](./README.md) verdict
3. Triage P1/P2 backlog for Production phase
4. Advance Play staged rollout if Go
5. Publish Beta summary (internal doc): what worked, gaps, Paid Sessions prerequisites

---

## Communication templates

### Beta invite (AR)

> مرحباً! أنت مدعو لتجربة جلسات القرآن المجانية في تطبيق أنا مسلم. حمّل النسخة التجريبية من الرابط، سجّل دخولك بجوجل، أكمل ملفك الشخصي، واحجز جلسة مجانية مع محفظ معتمد.

### Known limitations (AR)

> التجربة التجريبية: الجلسات مجانية فقط. لا يوجد دفع. ربط ولي الأمر للقُصّر قادم لاحقاً. الجلسة عبر رابط خارجي (زووم/جوجل ميت).
