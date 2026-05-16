# Responsive & Adaptive Design Guidelines

Recommendations for the Tilawa UI Kit and the Tilawa app. Goal: predictable behavior from phones to foldables to tablets without the fragility of global pixel scaling.

## Current foundation

- `TilawaDesignTokens` — spacing, radius, border, opacity, icon sizes.
- Component primitives in `packages/ui_kit` — `MetadataChip`, `SelectionPill`, `TilawaGlassPanel`, `TilawaSheetHandle`, `TilawaSettingsGroup/Tile`, `ImmersiveComposerScaffold`, `TilawaIconActionButton`.
- Short-window vs regular height behavior on `ImmersiveComposerScaffold` addresses two vertical device classes (token-backed `shortWindow*` thresholds).

This foundation is correct. The additions below formalize it.

## Core principle: two sizing axes, kept separate

| Concern | Driver | Never driven by |
| --- | --- | --- |
| Spacing, radius, border | Design tokens (fixed values) | Screen width |
| Typography | `MediaQuery.textScaler`, clamped `[1.0, 1.3]` | Screen width |
| Layout (columns, nav pattern, max width) | Breakpoints + `LayoutBuilder` | `screenutil`-style global factor |
| Media (covers, grids) | `AspectRatio` + `SliverGridDelegateWithMaxCrossAxisExtent` | Fixed pixel dimensions |

**Do not** scale the whole UI by `screenWidth / designWidth`. That is the shortcut that produces odd results like a 1.5× search bar height on a 1.87× wider device (the pattern seen in Talabat's build).

## 1. Formalize breakpoints in the UI kit

Add `TilawaBreakpoints` next to `TilawaDesignTokens`:

```dart
class TilawaBreakpoints {
  static const double narrowUpperBound = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

enum TilawaWindowSize { narrow, medium, expanded, large }

extension TilawaWindowSizeX on BuildContext {
  TilawaWindowSize get windowSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width >= TilawaBreakpoints.expanded) return TilawaWindowSize.large;
    if (width >= TilawaBreakpoints.medium) return TilawaWindowSize.expanded;
    if (width >= TilawaBreakpoints.narrowUpperBound) {
      return TilawaWindowSize.medium;
    }
    return TilawaWindowSize.narrow;
  }
}
```

Aligns with Material 3 window size classes. Replaces ad-hoc `MediaQuery.size.width > X` checks scattered in feature code.

## 2. Content max-width tokens

Add to `TilawaDesignTokens`:

| Token | Value | Used for |
| --- | --- | --- |
| `contentMaxWidthReader` | 720 | Quran reader page |
| `contentMaxWidthForm` | 560 | Settings, dialogs, auth |
| `contentMaxWidthMedia` | 1200 | Share composers, galleries |

Wrap screens in `ConstrainedBox(maxWidth: tokens.contentMaxWidthX)` and center. Prevents tablets/desktop from stretching text lines and cards to unreadable widths.

## 3. Adaptive shell

Promote a `TilawaAdaptiveShell` organism:

- **Narrow (phone)** → bottom `NavigationBar`.
- **Medium** → `NavigationRail` (icons + labels).
- **Expanded** → extended `NavigationRail` or persistent `Drawer`.

API sketch:

```dart
TilawaAdaptiveShell(
  destinations: [...],
  body: ...,
)
```

Biggest tablet/foldable UX win for a Quran app: a persistent rail enables quick surah/juz navigation without sacrificing reading area.

## 4. Reader-specific policy

The Quran reader is the highest-stakes surface. Codified rules:

- **Page width** locked to `contentMaxWidthReader`, centered, never stretched.
- **Aspect ratio preserved** — scale the *container*, not the 15-line grid.
- **Font scale** driven by a user setting in preferences, not device size. Tablet users often want relatively smaller text, not larger.
- **Layout constants** (`25/720` horizontal padding, width divisor `16.5`, height divisor `27.762`) remain the source of truth — see memory and existing implementation.

Already implemented correctly for QCF fonts; worth documenting as kit policy so it doesn't drift.

## 5. Grid helpers

Promote `TilawaContentGrid`:

```dart
TilawaContentGrid(
  targetItemWidth: 280,
  itemBuilder: ...,
)
```

Wraps `SliverGridDelegateWithMaxCrossAxisExtent` with token-driven spacing. Use for reciters list, bookmarks, history. The grid chooses column count from available width — no manual breakpoint branching per grid.

## 6. Text scaling policy

At the `MaterialApp` level:

```dart
MaterialApp(
  builder: (context, child) {
    final scaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.3,
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child!,
    );
  },
)
```

Respects accessibility settings without allowing layouts to break at extreme scale factors. Arabic text has tight line heights — unbounded scaling is a layout hazard.

## 7. What not to do

- Do **not** add `flutter_screenutil` or equivalent. The token system is already better; global scaling is fragile and couples every widget to one design size.
- Do **not** scale atoms (`MetadataChip`, `SelectionPill`, icons) by screen width. Fixed sizes + clamped `textScaler` is correct.
- Do **not** add a "density" toggle speculatively. Material's default works; add only if users request it.
- Do **not** use raw `MediaQuery.size.width * 0.x` math in widgets. Use breakpoints or `LayoutBuilder`.

## 8. The target stack

```
MaterialApp (with clamped textScaler)
  └─ TilawaAdaptiveShell (NavigationBar ↔ Rail ↔ Drawer by windowSize)
       └─ ConstrainedBox(maxWidth: tokens.contentMaxWidth*)
            └─ LayoutBuilder for local decisions
                 └─ TilawaContentGrid / SliverGrid with maxCrossAxisExtent
                      └─ AspectRatio for media
                           └─ Atoms sized from design tokens
```

## Rollout plan

Incremental, low-risk:

1. **Phase 1** — Add `TilawaBreakpoints` + `windowSize` extension in `packages/ui_kit`. Migrate existing ad-hoc width checks.
2. **Phase 2** — Add `contentMaxWidth*` tokens to `TilawaDesignTokens`. Apply to reader, settings, share composers.
3. **Phase 3** — Build `TilawaAdaptiveShell`. Ship tablet/foldable UX.
4. **Phase 4** — `TilawaContentGrid`. Migrate reciters, bookmarks, history.
5. **Phase 5** — Document and enforce the clamped `textScaler` at the app root.

Each phase is independently shippable and reversible.

## Reference: why not proportional scaling

Observed ratios from a large production app (Talabat) on 720px vs 1344px devices:

- Device width ratio: 1.87×
- Card width ratio: 1.50×
- Card height ratio: 1.50×
- Search bar width ratio: 1.90× (matches device)
- Search bar height ratio: 1.50×

The inconsistent width ratios reveal that **layout width is screen-relative** (search bar fills screen minus margin) while **content size uses a dampened scale factor** (cards, bar height). Mixing axes inside a single scaling utility is how production apps end up with subtly wrong proportions. Keeping the axes separate — as this document prescribes — avoids that class of bug by construction.
