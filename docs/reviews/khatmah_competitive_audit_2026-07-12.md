# Al-Khatmah Competitive Audit: Khatmah Android vs MeMuslim

**Date:** 2026-07-12

**Mode:** Documentation-only competitive and production-readiness audit

**Evidence inspected:** 28 competitor screenshots; current repository at commit `94dd38fe5` plus the pre-existing staged Smart-Khatma-default change; Specs 023, 041, and 043; Flutter/domain/native code and tests
**Verdict:** **Not ready** for a production Al-Khatmah rollout. The plan domain is promising, but the core reading-range, daily-completion, and Home journey are not yet coherent enough to earn user trust.

## Evidence conventions

- **[Screenshot evidence]** Directly visible in the supplied Khatmah capture.
- **[Repository evidence]** Directly verified in the current MeMuslim worktree.
- **[Specification evidence]** Stated by Spec 023, Spec 041, or the Spec 043 roadmap.
- **[Product inference]** A reasoned interpretation, not directly proven.
- **[Unknown]** The screenshots/code inspected cannot establish the behavior.

The competitor screenshots demonstrate visible UI states, not the competitor's internal correctness. No screenshot-derived behavior is treated as an implementation requirement without an explicit recommendation and acceptance criterion.

## 1. Screenshot inventory

| Filename | Inferred screen / flow step | Visible actions and state | Important pattern | Confidence / uncertainties |
|---|---|---|---|---|
| `Screenshot_1783884624.png` | New Khatmah: choose start boundary (1) | “Start from” selector defaults to Beginning of Quran; Continue | Creation is a short wizard; start boundary is explicit | High. Entry path before this screen is not captured. |
| `Screenshot_1783884630.png` | Start-boundary selector open (1a) | Dropdown option “Juz' 2” visible | Supports a non-default Quran boundary | High for Juz selection; full option set unknown. |
| `Screenshot_1783884647.png` | New Khatmah: duration/amount (2) | 5-day duration with −/+; calculated “5 Juz' & 5 Rub'”; Continue | Duration and calculated daily amount are shown together before creation | High. Whether daily amount itself is editable is unclear because both fields show dropdown affordances. |
| `Screenshot_1783884655.png` | Prayer location onboarding (parallel setup) | Detect Location, Skip | App-level setup interrupts the captured Khatmah flow | High. Not a Khatmah capability. |
| `Screenshot_1783884663.png` | Location success | Found location, Continue | Explicit success confirmation | High. Not a Khatmah capability. |
| `Screenshot_1783884666.png` | Today / current session (3) | Starts Juz' 2; exact Surah/Ayah and page 22→139 range; Start Reading; Done Reading; session counts 0 previous/4 upcoming | Current session is the primary object; exact boundaries reduce ambiguity | High. Manual Done Reading is visible but validation behavior is unknown. |
| `Screenshot_1783884677.png` | Quran reader opened from current session (4) | Page 22, Juz' 2; settings, bookmark; Mushaf page | Direct transition to the session's exact start | High. End-boundary enforcement is unknown. |
| `Screenshot_1783884680.png` | Quran reader rendering failure | Header and scrubber visible; most Quran content black/corrupted | Severe reliability/trust failure in the captured competitor build | High as visual evidence; root cause unknown. |
| `Screenshot_1783884694.png` | Session advanced / daily completion feedback (5) | Modal: proceeded to next session; previous sessions available in More; background shows next session | Explicit transition feedback after manual completion | High. Whether progress was verified or merely accepted is unknown. |
| `Screenshot_1783884698.png` | Next current session | Juz' 7, page 140→256; 1 previous/3 upcoming | Plan is divided into discrete, inspectable sessions | High. |
| `Screenshot_1783884701.png` | Later current session / ahead state | Juz' 13, page 256→371; “Ahead by day”; 2 previous/2 upcoming | Progress feedback indicates ahead/behind schedule without hiding the range | High. Grammar/number handling is visibly weak. |
| `Screenshot_1783884704.png` | Later session with rendering corruption | Juz' 19 and partial range/session UI; large black regions | Repeated severe rendering failure | High as visual evidence; exact obscured actions are uncertain. |
| `Screenshot_1783884710.png` | Athkar catalog, upper section | Morning/Night/Sleep/After Prayer/Waking Up/Masjid/Duaa/Quran Duaa | Separate app feature, not Khatmah flow | High. |
| `Screenshot_1783884712.png` | Athkar catalog, lower section | Travel Duaa, Rouqia Athkar | Separate app feature | High. |
| `Screenshot_1783884717.png` | Prayer Times | Next-prayer countdown; day/date; per-prayer alarms | Separate app feature | High. |
| `Screenshot_1783884722.png` | Quran Index | Surahs/Ajza' tabs; Surah list and page numbers | Reader navigation is separate from daily plan | High. |
| `Screenshot_1783884728.png` | Quran reader from Index | Al-Fatihah page 1; settings/bookmark/scrubber | Generic reader can be entered outside Khatmah | High. |
| `Screenshot_1783884733.png` | More, current Khatmah section | Previous Sessions (3), Upcoming Sessions (1), Bookmark; Daily Alarm; Start New Khatmah | History/settings separated from the daily task; reminder is discoverable but secondary | High. Restart confirmation and archive behavior unknown. |
| `Screenshot_1783884740.png` | More/settings, upper | Prayer and Athkar alarm controls; Quranic Sunnah alarms | Reminder infrastructure is broad, not necessarily plan-aware | High. |
| `Screenshot_1783884742.png` | More/settings, lower | Language, contact/social/share/rate | Separate settings | High. |
| `Screenshot_1783884750.png` | Support | One-time support amounts and Continue | Monetization is outside the active reader | High. Not relevant to Khatmah parity. |
| `Screenshot_1783884754.png` | Bookmark empty feedback | “The bookmark hasn't been set yet” dialog | Explicit empty feedback, but disruptive modal | High. |
| `Screenshot_1783884763.png` | Reader bookmark success | Page 371; snackbar “The bookmark has been set.” | Immediate, non-blocking success feedback | High. |
| `Screenshot_1783884767.png` | Reader rendering failure | Nearly all Mushaf content black/corrupted | Third captured severe Quran-render failure | High as visual evidence; root cause unknown. |
| `Screenshot_1783884769.png` | Reader recovered/normal | Same page 371 renders correctly | Failure may be intermittent rather than missing content | Medium-high; sequence suggests recovery but mechanism is unknown. |
| `Screenshot_1783884774.png` | Share session | Android share sheet contains exact session range and attribution | Session boundary is shareable as text | High. Sharing religious-activity progress is optional and should not be copied by default. |
| `Screenshot_1783885386.png` | Upcoming Sessions | Session 5 card shows Surah Ash-Shura 27 → An-Nas 6 and pages 486→604 | Future assignments can be inspected before they become current | High. Editing/reordering is not visible. |
| `Screenshot_1783885390.png` | Previous Sessions | Session cards show exact prior Surah/Ayah and page ranges | History is separate from Today and preserves assignment auditability | High. The first card is visually corrupted/clipped, so reliability remains a concern. |

