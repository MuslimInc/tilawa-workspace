# Home Screen Redesign — Product Decision Record

**Status:** Accepted  
**Date:** 2026-06-20  
**Deciders:** MeMuslim product & engineering  
**Related ADR:** [ADR-002: Home Screen Information Architecture](../adr/ADR-home-screen-information-architecture.md)  
**Implementation Plan:** [Home Screen Redesign Plan](../plans/home_screen_redesign_plan.md)  
**Acceptance Criteria:** [Home Screen Acceptance Criteria](../specs/home_screen_acceptance_criteria.md)

---

## The Central Question

> Why should a Muslim open MeMuslim every day?

The Home screen must answer this question. A Home screen that duplicates the bottom navigation does not answer it. A Home screen that shows progress, resumes journeys, surfaces daily context, and reflects the user's practice back to them does.

---

## Current Home — Problems

The Home screen at the time of this decision contains:

1. **A Reciters shortcut** — identical destination to the Reciters bottom-nav tab.
2. **A Qibla shortcut** — identical destination to the Qibla bottom-nav tab.
3. **A Prayer Day Strip** — five prayer pills duplicating the prayer information already dominant in the hero.
4. **A "Discover / Explore" section** — a navigation menu named as a feature section.
5. **A layout toggle (grid ↔ list)** — preference overhead with no user-value justification.
6. **A Daily Ayah block** — high-value content buried below duplicated navigation shortcuts, non-interactive.
7. **An Athkar section with no completion state** — looks identical whether the user has completed their practice or not.
8. **A Quran Resume Card with no streak or goal context** — resume exists but progress is invisible.

These problems produce a screen that:

- Feels like a **navigation menu**, not a destination.
- Creates **multiple paths to the same feature** (Home shortcut + bottom-nav tab).
- Increases **cognitive load** by asking the user to choose between redundant entry points.
- Provides **weak daily pull** — no reason to open specifically today versus yesterday.
- **Penalises new users** — progress-focused elements are empty, leaving a half-rendered screen.

---

## Product Goals

1. Home must provide value to the user, not route them elsewhere.
2. Home must answer: *What should I do right now?* and *What is new today?*
3. Home must be valuable within 3 seconds of launch, without tapping into another screen.
4. Home must serve both first-time users (no history) and returning users (rich history) without showing each the other's version.
5. Home must create a daily habit loop — a reason to return tomorrow that is specific to tomorrow.
6. Home must be KISS-compliant: no feature on Home unless it adds contextual value beyond the existing bottom-nav destination.

---

## Four Primary User Goals

These are the four actions a MeMuslim user most frequently intends when opening the app. Home must make each frictionless.

| Priority | Goal | Target |
|----------|------|--------|
| 1 | Know the next prayer immediately | Visible in hero, zero taps, zero scroll |
| 2 | Resume Quran reading quickly | One scroll + one tap, Quran card at or near first viewport |
| 3 | Resume Quran listening quickly | One scroll + one tap, Listening row below Quran card |
| 4 | Access Athkar quickly | Athkar card visible in Yours layer, status visible before tapping |

No other feature justifies permanent placement on Home unless it directly serves one of these goals or the "What is new today?" question.

---

## Decisions and Rationale

### Why duplicate bottom-nav shortcuts were removed

The bottom navigation is always visible. Every destination it contains is one tap away from any screen. A Home shortcut to the same destination adds zero taps of savings and adds one redundant entry point, increasing cognitive load. The only justification for a Home version of a bottom-nav feature is **contextual value that the tab itself cannot provide** — e.g., "Resume at page 45" vs "Open Quran".

When a Home element provides only navigation and no context, progress, or personalisation, it is removed.

### Why Qibla was removed from Home

Qibla has a dedicated bottom-nav tab. It has no progress state, no resume state, no daily variation, and no personalisation. It is identical on day one and day one thousand.

The contextual argument — that a user checking the prayer countdown might want Qibla — fails under scrutiny: a user who needs Qibla before prayer taps the Qibla bottom-nav tab, not a Home shortcut. The shortcut saves zero taps over the tab.

Qibla remains accessible via the bottom navigation. Its removal from Home reduces cognitive load without removing any capability.

### Why the Reciters shortcut was removed

Reciters has a dedicated bottom-nav tab. A generic "Browse Reciters" shortcut on Home is a navigation duplicate — it routes to the same screen as the tab, with no additional context.

The correct version of audio on Home is **Continue Listening** (see below), which provides context, personalisation, and a specific action. A browse shortcut provides none of these.

### Why Continue Listening replaces the Reciters shortcut

"Browse Reciters" answers: *Where can I go to find a reciter?*  
"Continue · Sheikh Mishary · Al-Baqarah" answers: *What was I listening to, and can I resume now?*

The second framing is a resumable action with zero decision overhead. The user sees their exact position and taps once to resume. This is audio-first product strategy — audio is elevated from a discovery destination to a resumable personal journey.

The Continue Listening row is **conditional**: it is invisible when no listening history exists. It never shows an empty state or a broken promise. A new user sees a shorter screen; a returning user sees their history.

### Why the Prayer Day Strip was removed

The hero card already owns the prayer context — it shows the next prayer's name, time, and countdown, updated in real time. A five-prayer strip below the hero duplicates this context with more visual weight but less focus.

