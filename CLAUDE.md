# Tilawa / Rattil — Claude Code guide

App brand name: **Rattil / رتل**. Internal codename and package names use
`tilawa`. Do not rename packages; use "Rattil" only in user-visible strings.

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
- Routing: **auto_route** — add routes to `app_router.dart`, access via
  `SomeRoute().push(context)` or `SomeRoute().go(context)`
- Result type: `Either<Failure, T>` from **dartz_plus** — never throw across
  layer boundaries
- No `BuildContext` below the presentation layer

## Design system

All design values come from theme extensions — never hard-code sizes or colors.

```dart
final tokens = theme.tokens;           // DesignTokens (spacing, radius, …)
final card   = theme.componentTokens.card;
final scheme = theme.colorScheme;
```

Localisation strings: `context.l10n` (extension on `BuildContext`).

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

Run from `apps/tilawa/`:

```sh
flutter test                        # all tests
flutter test test/features/athkar  # single feature
dart analyze                        # static analysis
dart fix --apply                    # auto-fix lint issues
flutter pub run build_runner build --delete-conflicting-outputs
```
