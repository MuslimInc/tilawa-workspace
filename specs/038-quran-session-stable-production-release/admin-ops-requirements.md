# Admin Ops Requirements — Stable Production v1

## Required capabilities

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Approve teacher applications | ✅ | `reviewTeacherApplication` CF; admin `teacher-application-detail` |
| Reject / suspend / revoke applications | ✅ | Same CF |
| Activate / deactivate teacher profiles | ✅ | `ModerateTeacherProfileUseCase`; `teachers.component` |
| Suspend Quran Sessions users | ✅ | `QuranSessionsUsersComponent` → `moderateQuranSessionsUser` |
| List all sessions / bookings | ✅ | Admin sessions module |
| Session detail moderation | ✅ | Cancel, no-show, complete, compensation, refund, reschedule confirm |
| View audit timeline | ✅ | `quran_session_events` in session detail |
| Reports work queue | ✅ Read-only | List + filters + detail |
| Disputes work queue | ✅ Read-only | List + detail + notice in ARB |
| Inspect call mode/provider on session | ✅ | Session doc fields in admin detail |
| Resolve support cases (refund/compensation) | ✅ | Session detail CF actions (not dispute detail UI) |

## Acceptable limitations (v1)

1. **Reports/disputes detail is read-only** — triage then open linked session for actions.
2. **Dispute resolve not in dispute detail component** — use session detail or CF directly.
3. **Wallet admin** — deployed but manual W1–W4 QA pending; out of free beta user scope.

## Ops runbook (support)

### Teacher approved but cannot access dashboard
1. Run `npm run quran-sessions:verify-teacher-activation -- --userId=UID`
2. Check `quran_teacher_profiles/{applicationId}.isActive` and `isPubliclyVisible`
3. If deactivated: `moderateTeacherProfile` activate or backfill script
4. Ask teacher to open Settings or pull-to-refresh (capability refreshes on resume)

### Wrong call type / broken meeting link
1. Session locked at booking (Option A)
2. Options: admin cancel + student rebook; or admin session detail actions
3. Post-v1: dedicated admin override callable

### Reschedule pending
1. Student/teacher submits request from mobile
2. Admin confirms via session detail with **request ID**
3. No mobile bilateral confirm in v1

### Report / dispute filed
1. Appears in admin reports/disputes queue
2. Read context; open session detail for moderation
3. Compensation/refund via session detail when warranted

### Admin Agora RTC token (support monitor)
1. `issueSessionRtcToken` CF skips session-epoch validation for callers with `admin` custom claim.
2. Admin receives a token for **their own** Agora uid — not impersonating student/teacher audio identity.
3. Use only for live-session monitoring/debug on staging; restrict admin claim holders.
4. Automated coverage: `issueSessionRtcToken.test.ts` admin-without-epoch case.

## Gaps (non-blocking)

| Gap | Priority |
|-----|----------|
| Dispute resolve button in dispute detail | P1 |
| Report resolve workflow in report detail | P1 |
| Bulk teacher backfill UI | P2 |
| Feature flag remote config in admin | P2 |

## Sign-off checklist

- [ ] Staging admin login works with `admin` custom claim
- [ ] Approve test teacher → profile created with `isActive: true`
- [ ] Session detail shows join metadata (participant-only in app; admin sees all)
- [ ] Report from mobile appears in admin queue within 1 min
- [ ] Dispute from mobile appears in admin queue
