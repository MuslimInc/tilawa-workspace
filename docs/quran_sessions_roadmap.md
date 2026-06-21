# Quran Sessions — Implementation Roadmap

> **Single source of truth** for feature status, architecture health, and
> production readiness. Update this file as work lands.
>
> Last updated: 2026-06-21 (pricing & location requirements added)
> Branch: `feature/quran-sessions`

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Completed — verified in codebase |
| [~] | Partially implemented |
| ☐ | Not started |
| 🚫 | Deferred (explicit decision) |
| ⛔ | Blocked (dependency missing) |

---

## 1. Product — MVP Scope

**Completion: ~55%**

### 1.1 Quran Sessions MVP

- ✅ Feature entry card on Home dashboard (`HomeSessionsEntryCard`)
- ✅ Profile gate at entry point — redirects to completion screen if profile incomplete
- ✅ Profile gate at booking screen — belt-and-suspenders check before slot loading
- ✅ Sessions home screen — abbreviated teacher list + navigation
- ✅ Full teacher list with infinite scroll pagination
- ✅ Teacher profile screen — bio, rating, pricing, availability
- ✅ Booking screen — slot selection, call type picker, eligibility inline errors
- ✅ My Sessions screen — upcoming + past sessions, cancel, review
- ✅ Teacher dashboard screen — teacher's sessions + availability overview
- ✅ Profile completion screen — gender, date of birth, country, city (all required)
- ✅ Experimental badge on CTA (MVP signal to users)
- [~] Session cancellation — domain + fake layer done; cancellation reason UI missing
- ☐ Session rescheduling — policy defined, use case in repo interface, no UI
- ☐ Real external meeting link display (MVP call type — link shown to student)

### 1.2 Teacher Marketplace

- ✅ Teacher data model (name, bio, gender, rating, pricing, specializations, languages)
- ✅ Verified teacher badge / verification status entity
- [~] Teacher filtering — BLoC wired (specialization + language params), no filter chip UI
- ☐ Teacher search by name
- ☐ Teacher sorting (rating, price, availability)
- ☐ Teacher reviews list on profile screen

### 1.3 Student Experience

- ✅ Browse teachers
- ✅ View teacher profile
- ✅ View availability slots (14-day rolling window)
- ✅ Book a session
- ✅ View own sessions
- ✅ Cancel a session (domain + fake layer)
- ✅ Submit a review after a session
- ☐ Reschedule a session
- ☐ Search teachers
- ☐ Filter by specialization / language (UI)
- ☐ Notification when booking confirmed
- ☐ Reminder before session

### 1.4 Teacher Experience

- ✅ Dashboard with sessions and availability overview
- ✅ Teacher profile display (read-only card shown to students)
- [~] Teacher profile completion — use case exists (`CompleteTeacherProfileUseCase`), no screen
- ☐ Teacher onboarding flow (screen + form)
- ☐ Availability management (add / remove slots from dashboard)
- ☐ Weekly schedule template
- ☐ Teacher earnings screen
- ☐ Teacher review history screen
- ☐ Teacher receiving booking notifications

### 1.5 Teacher Application & Identity (ADR-003)

> Teacher is a verified profile, not a user role. See [ADR-003](adr/003-teacher-application-lifecycle.md).

- ✅ `UserRole` — removed `teacher`; roles are now `student | admin | moderator`
- ✅ `TeacherApplication` entity — private/admin-facing; carries phone, lifecycle state
- ✅ `TeacherProfile` entity — public/student-facing; no sensitive fields
- ✅ `TeacherApplicationRepository` — interface + fake MVP implementation
- ✅ `TeacherProfileRepository` — interface + fake MVP implementation
- ✅ `StartTeacherApplicationUseCase`
- ✅ `SaveTeacherApplicationDraftUseCase`
- ✅ `SubmitTeacherApplicationUseCase` — validates phone (E.164) + completeness
- ✅ `GetTeacherApplicationStatusUseCase`
- ✅ `ApproveTeacherApplicationUseCase` — creates `TeacherProfile` on approval
- ✅ `RejectTeacherApplicationUseCase` — 30-day re-application cooldown
- ✅ `SuspendTeacherProfileUseCase`
- ✅ `RevokeTeacherProfileUseCase` — permanent; no re-application
- ✅ 11 typed teacher application/profile failures
- 🚫 OTP phone verification — deferred to post-MVP (see ADR-003 §Deferred)
- ✅ Teacher application screen (`TeacherApplicationScreen`) — phone, languages, specializations, bio
- ✅ Teacher application status screen (`TeacherApplicationStatusScreen`) — shows pending/approved/rejected/etc.
- ✅ "أريد أن أصبح محفظًا" entry card on sessions home screen
- ✅ Debug simulate-approval button (kDebugMode only — tree-shaken in release)
- ✅ Routes: `/sessions/teacher/apply`, `/sessions/teacher/status`
- ✅ `TeacherApplicationBloc` — events-based, handles draft/submit/simulate-approval
- ✅ Dashboard edit slot: `AvailabilitySlotEdited` event + UI edit button
- 🚫 Admin application review screen — deferred (no admin UI)
- 🚫 Path selection / onboarding choice screen — deferred (entry card on home is sufficient for MVP)

