# Tilawa UX checklist

Run before shipping or in review mode. Mark each item pass / fail / N/A.

## Goal & flow

- [ ] User goal stated in one sentence; implementation matches it
- [ ] Primary task completable in ≤3 taps from app shell (or justified)
- [ ] No unnecessary steps (picker only when catalog is large)
- [ ] Back navigation predictable (GoRouter `pop`, not mystery dismiss)

## Information architecture

- [ ] High-frequency actions not buried in Settings or More
- [ ] Home matches approved full stack in `home-dashboard-patterns.md` if touching Home
- [ ] No Home redesign/reorder without explicit user request
- [ ] No stale Home targets (`HomePrimaryActionZone`, `HomeDiscoverShortcuts`,
  `HomeDailyPracticeSection`, etc.)
- [ ] Home does **not** add Home, Prayer, or Settings/Profile tiles; no launcher
  grid mirroring bottom nav
- [ ] Reciters in quick tools, if present, selects the existing Reciters tab
- [ ] Customization (pins/favorites) has edit entry and sensible defaults
- [ ] Pin/favorite count capped; empty state has add CTA
- [ ] Picker modality matches [decision-trees.md](decision-trees.md) (sheet vs full screen)

## States

- [ ] Loading state present (no blank flash)
- [ ] Empty state with single primary CTA
- [ ] Error state with retry; message is human, not status code
- [ ] Success feedback calm (no confetti / gold celebration for routine actions)

## Worship & placement policy

- [ ] No support/donation UI on reader, prayer, athkar counting
- [ ] No cold-start popup for this feature
- [ ] Product tour only on calm catalog entry (if applicable)

## Copy & localization

- [ ] All chrome strings in `app_en.arb` + `app_ar.arb`
- [ ] Voice calm; no Premium/Pro/Unlock/exclamation marketing
- [ ] Arabic content uses correct locale fields where applicable

## Accessibility

- [ ] Icon-only controls have semantics / tooltips
- [ ] Touch targets ≥ 44 dp (`tokens.minInteractiveDimension`)
- [ ] Layout checked at text scale 1.4
- [ ] RTL verified for directional layout

## Technical UX boundaries

- [ ] No `BuildContext` below presentation layer
- [ ] Refresh/pull-to-refresh only where data can change
- [ ] Destructive actions confirm or use undo pattern where repo supports it