**Inventory check:** 28 of 28 files inspected visually; none skipped.

## 2. Competitor Khatmah flow map

```text
Unknown entry
  → New Khatmah: choose Quran/Juz start boundary
  → choose duration and see calculated Juz/Rub daily amount
  → [app-level location onboarding appeared in this capture; relationship uncertain]
  → Today: exact current-session start/end Surah, Ayah, and page
  → Start Reading
  → Quran reader at exact start page
  → manual Done Reading
  → explicit “next session” feedback
  → current session advances; previous/upcoming counts update
  → ahead-of-plan feedback
  → More: previous sessions / upcoming sessions / bookmark / daily alarm / start new Khatmah
      → inspect exact historical and future session ranges
  → full-plan completion: UNKNOWN (not captured)
  → missed-day recovery: UNKNOWN (not captured)
```

Reusable principles—not visual patterns to clone:

1. Make today's assigned range explicit before opening the reader.
2. Keep one clear daily primary action.
3. Separate daily work from history/settings.
4. Confirm the transition from one daily assignment to the next.
5. Let the user understand where plan progress came from.

Behaviors not recommended for copying:

- Manual “Done Reading” without visible verification: it may create false completion.
- Juz/Rub as the only unit: MeMuslim already uses page-based Mushaf progress and should retain one verified unit.
- “Ahead by day” grammar and thumbs-up pressure.
- Modal-heavy feedback for routine actions.
- Session sharing by default; religious activity should remain private unless the user deliberately chooses to share.
- The competitor's saturated visual identity, navigation composition, illustrations, and exact wording.

## 3. MeMuslim current-state map

```text
Home
  → More actions (only when Smart Khatma flag is enabled)
  → Smart Khatma hub
      no plan → choose 7/15/30/60 days
              → plan is created immediately from last-read page
      active → overall %, day/duration, today's page count, remaining pages/days
             → Continue Reading / Today Goal
             → generic QuranLastReadRoute
             → image reader saves last-read page and attempts monotonic +1 plan progress
      missed → Catch up today OR Extend plan
      completed → distinct completion state (added in current commit)

Optional and independently gated:
Home → Today Plan → Khatmah-derived reading page count + generic Continue
Android launcher → Daily Wird widget → Smart Khatma hub
```

Repository evidence:

- **Discovery:** `home_more_actions_group.dart` conditionally links to `SmartKhatmaHubRoute`; `smart_khatma_home_entry_card.dart` exists but has no production caller. **[Repository evidence]**
- **Flags:** committed `HEAD` defaults Smart Khatma off, but the inspected worktree already has a staged change making its environment default **on**. Today Plan and the Wird widget remain default off, so the daily core is split across rollout switches and the incomplete hub may become discoverable before its daily integration. **[Repository evidence]**
- **Creation:** `_KhatmaHubEmptyBody` dispatches `KhatmaPlanQuickStartRequested` directly for 7/15/30/60 days; no preview/confirmation/edit step exists. **[Repository evidence]**
- **Starting boundary:** `CreateKhatmaPlanUseCase` reads `QuranReaderRepository.getLastReadPosition()` and falls back to page 1. Users cannot choose a boundary in the UI. **[Repository evidence]**
- **Plan math:** `KhatmaPlan` computes total/completed/remaining pages, daily target, elapsed/remaining days, and missed-day debt. **[Repository evidence]**
- **Recovery:** catch-up records a strategy; extend increases duration by clamped missed days. The hub exposes both when `missedDays > 0`. **[Repository evidence]**
- **Reader navigation:** both `openKhatmaReaderAndRefresh` and Today Plan's continue action push `QuranLastReadRoute`, not a plan-range route. **[Repository evidence]**
- **Reader write-back:** `quran_image_reader_screen.dart` saves every visible page and calls `UpdateKhatmaProgressUseCase` when Smart Khatma is enabled. **[Repository evidence]**
- **Progress acceptance:** the use case ignores backward movement and ignores jumps larger than one page. **[Repository evidence]**
- **Daily completion:** `WirdProgressSummary` can derive assigned/completed/remaining pages from a daily checkpoint, but the in-app Khatmah hub does not render those daily completed/remaining values. The separate Today Plan permits manual task toggling independent of Khatmah progress. **[Repository evidence]**
- **Persistence:** one plan is stored under `smart_khatma.active_plan.v1`; current parsing tolerates missing optional legacy fields and ignores malformed data. **[Repository evidence]**
- **Completion:** current commit renders a dedicated full-plan completion state and start-another action. **[Repository evidence]**
- **Reminder:** no Khatmah/Wird reminder service or setting exists; only unrelated prayer, Athkar, Tasbeeh, and Quranic-Sunnah reminders were found. **[Repository evidence]**
- **Widget:** Flutter summary/adapter/sync plus Android payload/provider/layout/manifest/deep-link are now present, behind a dedicated default-off flag. It is an optional extension and does not complete the Flutter journey. **[Repository evidence]**

## 4. End-to-end journey audit

| Journey | Status | Evidence and blocker |
|---|---|---|
| A — New user | **Works partially** | Discovery is secondary; creation supports only duration presets and commits immediately. No plan preview, selectable start boundary, end date, or calculated range before confirmation. (`home_more_actions_group.dart`, `smart_khatma_hub_screen.dart`, `CreateKhatmaPlanUseCase`) **[Repository evidence]** |
| B — Daily use | **Blocked** | A target count exists, but no explicit start/end assignment is shown or routed. Continue opens generic last-read, and daily completion is not tied to verified Khatmah progress. (`smart_khatma_plan_actions.dart`, `today_plan_card.dart`) **[Repository evidence]** |
| C — Interrupted day | **Works partially** | Last-read page persists locally and reader resume exists. However, resume is generic reader state, not a persisted Khatmah assignment/session boundary; daily accuracy can diverge after reading elsewhere. **[Repository evidence]** |
| D — Missed days | **Works partially** | Debt math and catch-up/extend controls exist with calm copy. No before/after recalculation preview or explicit new end date/target is shown. **[Repository evidence]** |
| E — Entire plan completion | **Works partially** | Current commit adds a distinct completion surface. Completion correctness still depends on ambiguous/off-by-one page semantics and exact sequential page visits; starting at page 604 cannot naturally advance. **[Repository evidence]** |
| F — Failure and migration | **Works partially** | Legacy optional fields, malformed JSON, local persistence, local-day checkpoints, and timezone tests exist. Unsupported minute plans fail the widget summary; there is no user recovery explanation or migration path for that state. Offline core plan math works because it is local. **[Repository evidence]** |

## 5. Capability matrix