### 1.6 Admin Experience

- ✅ `BlockAccountUseCase` — domain layer
- ✅ `UpdateTeacherEligibilityPolicyUseCase` — domain layer
- ✅ `GetSessionPolicyUseCase` — domain layer
- ✅ `ApproveTeacherApplicationUseCase` — domain layer
- ✅ `RejectTeacherApplicationUseCase` — domain layer
- ✅ `SuspendTeacherProfileUseCase` — domain layer
- ✅ `RevokeTeacherProfileUseCase` — domain layer
- ☐ Admin dashboard screen
- ☐ Teacher application review screen
- ☐ Teacher suspension/revocation screen
- ☐ User suspension flow
- ☐ Report management
- ☐ Content moderation
- ☐ Audit logs

---

## 2. Architecture

**Completion: ~85%**

### 2.1 Package Boundaries

- ✅ `packages/quran_sessions/` — pure domain + presentation package (no Firebase, no HTTP)
- ✅ `apps/tilawa/lib/features/quran_sessions/` — app-layer wiring (DI, fakes, routing)
- ✅ No `BuildContext` below presentation layer
- ✅ No Firebase/HTTP imports inside the domain
- ✅ Payment, call, and scheduling logic isolated behind boundary interfaces
- ✅ Public barrel file (`quran_sessions.dart`) — clean export surface
- [~] Production `QuranSessionsModule` — structure ready but missing `UserProfileRepository` and `SessionPolicyRepository` registration

### 2.2 Domain Entities

- ✅ `UserProfile` (userId, role, gender, dateOfBirth, countryCode, countryName, cityId, cityName, currencyCode, timezone, accountStatus, guardianId)
- ✅ `SessionPrice` (amount, currencyCode, countryCode, cityId) — market-resolved; no exchange-rate conversion in MVP
- ✅ `MarketConfig` + `CityConfig` — Firestore `quran_session_market_configs/{countryCode}` shape; MVP: Egypt/EGP only
- ✅ `QuranTeacher` (id, displayName, gender, verificationStatus, pricingType, price: SessionPrice?, specializations, languages, rating)
- ✅ `QuranBooking` (lifecycle: pending → confirmed → completed/cancelled/refunded)
- ✅ `QuranSession` (scheduled → inProgress → completed/cancelled/noShow)
- ✅ `TeacherAvailability` (slotId, startsAt, endsAt, isBooked)
- ✅ `QuranSessionSafetyPolicy` (global: gender rules, child threshold, recording)
- ✅ `TeacherEligibilityPolicy` (per-teacher: allowed genders, canTeachChildren)
- ✅ `SessionReview` (rating, comment)
- ✅ `SessionCallType` (externalMeeting, voiceCall, videoCall)
- ✅ `SessionPricingType` (free, fixedPerSession, subscription)
- ✅ `TeacherVerificationStatus` (pending, verified, rejected, suspended)
- ✅ `UserRole`, `UserGender`, `UserAgeGroup`, `AccountStatus`, `AccountRestrictionReason`

### 2.3 Repository Interfaces

- ✅ `MarketConfigRepository` (getMarketConfig, getSupportedMarkets, getCityConfig)
- ✅ `TeacherRepository` (getTeachers w/ pagination, getById, getAvailableSlots, getReviews, resolveTeacherPrice)
- ✅ `BookingRepository` (create, cancel, reschedule, getStudentBookings, submitReview)
- ✅ `SessionRepository` (getById, getStudentSessions, getTeacherSessions, updateNotes)
- ✅ `UserProfileRepository` (getProfile, updateProfile, blockAccount)
- ✅ `SessionPolicyRepository` (getGlobalPolicy, getTeacherEligibilityPolicy, update*)
- ✅ `AvailabilityProvider` (boundary interface for scheduling)
- ✅ `PaymentProvider` (boundary interface — charge, refund)
- ✅ `CallProvider` (boundary interface — join, leave, end)
- ✅ `TeacherPayoutProvider` (boundary interface stub)

### 2.4 Remote Data Sources (interfaces)

- ✅ `BookingRemoteDataSource` (create, cancel, reschedule, getStudentBookings, submitReview)
- ✅ `TeacherRemoteDataSource` (getTeachers, getById, getAvailableSlots, getReviews)
- ✅ `SessionRemoteDataSource` (getById, getStudentSessions, getTeacherSessions, updateNotes)
- ☐ `UserProfileRemoteDataSource` — no interface, no implementation
- ☐ `SessionPolicyRemoteDataSource` — no interface, no implementation

### 2.5 Data Layer (Implementations)

