# Master Roadmap: MeMuslim Daily Companion Initiative

## Vision
Transform MeMuslim from a standard Islamic utility into an ad-free, high-trust, daily companion app with the industry's most reliable Athan, flawless Quranic integrity, and a sticky daily Khatmah habit.

## Scope Chosen: Option A (Independent Workstreams within Spec 043)
We are keeping the three P0 domains (Quran Integrity, Athan Reliability, Location Fallback) within Spec 043 as **independently releasable workstreams**. 
**Rationale based on repository evidence:** While these domains are distinct, they share core DI and feature-flag infrastructure. Breaking them into separate specs risks duplicating the foundational setup. By utilizing explicit phase boundaries, separate Feature Flags (`enable_quran_integrity`, `enable_athan_health`, `enable_manual_location`), separate PRs, and separate rollout tasks, we ensure they can ship independently without blocking each other.

## Phase Overview & Ownership Boundaries

### P0: Core Trust and Reliability (Spec 043 - Current)
- **Workstream 1: Manual Location Fallback**
  - Exit Criteria: Users denying GPS can manually select a city; prayer times calculate successfully.
- **Workstream 2: Athan Reliability Architecture**
  - Exit Criteria: Android Exact Alarms harden Athan delivery; iOS background delivery optimized; Health Check UI provides diagnostics.
- **Workstream 3: Quran Integrity**
  - Exit Criteria: Immutable manifest validation passes on startup; no runtime mutation allowed; manual validation tests pass for all 114 Surahs.

### P1: Daily Quran Habit and Retention (Specs 023 & 022)
- **Ownership:** Spec 023 owns Khatmah planning, daily targets, and reading tracking. Spec 043 provides the trust foundation but does NOT implement Khatmah logic.
- **Exit Criteria:** Users can start a Khatmah, track progress, and see today's target on the Home screen.

### P1/P2: Differentiation & Glanceable Progress (Spec 041)
- **Ownership:** Spec 041 owns the Widget Suite (Prayer countdown, Ayah of the day). Spec 043 ensures the prayer calculation and location data fed to widgets are reliable.
- **Exit Criteria:** Widgets render correctly and reflect active app state.

### P2: Differentiation & Advanced Experience (Future Spec 044)
- **Features Deferred:** Adding new Riwayat (Warsh/Qaloon), advanced Tafsir, and premium audio controls.
- **Features Rejected:** Ad-supported tier (violates premium calm positioning), cluttered Home screen widgets.

## Dependency Graph
1. `Spec 043: Location Fallback` -> Unblocks Prayer Times calculation for users without GPS.
2. `Spec 043: Athan Reliability` -> Depends on Location Fallback.
3. `Spec 041: Widget Suite` -> Depends on Spec 043 Location/Athan for accurate widget data.
4. `Spec 023: Smart Khatmah` -> Independent of Spec 043, can be developed in parallel.