| Capability | Khatmah evidence | MeMuslim status | MeMuslim path / exact behavior | Gap and user impact | Severity | Recommendation |
|---|---|---|---|---|---|---|
| Discover Khatmah | Current session dominates Today; Start New appears in More | **Implemented but weakly exposed** | `home_more_actions_group.dart`; dedicated Home card has no caller | New and returning users may not see the habit loop; active plan is not the primary Home object | P1, high confidence | Place one contextual Khatmah/Wird row in approved Home order; do not add another shortcut grid. |
| Select start boundary | Start from Quran/Juz selector | **Missing** | Creation always uses last-read page or page 1 | User cannot review/correct an accidental or stale last-read position | P1, high confidence | Offer “continue from page N” and “start from beginning” at minimum; advanced Juz selection can be progressive disclosure. |
| Duration presets | Duration step with increment controls | **Implemented and user-visible** | 7/15/30/60 buttons in `_KhatmaHubEmptyBody` | Presets are clear but narrow | P2 | Keep presets; add a bounded custom duration only if research/spec approves. |
| Calculated plan preview | Daily Juz/Rub shown before Continue | **Missing** | Button immediately creates plan | Users commit without seeing start page, end date, or daily load | P1 | Add a confirmation sheet showing start page, target page, end date, and pages/day. |
| Plan naming | Not visible | **Not applicable** | No plan name | No demonstrated competitor/user need | — | Do not add. |
| Exact today's range | Exact Surah/Ayah/page start and end | **Partially implemented** | Count and resume page exist; no end boundary in UI | User cannot know when today's Wird is complete | **P0** | Define one plan-owned daily assignment with inclusive start/end pages and show it in hub/Home/reader entry. |
| Start today's reading | Start Reading opens exact page | **Partially implemented** | `QuranLastReadRoute` opens generic last-read | Reading elsewhere can open the wrong page/range | **P0** | Route with the assignment start page; preserve a separate generic Quran resume path. |
| Progress write-back | Manual Done Reading advances session | **Partially implemented** | Reader page changes advance only one page at a time | Sequential reading is tracked, but semantic meaning of `currentPage` is inconsistent and lacks range ownership | **P0** | Define `nextUnreadPage` or `lastCompletedPage` unambiguously; migrate and test boundaries 1, 604, and arbitrary start. |
| Daily completion | Explicit next-session dialog | **Domain support exists, UX missing** | `WirdProgressSummary`; no core Khatmah daily-completion surface | Users cannot tell that today's target was actually met | **P0** | Derive daily completion only from verified page progress; show calm inline completion and next-day availability. |
| Manual task completion | Done Reading button | **Competitor behavior should not be copied** | Today Plan row is manually toggleable | Current MeMuslim manual toggle can contradict Khatmah progress | **P0** | Disable manual completion for Khatmah-backed reading tasks or make it read-only/derived. |
| Interrupted-day resume | Current session persists | **Partially implemented** | Generic last-read persists; checkpoint persists | Reading outside the plan can displace resume and daily start | P1 | Persist assignment identity and plan-specific resume high-water mark without parallel Quran history. |
| Overall progress | Previous/upcoming sessions and bar | **Implemented and user-visible** | Hub shows percent, day, remaining pages/days | Strong domain capability; lacks auditability to exact range | P2 | Keep aggregate hero; add compact assignment details below it. |
| Ahead/behind state | Ahead by 1/2 days | **Partially implemented** | `missedDays`; no ahead state | Behind recovery exists; ahead reading is simply reflected in page progress | P2 | Avoid competitive wording; optionally say “Today's Wird is complete” rather than “ahead.” |
| Catch up | Not captured | **Implemented and user-visible** | `SelectKhatmaCatchUpUseCase`, hub recovery panel | Selection does not visibly preview/change the target because catch-up mostly records metadata | P1 | Show current vs recalculated pages before confirmation and persist the chosen strategy's effective plan. |
| Extend | Not captured | **Implemented and user-visible** | `ExtendKhatmaPlanUseCase` adds missed days | New end date and resulting target are not shown before/after | P1 | Confirmation sheet with old/new end date and daily pages. |
| Pause/skip | Not captured | **Not applicable** | No shipped plan-domain support; Spec amendment explicitly says pause is unsupported in schema v1 | Adding it now would create unsupported parallel behavior | — | Keep out of scope until a dedicated approved spec defines temporal semantics/migration. |
| Full-plan completion | Not captured | **Partially implemented** | Dedicated completed UI in current commit | UI exists; correctness boundary remains unsafe | **P0** | Fix page semantics first; test final-page start, final transition, restart, and start-another. |
| History/archive | Previous Sessions list | **Missing** | Reset deletes the only active plan; no archive | Not required for one-active-plan MVP, but completed plan is overwritten/reset | P2 | Keep out of MVP unless product wants historical completions; document deletion clearly. |
| Destructive reset | Start New visible; confirmation unknown | **Implemented and user-visible** | `showTilawaConfirmDialog` | MeMuslim is safer here | — | Retain. |
| Reminder | Daily Alarm in More | **Documented but not implemented** | Roadmap calls reminder part of habit loop; no Khatmah reminder code | Daily habit lacks a user-controlled prompt | P1 | Add only after core correctness; reuse notification infrastructure and privacy-safe local scheduling. |
| Arabic/English | English captures only | **Implemented and user-visible** | ARB keys for hub; Android resources for widget | Current Khatmah-specific widget and hub have both locales; visual RTL/text-scale coverage is incomplete | P1/P2 | Add Arabic/English widget tests at 1.4 app scale and native supported scaling; verify directional icons. |
| Accessibility | Unknown | **Partially implemented** | FAB semantic label; Home card semantics inherited; native widget description | No comprehensive hub semantics or large-text regression suite | P1 | Test empty/active/recovery/completed/error in RTL/LTR at text scale 1.4; native compact/expanded at launcher scaling. |
| Offline/stale | Competitor reader corruption captured; offline unknown | **Partially implemented** | Core is local; widget keeps last snapshot and stale cue | Core UI has no explicit offline distinction because no network is required; widget behavior is appropriate | P2 | Do not invent an offline error for local plan math; show errors only for actual persistence/reader failures. |
| Android home widget | Not captured | **Widget-only** | `features/islamic_widgets/**`, `widget/wird/**`, manifest | Optional extension is more complete than core daily UX | P1 sequencing risk | Keep flag off until Phase 0/1 gates pass. |
| Analytics/privacy | Unknown | **Partially implemented** | Khatmah events include plan id and exact pages; some declared events have no emitter | Exact religious reading positions exceed what rollout monitoring needs | P1 | Minimize to duration bucket, aggregate progress bucket, action/result/failure; never send raw current/start page or precise history. |