- ✅ `BookingRepositoryImpl` (wraps remote data source + error mapping)
- ✅ `TeacherRepositoryImpl`
- ✅ `SessionRepositoryImpl`
- ✅ `TeacherMapper`, `BookingMapper`, `SessionMapper`, `ReviewMapper`, `AvailabilityMapper`
- ✅ `QuranTeacherDto`, `QuranBookingDto`, `QuranSessionDto`, `SessionReviewDto`, `TeacherAvailabilityDto`
- ✅ `RepositoryErrorMapper` (RemoteException → QuranSessionsFailure)
- ✅ All MVP fake repositories: Teacher, Booking, Session, UserProfile, SessionPolicy, Availability, MarketConfig
- ✅ `QuranSessionsMvpStore` — shared singleton; per-market teacher pricing map (`EG_cairo`, etc.)
- ✅ `FakeMvpMarketConfigRepository` — Egypt/EGP market (Cairo, Alexandria, Giza); EGP is Egypt-only, not a global default
- ☐ `UserProfileRepositoryImpl` — no Firestore implementation
- ☐ `SessionPolicyRepositoryImpl` — no Firestore implementation
- ☐ Concrete Firestore data source for teachers, bookings, sessions
- ☐ `UserProfileDto` + UserProfile mapper

### 2.6 Use Cases

- ✅ `GetTeachersUseCase`
- ✅ `GetTeacherProfileUseCase`
- ✅ `GetTeacherAvailabilityUseCase`
- ✅ `GetStudentSessionsUseCase`
- ✅ `GetTeacherSessionsUseCase`
- ✅ `CreateBookingUseCase`
- ✅ `CancelBookingUseCase`
- ✅ `SubmitReviewUseCase`
- ✅ `GetUserProfileUseCase`
- ✅ `CompleteStudentProfileUseCase`
- ✅ `CompleteTeacherProfileUseCase`
- ✅ `GetSessionPolicyUseCase`
- ✅ `UpdateTeacherEligibilityPolicyUseCase`
- ✅ `BlockAccountUseCase`
- ✅ `GetMarketConfigUseCase` (getMarketConfig for country, allMarkets)
- ✅ `ValidateBookingEligibilityUseCase` — 8-step chain: profile completeness (incl. country/city) → market enabled → teacher verified → teacher pricing in market → global policy → teacher policy → gender → age
- ✅ `PriceFormatter` — formats `SessionPrice` with per-currency symbols; no exchange-rate conversion
- ☐ `RescheduleBookingUseCase` — no dedicated use case (only repo method)
- ☐ `UpdateTeacherAvailabilityUseCase`
- ☐ `ApproveTeacherUseCase`
- ☐ `SuspendAccountUseCase`

### 2.7 Failure Hierarchy

