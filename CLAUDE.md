# Tilawa — Claude Code guide

## Agent behavior

Follow the **Karpathy behavioral guidelines** on every task (think first,
simplicity, surgical diffs, verifiable goals). Canonical copy:

- Cursor: [`.cursor/rules/karpathy-guidelines.mdc`](.cursor/rules/karpathy-guidelines.mdc)
  (`alwaysApply`) + [`.cursor/rules/tilawa-dart.mdc`](.cursor/rules/tilawa-dart.mdc)
  for Dart under `apps/tilawa/` and `packages/`
- Claude Code / other: this section + [`.agent/rules/karpathy-guidelines.md`](.agent/rules/karpathy-guidelines.md)

Before implementing: state assumptions, define success criteria (e.g.
`melos run fix:format`, `dart analyze`, `flutter test test/features/<feature>/`),
then loop until they pass. Every changed line should trace to the user's request.
Formatting: see [`.cursor/rules/tilawa-dart.mdc`](.cursor/rules/tilawa-dart.mdc).

---

App brand name: **Tilawa / تلاوة**. Internal codename and package names use
`tilawa`. Do not rename packages; use "Tilawa" only in user-visible strings.

## Repo layout

```
apps/tilawa/          Main Flutter app
packages/ui_kit/      TilawaCard, tokens, shared widgets
packages/core/        Domain types, error types, typedefs
packages/quran_*/     Quran data packages
```

Feature code lives under `apps/tilawa/lib/features/<feature>/` with
`presentation/`, `domain/`, and `data/` sub-layers.

## Architecture rules

- State management: **flutter_bloc** (`Cubit` preferred over `Bloc`)
- DI: **get_it** — register in `core/di/` modules, inject via constructor
- Routing: **GoRouter** + **go_router_builder** — routes in
  `lib/router/app_router_config.dart`; use `SomeRoute().push(context)` or
  `.go(context)`. Root overlay modals (e.g. expanded Quran player `/player`)
  live **outside** `TypedShellRoute` with `$parentNavigatorKey =
  AppRouter.navigatorKey`. See
  [`docs/architecture/navigation.md`](docs/architecture/navigation.md) and
  [ADR-001](docs/adr/001-quran-player-root-overlay-route.md).
- Result type: `Either<Failure, T>` from **dartz_plus** — never throw across
  layer boundaries
- No `BuildContext` below the presentation layer

## Home dashboard (approved — do not redesign)

The current Home screen is **product-approved**. Source of truth:

- Code: `apps/tilawa/lib/features/home/presentation/`
- Patterns: [`.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md`](.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md)
- Artifacts: [`docs/design/home_screen_design_artifacts.md`](docs/design/home_screen_design_artifacts.md)

**Approved order:** `HomeDashboardHeroSliver` → tutor sliver (flag) →
`HomePrimaryActionsSection` → `HomeQuickToolsSection` → `TodayPlanCard` →
`HomeMoreActionsGroup` → `HomeListeningResumeRow` → `HomeDailyInspirationSection`
→ closing mark.

When working on Home: **preserve** this stack. Do **not** redesign from scratch,
reorder sections, wire stale widgets (`HomePrimaryActionZone`,
`HomeDiscoverShortcuts`, `HomeDailyPracticeSection`), or add a launcher grid
unless the user explicitly requests a Home redesign.

**Allowed without redesign approval:** bug fixes, spacing, overflow,
accessibility, token consistency, RTL layout — using existing approved widgets.

**Historical only (do not implement):** `docs/product/home_screen_redesign.md`,
`docs/plans/home_screen_redesign_plan.md`,
`docs/migrations/home_screen_redesign_migration.md`,
`docs/specs/home_screen_acceptance_criteria.md`,
`docs/adr/ADR-home-screen-information-architecture.md`.

## Design system

All design values come from theme extensions — never hard-code sizes or colors.

```dart
final tokens = theme.tokens;           // DesignTokens (spacing, radius, …)
final card   = theme.componentTokens.card;
final scheme = theme.colorScheme;
```

Localisation strings: `context.l10n` (extension on `BuildContext`).

**UI / UX skills:** `tilawa-apply-ux-principles` (flows, placement),
`tilawa-apply-ui-principles` (composition), `tilawa-ui-ux-guard` (review pass);
visual tokens: `flutter-apply-tilawa-theming`. Canonical human specs: `DESIGN.md`,
`docs/tilawa_brand.md`.

## Known pitfall — TilawaCard and interactive children

`TilawaCard` places a `Positioned.fill` InkWell at **z=0** (background) and
the card content at **z=1** (foreground). Flutter hit-tests the foreground
first, so nested interactive widgets (buttons, menus) receive taps correctly
and the card's `onTap` fires only on blank space.

**The one case this still doesn't cover**: when a nested widget needs a
*different* action from the card's `onTap`. In that case, place the control as
a **sibling** of `TilawaCard` in an outer `Row`, not inside `child`:

```dart
// WRONG — delete button has a different action from card navigation
TilawaCard(
  onTap: () => navigateToDetail(),
  child: Row(children: [..., IconButton(onPressed: () => delete())]),
)

// CORRECT — sibling Row
Row(
  children: [
    Expanded(child: TilawaCard(onTap: () => navigateToDetail(), child: ...)),
    IconButton(onPressed: () => delete()),
  ],
)
```

Existing examples of the sibling pattern:
`BookmarkCard`, `HistoryCard`, `PlaylistCard`, `TasbeehScreen` history list.

## Testing conventions

- Unit tests: `package:test` + `package:checks` assertions
- Widget tests: wrap in `MaterialApp` with `AppTheme.getLightTheme(...)` + l10n
  delegates; use fake repositories (see `test/features/athkar/helpers/`)
- Prefer **fakes over mocks** — only reach for `mockito` when a fake is
  impractical
- Tests live under `apps/tilawa/test/` mirroring the `lib/` feature tree

## Common commands

Run from the workspace root (or `apps/tilawa/` for app-only commands):

```sh
melos run fix:format                  # dart fix + format (workspace root; after edits, before commit)
melos run gen                         # l10n + build_runner (--workspace)
flutter test                          # all tests (from apps/tilawa)
flutter test test/features/athkar     # single feature
dart analyze                          # static analysis
```
