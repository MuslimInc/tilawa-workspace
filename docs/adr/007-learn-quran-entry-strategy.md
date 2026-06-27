# ADR-007: Learn Quran Entry Strategy inside MeMuslim

**Status:** Proposed  
**Date:** 2026-06-27  
**Deciders:** Product Strategy, UX, Growth PM, Flutter Architecture, Design System  
**Context tags:** navigation, IA, retention, worship-first, reversibility

---

## Executive summary

**The launch-time choice is a bad idea. Do not build it.** A "Continue to
MeMuslim vs Go to Learn Quran" gate every launch (or even once) taxes 100% of
users to serve a feature that today converts a small single-digit fraction of
them, fractures a single worship habit into two competing front doors, and
creates a second app-inside-an-app that has been explicitly ruled out.

**What to do instead:** keep one Home, one shell, one habit. Make Learn Quran a
**first-class but context-driven Home priority** — the card already shipped
(`HomeFeaturedTutorCard`) is the right primitive; the missing piece is
**state-awareness**, not a mode switch. When a user has a session in the next
N hours, an incomplete booking, or assigned revision, Home promotes a
**Next Session / Continue Learning** card to the top zone. When they don't,
Learn Quran sits calmly as a featured card. Capture a one-time, **non-blocking**
interest signal during normal use (not a gate) to bias ordering. Defer the
bottom-nav tab until analytics prove sustained engagement.

**Why this is the honest answer:** the current architecture already encodes the
correct instinct — sessions live outside the shell as a deep funnel, and the
entry is a Home card, not a tab. The risk in the proposal isn't the feature
ambition; it's the **entry mechanism**. A mode-fork is the single
highest-regret, hardest-to-reverse decision on the table (duplicated nav stacks,
split analytics, ambiguous back behavior, two onboarding paths). Personalized
Home priority gets ~90% of the "Learn Quran feels core" benefit with ~10% of the
risk and is fully reversible.

**Bottom line:** Learn Quran can become a core pillar **without its own mode**.
Promote by context, not by a fork.

---

## Current architecture (audited baseline)

- **Bottom nav (phone):** `[Home]` · `[Quran ▸ push to /quran-index]` ·
  `[Reciters tab]` · `[Settings tab]`. No Quran Sessions tab.
  (`apps/tilawa/lib/screens/app_shell_nav_destinations.dart`,
  `main_tab_viewport.dart` — 3 lazy tabs.)
- **Home body order** (`home_dashboard_body.dart`): Prayer hero → Primary
  actions (Reader, Athkar) → Quick tools (Reciters, Qibla, Tasbeeh) →
  **Featured Tutor card (zone 4, flag-gated)** → Today Plan → More → Continue →
  Inspiration.
- **Learn Quran entry today:** `HomeFeaturedTutorCard` (gated by
  `quranSessionsFeatureConfig().quranSessionsEnabled`) → `openHomeQuranSessions`
  → profile gate → `/sessions`; ghost "My Sessions" → `/sessions/my`. Plus a
  Settings teacher funnel and notification deep links.
- **Sessions route tree:** `/sessions/*` lives **outside** `TypedShellRoute`
  (sibling tree, full-screen pushed funnel), guarded by
  `quranSessionsFeatureRedirect` + `quranSessionsSessionRedirect`.
- **Notifications/deep links:** one `DeepLinkResolver` handles `quran_session` /
  `incoming_quran_session_call` → session detail or My Sessions; cold start lands
  Home first, then pushes target.
- **Flags / posture:** `quranSessionsEnabled` on; **booking OFF** and
  **paid wallet OFF** by default in prod (`phase_3_marketplace_flags.md`).
  Correct restraint.

---

## 1. Product strategy diagnosis

