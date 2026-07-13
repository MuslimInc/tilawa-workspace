# Amendment: Review-Insight Gaps for Smart Khatma (023-A)

> **Superseded for release progress semantics:** listening, adherence, pause,
> and high-water-mark requirements in this research amendment are post-release.
> `amendment-production-readiness.md` is the normative release contract.

**Status**: Proposed (documentation only — do not implement yet)
**Parent**: `specs/023-smart-khatma-reading-plan/spec.md` (active; MVP shipped)
**Source evidence**: Khatmah review sample, `docs/khatmah_reviews_deep_analysis_for_memuslim.xlsx`
(extremes-only sample — see `specs/043-core-trust-and-reliability/research.md`). Research IDs
**K35** (recitations/listening) and **K51** (adherence days). Both are *moderate/inferred*
strength, **not** proven majority demand.

## Why an amendment (not a spec rewrite)
Spec 023's MVP is implemented in the repository — verified files:
`features/smart_khatma/domain/entities/khatma_plan.dart` (plan math, `todayTargetPages`,
`missedDays`, calm catch-up), 7 use cases (create/getActive/todayTarget/updateProgress/
catchUp/extend/reset), `khatma_plan_bloc`, `khatma_plan_local_datasource`,
`smart_khatma_home_entry_card`, `smart_khatma_hub_screen`, and khatma analytics
(`khatma_created`, `khatma_progress_updated`, `khatma_goal_completed`,
`khatma_catchup_selected`, `khatma_extend_selected`, `khatma_completed`,
`khatma_dashboard_viewed`, `khatma_continue_reading`). Rewriting the shipped spec would
damage historical accuracy, so confirmed gaps are added here as scoped amendments.

## Repository reality that bounds scope (do NOT rebuild these)
- **A listening streak already exists**: `features/home/domain/quran_engagement_streak.dart`
  (`quranEngagementStreakDays`) — non-punitive, computed from listening history; surfaced via
  `home_quran_resume_state.streakDays`. It is **engagement-based, not Wird-completion-based**.
- **Continue-listening already exists** at Home: `home_listening_resume_row.dart`,
  `home_quran_resume_cubit`, `reciters/.../reciter_history_section.dart`. Resume position
  (surah/ayah/page) is already tracked. It is **not tied to the Khatma today-target**.
- The Khatma `readingStyle` enum has `pages | minutes` but no audio/listening progress path.

Therefore these amendments are **integration + a plan-completion signal**, not new subsystems.

---

## 023-A1 — Integrate listening progress with the active daily Quran plan

**Disposition: PARTIALLY IMPLEMENTED.** Continue-listening *resume itself is already
implemented* — do **not** rebuild it, and do **not** describe "Continue Listening on Home" as
a new feature. This amendment defines **only the missing integration**: making listening
**plan-aware** (feeding the daily Khatma target), which today it is not.

### Audited current behavior (repository evidence)
| Question | Finding | File |
|---|---|---|
| State persisted | reciterId/Name, surahId/Name, moshafId/Name, audioUrl, **lastPositionMs**, durationMs, artworkUrl, historyId, playedAt | `history_entity.dart`, `home_listening_resume_state.dart` |
| Surah / reciter / playback position preserved | **Yes** — resume replays via `AudioPlayerBloc.playFromQueue(..., initialPosition: lastPositionMs)` | `home_listening_resume_row.dart` |
| Ayah preserved | **No** — audio history is surah+position level, not ayah | `home_listening_resume_cubit.dart` |
| Works offline | **Not explicit** — replays `latest.audioUrl`; no downloaded-vs-remote check or "not downloaded" affordance | `home_listening_resume_cubit.dart` |
| Connected to Khatma/Wird plan | **No** — the listening cubit reads only `HistoryRepository`; it never touches the plan | `home_listening_resume_cubit.dart` |
| Listening contributes to plan completion | **No** — only reading feeds the plan: `HomeQuranResumeCubit._goalProgress` derives Khatma progress from the **last read page** only | `home_quran_resume_cubit.dart` |
| Competes with Continue Reading on Home | **No** — reading is the primary resume card; listening is a separate conditional slim row ("YOURS layer") | `home_dashboard_body.dart` |
| Satisfies review K35 | **No.** K35 ("القراءات لا تعمل") is a **playback-failure** complaint = audio robustness (ledger: `future_spec`), *not* continue-listening resume. 023-A1 is therefore **not** backed by K35. |

