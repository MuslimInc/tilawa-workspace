# User Stories — Quran Sessions

**Format:** Implementable stories for all epics.  
**Epics:** [epics.md](./epics.md)  
**Sprints:** [sprint-plan.md](./sprint-plan.md)

**Legend — Release:** Free Beta | Production | Paid Sessions (postponed)

---

## E-01 — Student Experience

### US-001: Sessions home entry with profile gate

As a **student**,  
I want the home screen Quran Sessions card to check my profile completeness before entry,  
so that I complete required safety fields before browsing teachers.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-045 (auth UID), US-046 (profile Firestore)  
**Acceptance Criteria:**
- Given I am signed in with incomplete `quranSessionsProfile`, when I tap the sessions entry card, then I am routed to `ProfileCompletionScreen` (`/sessions/profile/complete`).
- Given I complete gender, DOB, country, and city, when I save, then I return to sessions hub without re-gating.
- Given `quranSessionsEnabled` is false, when I tap entry, then sessions UI is hidden or shows disabled state per `quran_sessions_feature_flags.dart`.
**Tests Required:**
- Unit: `GetUserProfileUseCase`, profile completeness check
- Widget: `HomeSessionsEntryCard` gate navigation
- Emulator: profile doc create on first sign-in
**Notes:** Gate exists at `HomeSessionsEntryCard`; verify real UID via `requireQuranSessionsUserId`.

---

### US-002: Browse verified teacher list

As a **student**,  
I want to browse a paginated list of verified teachers in my market,  
so that I can find a suitable Quran teacher.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-034 (approved teachers seeded), US-058 (discoverability flag)  
**Acceptance Criteria:**
- Given ≥1 verified teacher in EG market, when I open `/sessions/teachers`, then teachers load with name, rating, specializations, and free price label.
- Given I scroll to list end, when more pages exist, then infinite scroll loads next page without duplicate IDs.
- Given no teachers in market, when list loads, then empty state (`quran_sessions_student_empty_state.dart`) shows with notify-interest CTA if configured.
**Tests Required:**
- BLoC: `TeacherListBloc` pagination
- Widget: teacher list renders cards
- Firestore rules: read public teacher profiles only
**Notes:** `TeacherListBloc` wired; filter UI deferred to US-017.

---

### US-003: View teacher profile and availability preview

As a **student**,  
I want to view a teacher's bio, languages, specializations, and upcoming slots,  
so that I can decide whether to book.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-002, US-025 (teacher availability)  
**Acceptance Criteria:**
- Given a verified teacher ID, when I open `/sessions/teachers/:teacherId`, then profile shows verified badge, bio, languages, specializations, and price via `PriceFormatter.formatOrFree`.
- Given teacher has slots in next 14 days, when profile loads, then availability preview or "احجز" CTA navigates to booking.
- Given teacher is suspended, when I open profile, then booking CTA is disabled with policy message.
**Tests Required:**
- BLoC: `TeacherProfileBloc`
- Unit: `GetTeacherProfileUseCase`, `GetTeacherAvailabilityUseCase`
**Notes:** `teacher_profile_screen.dart` exists.

---

### US-004: Complete student profile with market selection

As a **student**,  
I want to select my country and city from backend-controlled markets,  
so that eligibility and pricing resolve correctly for my location.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-046, US-059 (market config Firestore)  
**Acceptance Criteria:**
- Given Egypt is the only enabled market, when I open profile completion, then country defaults to EG but city requires explicit selection.
- Given I change country, when city was selected, then city clears and repopulates from new market's `enabledCities`.
- Given I save, when Firestore write succeeds, then `currencyCode` and `timezone` derive from `CityConfig`.
**Tests Required:**
- BLoC: `ProfileCompletionBloc` (P0 gap — currently untested)
- Unit: `CompleteStudentProfileUseCase`
- Widget: `ProfileCompletionScreen` country/city pickers
**Notes:** Roadmap P0 — `ProfileCompletionBlocTest` missing.

---

### US-005: Booking eligibility inline errors

As a **student**,  
I want clear inline messages when I am ineligible to book,  
so that I know how to fix the issue without support.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-004, US-048 (policy repo)  
**Acceptance Criteria:**
- Given incomplete profile, when booking screen loads, then `ProfileIncompleteFailure` shows "إكمال الملف الشخصي" CTA.
- Given gender mismatch with teacher, when eligibility runs, then `GenderNotAllowedFailure` message displays without slot picker.
- Given child student without guardian (future), when `GuardianApprovalRequiredFailure`, then blocked state shows (Beta: block only; remediation deferred Production).
**Tests Required:**
- Unit: `ValidateBookingEligibilityUseCase` — 12 cases (P0 gap)
- BLoC: `BookingBloc` eligibility gate
**Notes:** `ValidateBookingEligibilityUseCase` has **0 tests** per roadmap.

---

### US-006: Book a free session slot

