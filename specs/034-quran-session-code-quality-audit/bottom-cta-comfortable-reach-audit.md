# Bottom CTA Comfortable Reach Audit

**Date:** 2026-06-23  
**Scope:** `packages/quran_sessions/lib/src/presentation/` screens + widgets; UI Kit footer primitives in `packages/ui_kit/lib/src/foundation/`  
**Method:** Read-only source audit — no code changes  
**Rubric:** 20 Comfortable Reach Rules (below), aligned with spec 014 (ergonomic floor), spec 015 FR-A01–A04 (sheet footers), and `TilawaComfortableReachPadding`

---

## Summary

| Metric | Count |
|--------|------:|
| Screens / sheets audited | 28 |
| **P0** violations | **1** (was 8; 7 fixed 2026-06-23) |
| **P1** violations | **13** (was 14; teacher profile FAB fixed) |
| **P2** violations | **11** |
| Screens already good (kit-standard footers) | **9** |
| Missing screens (no UI) | **2** (booking confirmation route, dispute) |

**Good examples:** `teacher_application_screen.dart` (editing state), `profile_completion_screen.dart`, `complete_teacher_public_profile_screen.dart`, `weekly_availability_screen.dart` (Hours + Overrides tabs), `availability_override_sheet.dart`, `time_range_editor_sheet.dart` → `TilawaCupertinoPickerSheet`.

**UI Kit inventory**

| Component | Exists? | Notes |
|-----------|---------|-------|
| `TilawaStickyFooterAction` | **No** | Not in repo. Use `TilawaBottomActionArea` + `TilawaButton` or `TilawaFormSubmitFooter`. |
| `TilawaBottomSheetActionBar` | **Yes** (as `TilawaBottomSheetActions`) | `packages/ui_kit/lib/src/foundation/tilawa_bottom_sheet_actions.dart` — stacks below 360 dp width. |
| `TilawaFormSubmitFooter` | **Yes** | Validation summary + full-width `TilawaButton`. |
| `TilawaBottomSheetScaffold` | **Yes** | Sticky `footer` + `TilawaComfortableReachPadding` (`kind: sheet`). |
| `TilawaBottomActionArea` | **Yes** | Full-screen sticky band; mirrors sheet footer chrome. |
| `TilawaFormScreenScaffold` | **Yes** | Scroll body + `TilawaBottomActionArea` footer. |
| `TilawaThumbReachLayout` | **Yes** | 72/28 split for short wizard steps (unused in Quran Sessions today). |

**Comfortable-reach math (kit):** `TilawaComfortableReachPadding.resolve` → `spaceHuge` (48 dp) when `systemBottomSafeArea == 0`, else `systemBottomSafeArea + spaceExtraLarge` (24 dp). Sheet footer also adds `footerPadding` (16 dp sides, 12 top, 16 base) from `TilawaBottomSheetScaffoldTokens`.

---

## 20 Comfortable Reach Rules (audit rubric)

| # | Rule |
|---|------|
| R01 | Primary CTA sits in thumb zone (lower third), not top app bar / top of scroll. |
| R02 | Form / confirm flows use **sticky** footer — CTA must not scroll away. |
| R03 | Sheets use `TilawaBottomSheetScaffold.footer` (or `showTilawaFormSheet` / `TilawaCupertinoPickerSheet`). |
| R04 | Full-screen forms use `TilawaFormScreenScaffold` or `Scaffold.bottomNavigationBar` + `TilawaBottomActionArea`. |
| R05 | Bottom inset from `TilawaComfortableReachPadding` — no raw `16` as sole bottom padding. |
| R06 | `SafeArea` bottom handled by kit footers (`SafeArea(top: false, bottom: false)` + computed inset). |
| R07 | Keyboard open: submit stays visible (`keyboardAware: true`, `viewInsets` / kit buffer `spaceSmall`). |
| R08 | Scroll body has trailing padding so last row is not hidden behind sticky footer. |
| R09 | One obvious **primary** action per screen/sheet; secondaries are outline/text. |
| R10 | Destructive confirm not adjacent equal-weight to dismiss without clear hierarchy (spec 015 / UX). |
| R11 | Min 48 dp touch targets (`kMeMuslimMinInteractiveDimension` / `TilawaButton`). |
| R12 | Full-width primary on phone (`TilawaButton(isFullWidth: true)`). |
| R13 | No `FloatingActionButton` for main booking CTA on long scroll profiles. |
| R14 | Paired footer actions stack on narrow width (`TilawaBottomSheetActions` @ 360 dp). |
| R15 | `footerExtraBottom` when host shell nav / mini-player stacks under route. |
| R16 | Sheet dismiss: handle drag and/or trailing close (spec 014 FR-005). |
| R17 | Spacing from `theme.tokens` / `componentTokens` — not magic `EdgeInsets.all(16)`. |
| R18 | Consistent button atom (`TilawaButton`) across feature, not mix `ElevatedButton` / `FilledButton`. |
| R19 | List browse screens: inline card CTAs acceptable; **flow completion** CTAs still sticky. |
| R20 | P0 safety flows (report, cancel, dispute) must meet R02–R07 before Free Beta. |

