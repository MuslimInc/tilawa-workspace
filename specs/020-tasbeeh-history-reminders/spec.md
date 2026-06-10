# Feature Specification: Tasbeeh History Grid, Clear All & Reminders

**Feature Branch**: `020-tasbeeh-history-reminders`
**Created**: 2026-06-10
**Status**: Draft — ready for `/speckit.plan`
**Input**: Product request — (1) saved-dhikr history grid view, (2) clear all
saved tasbeeh once, (3) per-dhikr local notification reminders.

**Depends on**: Existing Tasbeeh hub (`TasbeehScreen`, Hive persistence,
`TasbeehCubit`). Notification infrastructure (`flutter_local_notifications`,
`AthkarNotificationService` pattern, `NotificationConfig`).

---

## Context

Tasbeeh recently moved to a **home hub** with a list of saved dhikr, quick count,
and per-item delete. Power users with many saved counters need **scan-friendly
layouts**, a **bulk reset** when starting fresh, and **habit nudges** to resume
a specific dhikr — without coupling to prayer-time athkar reminders (morning /
evening categories).

This spec covers three independently shippable slices that share the same
feature area and data store.

---

## Goals

1. Let users **switch** between list and grid when browsing saved dhikr on the
   home hub.
2. Let users **delete all saved dhikr** in one confirmed action.
3. Let users **schedule a daily local reminder** for a specific saved dhikr;
   tapping the notification opens counting for that dhikr.

## Non-Goals (v1)

- Cloud sync or backup of tasbeeh history.
- Repeating reminders other than **once per day at a chosen local time** (no
  custom weekdays, no interval reminders).
- Reminders for **quick count** (ephemeral, not persisted).
- Push / FCM reminders (local only).
- iOS parity in v1 unless explicitly scoped during plan (Android-first, mirror
  prayer-notifications platform scope).

---

## User Scenarios & Testing

### User Story 1 — Browse saved dhikr in grid view (Priority: P1)

As a user with several saved tasbeeh counters, I want to see them in a **compact
grid** so I can find and open one faster than scrolling a long list.

**Why this priority**: Improves daily usability immediately; no new permissions
or background work; builds on existing home hub.

**Independent Test**: Seed ≥4 saved dhikr → toggle grid → verify 2-column layout
on phone, tap cell → `selectedCounting` for that dhikr.

**Acceptance Scenarios**:

1. **Given** the Tasbeeh home hub with ≥1 saved dhikr, **When** the user toggles
   view mode to grid, **Then** saved items render in a responsive grid (2 columns
   compact width, 3 columns medium/expanded) with dhikr title and `count /
   target` visible.
2. **Given** grid view is active, **When** the user taps a cell, **Then** the
   app opens saved-dhikr counting for that item (same as list row tap).
3. **Given** grid view is active, **When** the user toggles back to list,
   **Then** the current list layout (text + integrated delete strip) is shown.
4. **Given** the user changed view preference, **When** they leave and return to
   Tasbeeh home, **Then** the last chosen view (list | grid) is restored.
5. **Given** RTL locale (Arabic), **When** grid is shown, **Then** reading order
   and chevrons/icons respect directionality; no mirrored numerals in progress.

---

### User Story 2 — Clear all saved tasbeeh (Priority: P2)

As a user who wants to start over, I want to **delete every saved dhikr at once**
so I do not have to remove items one by one.

**Why this priority**: Reduces friction for reset / privacy; smaller scope than
reminders; depends only on existing repository delete APIs.

**Independent Test**: Seed N items → Clear all → confirm → Hive empty, home empty
state, no orphaned UI selection.

**Acceptance Scenarios**:

1. **Given** ≥1 saved dhikr on the home hub, **When** the user opens the overflow
   / action menu and chooses “Clear all saved tasbeeh”, **Then** a confirmation
   dialog shows the count of items to be deleted.
2. **Given** the confirmation dialog, **When** the user confirms, **Then** all
   saved dhikr are removed from local storage, any active selection is cleared,
   and the home empty state is shown.
3. **Given** the confirmation dialog, **When** the user cancels, **Then** no
   data changes.
4. **Given** zero saved dhikr, **When** the user views the home hub, **Then** the
   clear-all action is hidden or disabled.
5. **Given** a saved dhikr has a reminder scheduled (Story 3), **When** clear all
   is confirmed, **Then** all related local notifications are cancelled.

---

### User Story 3 — Daily reminder for a specific saved dhikr (Priority: P3)

As a user trying to build a dhikr habit, I want a **daily notification** for a
chosen saved tasbeeh so I am nudged to open and count at my preferred time.

**Why this priority**: Highest implementation and permission complexity; reuses
notification stack but needs new scheduling, persistence, and settings UI.

**Independent Test**: Enable reminder for “Subhan Allah” at 09:00 → grant
permission → notification fires next day → tap → opens counting for that dhikr.

**Acceptance Scenarios**:

1. **Given** a saved dhikr, **When** the user enables “Daily reminder” and picks
   a local time, **Then** the preference is persisted and a daily
   `zonedSchedule` notification is registered for that dhikr only.
2. **Given** a reminder is enabled, **When** the scheduled time arrives and
   notification permission is granted, **Then** a local notification appears with
   the dhikr text (truncated if needed) and neutral copy (e.g. “Time for your
   dhikr”).
