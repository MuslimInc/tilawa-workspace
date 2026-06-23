# Acceptance Criteria — Quran Sessions (Given / When / Then)

Canonical Given/When/Then for core flows. Story-level AC in [user-stories.md](./user-stories.md).  
**Policies:** [business-rules.md](../031-quran-session-blueprint/business-rules.md)  
**Smoke:** [production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md)

---

## 1. Student booking (free)

**Given** I am a signed-in student with complete `quranSessionsProfile` (gender, DOB, country, city),  
**And** `quranSessionsBookingEnabled` is true,  
**And** the teacher is verified with `pricingType: free` in my market,  
**And** I pass gender and age eligibility,  
**When** I select an available slot and `externalMeeting` call type and confirm booking,  
**Then** `createSessionBooking` creates booking + session with `lifecycleStatus: scheduled`,  
**And** the slot is locked for other students,  
**And** I see the session in My Sessions,  
**And** I receive booking confirmation push within 60s (if notifications enabled).

**Given** I retry booking with the same `idempotencyKey`,  
**When** the CF processes the duplicate request,  
**Then** I receive the same `bookingId` and only one booking document exists.

**Given** another student already booked the slot,  
**When** I attempt to book the same slot with a different idempotency key,  
**Then** booking fails with slot unavailable / `already-exists`.

**Given** my account is blocked,  
**When** I attempt to book,  
**Then** `createSessionBooking` returns `account_blocked` and no session is created.

---

## 2. Teacher availability

**Given** I am an approved teacher with completed public profile,  
**When** I save weekly availability (e.g. Mon 10:00–12:00 Cairo time),  
**Then** bookable slots generate for the next 14 days on enabled days,  
**And** students see those slots on the booking screen.

**Given** I set a vacation override for a specific date,  
**When** slot generation runs for that date,  
**Then** no slots are offered on that date.

**Given** I toggle a single unbooked slot unavailable on my dashboard,  
**When** a student refreshes the booking screen,  
**Then** that slot no longer appears.

**Given** a slot is already booked,  
**When** I attempt to toggle it unavailable,  
**Then** the UI blocks the action and instructs me to cancel the session first.

---

## 3. Teacher application

**Given** `teacherApplicationEnabled` is true and I have no pending application,  
**When** I complete phone (valid E.164 for selected country), languages, specializations, and bio and submit,  
**Then** my application status becomes `pending`,  
**And** I cannot edit locked fields until admin acts.

**Given** my application was rejected less than 30 days ago,  
**When** I attempt to submit a new application,  
**Then** submission is blocked with cooldown message per ADR-003.

**Given** admin approves my application via `reviewTeacherApplication`,  
**When** approval completes,  
**Then** a `TeacherProfile` is created with `verificationStatus: verified`,  
**And** I am prompted to complete my public marketplace profile.

---

## 4. Admin approval

**Given** I am an admin with Firebase admin claim,  
**When** I open pending applications in `tilawa_admin` and approve an application,  
**Then** the teacher profile is created server-side,  
**And** the applicant can complete public profile and set availability,  
**And** the teacher appears in student marketplace (subject to discoverability flag).

**Given** I reject an application with reason,  
**When** rejection is saved,  
**Then** applicant sees rejected status with reason,  
**And** 30-day re-application cooldown applies.

---

## 5. Cancellation

**Given** I am the student on a session more than 24 hours before start (early cancel),  
**When** I cancel with reason at least 20 characters,  
**Then** session becomes `cancelledByStudent`,  
**And** the slot is released,  
**And** the teacher receives cancellation notification.

**Given** I am the student within 60 minutes of start (block window),  
**When** I attempt to cancel,  
**Then** cancellation is blocked with policy message from resolved config.

**Given** I am the teacher on an upcoming session,  
**When** I cancel with mandatory reason,  
**Then** session becomes `cancelledByTeacher`,  
**And** student receives notification,  
**And** compensation `restoreSessionCredit` is queued (Beta: credit / manual_pending only).

**Given** I am not a participant,  
**When** I call cancel CF,  
**Then** I receive `permission-denied` / `not_participant`.

---

## 6. Reschedule

**Given** I am student or teacher on a session with 0 prior reschedules and >24h before start,  
**When** I submit reschedule request with reason ≥20 chars and proposed new slot,  
**Then** a pending reschedule request is created and counterparty is notified.

**Given** the counterparty confirms the new slot via `confirmSessionReschedule`,  
**When** confirmation succeeds,  
**Then** session `startsAt`/`endsAt` update atomically,  
**And** old slot releases and new slot locks,  
**And** status returns to `scheduled`.