---

## Audit Table

| Screen | File | CTA Type | Current Placement | SafeArea? | Keyboard Safe? | Bottom Nav Conflict? | Reachability | Violation | Severity | Recommended Fix |
|--------|------|----------|-------------------|-----------|----------------|----------------------|--------------|-----------|----------|-----------------|
| Student — Discovery / Home | `screens/quran_sessions_home_screen.dart` | App bar `TextButton` (My Sessions); list `TextButton` (See all); empty `TilawaButton` center | Top-right app bar + end of list / centered empty | N/A (no bottom CTA) | N/A | Low — pushed route, no shell footer in route tree | My Sessions top-right (R01) | Secondary nav in app bar out of thumb zone | P2 | Accept for browse; optional move My Sessions to body footer link |
| Student — Teacher list | `screens/teacher_list_screen.dart` | Error retry `TilawaButton` centered | `Center` in body | No | N/A | Low | Center screen (R01) | Retry not thumb-zone | P2 | `TilawaIllustratedState` OK; optional `TilawaThumbReachLayout` for error |
| Student — Teacher profile | `screens/teacher_profile_screen.dart` | `TilawaBottomActionArea` book CTA | Sticky bottom band (FAB removed) | Yes — kit | N/A | Low | Thumb zone | — | — | **Fixed** 2026-06-23 (P1) |
| Student — Booking | `screens/booking_screen.dart` | `TilawaButton` confirm | `bottomNavigationBar` → `TilawaBottomActionArea` | Yes — kit | N/A | Low | Thumb zone | — | — | **Fixed** 2026-06-23 |
| Student — Booking confirmation | `screens/booking_screen.dart` L97–107 | Toast only (`TilawaFeedback.showToast`) | No screen / no CTA | N/A | N/A | N/A | No confirmation UI | No dedicated confirm step (product gap) | P2 | Optional success sheet with sticky “View session”; not reach-critical |
| Student — Profile completion (booking gate) | `screens/profile_completion_screen.dart` L146–186 | `TilawaFormSubmitFooter` | `TilawaFormScreenScaffold` sticky footer | Yes — via `TilawaBottomActionArea` | Yes — kit `keyboardAware` | Low — `footerExtraBottom` not set | Thumb zone | — | — | **Good** — reference pattern |
| Student — My sessions | `screens/my_sessions_screen.dart` + `widgets/session_card.dart` L78–99 | `FilledButton.tonal` Join; `TextButton` Cancel / Detail / Reschedule | Inline per card, end-aligned row | No | N/A | Low | Mid-list (R19 OK for list); cancel error-color text easy mis-tap | Destructive cancel adjacent to join (R10) | P1 | Keep card actions; add sticky “Book session” empty CTA only on empty state; separate cancel to sheet (already does) |
| Student — Session detail | `screens/session_detail_screen.dart` | Join + Report | `bottomNavigationBar` → `TilawaBottomActionArea` | Yes — kit | N/A | Low | Thumb zone | — | — | **Fixed** 2026-06-23 |
| Student — Report issue | `widgets/report_concern_sheet.dart` | Kit footer actions | `TilawaBottomSheetScaffold` + `TilawaBottomSheetActions` | Yes — kit | Yes — kit footer | Low | Thumb zone | — | — | **Fixed** 2026-06-23 |
| Student — Dispute | `widgets/open_dispute_sheet.dart` | Kit footer + gateway | `TilawaBottomSheetScaffold`; `OpenSessionDisputeUseCase` → `openSessionDispute` CF | Yes — kit | Yes — kit footer | Low | Thumb zone | — | — | **Fixed** 2026-06-23 (minimal sheet + wire) |
| Student — Cancellation | `widgets/cancel_session_sheet.dart` | Keep primary + destructive secondary | `TilawaBottomSheetScaffold` + `TilawaBottomSheetActions` | Yes — kit | Yes — kit footer | Low | Thumb zone; R10 hierarchy | — | — | **Fixed** 2026-06-23 |
| Student — Reschedule | `screens/reschedule_session_screen.dart` | `TilawaFormSubmitFooter` | `TilawaBottomActionArea` sticky band + keyboard-aware | Yes — kit | Yes — `resizeToAvoidBottomInset` + kit | Low | Thumb zone | — | — | **Fixed** 2026-06-23 |
| Student — Empty / notify | `widgets/quran_sessions_student_empty_state.dart` L47–76 | `TilawaButton` ×2 via `TilawaIllustratedState` | Vertical center of viewport | No | N/A | Low | Centered — acceptable for empty (R19) | Not thumb-zone anchored | P2 | Optional `TilawaThumbReachLayout` if empty is primary gate |
| Teacher — Application (not started) | `screens/teacher_application_screen.dart` L153–184 | `TilawaButton` start | `Column` center `padding: 32` | No | N/A | Low | Mid-screen (R01) | Wizard entry not thumb reach | P1 | `TilawaThumbReachLayout` (short step) |
| Teacher — Application (editing) | `screens/teacher_application_screen.dart` L344–560 | `TilawaFormSubmitFooter` | `TilawaFormScreenScaffold` | Yes | Yes | Low | Thumb zone | — | — | **Good** |
| Teacher — Application status | `screens/teacher_application_status_screen.dart` | None (read-only); debug `OutlinedButton` | Scroll center; debug mid-page | No | N/A | Low | No production CTA | Approved navigates via bloc listener only | P2 | Add sticky “Open dashboard” when approved if host does not auto-nav |
| Teacher — Complete public profile | `screens/complete_teacher_public_profile_screen.dart` L175–274 | `TilawaButton` in `TilawaFormScreenScaffold` | Sticky footer; `resizeToAvoidBottomInset: true` | Yes | Yes | Low | Thumb zone | — | — | **Good** |
| Teacher — Dashboard | `screens/teacher_dashboard_screen.dart` | Empty `TilawaButton`; card/banner buttons; slot delete icon | Inline in scroll; `TilawaComfortableReachPadding` scroll tail L271–275 | Tail padding only | N/A | Low | Schedule CTA in empty center / banner mid-scroll | No sticky “Manage schedule” when slots exist | P1 | Optional sticky secondary footer when `onManageSchedule != null` |
| Teacher — Dashboard slot delete | `screens/teacher_dashboard_screen.dart` L360–375 | `AlertDialog` TextButtons | **Top** of dialog actions row | Dialog default | N/A | N/A | Top-half screen (R01) | Dialog actions not thumb-zone | P1 | `showTilawaConfirmSheet` with footer actions |
| Teacher — Friday banner | `widgets/friday_review_reminder_banner.dart` L42–54 | `TextButton` + `FilledButton.tonal` | Mid-scroll banner row | No | N/A | Low | Mid viewport | Accept for banner; dismiss + review same row | P2 | — |
| Teacher — Weekly availability (Hours) | `screens/weekly_availability_screen.dart` L233–316 | `TilawaBottomActionArea` Cancel + Save | `Scaffold.bottomNavigationBar` | Yes — kit | Yes | **Uses `bottomNavigationBar` slot** — name collision only; not tab nav | Thumb zone | — | — | **Good** |
| Teacher — Weekly availability (Overrides) | `screens/weekly_availability_screen.dart` L692–703 | `TilawaBottomActionArea` Add override | Bottom of tab `Column` | Yes | N/A | Low | Thumb zone | — | — | **Good** |
| Teacher — Vacation delete confirm | `widgets/availability_vacation_dialogs.dart` | `showTilawaConfirmDialog` | Center dialog | Dialog | N/A | N/A | Top dialog actions | Not sheet thumb pattern | P1 | Prefer `showTilawaConfirmSheet` for consistency |
| Teacher — Time range editor | `widgets/time_range_editor_sheet.dart` → `tilawa_cupertino_picker_sheet.dart` | `TilawaButton` in scaffold footer | Sticky sheet footer | Yes | Yes | Low | Thumb zone | — | — | **Good** |
| Teacher — Override editor sheet | `widgets/availability_override_sheet.dart` L78–84 | `TilawaButton` Save | `TilawaBottomSheetScaffold.footer` | Yes | Yes | Low | Thumb zone | — | — | **Good** |
| Teacher — Timezone picker sheet | `screens/weekly_availability_screen.dart` L801–822 | `ListTile` tap (no footer CTA) | Scroll list selection | Sheet scaffold, no footer | N/A | Low | Tap-to-select OK for picker (R19) | — | — | **Good** (picker preset) |
| Teacher — Duration picker sheet | `screens/weekly_availability_screen.dart` L838–857 | `ListTile` tap | Same | Same | N/A | Low | OK | — | — | **Good** |
| Teacher — Availability discard dialog | `screens/weekly_availability_screen.dart` L240–254 | `AlertDialog` TextButtons | Top dialog | Dialog | N/A | N/A | Top reach | Same as slot delete | P1 | `showTilawaConfirmSheet` |