## 6. UX comparison

| Dimension | Khatmah screenshot evidence | MeMuslim assessment |
|---|---|---|
| Discoverability | Today is literally the current Khatmah session | MeMuslim buries entry in More and gates the stronger Today integration separately. **[Repository evidence]** |
| Hierarchy | Exact current session and two CTAs dominate | MeMuslim's hub emphasizes overall percentage; today's assignment is only a page count and shares attention with three navigation rows and a FAB. **[Repository evidence]** |
| Daily-task clarity | Explicit range and Start Reading | MeMuslim lacks an end boundary and routes to generic resume. **[Repository evidence]** |
| Progress visibility | Previous/upcoming counts and ahead state | MeMuslim's overall percent/days/pages are stronger aggregate metrics, but daily completed/remaining values are absent from the core hub. **[Repository evidence]** |
| Resume | Session start is stable in the visible flow | MeMuslim uses global last-read, which is convenient but not plan-owned. **[Repository evidence]** |
| Recovery | Not captured | MeMuslim is ahead conceptually: calm catch-up/extend exists, but feedback and preview are weak. **[Repository evidence]** |
| Completion | Manual next-session feedback captured; full completion unknown | MeMuslim now has a calm full-completion surface, but daily completion is missing and final-page correctness is unsafe. **[Repository evidence]** |
| Accessibility | Unknown from screenshots | MeMuslim uses UI Kit/tokens and some semantics; state coverage at large text/RTL is not demonstrated. **[Repository evidence]** |
| Localization | English screenshots; awkward plural grammar visible | MeMuslim has Arabic/English ARB coverage and plural forms, a relative strength. **[Repository evidence]** |
| Visual density | Large card and persistent bottom nav; simple but space-inefficient | MeMuslim's UI Kit is calmer and more coherent; it should improve task hierarchy without copying the competitor. **[Product inference]** |
| Emotional tone | Progress/ahead thumbs-up can feel evaluative | MeMuslim's “adjusted gently” and acceptance-oriented completion copy better match the brand. **[Repository evidence]** |
| Trust | Exact ranges are understandable, but three captures show severe Quran rendering corruption | MeMuslim's QCF/image reader foundation may be stronger, yet ambiguous plan range/completion semantics remain a trust risk. **[Screenshot + repository evidence]** |

## 7. Strict production-readiness findings

### P0-1 — Page semantics are internally inconsistent

- **Issue:** `currentPage` is initialized to the start page, `completedPages` subtracts the start page, `remainingPages` includes the current page, and completion is forced when visiting the target page. This mixes “last viewed,” “last completed,” and “next unread” meanings.
- **Impact:** First-page credit, daily completed amount, final progress, and migration behavior can be off by one. A plan created while last-read is page 604 is not initially complete and has no page 605 transition to finish it.
- **Location:** `features/smart_khatma/domain/entities/khatma_plan.dart`; `create_khatma_plan_use_case.dart`; `update_khatma_progress_use_case.dart`.
- **Evidence:** **[Repository evidence]**
- **Smallest correction:** Choose one invariant (`nextUnreadPage` is the clearest), migrate v1 safely, and exhaustively test start=1, start=604, one-page plan, first accepted advancement, and final page.

