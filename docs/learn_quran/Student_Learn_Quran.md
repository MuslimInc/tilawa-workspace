# Student — Learn Quran (Quran Sessions)

**Scope:** Free 1:1 **video-only** beta. Backend/Admin is the source of truth;
Flutter renders resolved state only. Paid booking, wallet, group sessions, and
in-app Agora/WebRTC are explicitly out of scope.

**Completion (evidence-based, scoped to the free video-only beta): ~92%**
**Verdict: READY (with non-blocking follow-ups)**

---

## Implemented features (verified in code + tests)

- Home entry (`openHomeQuranSessions`) gated by admin `studentEntryEnabled`;
  unauthenticated users routed to `/login`. Feature config is 100%
  admin/Firestore-driven via `QuranSessionsPlatformConfigStore`
  (`quran_sessions_feature_flags.dart`), failing **closed** to `safeFallback`.
- Sessions hub, teacher list (infinite scroll), teacher profile, availability
  slot picker (14-day window), booking screen, My Sessions.
- **Server-authoritative pricing per teacher** (`getBookingPricingQuote` per
  teacher). Row price chip, teacher profile, and booking screen resolve from the
  same server context (`loadBookingEligibilityContext`) → they can never
  disagree.
- **No dead-end booking flow:**
  - Teacher list hides teachers with a non-transient `BookingBlockReason`
    (paid while payment provider disabled, market disabled, admin-disabled,
    teacher not bookable, pricing config missing). When all are hidden →
    dedicated `TeacherListNoBookableTeachers` empty state.
  - Teacher profile disables the Book CTA and shows `BookingBlockNotice` for a
    non-transient block.
  - Transport quote failure (`pricingQuoteUnavailable`) is treated as transient:
    the row stays visible and the booking screen shows neutral retry copy.
- **Free teachers remain bookable**; **paid teachers are not shown as bookable
  when payment is unavailable** — enforced by the same typed `blockReason` in
  list, profile, and booking.
- **Video-only:** call-type picker collapses to a read-only **"Video session"**
  label when the admin `sessionMode`/policy exposes a single call type
  (`_CallTypePicker` in `booking_screen.dart`). No segmented control is rendered.
- Eligibility gate (profile completeness, market, gender, age/guardian) surfaced
  inline with actionable CTAs; retry after profile completion without
  re-navigating.
- External meeting join from My Sessions.

## Checklist

- [x] Admin-driven entry (`studentEntryEnabled`), no dart-define gating
- [x] Per-teacher server pricing quote drives list + profile + booking
- [x] Non-bookable teachers filtered from list; dedicated empty state
- [x] Paid-not-bookable / block-reason notice on profile + booking
- [x] Free teachers bookable
- [x] Video-only read-only label (no call-type selection)
- [x] No dead-end booking paths (verified by widget + bloc tests)
- [x] Booking eligibility inline errors + retry
- [ ] Booking confirmation / reminder push notifications (non-blocking)
- [ ] Pull-to-refresh on My Sessions (non-blocking polish)

## Remaining work (non-blocking)

- FCM booking-confirmation + 24h/1h reminder wiring.
- Per-teacher quote is an **N+1 callable** on list load (one per teacher). Fine
  for a curated beta (5–15 teachers); recommend a batch `getBookingPricingQuotes`
  endpoint before opening to large markets. See Backend doc.

## Launch blockers

- None in the student app code path. (Blockers are ops/QA — see
  Production_Readiness_Learn_Quran.md.)

## Manual QA checklist

- [ ] Fresh sign-in → student entry visible only when admin `studentEntryEnabled=true`.
- [ ] Free teacher → bookable; complete booking; My Sessions shows session + join link.
- [ ] Paid teacher with payment provider disabled → NOT shown as bookable in list;
      profile shows block notice + disabled CTA.
- [ ] All teachers non-bookable → "No teachers available right now" empty state + retry.
- [ ] Booking screen shows read-only "Video session" label, no call-type control.
- [ ] Incomplete profile → inline CTA; after completion, booking proceeds without re-nav.

## Automated test coverage

- `packages/quran_sessions` full suite: **1205 passed / 2 skipped**.
- Key files: `teacher_list_bloc_test.dart` (filter + no-bookable state + per-teacher
  quotes), `booking_screen_test.dart` (video-only label; paid/admin-disabled/
  pricing-missing/quote-unavailable block + retry), `teacher_profile_screen_test.dart`
  (block notice + disabled CTA).
- App widget tests (home/visibility/cubits): **32 passed**.
