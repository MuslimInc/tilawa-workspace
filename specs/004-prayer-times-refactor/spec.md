# Feature Specification: Prayer Times Bloc Refactor

**Feature Branch**: `feature/prayer-times-bloc-refactor`  
**Created**: 2026-04-30  
**Status**: Draft  
**Input**: User description: "Refactor PrayerTimesBloc to resolve SOLID and Data Structure inefficiencies by extracting permission logic to a new PrayerPermissionsCubit and moving the countdown timer out of the bloc and into the UI layer using a StreamBuilder."

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

### Edge Cases

- How does system behave if user denies required permissions (exact alarm)? (It will reflect accurately in the new cubit state).
- What happens on low-memory devices? (Performance is improved since heavy state allocation every second is avoided).
- Does the countdown drift out of sync with real-time? (StreamBuilder.periodic ensures stable tick rate).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST manage Notification and Exact Alarm permissions in an isolated state container (`PrayerPermissionsCubit`).
- **FR-002**: System MUST NOT run a periodic `Timer` inside `PrayerTimesBloc` for countdown ticking.
- **FR-003**: System MUST calculate the time until the next prayer locally in the UI layer (e.g., via `StreamBuilder.periodic`).
- **FR-004**: System MUST trigger `loadPrayerTimes(forceReschedule: true)` exactly once when permissions transition to a granted state.
- **FR-005**: System MUST maintain exactly the same UI behavior and visual presentation as the original implementation.

### Key Entities 

- **PrayerAlarmCapability**: Holds the current notification and alarm permission states.
- **PrayerTimesState**: The core state containing current settings, location, and the pre-calculated prayer times for the day/month.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Performance profile shows zero `PrayerTimesBloc` state emissions occurring on a 1-second interval while viewing the prayer times screen.
- **SC-002**: `PrayerTimesBloc` lines of code and dependencies are reduced, explicitly separating permission use cases out of its constructor.
- **SC-003**: Users continue to receive accurate prayer time countdowns natively.

## Assumptions

- We assume no other blocs depend heavily on the 1-second interval previously emitted by `PrayerTimesBloc`.
- We assume the existing UI components (`PrayerTimesScreen` and `PrayerSettingsSheet`) can easily consume the newly decoupled state structures.