---

## 1. Top 5 issues to fix first

1. **Report concern sheet** (`report_concern_sheet.dart`) — P0 safety flow on bespoke `showModalBottomSheet`; no `TilawaBottomSheetScaffold`, no comfortable-reach padding, no sheet handle. Blocks US-015 reach + consistency.
2. **Cancel session sheet** (`cancel_session_sheet.dart`) — P0 destructive submit paired with keep; same bespoke footer gaps as report.
3. **Booking confirm CTA** (`booking_screen.dart` L208–213) — P0 primary action scrolls away; magic `16` padding instead of `TilawaBottomActionArea`.
4. **Session detail Join / Report** (`session_detail_screen.dart` L85–106) — P0 high-frequency actions at top of scroll; must be sticky for join window.
5. **Reschedule submit + reason field** (`reschedule_session_screen.dart` L75–99) — P0 keyboard can obscure submit; not using form scaffold.

---

## 2. Screens already good

- `profile_completion_screen.dart` — `TilawaFormScreenScaffold` + `TilawaFormSubmitFooter`
- `teacher_application_screen.dart` (editing) — same
- `complete_teacher_public_profile_screen.dart` — `TilawaFormScreenScaffold` + full-width `TilawaButton`
- `weekly_availability_screen.dart` — Hours tab `bottomNavigationBar` → `TilawaBottomActionArea`; Overrides tab bottom `TilawaBottomActionArea`
- `availability_override_sheet.dart` — `TilawaBottomSheetScaffold.footer`
- `time_range_editor_sheet.dart` — `TilawaCupertinoPickerSheet` / dual picker preset
- `_TimezonePickerSheet` / `_DurationPickerSheet` — list-picker pattern (no footer required)
- `teacher_dashboard_screen.dart` — scroll tail `TilawaComfortableReachPadding.resolve(context)` (L271–275)
- `teacher_application_screen.dart` — reference for validation + sticky submit