| Question | Answer | Reasoning |
|---|---|---|
| Separate **mode**? | **No.** | A mode forks identity, navigation, analytics, and habit. The moat is the *integrated* daily worship loop; a mode amputates Learn Quran from the prayer/Quran/athkar context that makes it trustworthy and sticky. |
| Core feature **inside main Home**? | **Yes — it already is** (zone 4 card). Elevate its *intelligence*, not its isolation. | One Home = one habit. |
| **Personalized Home priority**? | **Yes — this is the recommendation.** | Promote to the top zone *only when the user has live learning state*; otherwise stay calm in zone 4. |
| Own **entry point but not a mode**? | **Yes — `/sessions/*` already is that.** | A deep pushed funnel is correct. Entry point ≠ mode. |
| **Launch-time choice**? | **No — strong no.** | A recurring, unskippable-feeling tax before any value; harms the worship-first promise. |
| Long-term **risks of splitting**? | High and compounding (see §9). | Duplicated Home logic, ambiguous back stack, split metrics, doubled notification routing, theming drift, permanent "which app am I in?" cost. |

**Critical pushback:** "Learn Quran may become a core pillar" and "users should
choose a mode at launch" are contradictory. Core pillars are not behind a fork —
prayer times isn't behind a "do you want prayer times?" gate. A pillar earns
prominence by being *present and contextual*, not by demanding a routing
decision. Asking the user to pick signals Learn Quran is a *separate
destination*, not a pillar — undercutting the exact positioning intended.

---

## 2. User-intent analysis

| User type | Should see first | Launch choice: help/annoy? | Best path to Learn Quran | Friction risk |
|---|---|---|---|---|
| Opens for **prayer times** | Prayer hero (unchanged) | **Annoy** — screen before a 5s glance | Calm zone-4 card | High (majority intent) |
| Opens for **Quran read/listen** | Primary actions, continue-listening | **Annoy** | Card; later reader↔session links | High |
| Opens for **Athkar** | Quick tools → Athkar | **Annoy** | Card | Med-high |
| **Just booked** | **Next Session card promoted to top** | **Annoy** — intent already declared | Already in funnel; Home reflects it | A gate here is insulting |
| **Upcoming session soon** | **Next Session card at top**, prominent, Join when live | **Worse than nothing** — hides the relevant thing | Home auto-promotes + pre-session push | Gate adds taps to the one needed action |
| **Parent/guardian** | Guardian/child summary card when state exists | **Annoy + confusing** (whose mode?) | Card → `/sessions/guardian/*` | Mode ambiguity (parent vs learner) |
| **Interested, not booked** | Featured card + occasional teacher nudge | **Mild help at best, net annoy** | One-time interest tap (not a gate) → list → book | Recurring gate trains dismissal |
| **Not interested** | Nothing extra; calm, ignorable card | **Pure annoy** | Don't push; respect signal | Gate erodes trust |

**Pattern:** every persona is neutral or harmed by a launch choice. The two who
most benefit from prominence (booked / upcoming-session) are best served by
**automatic state-driven promotion**, which a generic two-button gate actively
obscures. This alone kills Option A.

---

## 3. UX / IA options — decision matrix

Scoring: ✅ strong / ⚠️ mixed / ❌ weak. "Long-term fit" = worship-first fit +
reversibility.

| Option | UX clarity | Friction | Discoverability | Retention | Confusion risk | Eng complexity | Long-term fit | Recommendation |
|---|---|---|---|---|---|---|---|---|
| **A — Launch choice every time** | ❌ | ❌ recurring | ✅ unmissable | ⚠️ novelty decay | ❌ "which app?" | ❌ dup stacks | ❌ contradicts pillar | **Reject** |
| **B — One-time onboarding preference** | ⚠️ | ⚠️ one-time | ⚠️ phrasing-dependent | ⚠️ weak unless drives perso | ⚠️ false "two apps" model | ⚠️ branch + stored pref | ⚠️ OK as *signal* only | **Partial — soft signal only** |
| **C — Personalized Home priority** | ✅ | ✅ zero added | ✅ contextual | ✅✅ feeds loop | ✅ one Home | ⚠️ Home state logic | ✅✅ reversible, native | **Adopt — primary** |
| **D — Focus Mode toggle** | ⚠️ | ✅ opt-in | ❌ buried | ⚠️ niche | ⚠️ 2nd layout | ❌ 2nd Home variant | ⚠️ premature | **Defer** |
| **E — Dedicated bottom tab** | ✅ | ✅ | ✅✅ persistent | ✅ if usage real | ⚠️ looks commercial | ⚠️ shell + tab budget | ✅ *once earned* | **Defer (metrics-gated)** |
| **F — Home card only (today)** | ✅ | ✅ | ⚠️ static | ⚠️ flat | ✅ | ✅ shipped | ✅ good floor | **Keep as baseline** |

