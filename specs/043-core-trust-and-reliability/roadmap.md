# Master Roadmap: MeMuslim Daily Companion Initiative

## Al-Khatmah immediate release sequence

```text
confirmed progress correctness
→ stable daily assignment
→ Khatmah reader entry
→ confirmation UX
→ Home integration
→ release validation
```

Widget rollout, reminders, adherence, listening progress, and architecture
refactoring are post-release and cannot block this core sequence.

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
> **Research insight preserved (do not lose this).** The Khatmah workbook's strongest
> *positive* signal is that the daily-habit loop — plan → daily Wird → reminder →
> completion → progress — is the real retention engine (K01, K05, K23, K57), stronger than
> raw feature breadth. Evidence strength is **moderate/inferred** (praise embedded in 5★
> text; theme N only 2), so it is stated as a strategic bet, not a majority demand. Spec
> 043 is deliberately P0-engineering (trust/reliability); this insight must live loudly in
> the roadmap so the specs combine into **one** coherent daily experience, not three silos.
- **Ownership:** Spec 023 owns Khatmah planning, daily targets, calm non-punitive
  catch-up, and reading tracking. Spec 043 provides the trust foundation but does NOT
  implement Khatmah logic.
- **Amendments recommended to Spec 023** (from reviews): a **gentle adherence streak**
  ("أيام الالتزام", K51 — non-punitive) and **continue-listening** audio progress (K35).
- **Exit Criteria:** Users can start a Khatmah, track progress, and see today's target on the Home screen.

### P1/P2: Differentiation & Glanceable Progress (Spec 041)
- **Ownership:** Spec 041 owns the Widget Suite (Prayer countdown [shipped], Ayah of the day [shipped], Athkar [shipped], Hijri, Share cards). Spec 043 ensures the prayer calculation and location data fed to widgets are reliable.
- **⚠️ Currently unowned retention opportunity (strongest observed in this extremes-only sample; not a total-demand estimate):** reviews **K48 (upvoted) and K51**
  explicitly request a **Khatma/Wird-progress widget** — which Spec 041 does **not** include
  and Spec 023 (in-app only) does not cover. Recommendation: **add a Wird-progress widget to
  Spec 041**, fed by Spec 023's `KhatmaTodayTarget`. Tracked in `spec.md` §7 and
  `research.md` §7.
- **Exit Criteria:** Widgets render correctly and reflect active app state.

### P2: Differentiation & Advanced Experience (Future Spec 044)
- **Features Deferred:** Adding new Riwayat (Warsh/Qaloon), advanced Tafsir, and premium audio controls.
- **Features Rejected:** Ad-supported tier (violates premium calm positioning), cluttered Home screen widgets.

## Dependency Graph
1. `Spec 043: Location Fallback` -> Unblocks Prayer Times calculation for users without GPS.
2. `Spec 043: Athan Reliability` -> Depends on Location Fallback.
3. `Spec 041: Widget Suite` -> Depends on Spec 043 Location/Athan for accurate widget data.
4. `Spec 023: Smart Khatmah` -> Independent of Spec 043, can be developed in parallel.

## The Combined User Experience (one coherent product, not three silos)
The three specs assemble into a single daily journey:
1. **Spec 043 (Trust foundation)** — trusted Quran data (text/number/boundary integrity +
   CDN-font verification), reliable adhan, and a safe location resolution that never
   dead-ends. *Invisible when it works; it is the floor everything else stands on.*
2. **Spec 023 (Daily habit)** — plan → today's Wird → **continue reading** / **continue
   listening** (023-A1) → **calm recovery** and **gentle adherence** (023-A2). This is the
   retention engine.