### Evidence honesty
There is **no direct review evidence** in the sample for "plan-aware listening." This is a
**product-coherence inference** (⚖️ judgment): the plan should reflect *all* Quran engagement,
not only reading. Strength: **weak/inferred** — it is a design-consistency bet, not a user demand.
It is included because it is low-cost (reuses shipped infrastructure) and removes an asymmetry,
**not** because users asked for it. If descoped, nothing regresses.

### Requirements (integration only)
- **FR-023A1.1**: Plan progress MUST use a single **high-water-mark page** (`currentPage =
  max(currentPage, engagedPage)`), advanced by **either** reading **or** listening. Progress is
  a monotonic high-water mark, **never a sum** — this structurally prevents double-counting a
  portion that is both read and listened.
- **FR-023A1.2**: A listening session MAY advance `currentPage` **only** when the current
  audio position maps to a Quran page **deterministically** (surah/ayah→page via the existing
  page map). If the mapping is not deterministic, listening MUST NOT change plan progress
  (no guessing; reading remains the source of truth).
- **FR-023A1.3**: This MUST reuse the existing listening-history + `AudioPlayerBloc` resume;
  it MUST NOT create a second resume system, player, or position store.
- **FR-023A1.4** (offline hardening, minor): when the resume audio is not available offline,
  the existing row SHOULD surface a calm "not downloaded" affordance instead of a silent fail.

**User journey**: User listens to a surah that maps to pages ahead of their last-read page →
the Khatma "today's Wird" progress advances to reflect the furthest engaged page → no
double-count if they later read the same pages.

**Acceptance criteria**
- Listening past page N (deterministic map) sets plan `currentPage = max(currentPage, N)`.
- Reading and listening the same range advances progress **once** (high-water mark), never twice.
- Non-deterministic audio position leaves plan progress unchanged.
- No new resume/player/store types are introduced (reuse only).

**Analytics** (extend existing, privacy-safe): `khatma_listening_progress` { `plan_id?`,
`engaged_page`, `advanced` (bool) }. No per-ayah identity tied to a user.

**Privacy**: reuse existing history; day/page-level only; no new precise-behavior logging.

**Tasks (not implemented)**
- [ ] T-023A1-a: Add a page-map resolver for audio position → Quran page (deterministic-only).
- [ ] T-023A1-b: Feed `max()` high-water-mark into `update_khatma_progress_use_case` from listening.
- [ ] T-023A1-c: Offline "not downloaded" affordance on the existing listening row.

**Tests**
- Unit: high-water-mark never double-counts; non-deterministic position is a no-op; offline branch.

**Non-goals**: new player/resume/store, background audio changes, cross-device sync, ayah-level
audio tracking, and re-implementing the already-shipped continue-listening row.

---

## 023-A2 — Gentle Wird adherence (plan-completion based)

- **FR-023A2.1**: Track **days the Wird target was met** for the active plan ("أيام الالتزام").
  This is distinct from the existing engagement streak (which counts any listening day); it
  MUST reflect **plan-day completion**, derived from existing `updateProgress`/`goalCompleted`
  signals — **reuse `quran_engagement_streak` computation style; do not add a punitive model**.
- **FR-023A2.2**: Language and visuals MUST be **calm and non-guilt** — show "days committed"
  and "best run"; MUST NOT show loss animations, red warnings, or "you broke your streak".