**Verdict: C (primary) on top of F (baseline), with B as a non-blocking signal,
E held in reserve. Reject A and D as defaults.**

---

## 4. Recommendation

> **Adopt personalized Home priority (Option C) layered on the existing featured
> card (Option F). Do NOT build a launch-time choice. Do NOT build a separate
> mode. Capture a one-time, non-blocking learning-interest signal (soft Option B)
> to bias ordering. Hold the dedicated bottom-nav tab (Option E) in reserve,
> gated on analytics.**

**Model in one sentence:** *One Home that promotes Learn Quran to the top when
the user has live learning state, and keeps it as a calm featured card
otherwise — never a fork, never a gate.*

Reasoning:
- Serves the two high-value personas better than a gate, by surfacing the next
  action automatically.
- Costs the worship-first majority **zero** added friction (hard constraint).
- **Fully reversible**; ships incrementally on existing primitives.
- Keeps positioning as "a worship app with serious Quran learning inside," not
  "a tutoring marketplace with prayer times attached."

---

## 5. Long-term vision — core pillar without an app-in-an-app

Thesis: **Learn Quran becomes core by weaving into the existing worship loop,
not by standing beside it.**

- **Home:** one intelligent top-zone slot rendering exactly one of — Next Session
  (countdown/Join), Continue Learning (assigned revision), Pending Booking
  (resume), or (else) the calm featured card. One slot, four states; never two
  competing heroes.
- **My Sessions:** reachable from Home (ghost button exists) and the promoted
  card; surfaced *when sessions exist*. Not a tab.
- **Next-session widget:** time-boxed; appears as the session approaches, Join
  when live, disappears after.
- **Quran reader integration (killer native bridge):** assigned ayat →
  "Open in reader" deep link into `/quran-reader/:surah`; a quiet "assigned by
  your teacher" ribbon in the reader when relevant. The existing reader becomes
  the homework surface — no new app.
- **Homework/revision:** post-session, the Continue-Learning state points at
  assigned ayat + the reader.
- **Athkar/prayer context:** schedule around prayer times; never overlap a live
  call with a prayer reminder. Context = trust.
- **Notifications:** reuse the existing FCM/`DeepLinkResolver` pipeline. One
  routing brain.
- **Teacher recommendations:** periodic, low-frequency surface for
  interested-not-booked users — earned, not pushed.
- **Parent/guardian:** a distinct *card state* (not a mode) when a child profile
  exists; routes to `/sessions/guardian/*`.
- **Progress tracking:** lightweight streak/goal in the same place as worship
  streaks — one progress language.

**Principle that keeps it native:** Learn Quran should *borrow* MeMuslim's
surfaces (Home slot, reader, notifications, settings), not *clone* them. The day
it has its own home, its own notifications brain, and its own progress system, it
has become the app-in-an-app being avoided.

---

## 6. Navigation strategy

| Question | Recommendation |
|---|---|
| Learn Quran in bottom nav? | **Not yet.** Tab budget is tight; a tab for a booking-OFF feature signals "marketplace." Earn it with metrics (§10). |
| Home priority card? | **Yes — the spine.** One intelligent top slot + calm zone-4 card. |
| My Sessions from Home? | **Yes, conditionally** — surface when sessions exist. |
| Upcoming session above/below prayer card? | **Below the prayer hero, above primary actions, only when imminent/live.** Prayer hero stays the anchor; never displaced. |
| Return to normal app after session? | **Yes** — pushed full-screen flow pops back to Home. No mode to "exit." |
| Notification deep links? | Keep current: session → detail/My Sessions; incoming call → full-screen intent → detail. One resolver. |
| Cold-start routing? | Keep current: **Home first, then push target.** A mode would force "which home?" — another reason not to fork. |
| Logged-in entry? | Always land on **Home**; state-driven promotion does the rest. Guards on `/sessions/*` unchanged. |

