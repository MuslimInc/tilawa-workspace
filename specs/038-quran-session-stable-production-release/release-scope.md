# Release Scope — Quran Sessions Stable Production v1

## In scope

### Student
- Profile completion gate before sessions home
- Browse verified public teachers (`isPubliclyVisible`)
- View teacher profile + availability window
- Book **free individual** session (when `quranSessionsBookingEnabled=true`)
- Session mode: external meeting (primary) + mock voice/video (when platform config allows)
- My sessions list; session detail; join via `SessionCallProvider`
- Cancel session (student)
- Request reschedule (counterparty confirms via admin)
- Report concern; open dispute

### Teacher
- Apply (when `teacherApplicationEnabled=true`)
- Application status with post-approval **متابعة** navigation
- Complete public profile; weekly availability
- Dashboard: upcoming sessions, slot management, cancel
- External meeting URL editor
- Join sessions as teacher

### Admin (Angular panel)
- Review teacher applications (approve/reject/suspend/revoke)
- Moderate teachers (activate/deactivate)
- Suspend Quran Sessions users
- Sessions list + detail: cancel, no-show, complete, compensation, refund, reschedule confirm
- Reports + disputes queues (read-only triage)
- Audit timeline per session

### Backend
- Cloud Functions for all mutations
- Firestore rules: participant reads; CF-only writes
- Single-active-device epoch on callables
- Notification outbox + FCM to active device
- Idempotency on booking/cancel/dispute/report

### Platform
- Feature flags via `AppLaunchConfig` dart-defines
- Firestore `enabledCallProviders` server kill for mock/external
- Android external URL queries for meeting links

## Out of scope

| Feature | Handling |
|---------|----------|
| Paid booking | `DisabledPaymentProvider`; CF rejects payment when disabled |
| Wallet top-up / checkout | Not exposed; read-only wallet screen may remain |
| Group booking | CF `group_booking_not_supported`; no UI |
| In-app RTC (Agora/WebRTC) | Stubs only; not in DI |
| Mode/provider change after book | Locked (Option A); cancel + rebook or admin session actions |
| Mobile reschedule confirm | Admin confirms by request ID |
| Teacher mobile no-show | Admin only |
| Admin dispute resolve UI | Session detail CF actions |

## Production defaults (`play_production`)

| Flag | Default |
|------|---------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` | `true` |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `false` |
| `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED` | `false` |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | `false` |

Enable booking + teacher apply deliberately when ops ready.

## Session mode / provider policy (v1)

**Option A — lock at booking.** See [037 session-mode-provider-change-policy](../037-quran-session-free-beta-closure/session-mode-provider-change-policy.md).

Admin support may override via existing session detail moderation (audited CF writes); dedicated `adminOverrideSessionCallSettings` callable is post-v1 nice-to-have.