- ✅ `NetworkFailure`, `TimeoutFailure`
- ✅ `ServerFailure`, `UnauthorizedFailure`
- ✅ `NotFoundFailure`, `ValidationFailure`
- ✅ `SlotUnavailableFailure`, `BookingConflictFailure`
- ✅ `ProfileIncompleteFailure`, `GenderNotAllowedFailure`, `AgeNotAllowedFailure`
- ✅ `TeacherNotVerifiedFailure`, `AccountBlockedFailure`, `GuardianApprovalRequiredFailure`
- ✅ `PolicyViolationFailure`
- ✅ `MarketNotEnabledFailure` (country/city disabled), `TeacherNotInMarketFailure` (paid teacher has no price for student's market)
- ✅ `PaymentDeclinedFailure`, `PaymentCancelledFailure`, `PaymentProviderFailure`
- ✅ `CacheFailure`, `UnknownFailure`
- ✅ Arabic fallback `toLocalizedMessage()` in package (`QuranSessionsFailureUi`)
- ☐ `toLocalizedMessage` wired to app l10n ARB keys (currently uses hardcoded Arabic strings)

### 2.8 Dependency Injection

- ✅ `QuranSessionsMvpModule` — full MVP fake wiring (all repos, use cases, BLoC factories)
- ✅ `QuranSessionsModule` — production skeleton (teacher, booking, session layer only)
- [~] Production module missing: `UserProfileRepository`, `SessionPolicyRepository`, `ValidateBookingEligibilityUseCase`, `ProfileCompletionBloc`, eligibility use cases
- ☐ Real auth UID plumbed into DI (currently hardcoded `'student_mvp'`)

### 2.9 Routing

- ✅ `QuranSessionsRoutes` constants (`/sessions`, `/sessions/teachers`, etc.)
- ✅ All 7 MVP routes in `quranSessionsRoutes` with BLoC provision
- ✅ Integrated into app router (`app_router.dart`)
- ✅ Profile completion route returns `bool` result to caller
- [~] `teacherDashboard` route is hardcoded to `teacher_1` — not auth-aware

### 2.10 BLoC Architecture

- ✅ `TeacherListBloc` (load, load more, filter)
- ✅ `TeacherProfileBloc` (load profile + availability)
- ✅ `BookingBloc` (eligibility check → slot load → submit; eligibility retry)
- ✅ `MySessionsBloc` (load sessions, cancel, submit review)
- ✅ `TeacherDashboardBloc` (load sessions + availability, toggle slot availability)
- ✅ `ProfileCompletionBloc` (load, edit gender + DOB, submit)
- ☐ `AdminBloc` — not started
- ☐ `TeacherOnboardingBloc` — not started

---

## 3. User Profiles

**Completion: ~60%**

### 3.1 Google Sign-In

- ✅ `AuthService` with `signInWithGoogle()`
- ✅ Firebase Auth integration
- ✅ `UserRepository` writes Google profile to Firestore `users/{uid}` (displayName, email, photoUrl, createdAt, lastSignInTime)
- ✅ FCM token stored in `users/{uid}/fcm_tokens`
- ✅ `AuthBloc` wired in app shell

### 3.2 Quran Sessions Profile (`quranSessionsProfile` in Firestore)

- ✅ `UserProfile` domain entity — all required fields including location:
  `role, gender, dateOfBirth, countryCode, countryName, cityId, cityName, currencyCode, timezone, accountStatus, guardianId`
- ✅ `UserProfile.isComplete` — requires gender + dateOfBirth + countryCode + cityId (all four)
- ✅ `UserProfile.ageGroup(threshold)` — derives child/adult from DOB
- ✅ `UserProfile.missingFields` — machine-readable list for `ProfileIncompleteFailure` (includes `countryCode`, `cityId`)
- ☐ Firestore `UserProfileRepositoryImpl` — `quranSessionsProfile` sub-document not written or read
- ☐ `UserProfileDto` — no DTO for serialization
- ☐ Auto-create student profile on first sign-in

### 3.3 Profile Fields

- [~] `fullName` — entity has `displayName` field; completion screen does not collect it yet
- ✅ `gender` — collected in `ProfileCompletionScreen`, persisted via use case
- ✅ `dateOfBirth` — collected in `ProfileCompletionScreen`, persisted via use case
- ✅ `ageGroup` — computed from DOB at runtime; not stored (computed on read)
- ✅ `role` — entity supports student/teacher/admin; MVP defaults to student
- ✅ `accountStatus` — active/underReview/suspended/blocked
- ✅ `countryCode` (ISO 3166-1 alpha-2) — **required**; collected in `ProfileCompletionScreen`
- ✅ `countryName` — display name, stored alongside `countryCode`
- ✅ `cityId` — **required**; machine ID within country (e.g. `'cairo'`)
- ✅ `cityName` — display name, stored alongside `cityId`
- ✅ `currencyCode` (ISO 4217) — derived from `CityConfig` at completion time; drives price display
- ✅ `timezone` (IANA tz) — stored for scheduling; not yet used for display
- ☐ `guardianId` / guardian information — modeled, not collected

> **Currency rule:** `currencyCode` comes from the student's market config, never hardcoded
> in widgets. `EGP` is Egypt-specific, not a global default. Multi-currency display
> uses `PriceFormatter`; exchange-rate conversion is deferred.

> **Location rule:** country/city must be explicitly selected by the student. Google
> account country, device locale, IP address, and GPS are not trusted as profile data.
> They may be used as *suggestions* only (MVP auto-suggests Egypt when it is the only
> enabled market, but the user must confirm).

### 3.4 Profile Completion Flow

- ✅ Gate at `HomeSessionsEntryCard` — checks profile before navigating to sessions
- ✅ Gate at `BookingScreen` — eligibility check before slot loading (belt-and-suspenders)
- ✅ `ProfileCompletionScreen` — gender, date of birth, country picker, city picker
- ✅ `ProfileCompletionBloc` — load → edit (gender + DOB + country + city) → save → return `true`
- ✅ Country dropdown populated from `GetMarketConfigUseCase.allMarkets()` (backend-controlled)
- ✅ City dropdown populated from selected market's `enabledCities`; cleared when country changes
- ✅ MVP auto-suggests the only enabled market (Egypt) for new profiles; city still requires explicit pick
- ✅ On completion, returns to the booking flow automatically
- ☐ Real auth UID passed to profile gate (currently hardcoded `'student_mvp'`)
- ☐ `fullName` field in completion screen
- ☐ Skip / remind-later flow for optional fields

---

## 4. Safety & Eligibility

**Completion: ~70%**

- ✅ `ValidateBookingEligibilityUseCase` — all checks in domain layer, bypassed only by tests
- ✅ Step 1 — Student profile completeness: requires gender + DOB + **countryCode + cityId**; emits `ProfileIncompleteFailure` with `missingFields`
- ✅ Step 2 — Student account active check; emits `AccountBlockedFailure`
- ✅ Step 3 — Market enabled: verifies `MarketConfig.isEnabled` + `CityConfig.isEnabled`; emits `MarketNotEnabledFailure`
- ✅ Step 4 — Teacher exists + verified; emits `TeacherNotVerifiedFailure`
- ✅ Step 4b — **Teacher pricing in student's market**: for paid teachers, `resolveTeacherPrice(countryCode, cityId)` must return non-null; emits `TeacherNotInMarketFailure`
- ✅ Step 5 — Global safety policy fetch
- ✅ Step 6 — Per-teacher eligibility policy fetch
- ✅ Step 7 — Gender combination check (teacher vs student, global + teacher policy)
- ✅ Step 8 — Child age detection using `childAgeThreshold`; `canTeachChildren` + guardian approval
- ✅ Teacher `canTeachChildren` check
- ✅ `GuardianApprovalRequiredFailure` emitted when required
- ✅ `AccountBlockedFailure` with typed restriction reason
- ✅ All eligibility failures surfaced inline in `BookingScreen` (`_EligibilityBlockedView`)
- ✅ "إكمال الملف الشخصي" CTA rendered inline for `ProfileIncompleteFailure`
- ✅ Retry eligibility after profile completion without re-navigating
- [~] Guardian approval flow — failure emitted, no UI to handle it (no guardian linking screen)
- ☐ Admin-initiated account suspension (use case exists, no admin UI or trigger)
- ☐ `videoCallAllowedForChildren` policy enforced in call type picker
- ☐ Reporting / flagging a teacher or session

---

## 5. Student Features

**Completion: ~65%**

- ✅ Home screen entry card with experimental badge
- ✅ Sessions hub screen (`QuranSessionsHomeScreen`)
- ✅ Teacher list with infinite scroll and pagination
- ✅ Teacher profile screen (bio, rating, price, specializations, call types, availability)
- ✅ Availability slot picker (14-day rolling window, grouped by date)
- ✅ Booking screen with slot selection + call type selection
- ✅ Eligibility gate UI with per-failure inline messaging
- ✅ Booking success with snackbar + navigation to My Sessions
- ✅ My Sessions screen (upcoming + past, grouped or listed)
- ✅ Session card with teacher name, time, status
- ✅ Submit review from completed session
- [~] Cancel session — domain + fake impl; no cancel reason picker or confirmation dialog
- ☐ Reschedule session
- ☐ Teacher search (name search)
- ☐ Filter bar UI (specialization chips, language chips) — BLoC wired, UI missing
- ☐ Pagination loading indicator in teacher list
- ☐ Pull-to-refresh on My Sessions
- ☐ Empty state illustrations (using text only currently)

---

## 6. Teacher Features

**Completion: ~25%**

- ✅ Teacher profile display in marketplace (read-only, student-facing)
- ✅ Teacher initials avatar widget (no real avatars yet)
- ✅ Teacher dashboard screen (upcoming sessions, availability slots)
- ✅ Slot availability toggle from dashboard (`TeacherDashboardBloc`)
- ✅ `CompleteTeacherProfileUseCase` — domain layer
- ☐ Teacher onboarding screen (collect gender, bio, specializations, languages)
- ☐ Teacher profile edit screen
- ☐ Availability management UI (add / remove / bulk-edit slots)
- ☐ Weekly schedule template
- ☐ Earnings screen
- ☐ Review history screen
- ☐ Real avatar upload
- ☐ Teacher verification status display
- ☐ Teacher-side session notes

---

## 7. Admin Features

**Completion: ~10%**

Domain layer has the building blocks; no admin UI exists.

- ✅ `BlockAccountUseCase`
- ✅ `UpdateTeacherEligibilityPolicyUseCase`
- ✅ `GetSessionPolicyUseCase`
- ✅ Typed `AccountRestrictionReason` enum (falseIdentity, policyViolation, safetyConcern, abuseReport, repeatedNoShow, adminDecision)
- ☐ Admin dashboard screen
- ☐ Teacher approval / rejection flow
- ☐ Teacher suspension screen
- ☐ User suspension screen
- ☐ Global safety policy editor
- ☐ Per-teacher eligibility policy editor
- ☐ Session reports
- ☐ Moderation queue
- ☐ Audit log

---

## 8. Scheduling

**Completion: ~35%**

- ✅ `TeacherAvailability` entity (slotId, startsAt, endsAt, isBooked)
- ✅ `AvailabilityProvider` boundary interface
- ✅ Fake 14-day rolling slot generation per teacher
- ✅ `DateGroupedSlotPicker` widget (slots grouped by date in UI)
- ✅ `BookingPolicy` — minimum lead time validation (1 hour default)
- ✅ `CancellationPolicy` — full refund >24 h, no refund within 24 h
- ✅ `ReschedulePolicy` — max 1 reschedule, >24 h window
- [~] Slot conflict: fake layer marks slot as booked on create; real-time conflict race not handled
- ☐ Teacher slot management (CRUD from teacher's dashboard)
- ☐ Weekly schedule template (recurring availability)
- ☐ Time zone handling — all times are device-local; no UTC storage or tz display
- ☐ Ramadan schedule adjustments
- ☐ Recurring session bookings
- ☐ Multi-session package booking

---

## 9. Calls

**Completion: ~15%**

- ✅ `CallProvider` abstract boundary interface
- ✅ `CallRoom` model
- ✅ `CallTokenProvider` interface
- ✅ `ExternalMeetingCallProvider` — stub (opens external URL)
- ✅ `AgoraCallProvider` — stub; throws `UnimplementedError` (scoped to V2)
- ✅ `WebRtcCallProvider` — stub (scoped to V3)
- ✅ `SessionCallType` UI picker in `BookingScreen`
- ✅ `meetingLink` field on `QuranSession` entity
- ☐ Working external meeting link flow — link not yet displayed or opened in student My Sessions
- ☐ In-app voice/video call UI (any provider)
- ☐ `videoCallAllowedForChildren` policy enforced in call type picker
- 🚫 Agora integration — deferred to V2 (explicit comment in `AgoraCallProvider`)
- 🚫 WebRTC integration — deferred to V3

---

## 10. Pricing & Market Configuration

**Completion: ~65%**

> **Architecture decision:** all pricing comes from the backend (`quran_session_market_configs/`
> Firestore collection), never from hardcoded app values. Currency is derived from the
> student's market profile — `EGP` is Egypt's currency only, not a global default.
> Exchange-rate conversion is deferred post-MVP. Payments are deferred post-MVP.

- ✅ `SessionPrice` entity — `{amount, currencyCode, countryCode, cityId?}`
- ✅ `MarketConfig` + `CityConfig` — mirrors `quran_session_market_configs/{countryCode}/cities/{cityId}`
- ✅ `MarketConfigRepository` interface — `getMarketConfig`, `getSupportedMarkets`, `getCityConfig`
- ✅ `GetMarketConfigUseCase` — `call(countryCode)` and `allMarkets()`
- ✅ `FakeMvpMarketConfigRepository` — Egypt/EGP; Cairo, Alexandria, Giza; all enabled
- ✅ `QuranSessionsMvpStore.teacherMarketPricing` — per-market price map (`EG_cairo` → `SessionPrice`)
- ✅ `TeacherRepository.resolveTeacherPrice(teacherId, countryCode, cityId)` — market-aware price lookup
- ✅ `PriceFormatter.format` / `formatOrFree` — symbol mapping per ISO 4217 code; no hardcoded currency
- ✅ Teacher card and teacher profile screen show price via `PriceFormatter` (not raw numbers)
- ✅ `SessionPriceDto` + `SessionPriceDtoMapper` — wire DTO to domain (`SessionPrice`)
- ✅ Eligibility check validates teacher has pricing in student's market before booking
- ☐ `MarketConfigRemoteDataSource` — no Firestore implementation yet
- ☐ `MarketConfigRepositoryImpl` — no production implementation
- ☐ Teacher pricing management (admin sets `teachers/{id}/pricing/{marketId}` in Firestore)
- ☐ Multi-country market support (only Egypt enabled in MVP)
- ☐ Exchange-rate display (e.g. show EGP and approximate USD) — deferred

## 11. Payments

**Completion: ~10%**

- ✅ `PaymentProvider` boundary interface (charge, refund)
- ✅ `TeacherPayoutProvider` boundary interface
- ✅ `SessionPricingType` entity (free, fixedPerSession, subscription)
- ✅ `PaymentFailure` hierarchy (ChargeDeclinedFailure, ChargeCancelledFailure, GatewayFailure)
- ✅ `BookingRepository.createBooking` accepts `paymentReference` (opaque token)
- ✅ `payment_failure_mapper.dart` in `BookingBloc` (maps PaymentFailure → QuranSessionsFailure)
- ☐ Any concrete `PaymentProvider` implementation (Stripe, Tap, etc.)
- ☐ Payment flow wired into `BookingBloc` (currently skips payment for free sessions)
- ☐ Paid session booking UI (price display, payment sheet)
- ☐ Commission model / platform fee configuration
- ☐ Teacher payout implementation
- ☐ Refund flow
- ☐ Payment history / receipts
- 🚫 Payment integration — deferred post-MVP; EGP/Egypt market must be validated end-to-end first
- 🚫 Multi-currency payment settlement — deferred; single market (Egypt/EGP) first

---

## 12. Notifications

**Completion: ~15%**

The app-level FCM infrastructure exists but is not wired to Quran Sessions events.

- ✅ FCM service (`FcmService`) in app features/notifications
- ✅ FCM token storage in Firestore (`users/{uid}/fcm_tokens`)
- ✅ `FcmNotificationHandlerService` in app
- ✅ `NotificationsRepository` interface in app
- ☐ Booking confirmation notification (trigger + FCM message)
- ☐ Session reminder (24 h + 1 h before)
- ☐ Teacher notification when new booking received
- ☐ Cancellation alert to both parties
- ☐ Notification deep-link into session detail
- ☐ Notification action routing for Quran Sessions routes

---

## 13. Localization

**Completion: ~20%**

- ✅ All screen text is in Arabic — the primary language
- [~] Failure messages Arabic — provided by `QuranSessionsFailureUi` extension but using hardcoded strings, not ARB keys
- ☐ No Quran Sessions strings in `app_ar.arb` or `app_en.arb`
- ☐ All UI strings hardcoded in Dart files (not through `context.l10n`)
- ☐ English localization for any session screen
- ☐ RTL layout audit for sessions screens
- ☐ Date/time formatted using device locale (currently `intl` used directly in screens)
- ☐ Arabic date formatting in `ProfileCompletionScreen` is locale-correct (uses `intl` with `'ar'`)

---

## 14. Testing

**Completion: ~40%**

### BLoC Tests (packages/quran_sessions/test/)

- ✅ `BookingBlocTest` — eligibility gate, slot selection, booking submit, failure handling
- ✅ `MySessionsBlocTest`
- ✅ `TeacherDashboardBlocTest`
- ✅ `TeacherListBlocTest`
- ✅ `TeacherProfileBlocTest`
- ☐ `ProfileCompletionBlocTest` — not started
- ☐ `ValidateBookingEligibilityUseCase` unit tests — use case untested

### Domain / Use Case Tests

- ✅ `CreateBookingUseCaseTest`
- ✅ `GetTeachersUseCaseTest`
- ☐ `CompleteStudentProfileUseCase` tests
- ☐ `ValidateBookingEligibilityUseCase` tests (gender rules, child rules, etc.)

### Boundary Tests

- ✅ `BookingPolicyTest`
- ✅ `CancellationPolicyTest`
- ✅ `CallProviderTest`

### Data Tests

- ✅ `TeacherMapperTest`
- ☐ Mapper tests for Booking, Session, Review, Availability

### Fake / Fixture Infrastructure

- ✅ `FakeTeacherRepository`
- ✅ `FakeBookingRepository`
- ✅ `FakeSessionRepository`
- ✅ `FakeUserProfileRepository`
- ✅ `FakeSessionPolicyRepository`
- ✅ `FakeAvailabilityProvider`
- ✅ `FakeMarketConfigRepository` (Egypt/EGP; used in booking bloc tests)
- ✅ `FakeCallProvider`, `FakePaymentProvider`
- ✅ `fixtures.dart` — `makeTeacher` now includes default EGP market price; `makeProfile` accepts `countryCode`/`cityId`

### Widget Tests

- ☐ `ProfileCompletionScreen` widget test
- ☐ `BookingScreen` widget test
- ☐ `TeacherListScreen` widget test
- ☐ `MySessionsScreen` widget test

### Integration Tests

- ☐ End-to-end booking flow test
- ☐ Profile completion gate flow test

---

## 15. Documentation

**Completion: ~20%**

- ✅ Inline doc comments on all domain entities and use cases
- ✅ `AgoraCallProvider` deferred V2 notice
- ✅ `QuranSessionsModule` usage example in class doc
- ✅ `QuranSessionsFailureUi` usage example in class doc
- ✅ `docs/adr/ADR-001` (GoRouter root overlay for Quran player)
- ☐ Quran Sessions product spec document
- ☐ Safety policy document (child rules, gender rules)
- ☐ Teacher marketplace policy
- ☐ ADR for Quran Sessions architecture decisions
- ☐ ADR for fake-first MVP approach
- ☐ Contributor guide for adding a new session feature

---

## 16. Production Readiness

### 🔴 Must Have Before Launch

> The feature cannot go live without these.

- [ ] **Real auth UID** — replace hardcoded `'student_mvp'` with `FirebaseAuth.instance.currentUser!.uid` everywhere (entry card, routes, BLoCs)
- [ ] **`UserProfileRepositoryImpl`** — read/write `users/{uid}.quranSessionsProfile` in Firestore (dto + mapper + remote data source)
- [ ] **Auto-create student profile** — on first Google Sign-In, write a `quranSessionsProfile` document with `role: student`, `profileCompleted: false`, `accountStatus: active`
- [ ] **Firestore `UserProfileRemoteDataSource`** — interface + implementation
- [ ] **`UserProfileDto`** — serialization model for the Firestore sub-document
- [ ] **`MarketConfigRepositoryImpl`** — read `quran_session_market_configs/{countryCode}` from Firestore (pricing is backend-controlled, not in app)
- [ ] **Real teacher data in Firestore** — remove fake teacher list, wire real data source; teacher pricing in `teachers/{id}/pricing/{marketId}`
- [ ] **External meeting link shown to student** — display `meetingLink` in My Sessions for confirmed sessions
- [ ] **Production `QuranSessionsModule` complete** — register `UserProfileRepository`, `SessionPolicyRepository`, `ValidateBookingEligibilityUseCase`, `ProfileCompletionBloc`
- [ ] **Session strings in ARB** — move all hardcoded Arabic strings out of Dart files into `app_ar.arb`
- [ ] **`ProfileCompletionBlocTest`** — zero test coverage on this critical gate
- [ ] **`ValidateBookingEligibilityUseCase` tests** — core safety logic untested

### 🟡 Should Have Before Launch

> Required for a complete user experience but not a launch blocker.

- [ ] **Teacher filter UI** — specialization + language chips (BLoC already wired)
- [ ] **Cancel session confirmation dialog** with cancellation reason picker
- [ ] **Booking confirmation notification** — FCM push on booking success
- [ ] **Session reminder notification** — FCM push 24 h + 1 h before
- [ ] **English localization** — session strings in `app_en.arb`
- [ ] **Pull-to-refresh** on My Sessions
- [ ] **Empty state illustrations** for no-sessions and no-teachers views
- [ ] **`fullName` field** in profile completion screen
- [ ] **RTL layout audit** of all session screens

### 🟢 Nice to Have (Post-Launch)

> Can ship later.

- [ ] Teacher onboarding screen
- [ ] Teacher availability management UI
- [ ] Weekly schedule template
- [ ] Session reschedule UI
- [ ] Admin dashboard
- [ ] Teacher review history screen
- [ ] Teacher earnings screen
- [ ] Search by teacher name
- [ ] Guardian linking and approval flow
- [ ] Payment integration (Tap / Stripe)
- [ ] In-app voice call (Agora V2)
- [ ] In-app video call (Agora / WebRTC V3)
- [ ] Ramadan scheduling adjustments
- [ ] Recurring session packages

---

## 17. Section Completion Summary

| Section | Status | % |
|---------|--------|---|
| Product — MVP | Partially implemented | ~60% |
| Architecture | Mostly complete | ~85% |
| User Profiles | Partially implemented | ~70% |
| Safety & Eligibility | Mostly complete | ~80% |
| Pricing & Market Config | MVP fake done | ~65% |
| Student Features | Partially implemented | ~65% |
| Teacher Features | Early stage | ~25% |
| Admin Features | Domain only | ~10% |
| Scheduling | Domain + fake done | ~35% |
| Calls | Stubs only | ~15% |
| Payments | Deferred (MVP: free) | ~10% |
| Notifications | Not started | ~15% |
| Localization | Arabic hardcoded | ~20% |
| Testing | BLoC layer covered | ~40% |
| Documentation | Sparse | ~20% |
| **Overall** | | **~40%** |

---

## 18. Top 10 Remaining Tasks

Priority-ordered by production impact.

| # | Task | Why |
|---|------|-----|
| 1 | Replace `'student_mvp'` with real `FirebaseAuth` UID | Without this, every user sees the same data; feature is not multi-user |
| 2 | `UserProfileRepositoryImpl` (Firestore) + DTO + mapper | Quran Sessions profile is not persisted; data resets on app restart |
| 3 | Auto-create `quranSessionsProfile` document on sign-in | New users have no profile and will hit `NotFoundFailure` on first entry |
| 4 | Complete production `QuranSessionsModule` registration | Eligibility + profile use cases missing from production DI |
| 5 | Move session strings into ARB files | Strings are hardcoded in Dart; English users see Arabic; l10n contract violated |
| 6 | `ProfileCompletionBlocTest` | Core gate has zero test coverage |
| 7 | `ValidateBookingEligibilityUseCase` unit tests | Child/gender safety rules untested |
| 8 | Display `meetingLink` in My Sessions screen | Confirmed sessions show no call link; users cannot join |
| 9 | Filter bar UI (specialization + language chips) | BLoC fully wired; UX gap — users cannot narrow teacher list |
| 10 | Booking confirmation notification (FCM) | Users have no post-booking feedback outside the app |

---

## 19. Recommended Next Milestone

### Milestone: "MVP — Real Users, Real Data"

**Goal:** Feature works end-to-end with real Firebase authentication and real Firestore persistence. Fake data replaced. Suitable for internal testing with real accounts.

**Scope:**
1. Auth UID plumbed everywhere (replace `student_mvp`)
2. `UserProfileRepositoryImpl` + auto-create on sign-in
3. Production `QuranSessionsModule` completed
4. Real teacher data in Firestore (seed script or admin tool)
5. `meetingLink` displayed in My Sessions
6. ARB strings migration (sessions)
7. `ProfileCompletionBlocTest` + `ValidateBookingEligibilityUseCase` tests
8. Booking confirmation FCM notification

**Exit criteria:**
- A fresh Google Sign-In shows the profile gate on first entry
- After profile completion, the gate does not reappear
- Booking a real slot persists to Firestore
- My Sessions shows the booked session with meeting link
- `dart analyze` clean, `flutter test` green

---

## 20. Recommended Implementation Order

```
Phase 1 — Real Data Foundation (next sprint)
  1. Plumb real auth UID everywhere
  2. UserProfileDto + UserProfileRemoteDataSource interface
  3. FirestoreUserProfileDataSource (read/write quranSessionsProfile — incl. countryCode/cityId)
  4. UserProfileRepositoryImpl
  5. Auto-create student profile on sign-in
  6. MarketConfigRepositoryImpl (read quran_session_market_configs from Firestore)
  7. Complete production QuranSessionsModule (incl. MarketConfigRepository)

Phase 2 — Student Flow Completeness
  7. Seed real teacher data in Firestore
  8. Wire TeacherRemoteDataSource to Firestore
  9. Display meetingLink in My Sessions
 10. Cancel session confirmation dialog
 11. Filter bar UI (specialization + language)

Phase 3 — Quality & L10n
 12. Move all session strings to app_ar.arb + app_en.arb
 13. ProfileCompletionBlocTest
 14. ValidateBookingEligibilityUseCase tests
 15. Widget tests (BookingScreen, ProfileCompletionScreen)
 16. RTL layout audit

Phase 4 — Notifications
 17. Booking confirmation FCM trigger
 18. Session reminder (24 h + 1 h)
 19. Notification deep-link routing

Phase 5 — Teacher Side
 20. Teacher onboarding screen
 21. Availability management UI
 22. Weekly schedule template
 23. Teacher review history

Phase 6 — Admin & Policy
 24. Admin dashboard
 25. Teacher approval / suspension flows
 26. Global safety policy editor

Phase 7 — Payments & Calls (post-MVP)
 27. Payment integration (Tap Payments or Stripe)
 28. Paid booking flow
 29. Agora voice/video (V2)
```