**North star:** bottom nav + Home are the stable spine; Learn Quran is
contextual content within that spine plus a deep pushed funnel. No new persistent
structure until usage demands it.

---

## 7. Retention & habit loop (Hook model)

| Stage | Learn Quran instances | Where it lives (no launch choice) |
|---|---|---|
| **Trigger** | Prayer-time open (incidental), upcoming-session push, revision reminder, daily goal, tutor feedback | External pushes; internal = the promoted Home slot already in the daily scroll. |
| **Action** | Open → see Next Session at top → Join / revise assigned ayat (in reader) / book next | Single top slot; one tap to the right action. No decision screen. |
| **Reward** | Progress, streak, teacher feedback, recitation improvement, spiritual confidence | Surfaced in the same card post-session. |
| **Investment** | Saved teacher, schedule, goal, child profile, reviews, progress history | Each investment makes the next Home promotion smarter — loop compounds. |

The promoted slot **is** the loop's action surface: a returning learner opens for
prayer (existing trigger) and immediately sees their next session/revision — the
worship habit carries the learning habit. A gate breaks this by inserting a
decision before the trigger pays off. Habit design *reduces* steps between
trigger and reward; a gate adds one.

---

## 8. Monetization & trust impact

- **Mode = "more serious"?** Marginal, at high cost. "Serious via isolation"
  reads as "this is the commercial part" — the marketplace-first perception to
  avoid.
- **Makes the app feel commercial?** **Yes** — a fork/tab for a paid feature is
  the strongest "now selling something" signal. Calm integration reads as
  service; separation reads as storefront.
- **Reduce trust?** Real risk; worship-app trust is fragile.
- **Separated or integrated pricing?** **Calmly integrated.** Price/paid signals
  belong inside the funnel (teacher chips, booking summary), not on Home or nav.
  Home shows *learning*, not *pricing*.
- **Avoid marketplace-first feel:** lead with the spiritual outcome, keep paid
  surfaces deep in the funnel (current booking-OFF/wallet-OFF defaults already do
  this), never price on Home or a tab.

Current posture (experimental badge, sandbox-only payments, booking off in prod)
is correct restraint. A launch fork would loudly contradict it. Keep the quiet.

---

## 9. Engineering / architecture impact

**Recommended path (Option C) — additive, low-risk:**
- **Routing/shell:** unchanged. The slot is a Home widget reading a small cubit.
- **State restoration:** unchanged — one shell, one tab model.
- **Deep links/notifications:** unchanged — one resolver handles session payloads
  + cold start.
- **Auth/profile gate:** unchanged — existing redirects stay.
- **Feature flags:** reuse `quranSessionsEnabled`; add at most one rollout flag
  for the promoted slot.
- **Design system:** one card primitive (extend `HomeFeaturedTutorCard` states);
  tokens exist.
- **Analytics:** one Home, one funnel = clean attribution.
- **Testing:** widget tests for the 4 slot states + Home ordering; no
  nav-stack test explosion.

**If you fork (Option A/D) — risks invited:** duplicated nav stacks and ambiguous
"back from Learn Quran goes where?"; duplicated Home logic that drifts;
unpredictable hardware-back/swipe across the fork; theming divergence; cold-start
resolver must decide *which mode* (more branches); retention/DAU split across
modes; an onboarding branch in the most fragile flow.

**Verdict:** Option C is purely additive to a deliberately clean shell; a fork is
a structural change with a long maintenance tail and a hard reversal cost. The
cheap, reversible option is also the better-UX option — take the alignment.

---

## 10. Analytics plan — instrument before promoting