---

## 3. Screens needing UI Kit standardization

| Screen / sheet | Current | Target kit API |
|----------------|---------|----------------|
| `report_concern_sheet.dart` | Raw `showModalBottomSheet` + `Padding(16)` | `showTilawaFormSheet` or `TilawaBottomSheetScaffold` + `TilawaBottomSheetActions` |
| `cancel_session_sheet.dart` | Same | Same |
| `booking_screen.dart` | Inline `Column` + `TilawaButton` | `TilawaFormScreenScaffold` or `TilawaBottomActionArea` via `bottomNavigationBar` |
| `reschedule_session_screen.dart` | `FilledButton` + magic padding | `TilawaFormScreenScaffold` + `TilawaFormSubmitFooter` |
| `session_detail_screen.dart` | `FilledButton` / `OutlinedButton` in `ListView` | `TilawaBottomActionArea` on scaffold |
| `teacher_profile_screen.dart` | `FloatingActionButton.extended` | `TilawaBottomActionArea` |
| `my_sessions_screen.dart` / `session_card.dart` | `ElevatedButton` / `FilledButton.tonal` / `TextButton` mix | `TilawaButton` variants |
| `teacher_dashboard_screen.dart` / `weekly_availability_screen.dart` dialogs | `AlertDialog` | `showTilawaConfirmSheet` |
| `teacher_application_screen.dart` `_NotStartedView` | Centered button | `TilawaThumbReachLayout` |

---

## 4. Need reusable sticky footer component?

**No new component required.**

Existing stack covers cases:

- **Full-screen forms:** `TilawaFormScreenScaffold` + (`TilawaFormSubmitFooter` | `TilawaButton`)
- **Full-screen actions:** `Scaffold.bottomNavigationBar` → `TilawaBottomActionArea`
- **Sheets:** `TilawaBottomSheetScaffold.footer` + (`TilawaBottomSheetActions` | `TilawaButton`)
- **Short wizard:** `TilawaThumbReachLayout`

`TilawaStickyFooterAction` was **not found** — do not add unless a fourth pattern emerges; extend `TilawaBottomActionArea` if shell `footerExtraBottom` becomes common.

---

## 5. CTAs that should move inline (de-sticky or de-FAB)

