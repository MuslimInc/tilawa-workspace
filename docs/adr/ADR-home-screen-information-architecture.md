# ADR-002: Home Screen Information Architecture

**Status:** Accepted  
**Date:** 2026-06-20  
**Deciders:** MeMuslim product & engineering  
**Product Decision Record:** [Home Screen Redesign](../product/home_screen_redesign.md)

---

## Context

The MeMuslim Home screen serves as the entry point for every session. At the time of this decision, it functions as a navigation menu — presenting shortcuts to features that already exist in the bottom navigation bar (Reciters tab, Qibla tab) alongside a five-prayer strip that duplicates the hero's prayer context, and a labelled "Discover" section that is structurally a launcher.

This creates measurable problems:

- **Multiple paths to the same destination** increase cognitive load without adding capability.
- **Home feels like a menu**, not a reason to visit daily.
- **New users** see a screen of shortcuts with no context about what to do first.
- **Returning users** see no progress, no streak, no completion state — no signal that the app knows them.
- The screen does not create a daily habit loop. There is no feature-specific reason to open MeMuslim today rather than yesterday.

Three architectural approaches were evaluated before reaching this decision.

---

## Decision

Adopt **Concept C — Hybrid** information architecture.

Home is structured as two named layers serving two simultaneous user states:

**TODAY layer** — always-valuable content requiring no user history:
- Daily Ayah card with bookmark and share interactions
- (Prayer context owned by the hero above; not repeated here)

**YOURS layer** — history-dependent content that degrades gracefully:
- Quran Progress Card (resume + streak + goal %; new user: begin CTA)
- Listening Row (conditional; hidden entirely if no listening history)
- Athkar Compact Card (three labelled rows, time-sorted, with completion state)

**FOOTER** — single utility without a bottom-nav tab:
- Tasbeeh (icon link; unemphasised)

All bottom-nav duplicates (Reciters shortcut, Qibla shortcut) are removed. The Prayer Day Strip is removed. The Discover section is removed. The layout toggle preference is removed.

Full information architecture and rationale: [Product Decision Record](../product/home_screen_redesign.md).

---

## Consequences

### Positive

- Home answers both "What should I continue?" and "What is new today?" simultaneously.
- New users encounter a full, useful screen on first launch — the Today layer requires no history.
- Returning users encounter progress, streaks, and completion state — signals that the app knows them.
- Removes three bottom-nav duplicates, eliminating the "menu" feeling.
- Daily Ayah creates a history-independent daily pull — a reason to open the app today specifically.
- Athkar Compact Card makes practice status visible without opening any sub-screen.
- Aligns with Quran-first strategy (Quran card is first Yours element) and Audio-first strategy (Listening row is second Yours element, above utility tools).

### Negative / Trade-offs

- **Discoverability decreases** for features that have been removed from Home. Users must learn that Reciters and Qibla live in the bottom navigation rather than Home. This is mitigated by the bottom navigation always being visible.
- **Implementation complexity is moderate** — the Athkar Compact Card requires reading completion state from the athkar domain layer; the Quran Progress Card requires streak and goal-progress queries; the Listening Row requires last-played state from the player.
- **The Yours layer is sparse on day one** — the Listening Row is hidden, the Quran card shows a generic CTA, and the Athkar card shows "Not started" for all three rows. This is acceptable because the Today layer is always full. But it means the screen is at its weakest during the onboarding window. A future onboarding flow should direct users to complete a first Quran session and first Athkar session, which fills the Yours layer immediately.
- **Row ordering in the Athkar card is time-dependent** — if the prayer time service is slow to initialise, the ordering may be incorrect at cold launch. The ordering logic must use the same local prayer calculation used by the hero (no network dependency).

---

## Alternatives Considered

### Concept A — Dashboard First

*"Your Islamic life, measured and resumed."*

**Architecture:** Hero → Daily Ayah → Quran Progress → Listening Row → Contextual Athkar Hero → Pinned Athkar List → Tools Footer.

**Philosophy:** Home is a personal command center. Every element shows progress or enables continuation. The screen is optimised for returning users with established history.

**Why it was not selected:**

Concept A is the right architecture for a product where the majority of users have significant history. It performs at 9/10 for returning users and 6/10 for new users. The new-user experience is the critical gap: a user with no Quran history, no listening history, and no completed Athkar encounters a screen of placeholder states. The Quran card shows a generic "Start your journey" CTA, the Listening row is invisible, and the Athkar section shows unlit completion indicators with nothing completed. The screen is functional but not compelling.

MeMuslim cannot afford to build Home only for users who already have history. The onboarding window is when the habit loop is established or abandoned. A screen that appears half-rendered during onboarding undermines activation.

Concept A's streak and goal mechanics are preserved as components within the Quran Progress Card in the selected Concept C architecture.

**Estimated retention impact vs current:** D7 +12–18%.

---

### Concept B — Quick Access First

*"Everything you need. One tap away."*

**Architecture:** Compact hero → Four primary feature tiles (Quran, Reciters, Athkar, Prayer Times) → Continue Strip (horizontal scroll, history-dependent) → Daily Ayah (compact, bottom) → Tools Footer.

**Philosophy:** Home is a precision instrument. It assumes the user has intent and optimises for reaching any major feature in one tap. Progress and streaks are secondary.

**Why it was not selected:**

Concept B solves the new-user problem cleanly — the four-tile grid renders immediately with static labels, no placeholder states, no broken promises. A new user sees a clear, understandable screen from the first launch.

However, it sacrifices the daily habit loop almost entirely. Without streak mechanics, completion state, or progress visibility as primary signals, the app becomes "open when I need it" rather than "open every day." The four-tile grid is structurally a launcher — it answers "Where can I go?" which is already answered by the bottom navigation. This directly violates the product principle that Home must not be a navigation menu.

Additionally, Concept B explicitly duplicates three bottom-nav destinations (Reciters, Prayer Times, and implicitly Qibla via Prayer Times proximity) in the primary action grid. The product principle states that duplication requires contextual value above what the tab provides. Four equal static tiles provide none.

Audio-first alignment is the weakest of the three concepts: Reciters is one of four equal tiles, given no visual priority over Prayer Times.

**Estimated retention impact vs current:** D7 +3–7%.

---

### Concept C — Hybrid (Selected)

*"A reason to come back. A reason to stay."*

See **Decision** above and [Product Decision Record](../product/home_screen_redesign.md) for full rationale.

**Estimated retention impact vs current:** D7 +15–22%.

---

## Comparison Summary

| Dimension | A — Dashboard | B — Quick Access | C — Hybrid (Selected) |
|-----------|--------------|-----------------|----------------------|
| New-user experience | 6/10 | 8/10 | **9/10** |
| Returning-user experience | **9/10** | 7/10 | **9/10** |
| Discoverability | Low | High | Medium |
| D7 retention estimate | +12–18% | +3–7% | **+15–22%** |
| Quran-first alignment | Strong | Moderate | **Strong** |
| Audio-first alignment | Moderate | Weak | **Strong** |
| KISS compliance | High | Medium | **Medium–High** |
| Risk of "menu" feeling | Low | **High** | Low |
| Works without history | Adequate | **Excellent** | **Excellent** |
