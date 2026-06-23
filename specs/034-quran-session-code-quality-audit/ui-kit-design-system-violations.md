# UI Kit & Design System Violations — Quran Sessions

**Audit date:** 2026-06-23  
**Reference:** `packages/ui_kit/`, `DESIGN.md`, Tilawa theme extensions (`theme.tokens`, `theme.componentTokens`)

---

## Raw Material vs UI Kit

| Issue | File | Location | Current | Expected | Severity | Beta blocker |
|-------|------|----------|---------|----------|----------|--------------|
| `Card` not `TilawaCard` | `session_card.dart` | L38–42 | `Card` + manual padding | `TilawaCard` | **P2** | N |
| `ElevatedButton` retry | `my_sessions_screen.dart` | L77–80 | Raw Material | `TilawaButton` | **P2** | N |
| Join/cancel buttons | `session_card.dart` | L84–96 | `TextButton`, `FilledButton.tonal` | `TilawaButton` variants | **P2** | N |
| Cancel sheet buttons | `cancel_session_sheet.dart` | L89–100 | `OutlinedButton` / `FilledButton` | `TilawaButton` in sheet | **P2** | N |
| Friday banner | `friday_review_reminder_banner.dart` | L44–49 | `TextButton` / `FilledButton.tonal` | `TilawaButton` | **P2** | N |
| Teacher dashboard errors | `teacher_dashboard_screen.dart` | L165 | `ElevatedButton` | `TilawaButton` (partial — L151 uses Tilawa) | **P2** | N |
| Weekly availability dialogs | `weekly_availability_screen.dart` | L245–249 | `TextButton` pair | `TilawaButton` | **P2** | N |
| **Good:** Booking screen | `booking_screen.dart` | L208–297 | `TilawaButton` large | ✓ | — | — |
| **Good:** Teacher list empty | `quran_sessions_student_empty_state.dart` | L47–56 | `TilawaButton` | ✓ | — | — |
| **Good:** Weekly availability cards | `weekly_availability_screen.dart` | L751 | `TilawaCard` | ✓ | — | — |

---

## Hardcoded colors (not `colorScheme` / tokens)

| Issue | File | Location | Values | Severity | Beta blocker |
|-------|------|----------|--------|----------|--------------|
| Debug panel amber theme | `teacher_application_status_screen.dart` | L187–342 | `Colors.green`, `Colors.orange`, `Colors.amber.*` | **P1** | N |
| Avatar palette | `teacher_initials_avatar.dart` | L75–81 | Seven `Color(0xFF…)` constants | **P2** | N |
| Avatar text | `teacher_initials_avatar.dart` | L37, L41 | `Colors.white` | **P2** | N |
| Profile chip border | `profile_completion_screen.dart` | L499 | `Colors.transparent` | **P2** | N (transparent OK) |
| **Good:** `_StatusBadge` | `session_card.dart` | L123–148 | Uses `scheme.primaryContainer`, etc. | ✓ | — |
| **Good:** Empty state icon | `my_sessions_screen.dart` | L218 | `scheme.outlineVariant` | ✓ | — |

---

## Hardcoded spacing / sizes (not `theme.tokens`)

| Issue | File | Location | Values | Severity | Beta blocker |
|-------|------|----------|--------|----------|--------------|
| Screen padding | `my_sessions_screen.dart` | L94, L145, L211 | `EdgeInsets.all(16/32)` | **P2** | N |
| Session detail padding | `session_detail_screen.dart` | L38 | `all(16)` | **P2** | N |
| Session card padding | `session_card.dart` | L39–41 | `horizontal: 16, vertical: 6`, `all(14)` | **P2** | N |
| Status badge | `session_card.dart` | L158 | `horizontal: 8, vertical: 4`, `fontSize: 11` | **P2** | N |
| Section header | `my_sessions_screen.dart` | L196 | `fromLTRB(16, 20, 16, 8)` | **P2** | N |
| Empty state icon | `my_sessions_screen.dart` | L217 | `size: 64` | **P2** | N |
| **Good:** Badge radius | `session_card.dart` | L152–155 | `tokens.resolveRadius(family: chip)` | ✓ | — |
| **Good:** Several widgets | `teacher_dashboard_inline_empty_state.dart`, `date_grouped_day_tab_bar.dart` | — | `theme.tokens` | ✓ | — |

**Note:** Many screens use token spacing inconsistently — booking/availability better than sessions list.

---

## ARB / localization gaps

| Issue | File | Location | Problem | Severity | Beta blocker |
|-------|------|----------|---------|----------|--------------|
| Timeline action names | `session_detail_screen.dart` | L63 | `event.action.name` raw enum | **P1** | N |
| Timeline fallback subtitle | `session_detail_screen.dart` | L65–66 | `'${previous} → ${new}'` English arrow | **P1** | N |
| Specialization IDs displayed? | `teacher_application_screen.dart` | L323+ | IDs like `tajweed` — need l10n map if shown raw | **P2** | N |
| Package l10n AR/EN | `packages/quran_sessions/lib/l10n/` | — | **Present** for core flows ✓ | — | — |
| Admin UI | `sessions.component.html` | All strings | English hardcoded | **P2** | N (admin EN Beta OK) |
| Cancel policy keys | `cancel_session_sheet.dart` | L27–34 | Mapped to l10n ✓ | — | — |

---

## Admin design system

| Issue | File | Problem | Severity |
|-------|------|---------|----------|
| Inline Tailwind | All quran-sessions components | No shared Tilawa admin design tokens | **P2** |
| Raw `bg-blue-600` buttons | sessions + applications HTML | Not theme-token driven | **P2** |
| Dark mode classes present | HTML | Manual `dark:` — consistent at least | — |

---

## Functional UI gaps (design system can't fix alone)

| Gap | File | Issue | Severity | Beta blocker |
|-----|------|-------|----------|--------------|
| No join CTA on detail | `session_detail_screen.dart` | Missing component entirely | **P0** | **Y** |
| Join button visible but broken | `session_card.dart` L91–96 + empty bloc | Misleading affordance | **P0** | **Y** |
| No report/dispute entry | No screen file | Safety UX missing | **P1** | N (product) |

---

## Summary

| Category | P0 | P1 | P2 |
|----------|----|----|-----|
| Raw widgets | 0 | 0 | 8 |
| Hardcoded colors | 0 | 1 | 3 |
| Hardcoded spacing | 0 | 0 | 7 |
| ARB gaps | 0 | 2 | 2 |
| Functional UI | 2 | 1 | 0 |
| **Total** | **2** | **4** | **20** |

**Beta note:** UI Kit inconsistency is **acceptable for Beta** if join path works. P0 items are **missing/broken components**, not token nitpicks.