### P0-2 — “Continue” does not open a plan-owned daily assignment

- **Issue:** Khatmah and Today Plan both push `QuranLastReadRoute`; no route carries today's assignment start/end.
- **Impact:** Reading elsewhere can make Continue open the wrong place; users cannot verify what counts toward today's Wird.
- **Location:** `smart_khatma_plan_actions.dart`; `today_plan_card.dart`; `get_khatma_today_target_use_case.dart`.
- **Evidence:** **[Repository evidence]**
- **Smallest correction:** Produce a versioned daily assignment from the plan domain and route to its start page. Do not create another reader or progress store.

### P0-3 — Daily completion can contradict verified Khatmah progress

- **Issue:** Today Plan lets the user manually toggle `read_quran` complete while Khatmah progress is independently derived from reader page changes.
- **Impact:** Home can say reading is done while the Khatmah summary says pages remain, undermining religious-activity trust and widget accuracy.
- **Location:** `_TodayPlanTaskRow`, `TodayPlanBloc._onTaskToggled`, `WirdProgressSummary`.
- **Evidence:** **[Repository evidence]**
- **Smallest correction:** For a Khatmah-backed reading task, render completion from the plan summary and reject manual toggling; retain toggling for unrelated Today Plan tasks.

### P0-4 — No core in-app daily-completion state

- **Issue:** Contract A computes completed/remaining/ratio, but the Flutter Khatmah hub displays assigned pages only. The most complete daily surface is the optional Android widget.
- **Impact:** The feature cannot close its central daily ritual without an optional launcher extension.
- **Location:** `get_wird_progress_summary_use_case.dart`; `smart_khatma_hub_screen.dart`; `wird_progress_widget_adapter.dart`.
- **Evidence:** **[Repository evidence]**
- **Smallest correction:** Reuse Contract A in the hub/Home; show assigned, completed, remaining, and calm day-complete state.

### P1 findings

1. **Weak discovery and split flags:** Smart Khatma lives under More; the inspected staged config enables it by default while Today Plan remains a separate default-off gate. **[Repository evidence]**
2. **Immediate creation without preview:** duration tap persists immediately; no calculated end date/range confirmation. **[Repository evidence]**
3. **Recovery lacks consequences:** catch-up/extend are exposed but no old/new target or end-date preview is shown. **[Repository evidence]**
4. **No dedicated reminder:** the roadmap names reminder as part of the retention loop; implementation is absent. **[Specification + repository evidence]**
5. **Privacy-heavy analytics:** exact page and local plan identifiers are logged even though aggregate rollout signals would suffice; several declared events are never emitted. **[Repository evidence]**
6. **Accessibility evidence incomplete:** no comprehensive hub RTL/LTR, dynamic text, semantics, or native compact/expanded state matrix. **[Repository evidence]**
7. **Unsupported minutes remain in the entity/API:** UI does not expose them and widget summary rejects them; this should stay non-user-facing until a verified progress source exists. **[Repository evidence]**

### P2 findings

1. No optional completed-plan archive/history; acceptable for the one-plan MVP if clearly documented.
2. No gentle “ahead” message; not necessary if day completion is clear.
3. Hub repeats Continue via FAB and navigation row, weakening one-primary-action hierarchy.
4. Some fallback failure strings remain stored in BLoC state even though current Khatmah surfaces now localize the display.

**Finding counts:** 4 P0, 7 P1, 4 P2.

## 8. Implementation roadmap

### Phase 0 — Correctness and blockers

| Requirement | Owner / expected files | Dependencies | Tests | Acceptance criteria | Rollout risk |
|---|---|---|---|---|---|
| Define unambiguous progress invariant and v1 migration | Spec 023; `khatma_plan.dart`, datasource, create/update/summary use cases | Decide inclusive/exclusive range semantics | Unit/property cases for pages 1/604, arbitrary start, same/back/jump, completion, legacy/malformed | No off-by-one; page 604 start is handled; migration preserves the furthest verified point | High: persisted user data |
| Introduce one daily assignment value (start/end/assigned/completed/remaining/date) derived from the same plan | Spec 023; domain entity/use case; no second store | Progress invariant | Serialization and local-day rollover tests | Same values feed hub, Today Plan, and widget summary | High: single-source-of-truth change |
| Route Khatmah Continue to assignment start | Spec 023; typed router + reader entry | Daily assignment | Routing + reader lifecycle tests | Continue always opens correct start; reading elsewhere does not displace plan resume | Medium |
| Make Khatmah-backed Today Plan completion derived/read-only | Spec 022/023 integration; Today Plan generator/BLoC/card | Daily assignment | BLoC/widget regression | Manual tap cannot contradict plan; completion changes after verified reader progress | Medium |

