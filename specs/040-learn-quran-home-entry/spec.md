# Feature Specification: Learn Quran Home Entry Strategy (ADR-007)

**Feature Branch**: `040-learn-quran-home-entry`  
**Created**: 2026-07-10  
**Status**: Authoritative Spec  

---

## User Scenarios & Testing

### User Story 1 - Personalized Home Priority (Option C)

As a student user, when I open the MeMuslim Home screen, I should see an entry point tailored to my active Quran learning state.

**Priority**: P1  
**Why this priority**: Correctly routing and reminding users of active/imminent sessions, pending payments, or revision homework maximizes engagement and prevents missed sessions.

**Acceptance Scenarios**:

1. **Given** an ongoing session (started <= 15m ago, ends in future), **When** I open the Home screen, **Then** I see the **Live Session Card** with a green "Live now" indicator and a "Join" action routing to the in-app call room details.
2. **Given** an imminent session (starts within next 2 hours), **When** I open the Home screen, **Then** I see the **Imminent Session Card** with a countdown (e.g., "Starts in 45m") and a "Join" action.
3. **Given** a pending booking (awaiting tutor approval or payment), **When** I open the Home screen, **Then** I see the **Pending Booking Card** showing the status (e.g., "Awaiting payment" or "Awaiting tutor approval") with a "View Details" action.
4. **Given** a completed session with a valid revision surah assigned within the last 7 days, **When** I open the Home screen, **Then** I see the **Continue Learning Card** with the surah/ayah focus and a "Practice" action routing to the Quran Reader.
5. **Given** no active learning states, and I have not yet responded to the interest prompt, **When** I open the Home screen, **Then** I see the **Tutoring Interest Prompt Card** asking if I want to learn Quran.

---

### User Story 2 - Fallback & Dismissal Behavior

As a student user, I want the ability to dismiss promotional cards without losing active learning states or overall discoverability.

**Priority**: P1  
**Why this priority**: Users must be able to keep their Home screen clean from promotional material if not interested, but crucial operational states (like live calls or pending payments) must never be hidden.

**Acceptance Scenarios**:

1. **Given** the Tutoring Interest Prompt is visible on Home, **When** I tap "Not Now", **Then** the card is hidden immediately and the fallback Featured Tutor card is also hidden.
2. **Given** I previously dismissed the Interest Prompt, **When** a session is booked, becomes imminent, or needs revision, **Then** the corresponding card (Live, Imminent, Pending, or Revision) is still shown on Home regardless of my previous dismissal.
3. **Given** I dismissed the promotional cards, **When** I want to find a tutor, **Then** the feature remains discoverable through Settings and the Home Dashboard Footer link.

---

## Requirements

### Functional Requirements

- **FR-001**: The system MUST resolve active slot states in this strict priority:
  1. Ongoing live session (startsAt <= now <= endsAt)
  2. Nearest upcoming imminent session within 2 hours (startsAt > now && difference <= 2h)
  3. Pending booking (SessionListClassifier.isStudentPending)
  4. Latest completed past session with a valid revision assigned (revisionSurahNumber >= 1) within 7 days and not yet marked as practiced
  5. None / interest prompt fallback
- **FR-002**: Tapping "Not Now" on the Interest Prompt MUST set `hasSetLearningInterest = true` and `isInterested = false` in the preference store, hiding both the interest card and the fallback Featured Tutor card.
- **FR-003**: Real learning states (FR-001 items 1-4) MUST bypass the interest preference checks and render on the Home screen.
- **FR-004**: Tapping "Practice" on a revision card MUST mark that session revision as practiced immediately so it does not reappear, then route the student to `QuranReaderRoute` at the correct surah/ayah.
- **FR-005**: Tapping "Join" on live/imminent session cards MUST navigate to the Session Detail screen using `QuranSessionsRoutes.sessionDetail` for secure token authorization.
- **FR-006**: When session loading or aggregate loading fails, the Home screen MUST degrade gracefully to the calm fallback state and must not crash or display an error message to the user.
- **FR-007**: Tapping "Yes, interested" on the Interest Prompt MUST NOT remove the Learn Quran section from Home: on the fallback state (`isInterested = true`, no active learning state), the system MUST render a persistent **Learn Quran Browse Card** routing to the tutor list, until a real learning state (FR-001 items 1–4) takes over. Only "Not Now" hides the section (FR-002).

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of widget and unit tests verify correct state priority resolution.
- **SC-002**: Tapping "Practice" resolves state to fallback immediately on the next state load.
- **SC-003**: All string labels are localized in English and Arabic.
- **SC-004**: Static analysis passes with zero warnings (`melos run analyze`).
