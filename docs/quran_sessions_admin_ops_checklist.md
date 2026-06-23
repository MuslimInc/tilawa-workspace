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