### Phase 1 — Complete core Flutter journey

| Requirement | Owner / expected files | Dependencies | Tests | Acceptance criteria | Rollout risk |
|---|---|---|---|---|---|
| Add creation review sheet | Spec 023 presentation; hub widgets + l10n | Correct plan preview use case | Arabic/English widget tests | Shows start, target 604, end date, pages/day; confirm/cancel; no write before confirm | Medium |
| Add start-boundary correction | Spec 023; creation request/use case | Preview | Unit + widget tests | Default last-read; user can choose beginning or valid page/Juz through existing Quran index data | Medium |
| Render daily progress and completed-day state in hub | Spec 023 presentation consuming Contract A | Daily assignment | Zero/partial/complete/stale-day widget tests | Assigned/completed/remaining agree with domain; one calm CTA | Low-medium |
| Complete recovery UX | Spec 023; recovery sheet + use cases | Correct plan math | Catch-up/extend unit and widget tests | Preview old/new daily load and end date; selection persists; no guilt language | Medium |
| Validate full-plan completion/restart | Spec 023 | Progress fix | Lifecycle/persistence/completion widget tests | Final page yields one distinct completion; restart survives app kill; start another is confirmed | Medium |

### Phase 2 — UX polish and Home integration

| Requirement | Owner / expected files | Dependencies | Tests | Acceptance criteria | Rollout risk |
|---|---|---|---|---|---|
| Compose one contextual Home Khatmah row in approved order | Spec 023 sole Home owner; `home_dashboard_body.dart` or approved Today section | Phase 1 state model | Home regression + RTL/text scale | Active target is visible within one scroll; no duplicate shortcut/card; completed/error/empty handled | Medium: Home hierarchy |
| Remove duplicate hub CTAs and clarify range hierarchy | Spec 023 presentation | Phase 1 | Widget/golden checks | One primary Continue; exact range above secondary plan metadata | Low |
| Accessibility/RTL/responsive pass | Spec 023 UI + l10n | Stable UI | AR/EN, 1.4 scale, narrow/wide, semantics, contrast | No overflow; 44dp targets; logical reading order; directional icons | Low |

### Phase 3 — Android widget completion

| Requirement | Owner / expected files | Dependencies | Tests | Acceptance criteria | Rollout risk |
|---|---|---|---|---|---|
| Reconcile current native provider with finalized Contract A/B | Spec 041; `islamic_widgets/**`, `widget/wird/**`, manifest/resources | Phases 0–1 | Dart serialization/bridge; Robolectric all states; resource compile | No plan math native; no-plan/active/day-complete/plan-complete/stale/malformed nonblank | Medium |
| Device/launcher validation | Spec 041 release task | Provider complete | Xiaomi/Redmi, Samsung, API 24/target API; reboot/resize/locale/process death | Persisted snapshot renders without app; deep link respects core flag | High OEM variance |
| Controlled activation | Spec 041 + launch config | Device validation | Flag/rollback tests | Default off; staged cohort enable; disabling hides picker and routes safely without data deletion | Low-medium |

### Phase 4 — Reminders, analytics, rollout, monitoring

| Requirement | Owner / expected files | Dependencies | Tests | Acceptance criteria | Rollout risk |
|---|---|---|---|---|---|
| Local daily Wird reminder configuration | New approved Spec 023 amendment; reuse notification scheduling | Core daily assignment | timezone/DST/reboot/permission/disable tests | User-controlled, local-only content, no guilt copy, exact destination, no duplicate notifications | High platform lifecycle |
| Privacy-minimized analytics | Spec 023/041 owned constants and emitters | Stable journeys | Parameter allow-list tests | No exact page, verse, raw plan id, or reading-history payload; action/result/freshness only | Low |
| Staged rollout and monitoring | Product/release | All gates | dashboards + kill-switch drill | 1%→10%→50%→100%; monitor creation success, assignment mismatch, persistence failure, deep-link failure, widget render failure; rollback preserves plan data | Medium |

## 9. Spec Kit reconciliation proposals

### Spec 023

1. Change status from broad “MVP shipped” language to **domain MVP implemented; core daily UX incomplete** until Phase 0/1 acceptance passes. **[Repository vs specification mismatch]**
2. Add a normative `KhatmaDailyAssignment` contract with explicit inclusive/exclusive page semantics and local-day behavior.
3. Add acceptance criteria for creation preview, plan-owned reader route, interrupted resume, daily completion, page-604 creation, and Today Plan consistency.
4. Keep minutes/listening/pause/adherence out of the release scope unless separately approved; the current amendment says documentation-only and schema v1 is pages-only.
5. Add reminder as a separate amendment, not hidden inside recovery or widget work.
6. Replace exact-page analytics requirements with privacy-safe buckets unless a documented product decision justifies precise local identifiers.

