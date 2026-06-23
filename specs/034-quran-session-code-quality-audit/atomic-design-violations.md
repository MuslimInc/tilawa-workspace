# Atomic Design Violations — Quran Sessions

**Audit date:** 2026-06-23

Classification: **Atom** (single control) · **Molecule** (composed control) · **Organism** (section) · **Template** (layout shell) · **Screen** (routed page)

---

## Misclassified / oversized components

| Component | File | Lines | Current | Should be | Extraction | UI Kit move |
|-----------|------|-------|---------|-----------|------------|-------------|
| `TeacherDashboardScreen` | `presentation/screens/teacher_dashboard_screen.dart` | ~1011 | Screen | Screen + 4–5 organisms | `_SessionSection`, `_AvailabilitySection`, `_FridayBannerHost`, `_DashboardError` | Partial — use existing `TilawaCard` patterns |
| `WeeklyAvailabilityScreen` | `presentation/screens/weekly_availability_screen.dart` | ~876 | Screen | Screen + organisms | Day row already `availability_day_hours_row.dart`; extract override CTA block | N |
| `ProfileCompletionScreen` | `presentation/screens/profile_completion_screen.dart` | ~723 | Screen | Wizard template + step organisms | `_GenderStep`, `_LocationStep`, `_BirthDateStep` | N |
| `TeacherApplicationScreen` | `presentation/screens/teacher_application_screen.dart` | ~645 | Screen | Form organism + screen shell | `_SpecializationChips`, `_DocumentUploadSection` | N |
| `TeacherDashboardBloc` UI coupling | `teacher_dashboard_screen.dart` L836+ | — | Screen holds analytics map keys | Molecule | `TeacherDashboardAnalytics` helper | N |

---

## Atoms that should use UI Kit

| Widget | File | Location | Issue | UI Kit target | Move to ui_kit? |
|--------|------|----------|-------|---------------|-----------------|
| `_StatusBadge` | `presentation/widgets/session_card.dart` | L110–168 | Custom chip colors + `fontSize: 11` | `TilawaChip` / status chip pattern | **N** — domain-specific statuses; keep in package, use tokens |
| `TeacherInitialsAvatar` | `presentation/widgets/teacher_initials_avatar.dart` | L37–81 | Hardcoded palette `Color(0xFF…)` | Token-based avatar colors | **N** — feature-specific; fix tokens in-package |
| Raw `Card` | `presentation/widgets/session_card.dart` | L38 | Material `Card` not `TilawaCard` | `TilawaCard` | **N** |
| Raw buttons | `my_sessions_screen.dart` L77; `session_card.dart` L84–96 | — | `ElevatedButton` / `FilledButton.tonal` | `TilawaButton` | **N** |
| Cancel sheet buttons | `cancel_session_sheet.dart` | L89–100 | `OutlinedButton` / `FilledButton` | `TilawaButton` in `TilawaBottomSheet` | **N** |
| Debug panel | `teacher_application_status_screen.dart` | L305–342 | Amber `Colors.*` debug card | Remove or gate behind `kDebugMode` | **N** |

---

## Good extractions already present

| Molecule/Organism | File | Used by |
|-------------------|------|---------|
| `SessionCard` | `widgets/session_card.dart` | `MySessionsScreen`, `TeacherDashboardScreen` |
| `TeacherCard` | `widgets/teacher_card.dart` | `TeacherListScreen` |
| `showCancelSessionSheet` | `widgets/cancel_session_sheet.dart` | Student + teacher cancel flows |
| `QuranSessionsStudentEmptyState` | `widgets/quran_sessions_student_empty_state.dart` | Home, list empty states |
| `DateGroupedDayTabBar` | `widgets/date_grouped_day_tab_bar.dart` | Booking, profile availability |
| `AvailabilityOverrideSheet` | `widgets/availability_override_sheet.dart` | Weekly availability |

---

## Missing organisms (gaps)

| Gap | Where needed | Recommendation | UI Kit? |
|-----|--------------|----------------|---------|
| Join session row | `SessionDetailScreen`, `SessionCard` | `SessionJoinActions` molecule: link preview + join CTA | N |
| Session timeline row | `session_detail_screen.dart` L61–73 | `SessionTimelineTile` with l10n labels | N |
| Admin filter bar | `tilawa_admin` sessions + applications | `AdminFilterBarComponent` | N |
| Report / dispute form | Not implemented | Post-beta organism; CF exists | N |

---

## Admin atomic map

| Piece | Level | File |
|-------|-------|------|
| `PageHeaderComponent` | Molecule | `shared/components/page-header/` |
| `StatusChipComponent` | Atom | `shared/components/status-chip/` |
| Filter grid | Should be organism | Duplicated in `sessions.component.html`, `teacher-applications.component.html` |
| Data table | Organism | Inline `<table>` per feature — no shared `AdminDataTable` |

---

## Top extraction recommendations (priority)

1. **`SessionJoinActions`** — unblocks join UX in card + detail (P0 product, clean atom boundary).
2. **`SessionTimelineTile`** — localizes timeline; shrinks `SessionDetailScreen`.
3. **Split `TeacherDashboardScreen`** — largest screen file; highest maintenance cost.
4. **Admin `FilterBarComponent`** — DRY between 2+ list screens.