The prayer strip answers "What are all five prayer times?" — a question that belongs on the Prayer Times screen, not on Home. The hero already answers "What is my next prayer?" — the question Home users actually have.

### Why the Athkar dot row was rejected

The Athkar dot row (three unlabelled coloured dots representing Morning / Evening / Sleep completion) was proposed in Concept C as a compact, glanceable completion indicator.

It was rejected because it fails the KISS test: a first-time user cannot derive the correct mental model within three seconds without onboarding. The dots require learning — which dot is which category, what the colours mean, that tapping opens a full screen, that they reset at midnight. A custom interaction pattern that requires a tooltip to explain is not KISS-compliant.

The same information — three Athkar categories, each with a completion state, each tappable — is fully communicable with a three-row labelled card. No learning required.

### Why the Athkar Compact Card was selected

```
┌──────────────────────────────────────────────────────┐
│  ☀  Morning Athkar    ✓ Done              →          │
│  ──────────────────────────────────────────────────  │
│  🌙  Evening Athkar   34 remaining        →          │
│  ──────────────────────────────────────────────────  │
│  ★   Sleep Athkar     Not started         →          │
└──────────────────────────────────────────────────────┘
```

- Icon + name: immediately identifies the category.
- Status text: completion state visible without tapping.
- Chevron: signals that tapping opens more.
- Row ordering: time-contextual (most urgent category surfaces first).

Zero learning cost. Identical information to the dot row. KISS-compliant.

The row ordering must be dynamic: Morning Athkar surfaces first at Fajr, Evening Athkar at Maghrib, Sleep Athkar after Isha. This ordering logic already exists in the contextual Athkar cubit and is reused here.

### Why the Daily Ayah was promoted

The Daily Ayah already existed in the previous Home screen. It was buried below duplicated navigation shortcuts, non-interactive, and positioned as decoration rather than content.

It was promoted to the top of the "Today" layer because:

1. It requires **no user history** — it is valuable on day one and day one thousand.
2. It changes **every day** — it is a specific reason to open the app today rather than yesterday.
3. With a bookmark and share action, it becomes a **daily micro-action** rather than passive content.
4. It answers the question "What is new today?" that resume-focused content cannot answer.

A user who has completed all their goals for the day still has a reason to open the app — today's Ayah is different from yesterday's.

### Why Home is a dashboard, not a navigation menu

A navigation menu answers: *Where can I go?*  
A dashboard answers: *What is happening, how am I doing, and what should I do next?*

The bottom navigation already answers "Where can I go?" for every major destination. Duplicating that answer on Home creates a screen that competes with its own navigation system.

A dashboard adds value that navigation cannot: progress, context, personalisation, and daily variation. These are the elements that make a screen worth visiting daily, not merely capable of reaching weekly.

---

## Final Information Architecture

```
HOME SCREEN
│
├── HERO  (collapsing, prayer-period ambient gradient)
│   ├── Greeting + Hijri date                         [ambient, no history needed]
│   ├── Next Prayer: name · time · countdown          [primary user goal 1]
│   └── Collapsed toolbar summary on scroll
│
├── ─── TODAY ─── (always-valuable, no history required)
│   └── Daily Ayah Card
│       ├── Arabic text + translation
│       ├── Surah + verse reference
│       └── Bookmark action · Share action
│
├── ─── YOURS ─── (history-dependent, degrades gracefully)
│   ├── Quran Progress Card                           [primary user goal 2]
│   │   ├── Returning user: Surah · Page · streak · % of today's goal
│   │   ├── Plan active: + Khatma plan label
│   │   └── New user: "Begin your Quran journey →"
│   │
│   ├── Listening Row  (conditional — hidden if no history)  [primary user goal 3]
│   │   └── "Continue · [Reciter Name] · [Surah Name] →"
│   │
│   └── Athkar Compact Card                           [primary user goal 4]
│       ├── [Icon] Morning Athkar   [status]  →
│       ├── [Icon] Evening Athkar  [status]  →
│       └── [Icon] Sleep Athkar    [status]  →
│           (row order: time-contextual, most urgent first)
│
└── ─── FOOTER ───
    └── Tasbeeh  (single icon link, no section header)
        [Only tool without a bottom-nav tab; present but unemphasised]
```

---

## What Was Removed and Why (Summary Table)

| Removed Element | Reason |
|----------------|--------|
| Reciters shortcut | Bottom-nav duplicate; replaced by Continue Listening |
| Qibla shortcut | Bottom-nav duplicate; no progress/resume state |
| Prayer Day Strip | Duplicates hero prayer context; belongs on Prayer Times screen |
| Discover / Explore section | Navigation menu disguised as a feature section |
| Grid ↔ list layout toggle | Preference overhead with no user-value justification |
| Athkar dot row | Custom pattern requiring onboarding; replaced by labelled card |

---

## Relationship to MeMuslim Product Strategy

**Quran-first:** The Quran Progress Card is the first personalised element on the screen, immediately below the Today anchor. It carries more visual weight than any other Yours element.

**Audio-first:** The Listening Row is the second element in the Yours layer. Audio is elevated above utility tools (Tasbeeh) — it is a resumable personal journey, not a browse shortcut.
