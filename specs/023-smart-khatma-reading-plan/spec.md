# Feature Specification: Smart Khatma & Reading Plan

**Feature Branch**: `feature/khatmah`  
**Created**: 2026-06-15  
**Updated**: 2026-07-13  
**Status**: Shipped MVP — normative progress contract in
`amendment-production-readiness.md`

## Product Specification

Smart Khatma helps users complete the Quran through a calm adaptive plan. One
active plan at a time, explicit user-selected boundaries, and user-confirmed
progress only.

## Mandatory Capabilities (MVP)

1. **Range selection**
   - Ordered start/end Surah with Ayah selectors resolved to inclusive Mushaf
     pages via `quran_qcf`.
   - Ordered start/end Mushaf page inputs (1…604).
   - All plan math uses only the selected range.

2. **Schedule selection**
   - Duration presets: 7, 15, 30, 60 days.
   - Target completion date (derives duration days).

3. **Preview before persist**
   - Shows boundaries, total pages, daily target, expected completion date.
   - Nothing saved until explicit confirm.

4. **Daily assignment**
   - Frozen start/end pages per local day.
   - Start opens assignment start; Resume opens first unconfirmed page.

5. **Progress**
   - Reader navigation never writes progress.
   - Save Progress sheet confirms “completed through page N” within today’s
     assignment.

6. **Lifecycle**
   - Edit plan duration/schedule (progress preserved).
   - Delete plan (confirmed reset).
   - Daily completion and full Khatmah completion states.
   - Start another Khatmah after full completion.

## UX Flow

1. Home contextual card → Smart Khatma hub.
2. No plan → Create Khatma → boundary mode → schedule → preview → confirm.
3. Active hub → today’s range, assigned/confirmed/remaining, Start/Resume.
4. Reader → Save Progress → hub refresh.
5. Behind schedule → extend plan (catch-up hidden).
6. Complete → Start another / Return to Quran.

## Canonical States

1. No Plan  
2. Create Plan (boundary + schedule + preview)  
3. Active / No progress today  
4. Active / Partial progress  
5. Today completed  
6. Full Khatmah completed  
7. Recoverable error / malformed data  

## Edge Cases

- Invalid or reversed boundaries → creation controls disabled; preview rejected.
- Same-day partial confirmation → assignment end frozen.
- Next local day → new assignment from first unconfirmed page.
- Malformed v2 JSON → error state; raw value not overwritten.
- Duration edit shorter than elapsed days → rejected.

## Persistence (v2)

Key: `smart_khatma.active_plan.v2`

Fields: `start_page`, `target_page`, `duration_days`, frozen
`assignment_*`, nullable `confirmed_completed_through_page`, optional
`adjustment`.

## Analytics (privacy-minimized)

- `khatma_created`: duration bucket only.
- `khatma_progress_updated`: source = user_confirmation.
- `khatma_goal_completed`, `khatma_completed`, `khatma_plan_adjusted`,
  `khatma_reset`, `khatma_extend_selected`.
- No raw page coordinates or plan ids in shipped events.

## Deferred (post-MVP)

- Today Plan Khatma-backed read-only integration (flag default-off).
- Android Wird widget (flag default-off).
- Reminders, pause, history archive, multiple concurrent plans.