3. **Given** a reminder notification, **When** the user taps it, **Then** the app
   navigates to `/athkar/tasbeeh` and opens counting for that dhikr.
4. **Given** a reminder is enabled, **When** the user disables it or deletes the
   dhikr, **Then** the scheduled notification is cancelled and stored schedule
   is cleared.
5. **Given** notification permission is denied, **When** the user tries to enable
   a reminder, **Then** the app explains why permission is needed and offers a
   path to system settings (no silent failure).
6. **Given** the device timezone changes, **When** the app resumes, **Then**
   reminders are rescheduled in the new zone (same local clock time).

---

## Edge Cases

| Case | Expected behavior |
|------|-------------------|
| Offline | Grid/list/clear-all work offline (Hive). Reminders are local schedules. |
| Low memory | Grid uses lazy builder; no unbounded children. |
| Very long dhikr text | Grid cell truncates (2 lines); full text in counting app bar. |
| Duplicate dhikr text | Reminder tied to **id**, not display text. |
| Clear all during counting | If user is in `selectedCounting`, clear-all returns to home. |
| Reminder while app open | Tapping in-tray still deep-links to counting. |
| OS kills app | Next schedule window restored on startup (ensure/reschedule pass). |
| Android 13+ POST_NOTIFICATIONS | Runtime permission before first schedule. |
| Dark mode | Grid cells and dialogs use theme tokens only. |

---

## Requirements

### Functional

- **FR-001**: Home hub MUST expose a **list \| grid** toggle when
  `savedDhikr.isNotEmpty`.
- **FR-002**: Grid MUST use `GridView` (or sliver equivalent) with token-based
  spacing and `TilawaCard` surfaces consistent with list tiles.
- **FR-003**: View preference (`list` \| `grid`) MUST persist in local preferences
  (e.g. `SharedPreferences`), default `list`.
- **FR-004**: Grid cells MUST support delete (long-press menu or inline control —
  plan phase decides; MUST NOT break tap-to-open).
- **FR-005**: Home hub app bar (or bottom sheet menu) MUST offer **Clear all
  saved tasbeeh** when count ≥ 1.
- **FR-006**: Clear all MUST require explicit confirmation showing item count.
- **FR-007**: Clear all MUST invoke a domain use case
  `ClearAllSavedTasbeehUseCase` (or equivalent) that deletes all Hive records
  atomically from the UI’s perspective.
- **FR-008**: `TasbeehDhikr` (or companion value object) MUST support optional
  reminder fields: `reminderEnabled: bool`, `reminderTime: TimeOfDay` (local).
- **FR-009**: Reminder UI MUST live on saved-dhikr counting screen and/or an edit
  sheet reachable from list/grid (minimum: counting screen overflow).
- **FR-010**: `TasbeehReminderNotificationService` (name TBD) MUST schedule exactly
  one daily notification per enabled dhikr using stable notification IDs derived
  from dhikr id.
- **FR-011**: Notification tap payload MUST deep-link to Tasbeeh counting for
  that `dhikrId` (extend `DeepLinkResolver` / router).
- **FR-012**: Deleting a dhikr or clear-all MUST cancel its notification(s).
- **FR-013**: Startup / resume MUST call `ensureTasbeehRemindersScheduled()` to
  heal drift after reboot or timezone change.
- **FR-014**: All new strings MUST use `context.l10n` (EN + AR).

### Key Entities

- **`TasbeehDhikr`** (extended): existing fields + `reminderEnabled`,
  `reminderHour`, `reminderMinute` (persisted in Hive JSON).
- **`TasbeehLayoutPreference`**: enum `list | grid` (presentation + prefs).
- **`TasbeehReminderSchedule`**: domain view — dhikrId, local time, next fire
  (computed, not stored).

---

## Success Criteria

- **SC-001**: User can switch list ↔ grid and preference survives app restart
  (manual QA + widget test).
- **SC-002**: Clear all removes 100% of saved items in one action; zero items
  remain in Hive (repository test).
- **SC-003**: Reminder fires within ±1 minute of chosen daily time on Android
  test device with permission granted (QA checklist).
- **SC-004**: Notification tap opens correct dhikr counting in ≥95% of cold-start
  and warm-start manual trials.
- **SC-005**: No regression to existing per-item delete and quick count (athkar
  test suite green).

---

## Assumptions

- “History” in the product request means **saved tasbeeh dhikr** on the home hub
  (not a separate audit log of count sessions).
- Grid is a **view mode** on the same home screen, not a new route.
- Reminders are **daily at one local time** per dhikr (v1).
- Notification channel: new `com.tilawa.app.tasbeeh_reminders` (low/default
  importance — habit nudge, not alarm).
- Notification ID block: `13000000 + stableHash(dhikrId) % 100000` (plan phase
  must verify no collision with athkar/prayer IDs).

---

## Open Questions (resolve in plan)

| ID | Question | Default if unresolved |
|----|----------|------------------------|
| OQ-001 | Grid delete UX: long-press vs trailing icon on cell? | Long-press → delete dialog |
| OQ-002 | Reminder settings entry: counting screen only or also list/grid? | Counting screen + long-press on grid/list |
| OQ-003 | iOS in v1? | Android only; iOS stub/no-op with TODO |
| OQ-004 | Show reminder badge on grid/list when enabled? | Small bell icon on tile |