3. **Spec 041 (Glanceable habit)** — makes it visible on the home screen: **Wird-progress
   widget** (041-A1, fed by 023's summary) + Ayah + Athkar + Hijri widgets.

**Home-screen relationship (avoid a crowded shortcut dashboard).** The Home surface stays a
time-ordered *journey*, not a grid of shortcuts. Canonical contextual order (already reflected
in the shipped Home resume/primary-action cards):
1. **Next prayer** (countdown).
2. **Today's Wird** (Khatma target + progress).
3. **Continue reading or listening** (single calm control).
4. **Relevant Athkar** (morning/evening by time window).
5. **Secondary utilities** (Qibla, tasbeeh, etc.) — below the fold, not competing.
Widgets mirror this order on the home screen; no widget introduces a *new* competing tile.

## Execution Order (dependency-aware)

### Track A — Trust (Spec 043 remaining P0) — *start now, no cross-spec blockers*
- Location fallback (FR-015..017; ADR accepted, `cities_prototype.db` exists).
- Adhan hardening + Health UI + timing diagnostics (FR-006..009) — extend existing tests.
- Quran integrity: manifest over **real assets** + **CDN-font verification** (FR-001/001a/002/003a/003b);
  Athkar content governance (GOV-003).

### Track B — Habit (Spec 023 amendment 023-A) — *parallel with Track A*
- 023-A2 gentle adherence + **produce the semantic Wird summary** (Contract A).
- 023-A1 **plan-aware listening** (integration only — resume already shipped; reuse it).
- MVP already shipped, so this is additive and independently releasable behind flags.

### Track C — Widgets (Spec 041 amendment 041-A1) — *blocked on the 023 semantic summary*
- Wird-progress widget + **041 presentation adapter** (Contract B) **must wait** for 023-A2's
  semantic summary producer to exist. Other 041 work (Hijri US4, Share US5) is independent.
- iOS widget is **not** in this track — it is a future child spec (`041-ios-widgetkit-foundation`).

**Parallelism summary**: A ∥ B fully. C's Wird widget waits on B's summary; C's other widgets don't.

## Parallel Ownership — file/module coordination (prevents two agents editing the same file)

### Per-track owned surfaces
| Track / Spec | Owns (create/modify) | Explicitly does NOT own |
|---|---|---|
| **A — Spec 043** | `scripts/generate_quran_manifest.dart`, `scripts/audit_quran_pipeline.dart`; `features/quran/data/quran_validation_service.dart`; `packages/quran_qcf/.../quran_font_service.dart` (post-download verify); `features/prayer_times/**` adhan health + diagnostics; `features/location/**` + `assets/data/cities.db`; Athkar content governance config | **No Home UX**, no Khatma domain, no widgets |
| **B — Spec 023** | `features/smart_khatma/**` (plan domain, use cases, adherence); the **semantic** `WirdProgressSummary` producer; plan-aware listening high-water-mark in `update_khatma_progress_use_case.dart`; **contextual habit data** it exposes to Home | **No widget code**, no presentation/localization of the summary, no audio player internals (reuse only) |
| **C — Spec 041** | `features/islamic_widgets/**`; the **presentation adapter** (Contract A→B); `WirdProgressWidgetPayload`; native `widget/wird/**`; widget refresh + deep-link | **No plan-progress calculation**, no Khatma domain edits |

### Shared integration points — single owner per file (do not co-edit)
| Shared surface | File(s) | **Sole owner for this initiative** | Others |
|---|---|---|---|
| DI registration | `core/di/**`, `smart_khatma_dependencies.dart` | each feature owns its **own** module file | never edit another feature's module |
| Analytics names | `packages/core/lib/constants/analytics_constants.dart` | **Spec 041** lands widget names; **023** lands khatma names — different constants, coordinate via PR, no overlap | append-only |
| Feature flags | `smart_khatma_feature_flags.dart` (023), `contracts/feature-flags.md` (043), `enable_wird_widget` (041) | each spec owns its **own** flag | — |
| **Home composition** | `features/home/presentation/widgets/home_dashboard_body.dart` | **Spec 023** owns Home habit-row changes (it owns contextual habit data); 043 & 041 **must not** edit Home | 041 ships a home-**screen** widget, not an in-app Home edit |
| Localization | `l10n/app_ar.arb` / `app_en.arb` | each spec adds its **own** keys | append-only, namespaced keys |
| Deep-link routes | `router/app_router_config.dart` | **Spec 041** adds `openKhatma` widget route; **023** owns in-app Khatma routes | coordinate the single `openKhatma` destination |

**Rule**: if a change touches a shared file, the **sole owner** in the table lands it; other
tracks request the change rather than editing in parallel. This keeps concurrent agents from
colliding on `home_dashboard_body.dart`, `app_router_config.dart`, or `analytics_constants.dart`.

## Recommended First Implementation Slice (revised — evidence-based)
**Spec 023-A2 — produce the versioned semantic Wird summary** (behind `enable_wird_adherence`).
- Continue-listening *resume* already exists, so it is **not** a valid "first slice" (would be
  re-describing shipped work). The genuinely unblocking, low-risk slice is the **summary producer**.
- It is built almost entirely from the **already-shipped** plan domain (today-target, progress),
  so it is small and additive.
- It **unblocks Track C** (the Android Wird widget + adapter can't start without Contract A output).
- It touches **no** Quran-rendering, adhan, location, or content-integrity code → cannot regress
  the trust floor while Track A hardening runs in parallel (no shared-file overlap: 023 owns
  `smart_khatma/**`; 043 owns integrity/adhan/location).
- **023-A1 plan-aware listening** follows as a separate, independent enhancement (also reuse-only).

*(Do not implement yet — sequencing recommendation only.)*
