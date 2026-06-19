---
name: tilawa-apply-ux-principles
description: >-
  Apply Tilawa UX principles when designing or refactoring screens, flows, and
  information architecture — worship-context placement, calm daily rituals,
  progressive disclosure, empty/loading/error states, accessibility, and copy
  voice. Use when planning home dashboard sections, quick-access shortcuts,
  pickers, onboarding, feature discovery, or any user-facing flow in
  apps/tilawa. Complements flutter-apply-tilawa-theming (visual tokens) and
  tilawa-apply-ui-principles (layout composition).
---

# Tilawa UX Principles

Apply when **deciding what the user sees, in what order, and how they complete a
task** — before or while implementing Flutter UI.

## Canonical references (read when unsure)

1. [`DESIGN.md`](../../../DESIGN.md) — placement policies (§9 Support, §11 Tours)
2. [`docs/tilawa_brand.md`](../../../docs/tilawa_brand.md) — voice, reverence, worship surfaces
3. [`CLAUDE.md`](../../../CLAUDE.md) — architecture boundaries (no `BuildContext` in domain)

Companion skills: `tilawa-apply-ui-principles`, `flutter-apply-tilawa-theming`,
`flutter-build-responsive-layout`.

## How to use

**Design mode:** Before coding, state user goal, primary path, and what is
deferred. Pick the simplest flow that matches existing Tilawa patterns.

**Implementation mode:** While building, run the [UX checklist](references/ux-checklist.md)
before handoff.

**Review mode:** Walk [references/ux-checklist.md](references/ux-checklist.md) and
report findings with screen/flow evidence — do not rewrite unless asked.

## Core UX tenets (Tilawa)

| Tenet | In practice |
|-------|-------------|
| **Content-first** | Worship and reading surfaces stay uninterrupted; chrome recedes. |
| **Daily ritual** | High-frequency actions (prayer, athkar, Quran resume) belong on Home or one tap away — not buried in Settings. |
| **Calm density** | Fewer choices per screen; progressive disclosure for customization (edit sheet, not 12 toggles on Home). |
| **One primary action** | Each screen/sheet has one obvious next step; secondary actions are text buttons or overflow. |
| **Gentle failure** | Errors suggest the next step; no error codes in user-facing copy. |
| **Respectful placement** | No monetization, tours, or marketing on active worship surfaces (see [references/placement-policy.md](references/placement-policy.md)). |

## Workflow: new or refactored screen

```
Task progress:
- [ ] 1. Name the user goal in one sentence
- [ ] 2. Map primary path (≤3 taps from shell)
- [ ] 3. Decide placement tier (Home hero / Home body / tab / pushed route)
- [ ] 4. Define empty, loading, error, and success states
- [ ] 5. Define customization entry (if user-pinned / favorites)
- [ ] 6. Add l10n keys (en + ar); no hard-coded chrome strings
- [ ] 7. Run UX checklist + widget test for primary path
```

### Step 1 — User goal

Ask: *What is the user doing in the next 30 seconds?*

Examples:
- Home athkar shortcuts → open a chosen category to count dhikr
- Reciters → find and play a recitation
- Settings → change preference once, leave

Avoid feature-list thinking ("expose all athkar APIs on Home").

### Step 2 — Frequency-based placement

| Frequency | Placement |
|-----------|-----------|
| Several times daily | Home body (card/row), hero metric, or persistent chrome (player) |
| Daily | Home section or tab root |
| Weekly / setup | Settings, profile, or full-screen picker |
| Rare / debug | Settings developer section only |

**Home dashboard zones** (top → bottom = attention):

1. **Now** — time-sensitive (next prayer, resume reading)
2. **Today** — plans, pinned shortcuts, daily modules (e.g. pinned athkar)
3. **More** — compact row for destinations **outside** bottom navigation only

When adding daily shortcuts (e.g. pinned athkar), place in **Today**, not More.

**Do not duplicate bottom navigation on Home.** Shell tabs already cover Home,
Prayer, Quran, Athkar, and Settings (`app_shell_screen.dart`). The More row is
for secondary routes only (e.g. Reciters, Qibla) — never re-add nav tabs as
Home tiles. See
[home-dashboard-patterns.md](../tilawa-apply-ui-principles/references/home-dashboard-patterns.md).

### Step 3 — Customization UX (favorites / pins)

Follow patterns that already exist:

- **Reciters favorites** — toggle in catalog; dedicated list elsewhere
- **Tasbeeh saved dhikr** — list on tasbeeh home with delete as sibling control

For Home pins:

- Sensible **defaults** for first launch (e.g. Morning + Evening athkar)
- **Edit** via section header `Row`: `TilawaSectionTitle` + `TilawaIconActionButton`
  (title widget has no trailing slot — see `pinned_athkar_home_section.dart`)
- **Picker:** bottom sheet for short local multi-select; full screen when search/filter needed
  (see [decision-trees.md](references/decision-trees.md))
- **Cap** visible pins (4–6) to prevent scroll fatigue
- **Persist locally**; no account required for MVP
- **Reorder** optional for v1; add/remove is minimum
- **Destructive remove** — confirm dialog or undo when data is lost

### Step 4 — States (required)

Every list or dashboard section needs:

| State | Tilawa component direction |
|-------|---------------------------|
| Loading | `TilawaLoadingIndicator` or skeleton in `TilawaCard` |
| Empty | `TilawaIllustratedState` / `TilawaEmptyState` + one CTA |
| Error | Illustrated state + Retry (`context.l10n.retry`) |
| Populated | Primary content |

Empty copy: invitation, not marketing ("Choose athkar for quick access" not
"Unlock your spiritual journey!").

### Step 5 — Accessibility & locale

- Semantic labels on icon-only shortcuts
- Test layout at **text scale 1.4** (app clamp in `tilawa_app.dart`)
- Arabic: use `nameAr` for athkar categories when `context.isArabic`
- RTL: use `AlignmentDirectional`, `EdgeInsetsDirectional`, `start`/`end`

Details: [references/accessibility.md](references/accessibility.md)

### Step 6 — Copy voice

From `docs/tilawa_brand.md` §8:

- Calm, second-person, no exclamation marks in chrome
- Respectful religious terms capitalized in English UI
- Support Tilawa terminology — never Premium / Pro / Unlock

## Anti-patterns (reject in review)

- Cold-start modal or popup for new Home sections
- **Home tile that duplicates a bottom-nav destination** (Prayer, Athkar, Settings, etc.)
- Settings tile as the only path to a daily action
- Forcing account sign-in for local pins/favorites
- Stacking 3+ competing CTAs on Home
- Feature tour on athkar/prayer/reader during active worship
- Empty grid with no CTA to add items
- Full-screen picker for a ≤10 item local toggle list (use sheet instead)

## Verification

From `apps/tilawa/` when UI ships:

```sh
dart analyze
flutter test test/features/<feature>/
```

Manually verify: primary path, empty state, RTL, text scale 1.4.

## Additional resources

- [references/ux-checklist.md](references/ux-checklist.md) — pre-ship checklist
- [references/placement-policy.md](references/placement-policy.md) — where features may appear
- [references/accessibility.md](references/accessibility.md) — a11y minimums
- [references/decision-trees.md](references/decision-trees.md) — sheet vs route, destructive flows
- [references/copy-voice-examples.md](references/copy-voice-examples.md) — tone examples for new strings