As a **student**,  
I want to select a slot and call type and confirm a free booking,  
so that I have a scheduled Quran session.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050 (createSessionBooking CF), US-058 (`quranSessionsBookingEnabled`)  
**Acceptance Criteria:**
- Given booking flag on and eligible profile, when I select slot + `externalMeeting` call type and confirm, then `CreateSessionBookingUseCase` calls `SessionCommandGateway` with `idempotencyKey`.
- Given booking succeeds, when I return to My Sessions, then new session appears with status `scheduled` and correct `startsAt`.
- Given same `idempotencyKey` retried, when CF receives duplicate, then same `bookingId` returned (no double booking).
- Given slot already taken, when I book, then `SlotUnavailableFailure` / `already-exists` surfaced in UI.
**Tests Required:**
- Unit: `CreateSessionBookingUseCase`
- BLoC: `BookingBloc` submit path
- CF integration: idempotency + slot lock (smoke #4, #5)
- E2E smoke: book flow on staging
**Notes:** Flag `quranSessionsBookingEnabled: false` in prod today.

---

### US-007: View my upcoming and past sessions

As a **student**,  
I want to see my sessions grouped by upcoming and past,  
so that I can manage my schedule.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050, US-051 (session Firestore read)  
**Acceptance Criteria:**
- Given I have bookings, when I open `/sessions/mine`, then upcoming sessions sort by `startsAt` ascending.
- Given a session completed, when listed in past, then review CTA appears if not yet reviewed.
- Given pull-to-refresh, when I pull, then list reloads from `SessionRepository.getStudentSessions`.
**Tests Required:**
- BLoC: `MySessionsBloc`
- Widget: `MySessionsScreen` session cards
**Notes:** Pull-to-refresh is P1; include if sprint capacity.

---

### US-008: Join session via meeting link

As a **student**,  
I want to tap a join button that opens the teacher's meeting link,  
so that I can attend my scheduled session.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-006, US-052 (meeting link on session doc)  
**Acceptance Criteria:**
- Given confirmed session with `meetingLink` populated, when I open session detail (`session_detail_screen.dart`), then join CTA is visible.
- Given I tap join, when link is valid URL, then external browser or in-app browser opens via `ExternalMeetingCallProvider`.
- Given session is cancelled, when I view detail, then join CTA is hidden.
- Given link missing within 1h of start, when I view detail, then support copy shown and report CTA available.
**Tests Required:**
- Widget: session detail join button visibility
- Unit: `CallProvider` external meeting open
- Emulator: staging session with link
**Notes:** **P0 gap** — `meetingLink` on entity but not displayed (`docs/quran_sessions_roadmap.md` #8).

---

### US-009: Receive booking confirmation notification

As a **student**,  
I want a push notification when my booking is confirmed,  
so that I have confirmation outside the app.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-055 (FCM delivery), US-056 (outbox on book)  
**Acceptance Criteria:**
- Given FCM token registered, when booking succeeds, then push received within 60s with session time and teacher name.
- Given I tap notification, when app opens, then deep-link routes to session detail or My Sessions.
- Given notification permission denied, when booking succeeds, then in-app snackbar still shows (existing behavior).
**Tests Required:**
- CF integration: `deliverSessionNotification` on book event
- Emulator: FCM token write + delivery mock
**Notes:** Outbox schema exists; delivery not wired.

---

### US-010: Cancel session with reason

As a **student**,  
I want to cancel an upcoming session with a required reason,  
so that teachers and admins understand why.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-053 (cancelSessionBooking CF), US-048 (cancellation policy config)  
**Acceptance Criteria:**
- Given session >24h away (early cancel), when I cancel with reason ≥20 chars, then status becomes `cancelledByStudent` and slot releases.
- Given session <60m away (block window), when I attempt cancel, then UI blocks with policy copy from resolved config (not hardcoded).
- Given cancel succeeds, when teacher has FCM token, then teacher receives cancellation notification.
**Tests Required:**
- Unit: `CancelSessionUseCase` actor=student
- BLoC: `MySessionsBloc` cancel
- Widget: `cancel_session_sheet.dart` reason validation
- CF integration: cancel smoke #1 unauthorized
**Notes:** `cancel_session_sheet.dart` partial — reason UX incomplete.

---

### US-011: Request session reschedule

As a **student**,  
I want to request a new time slot for my session,  
so that I can adjust my schedule within policy.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-054 (reschedule CFs), US-025  
**Acceptance Criteria:**
- Given session >24h before start and 0 prior reschedules, when I submit reschedule request with reason, then `requestSessionReschedule` creates pending request and notifies teacher.
- Given teacher confirms new slot, when `confirmSessionReschedule` succeeds, then session `startsAt` updates and status returns to `scheduled`.
- Given max reschedules exceeded, when I attempt, then UI shows policy block message.
**Tests Required:**
- Unit: `RequestRescheduleUseCase`, `ConfirmRescheduleUseCase`
- CF integration: reschedule E2E
- Widget: `reschedule_session_screen.dart`
**Notes:** Screen exists; not wired E2E to gateway.

---

### US-012: Submit session review after completion

As a **student**,  
I want to rate and comment after a completed session,  
so that I can share feedback on the teacher.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-006  
**Acceptance Criteria:**
- Given session status `completed` and no existing review, when I submit rating 1–5 and optional comment, then review persists via `SubmitReviewUseCase`.
- Given I already reviewed, when I open session, then review form is hidden.
- Given session not completed, when I view past sessions, then review CTA is not shown.
**Tests Required:**
- Unit: `SubmitReviewUseCase`
- BLoC: `MySessionsBloc` review submit
**Notes:** Public review list on teacher profile deferred (moderation).

---

### US-013: Session reminder before start

As a **student**,  
I want a reminder push 24 hours before my session,  
so that I do not forget.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-057 (sessionReminders job), US-055  
**Acceptance Criteria:**
- Given upcoming session in 24h, when scheduled job runs, then FCM push sent once per session per reminder tier.
- Given session cancelled before reminder fires, when job runs, then no reminder sent.
- Given quiet hours config (if enabled), when reminder would fire in quiet window, then deferred per `reminderPolicy`.
**Tests Required:**
- CF unit: `sessionReminders.ts` scheduling logic
- Integration: reminder job with test session
**Notes:** `functions/src/quranSessions/sessionReminders.ts` exists.

---

### US-014: View session detail and lifecycle status

As a **student**,  
I want to see session time, teacher, status, and available actions,  
so that I understand what I can do next.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-008, US-010, US-011  
**Acceptance Criteria:**
- Given scheduled session, when I open `/sessions/session/:sessionId`, then detail shows teacher name, time (localized), call type, lifecycle status label.
- Given policy allows cancel, when detail loads, then cancel CTA visible.
- Given policy allows reschedule, when detail loads, then reschedule CTA visible.
**Tests Required:**
- Widget: `session_detail_screen.dart`
- Unit: `GetSessionTimelineUseCase` if wired
**Notes:** S-08 partial per screen-inventory.

---

### US-015: Report safety concern on session

As a **student**,  
I want to report a safety concern about a session or teacher,  
so that admins can investigate.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-040 (admin reports queue), US-050  
**Acceptance Criteria:**
- Given terminal or active session I participate in, when I submit report with category + description ≥20 chars, then `reportSessionConcern` CF creates report doc.
- Given report submitted, when admin opens reports queue, then report appears with session link.
- Given I am not a participant, when I call report CF, then `permission-denied`.
**Tests Required:**
- CF integration: `reportSessionConcern`
- Widget: report concern modal (new — S-12)
- Admin UI: reports list
**Notes:** **CF exists; no mobile UI** per blueprint gap.

---

### US-016: Open dispute after completed session

As a **student**,  
I want to open a dispute on a completed session within policy window,  
so that I can seek remediation for a bad experience.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-041 (admin disputes queue), US-054  
**Acceptance Criteria:**
- Given session in `completed` status, when I open dispute with reason, then `openSessionDispute` transitions to `disputed`.
- Given session in `scheduled`, when I attempt dispute, then blocked (lifecycle guard LG-05).
- Given dispute opened, when admin resolves favor_student, then compensation record `manual_pending` created (Beta: no PSP).
**Tests Required:**
- Unit: lifecycle guard dispute transitions
- CF integration: smoke #7, #8
- Widget: dispute modal (new — S-13)
**Notes:** Post-terminal only per business rules.

---

### US-017: Filter teachers by specialization and language

As a **student**,  
I want to filter the teacher list by specialization and language chips,  
so that I find teachers matching my needs.

**Priority:** P2  
**Release:** Production  
**Dependencies:** US-002  
**Acceptance Criteria:**
- Given filter chips on teacher list, when I select "تحفيظ" and "العربية", then list reloads with `TeacherListBloc` filter params.
- Given filters active, when I clear filters, then full list restores.
**Tests Required:**
- BLoC: `TeacherListBloc` filter events
- Widget: filter bar overlay on S-03
**Notes:** BLoC wired; UI missing per roadmap.

---

### US-018: English localization for session screens

As a **student** using English app locale,  
I want session screens in English,  
so that I can use the feature in my preferred language.

**Priority:** P2  
**Release:** Production  
**Dependencies:** package l10n `packages/quran_sessions/l10n/`  
**Acceptance Criteria:**
- Given device locale `en`, when I open any session screen, then strings come from `quran_sessions_localizations_en.dart` / ARB, not hardcoded Arabic.
- Given device locale `ar`, when I open screens, then Arabic strings display with correct RTL.
**Tests Required:**
- Widget: locale switch smoke on key screens
- Static: no hardcoded Arabic in presentation layer (lint/grep check)
**Notes:** Package l10n partial; app ARB migration ongoing.

---

## E-02 — Teacher Experience

### US-019: Start teacher application

As a **teacher**,  
I want to apply to become a verified Quran teacher from sessions hub or settings,  
so that I can offer sessions on the platform.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-058 (`teacherApplicationEnabled`)  
**Acceptance Criteria:**
- Given application flag on, when I tap "أريد أن أصبح محفظًا", then `/sessions/teacher/apply` opens.
- Given I enter phone (E.164 per country), languages, specializations, bio, when I save draft, then `SaveTeacherApplicationDraftUseCase` persists.
- Given invalid phone for country (e.g. `01020030` for KW), when I submit, then `InvalidPhoneForSelectedCountryFailure` shown.
**Tests Required:**
- BLoC: `TeacherApplicationBloc` (exists — phone cases)
- Unit: `SubmitTeacherApplicationUseCase`, `PhoneNormalizer`
**Notes:** `TeacherApplicationScreen` shipped.

---

### US-020: Submit teacher application for review

As a **teacher**,  
I want to submit my completed application for admin review,  
so that I can become a verified teacher.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-019, US-033  
**Acceptance Criteria:**
- Given all required fields complete, when I submit, then application status becomes `pending` and editable fields lock.
- Given pending application exists, when I submit again, then `TeacherApplicationAlreadyPendingFailure`.
- Given rejected <30 days ago, when I submit, then cooldown failure per ADR-003.
**Tests Required:**
- Unit: `SubmitTeacherApplicationUseCase`
- Firestore rules: applicant write draft→pending only
**Notes:** `reviewTeacherApplication` CF for admin.

---

### US-021: View application status

As a **teacher**,  
I want to see my application status (pending, approved, rejected, suspended, revoked),  
so that I know next steps.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-020  
**Acceptance Criteria:**
- Given pending application, when I open `/sessions/teacher/status`, then status card shows pending with expected review copy.
- Given approved, when I open status, then CTA to complete public profile and open dashboard.
- Given revoked, when I open status, then re-application blocked with permanent message.
**Tests Required:**
- Widget: `teacher_application_status_screen.dart`
- Unit: `GetTeacherApplicationStatusUseCase`
**Notes:** Screen exists.

---

### US-022: Complete public teacher profile after approval

As a **teacher**,  
I want to complete my public marketplace profile after approval,  
so that students see accurate information.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-033, US-034  
**Acceptance Criteria:**
- Given approved application, when I open `complete_teacher_public_profile_screen.dart`, then I can set display name, bio, gender, specializations, languages visible to students.
- Given profile incomplete, when student views teacher card, then teacher hidden from marketplace OR shows incomplete state per policy.
- Given save succeeds, when I navigate to dashboard, then `TeacherProfile` doc updated server-side.
**Tests Required:**
- Unit: `CompleteTeacherProfileUseCase`
- Widget: complete profile screen
**Notes:** Screen marked ✅ in screen-inventory.

---

### US-023: Configure weekly availability schedule

As a **teacher**,  
I want to set my weekly recurring availability,  
so that bookable slots generate automatically.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-049 (slot generator), US-025  
**Acceptance Criteria:**
- Given I open `/sessions/teacher/availability`, when I set Mon/Wed/Fri 10:00–12:00, then slots generate for next 14 days excluding vacation overrides.
- Given overlapping windows on same day, when I save, then validation error shown.
- Given schedule saved, when student opens booking, then new slots appear within `maxHorizonDays`.
**Tests Required:**
- Unit: `slot_generator.dart`, schedule validators
- BLoC: availability save flow
- Widget: `weekly_availability_screen.dart`
**Notes:** `weekly_availability_screen.dart` exists.

---

### US-024: Set vacation and availability overrides

As a **teacher**,  
I want to block specific days or date ranges,  
so that students cannot book when I am unavailable.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-023  
**Acceptance Criteria:**
- Given vacation day selected, when slot generator runs, then no slots on that day.
- Given override removes single slot, when student refreshes booking, then slot unavailable.
**Tests Required:**
- Unit: override merge in slot generation
- Widget: `availability_override_sheet.dart`, vacation dialogs
**Notes:** Sheets exist per screen-inventory.

---

### US-025: View teacher dashboard with sessions and slots

As a **teacher**,  
I want a dashboard showing my upcoming sessions and availability overview,  
so that I manage my teaching schedule.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-022, US-051  
**Acceptance Criteria:**
- Given I am approved teacher, when I open `/sessions/teacher/dashboard` with my auth UID (not hardcoded `teacher_1`), then upcoming sessions and slot summary load.
- Given new booking received, when I refresh dashboard, then new session appears.
- Given I tap session, when detail opens, then shared `session_detail_screen.dart` shows teacher actions.
**Tests Required:**
- BLoC: `TeacherDashboardBloc`
- Routing: auth-aware teacher dashboard route (roadmap gap)
**Notes:** Route hardcoded to `teacher_1` — fix Sprint 3.

---

### US-026: Receive new booking notification

As a **teacher**,  
I want a push when a student books my slot,  
so that I can prepare for the session.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-055, US-056  
**Acceptance Criteria:**
- Given teacher FCM token, when student books, then teacher receives push with student first name and session time.
- Given tap notification, when app opens, then routes to teacher dashboard or session detail.
**Tests Required:**
- CF integration: outbox event on create booking
- Emulator: dual-token delivery
**Notes:** Same pipeline as US-009.

---

### US-027: Toggle individual slot availability from dashboard

As a **teacher**,  
I want to mark generated slots as unavailable without deleting schedule,  
so that I can block single slots quickly.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-023, US-025  
**Acceptance Criteria:**
- Given unbooked slot on dashboard, when I toggle off, then slot `isBooked` or `isAvailable=false` and hidden from student booking.
- Given booked slot, when I attempt toggle off, then blocked with message to cancel session first.
**Tests Required:**
- BLoC: `TeacherDashboardBloc` `AvailabilitySlotEdited` event
**Notes:** Event + UI edit button exist per roadmap.

---

### US-028: Cancel session as teacher with compensation trigger

As a **teacher**,  
I want to cancel a session I cannot attend with mandatory reason,  
so that the student is fairly compensated per policy.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-053, US-056 (compensation CF)  
**Acceptance Criteria:**
- Given upcoming session, when I cancel with reason ≥20 chars, then status `cancelledByTeacher` and `restoreSessionCredit` compensation queued (Beta: credit/manual_pending only).
- Given session in progress, when I attempt cancel, then lifecycle guard blocks (LG-04).
- Given cancel succeeds, when student views session, then cancelled state and compensation notice shown.
**Tests Required:**
- Unit: `CancelSessionUseCase` actor=teacher
- CF integration: teacher cancel → compensation record
- Policy: `ConfigurableCancellationPolicy` teacher cancel
**Notes:** CN-06 teacher cancel always compensates.

---

### US-029: Confirm or reject student reschedule request

As a **teacher**,  
I want to accept or decline a student's reschedule request,  
so that my calendar stays accurate.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-011, US-054  
**Acceptance Criteria:**
- Given pending reschedule request, when I confirm with valid new slot, then `confirmSessionReschedule` updates session time.
- Given I decline, when request expires per `requestExpiresHours`, then original time remains and student notified.
**Tests Required:**
- CF integration: `confirmSessionReschedule`
- Widget: teacher action on session detail
**Notes:** Teacher confirm UI on shared session detail.

---

### US-030: Mark student no-show after grace period

As a **teacher**,  
I want to mark a student as no-show after the grace period,  
so that attendance is recorded correctly.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-052, US-053 (`markSessionNoShow`)  
**Acceptance Criteria:**
- Given session start passed + `gracePeriodMinutes` elapsed, when I mark no-show, then status `studentNoShow`.
- Given before grace elapsed, when I attempt mark, then UI blocks.
- Given student had joined (attendance evidence), when I attempt mark, then blocked.
**Tests Required:**
- Unit: `MarkNoShowUseCase`
- CF integration: `markSessionNoShow`
- Policy: NS-03, NS-04
**Notes:** T-09 planned; system job also runs (NS-01, NS-02).

---

### US-031: Join session as teacher via meeting link

As a **teacher**,  
I want to open the meeting link from my session detail,  
so that I can start the session on time.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-008  
**Acceptance Criteria:**
- Given session with `meetingLink`, when I open teacher session detail, then join CTA opens same link as student.
- Given external meeting call type, when join tapped, then URL launcher invoked.
**Tests Required:**
- Widget: session detail teacher view join CTA
**Notes:** Shared S-08/T-07 screen.

---

### US-032: Request reschedule as teacher

As a **teacher**,  
I want to request a new time when I cannot make the scheduled slot,  
so that the student can accept an alternative.

**Priority:** P2  
**Release:** Free Beta  
**Dependencies:** US-054  
**Acceptance Criteria:**
- Given policy allows and session >24h out, when I request reschedule with reason, then student notified to confirm.
- Given student confirms, when CF completes, then new time active.
**Tests Required:**
- Unit: `RequestRescheduleUseCase` actor=teacher
- CF integration: reschedule request flow
**Notes:** Counterparty consent per blueprint decision #5.

---

## E-03 — Admin Operations

### US-033: Review pending teacher applications

As an **admin**,  
I want to list and review pending teacher applications,  
so that I approve qualified teachers.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-045, US-020  
**Acceptance Criteria:**
- Given admin claim, when I open `/quran-sessions/applications`, then pending applications list with applicant name, phone (admin-only), submitted date.
- Given I open detail, when I approve, then `reviewTeacherApplication` CF creates `TeacherProfile` and application status `approved`.
- Given I reject with reason, when saved, then 30-day cooldown applied per ADR-003.
**Tests Required:**
- Admin UI: `teacher-applications.component`, `teacher-application-detail.component`
- CF integration: `reviewTeacherApplication`
**Notes:** Admin UI exists (`apps/tilawa_admin`).

---

### US-034: Seed and manage approved teacher supply

As an **admin**,  
I want at least 5 approved public teachers in EG market for Beta,  
so that students have bookable supply.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-033, US-022  
**Acceptance Criteria:**
- Given staging environment, when seed script or manual approvals complete, then ≥5 teachers appear in student list with `verificationStatus: verified` and `pricingType: free`.
- Given teacher suspended, when student lists teachers, then suspended teacher hidden.
**Tests Required:**
- Manual: teacher list count on staging
- Firestore: teacher profile public read rules
**Notes:** B0-2 in blueprint — seed ≥5 teachers.

---

### US-035: Suspend or revoke teacher profile

As an **admin**,  
I want to suspend or permanently revoke a teacher,  
so that unsafe or policy-violating teachers are removed.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-033  
**Acceptance Criteria:**
- Given verified teacher, when I suspend with `restrictionReason`, then profile status `suspended` and future bookings blocked.
- Given revoked, when former teacher applies again, then permanently blocked.
- Given active sessions exist, when I suspend, then admin warned to cancel sessions manually.
**Tests Required:**
- Unit: `SuspendTeacherProfileUseCase`, `RevokeTeacherProfileUseCase`
- CF: moderation callables
- Admin UI: teacher detail actions (partial A-05)
**Notes:** Use cases exist in domain.

---

### US-036: Block or restrict student account

As an **admin**,  
I want to block a student account for policy violations,  
so that they cannot book sessions.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-045, US-048  
**Acceptance Criteria:**
- Given admin action via `moderateQuranSessionsUser` CF, when student blocked, then `accountStatus: blocked` and `createSessionBooking` returns `account_blocked` (smoke #3).
- Given blocked user, when they attempt client-side profile status change, then Firestore rules deny (smoke #2).
**Tests Required:**
- CF integration: blocked booking
- Firestore rules: `test:rules`
- Unit: `BlockAccountUseCase`
**Notes:** `BlockAccountUseCase` in domain; admin UI on users list.

---

### US-037: List and filter all sessions

As an **admin**,  
I want to browse sessions with filters by status, teacher, student, date,  
so that I can monitor platform activity.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-051  
**Acceptance Criteria:**
- Given admin opens `/quran-sessions/sessions`, when list loads, then sessions show lifecycle status, participants, time.
- Given filter by `disputed`, when applied, then only disputed sessions shown.
**Tests Required:**
- Admin UI: `sessions.component`
- Manual: staging data walkthrough
**Notes:** A-07 exists.

---

### US-038: Inspect session detail and timeline

As an **admin**,  
I want to view full session detail including audit timeline,  
so that I can investigate issues.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-037  
**Acceptance Criteria:**
- Given session ID, when I open `session-detail.component`, then booking + session fields, lifecycle status, meeting link (admin view), event timeline visible.
- Given compensation issued, when I view detail, then ledger reference link shown.
**Tests Required:**
- Admin UI: `session-detail.component`
- Unit: `GetSessionTimelineUseCase`
**Notes:** A-08 exists; audit export A-15 deferred.

---

### US-039: Admin session actions (cancel, no-show, force reschedule)

As an **admin**,  
I want to perform privileged session actions via CF facade,  
so that I can resolve operational issues.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050–US-054  
**Acceptance Criteria:**
- Given active session, when I admin-cancel with compensation choice, then `cancelSessionBooking` actor=admin and compensation per CN-09.
- Given session past grace, when I mark teacher no-show, then compensation auto-applied per policy.
- Given direct Firestore write attempted from admin panel, when saved, then **denied** — all mutations via callables.
**Tests Required:**
- CF integration: admin actor paths
- Admin UI: A-09 session actions panel (partial)
**Notes:** Anti-pattern: admin direct Firestore writes — must use facade.

---

### US-040: Reports queue for safety concerns

As an **admin**,  
I want a queue of student/teacher safety reports,  
so that I triage concerns within SLA.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-015  
**Acceptance Criteria:**
- Given reports submitted, when I open `/quran-sessions/reports`, then list shows status, category, session link, reporter (admin view).
- Given I resolve report, when `resolveSessionReport` called, then status updated and notifications sent.
**Tests Required:**
- CF integration: `reportSessionConcern`, `resolveSessionReport`
- Admin UI: A-10 (new)
**Notes:** **Planned** — A-10 not built.

---

### US-041: Disputes queue and resolution

As an **admin**,  
I want to resolve session disputes with compensation/refund choices,  
so that students receive fair outcomes.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-016  
**Acceptance Criteria:**
- Given open dispute, when I resolve `favor_student`, then `manual_pending` refund ledger doc created (smoke #7).
- Given resolve `with_compensation`, when saved, then compensation ledger `manual_pending` (smoke #8).
- Given resolution saved, when parties view session, then terminal status reflects outcome.
**Tests Required:**
- CF integration: `openSessionDispute`, `resolveSessionDispute`
- Admin UI: A-11 (new)
**Notes:** Financial ledger helpers in `financialLedgerService.ts`.

---

### US-042: Record manual pending compensation

As an **admin**,  
I want to issue session credit compensation without automated payment,  
so that Beta remediation works without PSP.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-056  
**Acceptance Criteria:**
- Given teacher cancel triggered compensation, when ledger written, then type `restoreSessionCredit` and status `manual_pending` or `applied` per Beta config.
- Given monetary compensation type selected in Paid phase, when Beta config, then blocked or downgraded to credit only.
**Tests Required:**
- CF integration: `issueSessionCompensation`
- Unit: `IssueCompensationUseCase`, `ConfigurableCompensationPolicy`
**Notes:** Beta: non-monetary types only per business-rules.

---

### US-043: Inspect bookings collection read-only

As an **admin**,  
I want read access to booking commercial state linked to sessions,  
so that I reconcile booking vs session lifecycle.

**Priority:** P2  
**Release:** Free Beta  
**Dependencies:** US-037  
**Acceptance Criteria:**
- Given session detail, when booking section loads, then `bookingId`, pricing type, payment reference (if any) visible.
- Given lifecycle mismatch, when backfill script run, then admin sees consistent status post-backfill.
**Tests Required:**
- Manual: backfill dry-run + verify in admin
**Notes:** Backfill scripts in `functions/` per production-readiness-p0.

---

### US-044: Moderate user list for Quran Sessions

As an **admin**,  
I want to view users with Quran Sessions profile fields,  
so that I can identify accounts needing action.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-046  
**Acceptance Criteria:**
- Given admin opens `/quran-sessions/users`, when list loads, then users show role, accountStatus, market location.
- Given user selected, when I trigger block, then CF moderation callable invoked (not client write).
**Tests Required:**
- Admin UI: `quran-sessions-users.component`
**Notes:** A-06 exists.

---

## E-04 — Backend & Platform

### US-045: Real auth UID in all session routes and DI

As a **system**,  
I want every Quran Sessions repository call scoped to the signed-in Firebase UID,  
so that users only see their own data.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** `AuthSessionProvider`, `FirebaseAuthSessionProvider`  
**Acceptance Criteria:**
- Given signed-in user, when any session BLoC loads, then `userId` from `requireQuranSessionsUserId` not `'student_mvp'`.
- Given teacher dashboard route, when teacher opens, then resolves teacher profile by auth UID mapping.
- Given signed out, when sessions route accessed, then redirect to auth.
**Tests Required:**
- Unit: session provider injection
- Integration: multi-user data isolation on staging
**Notes:** Mostly done per roadmap §16; verify teacher dashboard route.

---

### US-046: Persist quranSessionsProfile to Firestore

As a **system**,  
I want student/teacher profile fields read/written to `users/{uid}.quranSessionsProfile`,  
so that profile survives app restart.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-045  
**Acceptance Criteria:**
- Given new sign-in, when first sessions entry, then `getOrCreateProfile` writes shell with `profileCompleted: false`.
- Given profile completion, when saved, then all fields persist and `profileCompleted: true`.
- Given app restart, when profile loaded, then same data returned.
**Tests Required:**
- Unit: `UserProfileRepositoryImpl` with fake datasource
- Emulator: Firestore read/write rules for owner
**Notes:** `FirestoreUserProfileDataSource` shipped per roadmap.

---

### US-047: Deny client writes to bookings and sessions

As a **system**,  
I want Firestore rules to block direct client mutation of booking/session docs,  
so that lifecycle integrity is server-authoritative.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050  
**Acceptance Criteria:**
- Given student client, when direct write to `quran_bookings/{id}`, then rules deny.
- Given participant, when read own session, then allowed.
- Given non-participant, when read session, then deny.
**Tests Required:**
- Firestore rules: `npm run test:rules`
- Manual: unauthorized cancel smoke #1
**Notes:** `firestore.rules` + draft docs in `docs/security/`.

---

### US-048: Wire configurable policies from Firestore

As a **system**,  
I want cancellation, reschedule, compensation, and no-show policies resolved from config hierarchy,  
so that ops can tune without app release.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-059  
**Acceptance Criteria:**
- Given platform + EG market config, when cancel evaluated, then `ConfigurableCancellationPolicy` uses merged config not hardcoded 24h.
- Given missing config, when policy requested, then code fallback logged and used (emergency only).
**Tests Required:**
- Unit: `ConfigurableCancellationPolicy`, `ConfigurableCompensationPolicy` — CP-*, CO-*
- CF: policy load in cancel/book paths
**Notes:** Anti-pattern: hardcoded UI copy — read resolved policy.

---

### US-049: Server-side slot generation and integrity validation

As a **system**,  
I want bookable slots generated from teacher schedule server-side with integrity checks,  
so that double-booking races are prevented.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-023  
**Acceptance Criteria:**
- Given teacher schedule saved, when `createSessionBooking` runs, then `BookingIntegrityValidator` checks slot free, teacher verified, not vacation day.
- Given concurrent bookings same slot, when second request arrives, then `already-exists` / slot lock failure.
**Tests Required:**
- Unit: `BookingIntegrityValidator` BI-01..BI-06
- CF integration: `bookingEligibilityService.ts`, smoke #5
**Notes:** Client-side slot check is race-prone — CF authoritative.

---

### US-050: createSessionBooking callable end-to-end

As a **system**,  
I want free bookings created atomically via Cloud Function,  
so that booking + session docs stay consistent.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-047, US-049, US-058  
**Acceptance Criteria:**
- Given free teacher + valid slot, when CF called with `pricingType: free`, then booking + session created with `lifecycleStatus: scheduled` and `meetingLink` populated.
- Given paid teacher in Beta, when CF called, then `payment_provider_unavailable` (smoke #10).
- Given idempotency key duplicate, when retried, then same result (smoke #4).
**Tests Required:**
- CF integration: `createSessionBooking.ts`
- Unit: `CreateSessionBookingUseCase` → gateway
**Notes:** `functions/src/quranSessions/createSessionBooking.ts`.

---

### US-051: Firestore session and booking read repositories

As a **system**,  
I want Flutter app to read sessions/bookings from Firestore via repository impl,  
so that My Sessions and dashboards show live data.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-045, US-047  
**Acceptance Criteria:**
- Given production `QuranSessionsModule`, when `GetStudentSessionsUseCase` called, then Firestore query returns user's sessions ordered by time.
- Given teacher dashboard, when `GetTeacherSessionsUseCase` called, then teacher's sessions returned.
- Given DTO mapping, when legacy `status` and `lifecycleStatus` differ, then mapper prefers `lifecycleStatus` with fallback.
**Tests Required:**
- Unit: `SessionMapper`, `BookingMapper`
- Integration: read after book on staging
**Notes:** Dual-read until backfill complete.

---

### US-052: Populate meeting link on session creation

As a **system**,  
I want external meeting link set at booking time from teacher config or platform default,  
so that join flow works without manual admin step.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050  
**Acceptance Criteria:**
- Given `SessionCallType.externalMeeting`, when session created, then `meetingLink` non-null URL on session doc.
- Given teacher has personal meeting URL on profile, when booked, then teacher URL used; else platform default.
**Tests Required:**
- CF integration: create path sets link field
- Unit: session entity mapping
**Notes:** Blocks US-008, US-031.

---

### US-053: cancelSessionBooking callable with actor attribution

As a **system**,  
I want cancellations attributed to student, teacher, or admin with policy side-effects,  
so that audit and compensation are correct.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-048, US-047  
**Acceptance Criteria:**
- Given student cancel early, when CF completes, then `cancelledByStudent` + slot released.
- Given teacher cancel, when CF completes, then `cancelledByTeacher` + compensation job enqueued.
- Given non-participant cancel attempt, then `permission-denied` (smoke #1).
**Tests Required:**
- CF integration: `cancelSessionBooking.ts`
- Unit: `CancelSessionUseCase` all actors
**Notes:** Fixes legacy "always student cancel" gap.

---

### US-054: Reschedule callables (request + confirm)

As a **system**,  
I want reschedule flow executed atomically on confirm,  
so that old slot releases and new slot locks together.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-049, US-050  
**Acceptance Criteria:**
- Given valid reschedule request, when `requestSessionReschedule` succeeds, then pending request doc created with expiry.
- Given teacher confirms, when `confirmSessionReschedule` runs, then slot swap atomic; status returns `scheduled`.
- Given expired request, when confirm attempted, then failure.
**Tests Required:**
- CF integration: `requestSessionReschedule.ts`, `confirmSessionReschedule.ts`
- Unit: reschedule use cases
**Notes:** `reschedule_session_screen.dart` must call gateway.

---

### US-055: Wire FCM delivery for session notifications

As a **system**,  
I want outbox events delivered via FCM to device tokens,  
so that users receive booking and lifecycle pushes.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** app `FcmService`, `fcmTokenService.ts`  
**Acceptance Criteria:**
- Given outbox event `booking_confirmed`, when `deliverSessionNotification` runs, then FCM message sent to participant tokens in `users/{uid}/fcm_tokens`.
- Given invalid token, when delivery fails, then token pruned and error logged.
**Tests Required:**
- CF unit: `deliverSessionNotification.ts`, `notificationOutboxService.ts`
- Integration: end-to-end push on staging device
**Notes:** `functions/src/quranSessions/deliverSessionNotification.ts`.

---

### US-056: Financial ledger manual_pending records

As a **system**,  
I want refunds and compensations recorded as ledger docs without PSP calls in Beta,  
so that finance can reconcile manually later.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-053, US-041  
**Acceptance Criteria:**
- Given dispute resolution favor_student, when ledger written, then `quran_session_refunds` doc status `manual_pending`.
- Given duplicate refund approval, when same idempotency key, then one doc (smoke #6).
**Tests Required:**
- CF integration: `financialLedgerService.ts`, smoke #6–8
**Notes:** No real payment/payout in Beta.

---

### US-057: Scheduled jobs — reminders, expiry, no-show detection

As a **system**,  
I want cron/scheduled functions to send reminders, expire pending reservations, and mark no-shows,  
so that lifecycle progresses without manual intervention.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-055  
**Acceptance Criteria:**
- Given session in 24h, when `sessionReminders` job runs, then reminder outbox event created.
- Given `pendingPayment` expired (Paid only), when `expirePendingReservations` runs, then status `expired` — Beta: verify no-op on free-only.
- Given grace elapsed with no joins, when no-show job runs, then appropriate no-show status per NS-02.
**Tests Required:**
- CF unit: `sessionReminders.ts`, `expirePendingReservations.ts`, `markSessionNoShow.ts`
- Integration: smoke #9 expiry sync (paid path)
**Notes:** Call webhooks deferred; job-only for Beta.

---

### US-058: Feature flags per environment

As a **system**,  
I want `quranSessionsEnabled`, `teacherApplicationEnabled`, `quranSessionsBookingEnabled` controllable per build/environment,  
so that we can stage rollout and emergency kill.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** `quran_sessions_feature_flags.dart`, Remote Config optional  
**Acceptance Criteria:**
- Given staging build, when `quranSessionsBookingEnabled=true`, then booking UI active.
- Given production before launch, when flag false, then booking blocked with user-visible message.
- Given kill switch drill, when flag flipped false mid-Beta, then new bookings blocked; existing sessions readable.
**Tests Required:**
- Unit: feature flag resolution
- Manual: kill switch drill in Sprint 7
**Notes:** Booking flag **false** in prod today.

---

### US-059: Market config from Firestore

As a **system**,  
I want `quran_session_market_configs/{countryCode}` loaded for profile and eligibility,  
so that Egypt market enables booking with correct currency.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-046  
**Acceptance Criteria:**
- Given EG market doc `isEnabled: true`, when student completes profile with Cairo, then booking allowed.
- Given disabled market, when student attempts book, then `MarketNotEnabledFailure`.
**Tests Required:**
- Unit: `MarketConfigRepositoryImpl`, `GetMarketConfigUseCase`
- Emulator: market doc read
**Notes:** `FakeMvpMarketConfigRepository` for tests; prod impl exists per roadmap.

---

### US-060: Lifecycle backfill and consistency scripts

As a **system**,  
I want one-time backfill to align `lifecycleStatus` with legacy `status` fields,  
so that queries and UI show consistent state.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-051  
**Acceptance Criteria:**
- Given staging data with mismatches, when dry-run backfill executes, then report lists affected docs.
- Given apply backfill, when complete, then 0 ambiguous rows per B0-9.
- Given post-backfill, when app reads session, then `lifecycleStatus` authoritative.
**Tests Required:**
- Manual: `npm run quran-sessions:backfill-lifecycle` dry-run + apply
- Manual: `quran-sessions:backfill-booking-session-consistency`
**Notes:** Scripts documented in production-readiness-p0.md.

---

## E-05 — Release & Quality

### US-061: ValidateBookingEligibilityUseCase test suite

As a **system**,  
I want 12+ unit tests covering gender, child, market, and blocked account rules,  
so that safety logic cannot regress.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-005  
**Acceptance Criteria:**
- Given test matrix UC-VE-01..12, when `flutter test` runs, then all pass.
- Given new policy field added, when test missing, then CI fails coverage gate for use case file.
**Tests Required:**
- Unit: `validate_booking_eligibility_usecase_test.dart` (new)
**Notes:** **0 tests today** — roadmap P0 blocker.

---

### US-062: Widget tests for booking and session detail

As a **system**,  
I want widget tests for critical student paths,  
so that UI regressions are caught in CI.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-006, US-008  
**Acceptance Criteria:**
- Given fake repos, when `BookingScreen` widget test runs, then eligibility block and success paths render.
- Given session with link, when `SessionDetailScreen` test runs, then join CTA visible.
**Tests Required:**
- Widget: `test/features/quran_sessions/booking_screen_test.dart`, `session_detail_screen_test.dart`
**Notes:** WS-01, WS-03 in blueprint test-matrix.

---

### US-063: CF integration and rules test CI gate

As a **system**,  
I want `npm run test:integration` and `npm run test:rules` green in CI before deploy,  
so that backend regressions block release.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050–US-057  
**Acceptance Criteria:**
- Given PR touching `functions/src/quranSessions/`, when CI runs, then integration + rules tests execute on JDK 21+ emulator.
- Given test failure, when merge attempted, then blocked.
**Tests Required:**
- CI: functions test pipeline
**Notes:** production-readiness-p0 local verification commands.

---

### US-064: ProfileCompletionBloc test coverage

As a **system**,  
I want ProfileCompletionBloc unit tests for the profile gate,  
so that the critical entry gate is verified.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-004  
**Acceptance Criteria:**
- Given load, edit gender/DOB/country/city, save success and failure paths, when tests run, then all pass.
**Tests Required:**
- BLoC: `profile_completion_bloc_test.dart` (new)
**Notes:** Roadmap P0 gap.

---

### US-065: Staging deploy and smoke 10/10

As a **system**,  
I want staging Firebase deploy with full smoke checklist pass,  
so that Beta validation environment is trustworthy.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-050–US-060  
**Acceptance Criteria:**
- Given CF + rules deployed to staging, when smoke checklist 10 items run, then all pass per production-readiness-p0.md.
- Given smoke failure, when triaged, then P0 bug filed before Sprint 8.
**Tests Required:**
- Manual: staging smoke script
- E2E smoke: student/teacher/admin test accounts
**Notes:** Sprint 7 primary deliverable.

---

### US-066: Performance and load sanity check

As a **system**,  
I want teacher list and booking paths tested on low-end device and slow network,  
so that Beta users on budget phones have acceptable UX.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-002, US-006  
**Acceptance Criteria:**
- Given slow 3G throttling, when teacher list loads, then skeleton shown and TTI <5s on OPPO A98 class device.
- Given booking submit, when network slow, then loading state prevents double-tap duplicate requests (idempotency key same).
**Tests Required:**
- Manual: device matrix slow network row
- Optional: Firebase Performance traces
**Notes:** See qa-test-plan.md device matrix.

---

### US-067: Backfill production data pre-launch

As a **system**,  
I want production backfill executed after deploy with audit log,  
so that prod data matches lifecycle model before flag on.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-060, US-065  
**Acceptance Criteria:**
- Given prod deploy, when backfill dry-run shows 0 unexpected errors, then apply with ops sign-off.
- Given backfill complete, when sample sessions checked in admin, then lifecycle consistent.
**Tests Required:**
- Manual: backfill scripts with audit
**Notes:** Run after prod CF deploy, before booking flag.

---

### US-068: Google Play internal testing track upload

As a **system**,  
I want Beta APK/AAB on Play internal track for core team,  
so that install/update flow is validated before closed Beta.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-065  
**Acceptance Criteria:**
- Given signed release build, when uploaded to internal track, then core team installs and opens sessions feature.
- Given version code incremented, when prior build installed, then update offered.
**Tests Required:**
- Manual: internal track install on OPPO A98 + Pixel class device
**Notes:** See google-play-release-plan.md.

---

### US-069: Closed testing with trusted teachers and students

As a **system**,  
I want closed Play track for 20+ trusted users completing full flows,  
so that real-world feedback collected before staged rollout.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-068, beta-testing-plan.md  
**Acceptance Criteria:**
- Given closed testers enrolled, when ≥20 complete book→join→complete, then Beta success metric met.
- Given booking failure rate >5% (excl. user error), when measured, then stop condition triggered.
**Tests Required:**
- Manual: Beta cohort tracking spreadsheet
- Analytics: `AnalyticsConstants` session events
**Notes:** Sprint 8 focus.

---

### US-070: Staged production rollout on Play

As a **system**,  
I want staged rollout (5% → 20% → 50% → 100%) with monitoring,  
so that production issues are contained.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-069, US-071  
**Acceptance Criteria:**
- Given staged rollout at 5%, when crash-free sessions >99%, then advance to next stage.
- Given P0 bug or kill switch triggered, when rollback plan executed, then halt rollout.
**Tests Required:**
- Manual: Play Console staged rollout
- Sentry: error rate monitoring
**Notes:** Post–closed Beta success.

---

### US-071: Sentry and CF error alerting

As a **system**,  
I want Sentry alerts on Quran Sessions CF errors and Flutter crashes in session routes,  
so that ops responds within 1h during Beta.

**Priority:** P1  
**Release:** Free Beta  
**Dependencies:** US-065  
**Acceptance Criteria:**
- Given CF `createSessionBooking` error spike, when threshold exceeded, then alert fires.
- Given session screen crash, when reported to Sentry, then tagged `quran_sessions` for filter.
**Tests Required:**
- Manual: test error injection on staging
**Notes:** `user-Sentry` MCP available for verification.

---

### US-072: Rollback drill before public rollout

As a **system**,  
I want documented rollback executed once on staging,  
so that team can disable feature in <15 minutes.

**Priority:** P0  
**Release:** Free Beta  
**Dependencies:** US-058, rollback-plan.md  
**Acceptance Criteria:**
- Given drill start, when `quranSessionsBookingEnabled=false` + hide entry flag, then new bookings blocked within 5 min (Remote Config propagation).
- Given existing sessions, when rollback active, then My Sessions still readable; join links work.
- Given drill complete, when flags restored, then booking resumes on staging.
**Tests Required:**
- Manual: rollback checklist execution
**Notes:** Sprint 7 exit criteria.

---

## Paid Sessions (postponed)

Stories below are **out of Sprint 0–8 scope**. Marked for future planning only.

### US-P01: Paid session checkout UI

**Priority:** P0 (Paid) | **Release:** Paid Sessions — postponed  
Payment sheet, price display, `pendingPayment` soft lock. Depends on PSP selection.

### US-P02: PaymentProvider implementation (Tap/Stripe EG)

**Priority:** P0 (Paid) | **Release:** Paid Sessions — postponed  
`charge` + `refund` against sandbox then prod.

### US-P03: Automated refund on early student cancel

**Priority:** P0 (Paid) | **Release:** Paid Sessions — postponed  
RF-01..05 rules with PSP idempotency.

### US-P04: Teacher pricing self-serve editor

**Priority:** P1 (Paid) | **Release:** Paid Sessions — postponed  
T-12 screen; market bounds from admin config.

### US-P05: Teacher earnings and payout dashboard

**Priority:** P1 (Paid) | **Release:** Paid Sessions — postponed  
T-10, payout batch job PO-* rules.

### US-P06: Admin financial ledger UI (A-12)

**Priority:** P0 (Paid) | **Release:** Paid Sessions — postponed  
Settle `manual_pending` → paid with finance sign-off.

### US-P07: Subscription session packages

**Priority:** P2 (Paid) | **Release:** Paid Sessions — postponed  
SUB-* rules; entity only today.

### US-P08: In-app Agora voice/video calls

**Priority:** P2 (Paid) | **Release:** Paid Sessions — postponed  
`AgoraCallProvider` V2; external meeting sufficient until then.

---

## Story count summary

| Epic | Stories | P0 | P1 | P2 |
|------|---------|----|----|-----|
| E-01 Student | 18 | 9 | 6 | 3 |
| E-02 Teacher | 14 | 7 | 5 | 2 |
| E-03 Admin | 12 | 6 | 4 | 2 |
| E-04 Backend | 16 | 14 | 1 | 1 |
| E-05 Release | 12 | 8 | 3 | 1 |
| **Total** | **72** | **44** | **19** | **9** |
