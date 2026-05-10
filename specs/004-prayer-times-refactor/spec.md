# Feature Specification: Prayer Times Screen Stability and Refactor

**Feature Branch**: `stable`
**Created**: 2026-04-30
**Last Updated**: 2026-05-10
**Status**: Implemented in codebase — visual QA/goldens pending
**Input**: User description: "Refactor PrayerTimesBloc to resolve SOLID and Data Structure inefficiencies, then stabilize the Prayer Times screen UI/UX so it feels polished, easy to scan, and suitable for Google Play screenshot #1."

## Current Scope Snapshot (2026-05-10)

The Prayer Times screen is now a Today-first dashboard with a strong Next Prayer
hero, compact privacy-safe location context, a grouped daily schedule, contextual
alert state chips, and lightweight utility actions for Qibla and Manage Alerts.

The feature is no longer treated as a minimal release-only pass. The current
priority is a stable, high-quality Prayer Times UI/UX that follows KISS, YAGNI,
SOLID, Clean Architecture, Atomic Design, Tilawa UI Kit tokens, centralized
colors/tokens, and English/Arabic support.

### Current Codebase State

- `PrayerTimesBloc` owns prayer time loading, settings persistence, location,
  monthly data, and scheduling triggers.
- `PrayerPermissionsCubit` owns Android notification/exact alarm/battery
  capability checks and permission request state.
- Countdown ticking is UI-owned, not BLoC-owned.
- Row data is mapped through `PrayerRowViewDataMapper`; widgets do not directly
  derive alert rules from domain settings.
- Prayer time display formatting is centralized in
  `PrayerTimeLabelFormatter`.
- Privacy-safe location display is centralized in
  `PrayerLocationLabelFormatter`.
- Next Prayer hero, row chips, and schedule rows use Tilawa UI Kit primitives and
  `theme.tokens`.
- Time Adjustments are intentionally frozen and hidden for now; a TODO remains
  in `PrayerSettingsSheet`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Permissions Separation (Priority: P1)

Developers and the application need the prayer times capability (notification and exact alarm permissions) separated from the core prayer calculations. This ensures that requesting or checking permissions doesn't artificially bundle with prayer calculations, preventing God Class violations.

**Why this priority**: Core architectural separation to maintain the Single Responsibility Principle, making tests and logic flow cleaner.

**Independent Test**: Can be fully tested by opening the Prayer Settings Sheet, toggling permissions, and verifying that capability changes without triggering unintended side-effects in the core prayer calculation state.

**Acceptance Scenarios**:

1. **Given** the user navigates to prayer settings, **When** they tap to grant Notification Permission, **Then** the capability state updates independently and a single schedule refresh is triggered.
2. **Given** the app is running, **When** capability is checked in the background, **Then** only the permission state is queried without loading GPS or calculating prayer times.

---

### User Story 2 - UI-Driven Countdown Timer (Priority: P2)

Users need the "time until next prayer" countdown to smoothly tick every second without causing performance jank or heavy battery drain.

**Why this priority**: Currently, a 1-second interval forces the entire PrayerTimesBloc to re-emit state and perform deep `Equatable` comparisons (including lists and settings). Dropping this from the Bloc into a lightweight UI Stream drastically improves O(1) performance.

**Independent Test**: Can be fully tested by observing the countdown on the Prayer Times screen and verifying using Flutter DevTools that the Bloc is not emitting a state every second, but the UI is still updating accurately.

**Acceptance Scenarios**:

1. **Given** the user is viewing the prayer times screen, **When** the countdown ticks down each second, **Then** only the countdown widget rebuilds without triggering a full Bloc state copy.
2. **Given** the user leaves the screen, **When** the screen is disposed, **Then** the Stream stops ticking, saving resources.

---

### User Story 3 - Polished Today Dashboard (Priority: P1)

Users need the Prayer Times screen to quickly answer "what prayer is next, when
is it, and what alerts are configured?" without scanning through dense settings
or technical icon-only controls.

**Why this priority**: This is the primary Prayer Times experience and must be
strong enough for Google Play screenshot #1.

**Independent Test**: Open the Prayer Times tab with loaded prayer times and
verify the next prayer, countdown, location, alert state, schedule rows, Qibla,
and Manage Alerts are all understandable within one screen.

**Acceptance Scenarios**:

1. **Given** today's prayer times are loaded, **When** the user opens the screen,
   **Then** the Next Prayer hero is the dominant visual element and shows the
   next prayer, scheduled time, countdown, date context, and alert state.
2. **Given** a prayer row supports alerts, **When** the user scans the schedule,
   **Then** the row shows a readable alert state chip: Off, Notify only, or
   Adhan.
3. **Given** the next prayer appears in the schedule, **When** the user scans the
   list, **Then** the row is subtly highlighted and visually connected to the
   hero.

---

### User Story 4 - Focused Alert Controls (Priority: P1)

Users need prayer alert controls to be understandable and hard to trigger
accidentally.

**Why this priority**: Inline notification/adhan toggles are compact but create
risk of accidental rescheduling and unclear dependency between notification and
Adhan.

**Independent Test**: Tap a prayer row and verify a focused bottom sheet opens
with only valid alert modes for that prayer.

**Acceptance Scenarios**:

1. **Given** a five-prayer row is tapped, **When** the alert sheet opens, **Then**
   it offers Off, Notify only, and Adhan.
2. **Given** Sunrise is enabled in the display options, **When** the Sunrise row
   is tapped, **Then** the alert sheet offers only Off and Notify only.