| Current | Move to | Why |
|---------|---------|-----|
| `TeacherProfileScreen` FAB “Book session” | Remove FAB; keep slot-driven book in `AvailabilitySlotPicker` + optional sticky footer only when no slot selected | FAB duplicates slot tap (L254–257); FAB violates R13 on long profile |
| `SessionDetailScreen` Report | Can stay secondary in sticky footer **or** app bar overflow — not mid-list | Mid-list was worse; footer is enough |
| `MySessionsScreen` View details / Reschedule `TextButton`s | Keep inline under card (R19) | Secondary per-session actions; not flow-completion |
| `QuranSessionsHomeScreen` My Sessions app bar | Optional inline link in body | P2 polish only |

---

## 6. Free Beta blockers

| Blocker | Reach / UX impact |
|---------|-------------------|
| **Report concern sheet** not on kit scaffold (US-015) | Safety report flow fails comfortable-reach + consistency bar |
| **Dispute UI missing** | No `openDispute` presentation — cannot complete safety lifecycle |
| **Session detail** join/report placement | Join window UX broken on long timelines |
| **Cancel sheet** destructive pairing | Mis-tap risk on cancellation (R10) |

Non-blockers but ship with beta if time: booking sticky footer, reschedule keyboard, teacher profile FAB.

---

## 7. Recommended first PR

**Title:** `fix(quran-sessions): kit sticky footers for report + cancel sheets`

**Scope (single PR):**

1. Rewrite `report_concern_sheet.dart` → `showTilawaFormSheet` / `TilawaBottomSheetScaffold` + `TilawaBottomSheetActions` (primary submit, secondary cancel).
2. Rewrite `cancel_session_sheet.dart` same pattern; **primary = Keep session**, destructive confirm on `cancelSessionAction` with error styling or second step.
3. Update `report_concern_sheet_test.dart` pump helpers to match scaffold.
4. Manual: iPhone SE — submit visible without scrolling; keyboard open on description/reason field.

**Follow-up PR:** `booking_screen` + `session_detail_screen` sticky footers (`TilawaBottomActionArea`).

---

## 8. Tests required

| Test | File | Assert |
|------|------|--------|
| Report sheet uses scaffold footer | `test/presentation/widgets/report_concern_sheet_test.dart` | Finds `TilawaBottomSheetScaffold` or form sheet preset; submit tappable at bottom |
| Cancel sheet action order | New `cancel_session_sheet_test.dart` | Keep vs cancel semantics; destructive not default focus |
| Booking sticky CTA | New `booking_screen_test.dart` | With many slots, confirm button still visible (widget test with fixed viewport height) |
| Reschedule keyboard | New `reschedule_session_screen_test.dart` | `viewInsets` simulated — footer above keyboard |
| Session detail footer | New `session_detail_screen_test.dart` | Join button in `TilawaBottomActionArea` when `canJoin` |
| Golden / manual | Maestro or manual checklist | SE viewport thumb-zone per spec 015 T-A91 |

---

## Violation totals (recap)

| Severity | Count |
|----------|------:|
| P0 | 1 |
| P1 | 13 |
| P2 | 11 |

**Top P0 / P1 by file (remaining)**

| Priority | File | Issue |
|----------|------|-------|
| P0 | `booking_screen.dart` (confirmation route) | No dedicated confirm step — toast only (product gap, P2 reach) |
| P1 | `teacher_dashboard_screen.dart` | AlertDialog delete confirm |
| P1 | `weekly_availability_screen.dart` | Discard `AlertDialog` |
| P1 | `teacher_application_screen.dart` | Not-started center CTA |
| P1 | `session_card.dart` | Cancel adjacent join |

**UI Kit:** `TilawaStickyFooterAction` **does not exist**. Use `TilawaBottomActionArea`, `TilawaFormSubmitFooter`, `TilawaBottomSheetScaffold`, `TilawaBottomSheetActions`.

---

## Hotfix log (2026-06-23)

**Symptom:** After batch-3 sticky footer migration (`Scaffold.bottomNavigationBar` → `TilawaBottomActionArea`), teacher profile and booking screens showed only the CTA — solid surface-colored viewport with button centered; scroll body missing.

**Root cause:** `TilawaBottomActionArea` root `Material` expanded to `Scaffold.bottomNavigationBar`'s loose max-height constraint, consuming the viewport and leaving zero height for `body`.

**Fix:** Wrap footer chrome in `Column(mainAxisSize: MainAxisSize.min)` inside `tilawa_bottom_action_area.dart`. Regression test: `tilawa_form_screen_scaffold_test.dart` — `does not expand to fill scaffold bottomNavigationBar slot`.

**Screens affected (no screen-level diff needed):** `teacher_profile_screen.dart`, `booking_screen.dart`, `session_detail_screen.dart`, `weekly_availability_screen.dart` (Hours tab).