**Given** I already used my maximum reschedules (default 1),  
**When** I attempt another reschedule,  
**Then** request is blocked with policy message.

---

## 7. No-show

**Given** session start time has passed and `gracePeriodMinutes` (default 15) have elapsed,  
**And** no attendance evidence exists,  
**When** the scheduled no-show job runs,  
**Then** appropriate no-show status is applied per policy (e.g. `bothNoShow` after extended window).

**Given** I am the teacher and grace period has elapsed,  
**When** I mark student no-show via `markSessionNoShow`,  
**Then** session becomes `studentNoShow`,  
**And** student no-show metric increments (Beta: no auto-suspend).

**Given** grace period has not elapsed,  
**When** I attempt to mark no-show,  
**Then** action is blocked.

---

## 8. Reports

**Given** I am a session participant (student or teacher),  
**When** I submit a safety report with category and description ≥20 chars,  
**Then** `reportSessionConcern` creates a report document,  
**And** the report appears in admin reports queue.

**Given** I am not a participant,  
**When** I attempt to report,  
**Then** CF returns permission denied.

**Given** admin resolves the report,  
**When** `resolveSessionReport` completes,  
**Then** report status updates and reporter notified if configured.

---

## 9. Disputes

**Given** my session is in `completed` status,  
**When** I open a dispute with reason,  
**Then** `openSessionDispute` transitions session to `disputed`.

**Given** my session is still `scheduled`,  
**When** I attempt to open dispute,  
**Then** lifecycle guard blocks the action.

**Given** admin resolves dispute `favor_student`,  
**When** resolution saves,  
**Then** a refund ledger document is created with status `manual_pending` (Beta: no PSP call).

**Given** admin resolves with compensation,  
**When** resolution saves,  
**Then** compensation ledger document `manual_pending` is created.

---

## 10. Compensation / manual pending (Beta)

**Given** teacher cancels an upcoming session,  
**When** cancellation CF completes,  
**Then** compensation type `restoreSessionCredit` is recorded (not automated money transfer).

**Given** any monetary compensation or refund type in Beta config,  
**When** compensation is issued,  
**Then** only `manual_pending` ledger record is created for finance manual processing,  
**And** no PSP charge/refund API is called.

---

## 11. Firestore rules

**Given** I am a student client,  
**When** I attempt direct create/update/delete on `quran_bookings/{id}` or `quran_sessions/{id}`,  
**Then** Firestore rules deny the write.

**Given** I am a blocked user,  
**When** I attempt to set my own `quranSessionsProfile.accountStatus` to `active` via client,  
**Then** Firestore rules deny the write.

**Given** I am a session participant,  
**When** I read my session document,  
**Then** read is allowed.

**Given** I am not a participant,  
**When** I read another user's session,  
**Then** read is denied.

---

## 12. Notifications

**Given** booking succeeds and I have a valid FCM token,  
**When** outbox processes `booking_confirmed`,  
**Then** I receive push notification with session details.

**Given** I have an upcoming session in 24 hours,  
**When** `sessionReminders` job runs,  
**Then** I receive one T-24h reminder push (not duplicated on re-run).

**Given** session was cancelled before reminder scheduled,  
**When** reminder job runs,  
**Then** no reminder is sent.

**Given** I tap a session notification,  
**When** app opens,  
**Then** I am deep-linked to session detail or My Sessions.

---

## 13. Google Play beta release

**Given** Sprint 7 smoke 10/10 and rollback drill passed,  
**When** release build is uploaded to Play internal track,  
**Then** core team installs and verifies sessions feature with prod Firebase (booking flag per rollout plan).

**Given** closed Beta cohort of ≥20 users,  
**When** Beta period ends,  
**Then** ≥20 users completed at least one book→join flow,  
**And** booking success rate >95%,  
**And** dispute rate <3%.

**Given** staged rollout at 5%,  
**When** crash-free rate drops below 99% or P0 incident occurs,  
**Then** rollout is halted and rollback plan initiated.

---

## Traceability

| Flow | Primary stories | Smoke # |
|------|---------------|---------|
| Student booking | US-006, US-050 | 3, 4, 5, 10 |
| Teacher availability | US-023, US-049 | — |
| Teacher application | US-019–022, US-033 | — |
| Admin approval | US-033 | — |
| Cancellation | US-010, US-028, US-053 | 1 |
| Reschedule | US-011, US-054 | — |
| No-show | US-030, US-057 | — |
| Reports | US-015, US-040 | — |
| Disputes | US-016, US-041 | 7, 8 |
| Compensation | US-042, US-056 | 8 |
| Firestore rules | US-047 | 1, 2 |
| Notifications | US-009, US-013, US-055 | — |
| Play release | US-068–070 | — |