3. **Given** notification is Off, **When** settings are persisted, **Then** Adhan
   is also unavailable for that prayer.
4. **Given** Notify only is selected, **When** settings are persisted, **Then** a
   notification is scheduled without Adhan audio.

---

### User Story 5 - Simple Prayer Settings Sheet (Priority: P2)

Users need Prayer Settings to be lightweight and predictable, without hidden
draft state or a save/discard trap.

**Why this priority**: Settings are preferences and should apply immediately, as
the alert sheets already do.

**Independent Test**: Toggle 24-hour format and Show Sunrise, then dismiss the
sheet without pressing any save button.

**Acceptance Scenarios**:

1. **Given** the Prayer Settings sheet is open, **When** the user changes a
   dropdown or switch, **Then** the setting applies immediately.
2. **Given** the user dismisses the sheet via Done, back, or outside tap, **Then**
   no setting change is lost.
3. **Given** the user toggles 24-hour format, **When** the screen updates, **Then**
   all prayer time displays use the selected format consistently.

### Edge Cases

- How does system behave if user denies required permissions (exact alarm)? (It will reflect accurately in the new cubit state).
- What happens on low-memory devices? (Performance is improved since heavy state allocation every second is avoided).
- Does the countdown drift out of sync with real-time? (StreamBuilder.periodic ensures stable tick rate).
- If the user taps outside Prayer Settings after changing controls, changes must
  already be applied.
- If Sunrise is hidden, its notification setting may still exist but the row is
  not displayed.
- If Sunrise is shown, it must never expose Adhan controls.
- If the user changes 24-hour format while Monthly is open, monthly rows must
  rebuild with the new format.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST manage Notification and Exact Alarm permissions in an isolated state container (`PrayerPermissionsCubit`).
- **FR-002**: System MUST NOT run a periodic `Timer` inside `PrayerTimesBloc` for countdown ticking.
- **FR-003**: System MUST calculate the time until the next prayer locally in the UI layer (e.g., via `StreamBuilder.periodic`).
- **FR-004**: System MUST trigger `loadPrayerTimes(forceReschedule: true)` exactly once when permissions transition to a granted state.
- **FR-005**: System MUST make Next Prayer the dominant hero of the Today view.
- **FR-006**: System MUST show per-prayer alert state using readable row chips,
  not icon-only inline toggles.
- **FR-007**: System MUST open a focused per-prayer alert bottom sheet from a
  prayer row tap.
- **FR-008**: System MUST support exactly three alert modes for five prayers:
  Off, Notify only, and Adhan.
- **FR-009**: System MUST support exactly two alert modes for Sunrise: Off and
  Notify only.
- **FR-010**: System MUST prevent Adhan from being enabled when notification is
  disabled.
- **FR-011**: System MUST prevent Adhan from being enabled for Sunrise.
- **FR-012**: System MUST keep Qibla accessible but visually secondary.
- **FR-013**: System MUST keep Manage Alerts discoverable but not heavier than
  the prayer schedule.
- **FR-014**: System MUST keep location compact and privacy-safe.
- **FR-015**: System MUST apply 24-hour format consistently across hero, today
  rows, monthly rows, and legacy prayer time widgets.
- **FR-016**: System MUST keep business logic out of widgets by using feature
  presentation mappers/formatters.
- **FR-017**: System MUST use Tilawa UI Kit primitives and design tokens for
  spacing, color, radius, typography, and card treatments.
- **FR-018**: System MUST keep Prayer Settings immediate-apply, without a Save
  button or unsaved draft state.
- **FR-019**: System MUST hide Time Adjustments until the Prayer Times UX
  stabilizes.

### Key Entities 

- **PrayerAlarmCapability**: Holds the current notification and alarm permission states.
- **PrayerTimesState**: The core state containing current settings, location, and the pre-calculated prayer times for the day/month.
- **PrayerRowViewData**: Presentation model for one row in the Today schedule.
- **PrayerAlertViewData**: Presentation model for readable alert chip state and
  whether the row supports alerts/Adhan.
- **PrayerAlertMode**: Domain setting state: none, notification, or adhan.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Performance profile shows zero `PrayerTimesBloc` state emissions occurring on a 1-second interval while viewing the prayer times screen.
- **SC-002**: `PrayerTimesBloc` lines of code and dependencies are reduced, explicitly separating permission use cases out of its constructor.
- **SC-003**: Users continue to receive accurate prayer time countdowns natively.
- **SC-004**: A first-time user can identify the next prayer and remaining time
  within 3 seconds of opening the screen.
- **SC-005**: A user can identify whether a prayer is Off, Notify only, or Adhan
  without interpreting icon-only controls.
- **SC-006**: Sunrise never shows an Adhan option in row or global alert
  controls.
- **SC-007**: 24-hour format toggle updates all Prayer Times surfaces without
  restarting the screen.
- **SC-008**: Prayer Settings changes persist when the sheet is dismissed by any
  standard modal-dismiss gesture.
- **SC-009**: English and Arabic layouts remain readable without overflow in the
  hero, row chips, settings sheet, and alert sheet.

## Assumptions

- We assume no other blocs depend heavily on the 1-second interval previously emitted by `PrayerTimesBloc`.
- We assume the existing UI components (`PrayerTimesScreen` and `PrayerSettingsSheet`) can easily consume the newly decoupled state structures.
- We assume Time Adjustments are advanced controls and can remain hidden until a
  later UX pass.
- We assume Sunrise notification is useful as a reminder, but Adhan is not
  appropriate for Sunrise.
