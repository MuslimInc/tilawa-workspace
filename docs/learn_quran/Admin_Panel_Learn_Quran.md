# Admin Panel — Learn Quran (Quran Sessions)

**Project:** `apps/tilawa_admin` (existing Angular admin — no new panel created).
**Principle:** Admin Panel is the source of truth; the app renders resolved state.

**Completion (evidence-based): ~90%**
**Verdict: READY (with non-blocking follow-ups)**

---

## Implemented admin surfaces (verified in code)

| Area | Component | Controls |
|------|-----------|----------|
| Global settings | `global-settings` | Quran Sessions master switch, **student entry**, booking, session mode (`videoOnly`), booking mode, join-window/SLA/notice/limit timings, **and — added in this change — tutor entry** |
| Market pricing | `market-pricing` | Per-market currency + min price, enable/disable markets & cities |
| Teacher pricing | `teacher-pricing` | Free / fixed override or inherit market; **now shows authoritative effective price + pricing source** (this change) |
| Resolved config inspector | `resolved-config-inspector` | Calls `getResolvedSessionConfig(studentId, teacherId)` — the **authoritative** server resolution (effective price, bookable, block reason) shared with booking |
| Teacher applications | `teacher-applications`, `teacher-application-detail` | Review / approve / reject |
| Sessions & ops | `sessions`, `session-detail`, `active-sessions`, `session-disputes`, `session-reports`, `duplicate-accounts`, `users`, `user-wallets` | Operations + moderation |

## What changed in this pass

1. **Tutor entry is now admin-editable end-to-end.** Backend + Flutter already
   supported `teacherApplicationEnabled`, `teacherApplicationEntryEnabled`,
   `homeTeacherApplicationCardEnabled`, `teacherApplicationDiscoverability`, but
   `updatePlatformConfig` did not write them and no admin UI edited them
   (operators would have needed manual Firestore edits — forbidden). Added:
   - CF `updatePlatformConfig`: accepts, **validates**, and persists the four
     tutor-entry fields (booleans + discoverability enum), `{merge:true}` so
     omitted fields are preserved.
   - Admin `global-settings`: `PlatformConfig` fields, form controls, a "Tutor
     Entry" section (3 toggles + discoverability select), en/ar i18n.
2. **Teacher-pricing panel operational info completed.** The WIP added CSS + TS
   methods that were never rendered and included a **client-side bookability
   guess** (contradicts backend authority). Reworked to render the
   **authoritative** override info (pricing source + effective price, i18n en/ar)
   and defer live bookability to the Resolved config inspector via a note. Removed
   the speculative `bookableStatusLabel`.

## Checklist (directive controls → admin)

- [x] Quran Sessions enable/disable — `quranSessionsEnabled`
- [x] Student entry — `studentEntryEnabled`
- [x] **Tutor entry — `teacherApplication*` (now editable, this change)**
- [x] Booking enable/disable — `bookingEnabled`
- [x] Video-only rollout — `sessionMode: videoOnly`
- [x] Market configuration — `market-pricing`
- [x] Teacher pricing / free override / effective pricing / pricing source — `teacher-pricing`
- [x] Bookable status + block reason (authoritative) — `resolved-config-inspector`
- [x] Rollout configuration surfaced from a single Firestore doc
- [ ] Inline per-teacher live bookability chip in the pricing panel (non-blocking;
      inspector already authoritative)

## Launch blockers

- **Deploy** `updatePlatformConfig` (and the Quran Sessions callable batch) to the
  target Firebase project so the new tutor-entry writes take effect (ops).

## Manual QA checklist

- [ ] global-settings loads current config; toggling tutor-entry + saving persists
      to `quran_session_platform_config/global` and reflects in the app.
- [ ] Invalid discoverability rejected by the callable (server validation).
- [ ] teacher-pricing panel shows correct source (market vs override) + effective
      price after setting free / fixed / inherit.
- [ ] resolved-config-inspector returns bookable + blockReason matching the app.

## Automated test coverage

- Admin Vitest: **35 files / 164 tests passed**; production build clean.
- Backend `updatePlatformConfig` validation: **+3 new tests** (accept tutor-entry
  fields; reject invalid discoverability; reject non-boolean) — part of **388
  passing** function tests.