**Events (baseline):** `home_learn_quran_card_viewed`,
`home_learn_quran_card_tapped`, `learn_quran_onboarding_started`,
`teacher_list_viewed`, `teacher_profile_viewed`, `booking_started`,
`booking_completed`, `my_sessions_opened`, `session_joined`, `session_completed`,
`review_submitted`, `next_session_widget_tapped`.

**Add (to evaluate this ADR):** `home_next_session_card_viewed`/`_tapped`,
`home_learn_quran_card_dismissed` (or scroll-past proxy),
`learning_interest_signal_set` (interested/not), `revision_card_viewed`/
`_opened_in_reader`.

**Metrics (decision-grade):**

| Metric | Definition | Use |
|---|---|---|
| Card CTR | tapped / viewed | Real demand |
| Tutor-profile conversion | profile_viewed / list_viewed | Funnel health |
| Booking conversion | booking_completed / booking_started | Funnel health |
| Session join rate | joined / scheduled | Loop reliability |
| **Repeat booking rate** | users with ≥2 bookings / first-time bookers | **The pillar test** |
| 7-day retention (learners vs all) | standard | Does it lift retention? |
| Session completion rate | completed / joined | Quality |
| Feature-driven opens | opens attributed to session/revision push | Self-generating triggers? |

**Gate for Option E (tab):** promote only when repeat-booking + feature-driven
opens show Learn Quran *generates its own habit*. Until then, a tab is vanity.

**Experiments (ordered):** (1) promoted-slot placement; (2) one-time interest
prompt (soft, non-blocking) vs none — the ethical version of "ask once," without
gating entry; (3) My Sessions shortcut visibility logic; (4) calm featured card
copy/position; (5) later, tab vs no-tab holdout if thresholds met.

**Do NOT A/B test the launch-time choice** — it fails the worship-first
constraint on first principles; testing it normalizes the wrong mental model.

---

## 11. Suggested UX patterns (replacing the launch choice)

| Pattern | Where | When appears | When disappears | Why better than a gate |
|---|---|---|---|---|
| One-time interest setup | In normal use / quiet Settings toggle, never blocking | Once | After answered; biases ordering | Captures intent without taxing every open |
| Home personalization (spine) | Top zone, single intelligent slot | When learning state exists | Falls back to calm card | Shows the right action automatically |
| Next-session widget | Top slot, below prayer hero | As session approaches; Join when live | Auto-hides after end | Time-boxed beats permanent prominence |
| Floating near-session reminder | Lightweight, time-boxed | ~N min before live | After join/end | Surfaces the one urgent action precisely |
| My Sessions shortcut | Home ghost button (exists) | When sessions exist | Hidden when none | One tap; no fork |
| Focus toggle (Option D, deferred) | Settings | Opt-in | User-controlled | Serves power users without a 2nd Home for all |
| Continue-learning module | Top slot state | Revision pending | When done | Drives homework→reader loop |
| Teacher recommendation | Periodic Home section | Interested-not-booked, sparingly | After booking/dismiss | Earned discovery |
| Post-session revision card | Top slot, after a session | Post-completion window | After opened/aged out | Closes loop into reader |

Common thread: every pattern is contextual and self-retiring; a launch gate is
acontextual and permanent. Good worship UX is calm and appears only when it has
something to say.

---

## Decision

Adopt **personalized Home priority**: a single state-aware top-zone Home slot
that promotes Learn Quran (Next Session / Continue Learning / Pending Booking)
**only when relevant user state exists**, falling back to the existing calm
featured card otherwise. Capture a **one-time, non-blocking** learning-interest
signal to bias ordering. Keep one shell, one Home, one notification resolver, and
the existing `/sessions/*` deep funnel. **Reject** the launch-time choice and the
separate mode. **Defer** a dedicated bottom-nav tab, gated on repeat-booking and
feature-driven-open metrics.

### Recommended IA