- **FR-023A2.3**: A missed day MUST route into the **existing calm catch-up** (`selectKhatmaCatchUp`
  / `extend`) — never a penalty. Users MAY pause a plan; paused days are not counted as missed.
- **FR-023A2.4**: Adherence MUST expose a small, privacy-safe summary (count + best run +
  completion ratio) consumable by the Wird widget (see contract `contracts/wird-progress-summary.md`).
- **FR-023A2.5**: No competitive mechanics — no leaderboards, no comparison to other users,
  no shareable "streak" pressure.

**User journey**: User completes today's Wird → "days committed" ticks up calmly → if a day
is missed, the app offers "catch up gently" or "extend", never guilt.

**Acceptance criteria**
- Completing the Wird increments days-committed by 1 for that local day (idempotent).
- Missing a day does not reset with any punitive UI; catch-up/extend is offered.
- Pausing a plan freezes adherence without counting missed days.
- Adherence summary matches the widget summary contract fields.

**Analytics**: `khatma_adherence_viewed` { `plan_id?`, `days_committed`, `best_run` } (no PII).

**Privacy**: day-level booleans only; no precise reading log tied to identity; local-first.

**Tasks (not implemented)**
- [ ] T-023A2-a: Derive plan-day-completion adherence from existing progress signals.
- [ ] T-023A2-b: Calm adherence surface on the Khatma hub (reuse streak style).
- [x] T-023A2-c: Emit the versioned Wird summary for the widget (producer side).

### T-023A2-c implementation record

- Schema: `WirdProgressSummary.currentSchemaVersion == 1` in
  `domain/entities/wird_progress_summary.dart`; validated `noPlan`, `active`, and `completed`
  factories prevent invalid state combinations.
- Producer: `domain/usecases/get_wird_progress_summary_use_case.dart`; repository-only,
  locale-free, analytics-free, listening-free, and read-only.
- Daily checkpoint: `KhatmaPlan.progressDate` + `progressStartPage`, initialized and rolled over
  only by `update_khatma_progress_use_case.dart`, persisted under the existing
  `smart_khatma.active_plan.v1` key with backward-compatible optional fields.
- Adjustment semantics: `KhatmaPlan.adjustment` is the last selected recovery strategy;
  `adjustmentDate` scopes its semantic relevance to the selection's local civil day. Historical
  choices are not emitted as current state.
- Unit: schema v1 supports verified page progress only. `KhatmaReadingStyle.minutes` returns the
  existing failure type; it is never interpreted as pages.
- Pause: not supported by the shipped plan domain and therefore removed from schema v1 rather
  than emitted speculatively.
- Tests: summary invariants/read-only behavior, local-day rollover and injected clock, adjustment
  expiry, legacy/null/malformed serialization, unsupported units, and corrupt checkpoints.
- Remaining A2 gaps: adherence-day ledger, paused-plan domain behavior, and the calm adherence
  hub surface remain T-023A2-a/b. T-023A2-c alone does not mark all of 023-A2 complete.

**Tests**
- Unit: completion increments; miss → no punitive reset; pause freezes; best-run.
- Golden/widget: calm copy, no guilt affordances; RTL + LTR.

**Non-goals**: gamified streaks, social comparison, notifications pressure, reminder engine
(reminder configuration is a **separate** gap — noted below, not in this amendment).

---

## Out of scope for 023-A (explicitly)
- **Dedicated Wird reminder configuration** — the repo has no khatma/wird reminder settings;
  this is a real but separate gap. Recommend a focused follow-up (023-A3 or a reminder spec),
  reusing the prayer notification infra hardened by Spec 043. Not included here to keep the
  amendment shippable.
- The **widget itself** is owned by Spec 041 (`amendment-wird-progress-widget.md`); 023 only
  **produces** the summary via `contracts/wird-progress-summary.md`.

## Rollout
- Feature-flag both amendments (`enable_continue_listening_wird`, `enable_wird_adherence`),
  default off → staged. No change to shipped MVP behavior when flags are off.