### Spec 041

1. Mark T-041A1-c/d/f according to current code only after native state/deep-link/resize tests and the core dependency are accepted; code presence alone is not completion.
2. Make Phase 0/1 of Spec 023 a hard release dependency for enabling `wird`.
3. Reconcile the amendment's unsupported `paused` state with finalized Contract A v1 (`none/active/completed` only); do not require native paused rendering in v1.
4. Add provider-activation rollback acceptance: disabling the component must not delete the last Khatmah plan or block core in-app access.
5. Add analytics allow-list and native render-failure diagnostics without religious-content fields.

### Spec 043 roadmap

1. Update the combined journey to name the assignment/range and verified daily completion as the Spec 023 exit criteria.
2. The roadmap currently says the MVP is shipped and recommends adherence/listening next; repository evidence shows daily correctness must precede those additive amendments.
3. Keep Spec 043's trust ownership unchanged: it supplies Quran integrity primitives but must not own Khatmah progress logic.

### Task-ledger proposal

Add new unchecked Spec 023 tasks before any 023-A1/A2 expansion:

- `T-023-P0-1` Normalize page invariant + migrate v1.
- `T-023-P0-2` Add daily assignment contract and tests.
- `T-023-P0-3` Route plan-owned assignment into the existing reader.
- `T-023-P0-4` Derive Today Plan completion from Khatmah progress.
- `T-023-P1-1` Creation preview and boundary correction.
- `T-023-P1-2` Core in-app daily progress/completion states.
- `T-023-P1-3` Recovery consequence preview.
- `T-023-P1-4` Home composition and accessibility matrix.

Do not mark the Android widget release tasks complete until these core dependencies and the OEM matrix pass.

## 10. Production-readiness verdict

**MeMuslim Al-Khatmah is currently _not ready_.**

Strengths already implemented:

1. Calm page-based plan math with duration presets, debt calculation, catch-up, and extension.
2. Local-first single-plan persistence with legacy optional-field tolerance and malformed-data fallback.
3. Reader write-back using the existing Quran reader rather than a duplicate reader/store.
4. Arabic/English localization and a brand-appropriate calm recovery/completion voice.
5. Versioned semantic/widget contracts and a dedicated default-off widget rollout control. The staged core default-on change should not ship before P0 gates pass.

Release blockers:

1. No unambiguous page-progress invariant.
2. No plan-owned daily range or reliable route to it.
3. Manual Today Plan completion can contradict Khatmah progress.
4. No core in-app daily-completion state.

The Android widget must remain optional and disabled by default until these are resolved. It cannot be used as evidence that the core experience is complete.

## 11. Remaining unknowns

- Competitor full-plan completion, missed-day recovery, pause/skip, edit/cancel, offline behavior, notification delivery, and data migration were not captured.
- Screenshots cannot prove whether competitor “Done Reading” validates actual reading.
- The black competitor frames are visually certain, but their root cause and reproducibility are unknown.
- No live MeMuslim device walkthrough was performed in this documentation-only audit; repository behavior was traced from code/tests.
- Current Android widget code has automated native coverage, but the required Xiaomi/Redmi/Samsung launcher matrix is not recorded as complete.

## 12. Recommended next implementation slice

**Phase 0: normalize page semantics and introduce a single `KhatmaDailyAssignment` contract, with migration and boundary tests.**

This is the smallest slice that unlocks trustworthy reader routing, in-app daily progress, Today Plan consistency, completion, and the Android widget without duplicating logic. Do not start reminders, adherence, listening progress, or additional widget polish before this contract is accepted.

## Validation record

- `dart analyze lib/features/smart_khatma lib/features/islamic_widgets/app/wird_progress_widget_sync_service.dart lib/features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart lib/features/islamic_widgets/presentation/adapters/wird_progress_widget_adapter.dart` → **FAIL (exit 2): 9 diagnostics**: 2 inference warnings and 7 info-level lints. The warnings are the untyped `GoRouteData.push` calls in `smart_khatma_home_entry_card.dart` and `smart_khatma_plan_actions.dart`. No compile error was reported, but a production-readiness audit cannot call analysis clean.
- `flutter test test/features/smart_khatma test/features/islamic_widgets/app/wird_progress_widget_sync_service_test.dart test/features/islamic_widgets/domain/wird_progress_widget_payload_test.dart test/features/islamic_widgets/presentation/wird_progress_widget_adapter_test.dart test/router/widget_deep_link_test.dart` → **PASS: 55 tests**.
- Screenshot inventory → **PASS: 28 rows for 28 files**.
- Android widget boundary → reviewed separately from core Flutter; widget progress is not counted as completion of Journeys A–F.
