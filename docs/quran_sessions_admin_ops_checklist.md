# Quran Sessions — Admin Operations Checklist (MVO)

> Minimum ops required before enabling `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=true` in production.

---

## People & process

- [ ] Named review owner (weekly queue drain)
- [ ] Published review SLA (recommend 48–72h) reflected in app status copy
- [ ] Rejection reason policy (always fill `rejectionReason` on reject)

---

## Technical

- [ ] **Firestore rules deployed** (`firebase deploy --only firestore:rules`) — without this, apply shows `PERMISSION_DENIED`
- [ ] Firestore rules deployed (applicant draft/submit)
- [ ] Cloud Function `reviewTeacherApplication` deployed OR Admin SDK scripts verified
- [ ] Admin custom claim process documented for operators
- [ ] Composite index for `quran_teacher_applications`: `status` + `submittedAt` (if querying pending)
- [ ] Feature flags configured per environment

---

## Verification (staging)

1. Student opens Learn Quran → empty state with notify + secondary teach CTA (when discoverability on).
2. Applicant completes Profile → Apply → Submit → `pending`.
3. Operator lists pending → approves → `TeacherProfile` created.
4. Approved teacher appears in student teacher list; pending applicant cannot open dashboard.
5. Reject path sets cooldown; duplicate pending blocked.

---

## Kill switch

Set `--dart-define=TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=false` and redeploy/host config to disable apply routes and Profile entry.

---

## App Check enforcement runbook (Spec 039 / US4)

Enforcement of request attestation on Quran Sessions callables is controlled
by the deploy-time environment value `QURAN_SESSIONS_ENFORCE_APP_CHECK`
(`functions/src/quranSessions/sessionCallableOptions.ts`). It is **not** an
admin-panel setting and cannot be changed without a functions redeploy.

### Staged enable (staging only, then production)

1. Confirm the release gate in
   `docs/quran-sessions/production-readiness-checklist.md` § 3a has a named
   owner and record the current enforcement state.
2. Deploy functions to **staging** with `QURAN_SESSIONS_ENFORCE_APP_CHECK=true`,
   following the phase order in
   `docs/quran-sessions/app-check-staging-plan.md` (monitor → token issue →
   booking/cancel → all session callables).
3. Exercise the E1–E6 critical flows from attested clients and record dated
   results in the § 3a evidence table. Use Firebase debug tokens for
   simulators (staging/dev only).
4. Trigger one non-attested request (E7) and record the observable rejection.
5. Production enforce only after every § 3a success criterion is met,
   including 7 consecutive days under 0.1% callable error rate.

### Observable rejection handling

- Rejected calls fail before handler code runs; clients see a callable error,
  and Functions logs show the App Check rejection. Watch the callable error
  rate dashboards during each phase.
- If support reports "غير مخوّل" / permission-style failures from up-to-date
  app builds during a phase, treat it as a gate failure: capture the log
  entry (never the request payload or report/dispute text), then roll back.

### Rollback (config-only, no data mutation)

1. Redeploy functions with `QURAN_SESSIONS_ENFORCE_APP_CHECK` removed or set
   to anything other than `true`.
2. Verify a booking and one admin resolution succeed without attestation.
3. Record the rollback date and result in § 3a of the readiness checklist.
   No Firestore data is touched at any point.