```
Bottom nav (stable spine):  [Home]  [Quran ▸push]  [Reciters]  [Settings]
Home (single habit surface):
  Prayer Hero (anchor — never displaced)
  ▸ Learning Slot  ← Next Session | Continue Learning | Pending Booking | (else) calm Featured card
  Primary actions (Reader, Athkar)
  Quick tools
  More / Inspiration
Deep funnel (pushed, outside shell, unchanged):  /sessions/* (browse→book→detail→call)
Notifications → one DeepLinkResolver → session detail / My Sessions / incoming call
[Reserved, metrics-gated]  promote Learning to a 5th tab only on proven repeat use
```

### Alternatives considered

- **A — Launch choice every time:** rejected. Recurring friction tax;
  contradicts worship-first; forks the mental model; obscures the relevant action
  for booked users; high nav/analytics cost.
- **B — One-time onboarding fork question:** rejected as a *gate*; adopted only
  as a *soft, non-blocking interest signal*.
- **D — Separate Focus Mode:** deferred to an optional Settings toggle; not a
  default.
- **E — Dedicated bottom tab:** deferred; revisit only on proven, self-generating
  engagement.
- **F — Static Home card only:** retained as baseline/fallback; insufficient
  alone because it doesn't react to user state.

## Consequences

**Positive:** zero added friction for worship-first users; highest-value learner
states get automatic, precise surfacing; purely additive to a clean shell; fully
reversible; clean single-funnel analytics; positioning stays "worship app with
serious learning."

**Negative / costs:** requires Home-state logic and instrumentation; must enforce
strict promotion rules so the prayer hero is never displaced; defers the
"big visible" tab some stakeholders may want.

**Guardrails:** prayer hero remains the Home anchor; max one promoted learning
card; promotion strictly tied to live session lifecycle; no price/paid surfaces
on Home or nav; one notification resolver; ship behind a rollout flag with
per-state widget tests.

**Reversal cost:** low. The promoted slot is an additive Home widget reading a
small cubit; removing or re-scoping it touches one surface, not the shell,
routing, or notification pipeline.

---

## MVP implementation (scope only — no code in this ADR)

- Extend `HomeFeaturedTutorCard` into a small state machine driven by a
  lightweight Home-learning cubit: states `nextSession(imminent/live)`,
  `continueLearning(revision pending)`, `pendingBooking`, `none → calm card`.
- Place the promoted state in the top scrollable zone (below prayer hero); calm
  card stays in zone 4 when state = none.
- Wire "Open assigned ayat" to the existing `/quran-reader/:surah` deep link.
- Reuse existing notification routing; add the time-boxed near-session reminder.
- Instrument the §10 events from day one.
- Keep all paid/booking flags at current prod defaults.
- Ship behind one rollout flag; verify with widget tests per slot state + Home
  ordering.

## Risks

- Top-slot over-promotion crowding the worship anchor → prayer hero first, one
  promoted card max.
- Personalization staleness (passed session still shown) → tie strictly to
  session lifecycle.
- Interest-signal drifting toward a gate → keep non-blocking, dismissible,
  one-time.
- Tab pressure before metrics → hold the analytics gate.

## Open questions

- Realistic N (hours) for "imminent session" promotion?
- Does the guardian/child case need its own slot state at MVP, or defer?
- Is assigned-revision data available to power Continue-Learning, or later phase?
- What repeat-booking / retention threshold counts as "pillar-grade" to revisit
  the tab?

## Next step

Ship the §10 analytics instrumentation on the *current* Home card first (no UX
change), gather 2–4 weeks of baseline (CTR, booking conversion, repeat booking),
then implement the state-aware top slot (MVP). Decide the tab question only after
that data exists.

---

## References

- [ADR-001 Quran player root overlay route](001-quran-player-root-overlay-route.md)
- [ADR-002 Quran Sessions backend-agnostic architecture](002-quran-sessions-backend-agnostic-architecture.md)
- [ADR-004 Teacher application intake vs marketplace activation](004-teacher-application-intake-vs-marketplace-activation.md)
- [ADR-006 Scheduling policy layer](006-scheduling-policy-layer.md)
- [ADR Home screen information architecture](ADR-home-screen-information-architecture.md)
- [Phase 3 marketplace flags](../quran_sessions/phase_3_marketplace_flags.md)
