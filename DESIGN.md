---
version: alpha
spec: "https://stitch.withgoogle.com/docs/design-md/specification"
name: MeMuslim
tagline: Calm Islamic lifestyle companion — Quran, prayer, dhikr, and learning in a warm, readable, premium shell.
description: >-
  MeMuslim / أنا مسلم (formerly Tilawa) uses Material 3 with a small, calm palette:
  green global accent for CTAs and active chrome, warm parchment canvas, white elevated
  cards, gold featured heroes, and restrained shadows. Implementation truth lives in
  packages/ui_kit and apps/tilawa — this file is the single source of truth for humans
  and AI agents making UI/UX changes.

colors:
  # Brand / action (production-locked - unified for UI, splash, and launcher)
  primary: "#1DAB61"
  primary-accessible: "#148048"
  on-primary: "#003317"
  primary-dark: "#6BC992"
  primary-container-light: "#E0F2F1"

  # Semantic feedback
  success: "#43A047"
  success-dark: "#6BCF7F"
  warning: "#C2410C"
  warning-dark: "#FB923C"
  error: "#C74545"
  error-soft: "#E57373"
  error-dark: "#FFB4AB"
  on-error: "#FFFFFF"

  # Light surfaces (60-30-10)
  canvas: "#F3F6F4"
  surface: "#FFFFFF"
  surface-container-high: "#F0F7F2"
  surface-container-highest: "#DFE8E2"
  ink: "#1A2E24"
  body: "#1A2E24"
  mute: "#6B7F74"
  ash: "#BDBDBD"
  outline: "#E0E0E0"
  hairline: "#EEEEEE"

  # Featured / warm accents (not pay CTAs)
  gold-start: "#FFD28E"
  gold-end: "#FF9E44"
  gold-accent: "#F2AC1F"
  gold-foreground: "#1A2E24"

  # Dark surfaces
  canvas-dark: "#0E1413"
  surface-dark: "#141D1B"
  surface-container-dark: "#1A2624"
  surface-container-high-dark: "#2A3432"
  outline-dark: "#4A5C57"

  # Chrome
  bottom-nav: "#212528"

typography:
  font-family: "IBM Plex Sans Arabic"
  font-source: "packages/tilawa_ui_kit/IBMPlexSansArabic (bundled)"
  display-large:
    role: displayLarge
    fontSize: 57px
    fontWeight: 400
    lineHeight: 1.12
  title-large:
    role: titleLarge
    fontSize: 22px
    fontWeight: 700
    lineHeight: 1.27
    usage: "Screen titles, catalog app bars"
  title-medium:
    role: titleMedium
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.5
    usage: "Section headers, dashboard zones"
  body-large:
    role: bodyLarge
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-medium:
    role: bodyMedium
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.43
  body-small:
    role: bodySmall
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.33
    usage: "Metadata, captions"
  label-large:
    role: labelLarge
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.43
    usage: "Buttons, pills"
  arabic-loose-line-height: 2.0

spacing:
  tiny: 2px
  extra-small: 4px
  small: 8px
  medium: 12px
  large: 16px
  extra-large: 24px
  section: 20px
  xxl: 32px
  huge: 48px

rounded:
  small: 8px
  medium: 12px
  large: 20px
  extra-large: 24px
  hero: 28px
  card: 24px
  pill: 9999px

elevation:
  # Layered tiers (MeMuslimElevationX) — contact + ambient, tinted by ColorScheme.shadow
  raised-contact: "alpha 0.05, blur 3, offset 0 1"
  raised-ambient: "alpha 0.07, blur 24, offset 0 10"
  floating-contact: "alpha 0.06, blur 6, offset 0 2"
  floating-ambient: "alpha 0.11, blur 32, offset 0 14"
  elevation-multiplier: 1.0
  # Legacy single-shadow tokens (existing chrome only)
  shadow-alpha: 0.04
  shadow-strong-alpha: 0.08
  shadow-offset-small: "0 1.5"
  shadow-offset-medium: "0 3"
  blur-shadow: 12
  border-width-thin: 0.5

motion:
  duration-fast: 200ms
  duration-medium: 400ms
  duration-slow: 600ms
  curve-standard: easeOut
  curve-emphasized: easeOutCubic
  curve-symmetric: easeInOut

accessibility:
  min-touch-target: 48
  text-scale-clamp-min: 1.0
  text-scale-clamp-max: 1.0
  hero-text-scale-clamp-max: 1.3
---

# MeMuslim — DESIGN.md

Design system for **MeMuslim / أنا مسلم** (internal package name `tilawa`). Read this file before any UI/UX change.

**Read order:** `AGENTS.md` (how to build) → **this file** (how it looks) → [`docs/tilawa_brand.md`](docs/tilawa_brand.md) (brand intent). When intent and implementation conflict, **this file and code win on tokens**; [`docs/tilawa_brand.md`](docs/tilawa_brand.md) wins on product voice and moodboard direction.

**Companion docs:** [`packages/ui_kit/docs/design_system.md`](packages/ui_kit/docs/design_system.md) (freeze contract), [`docs/design/color_architecture.md`](docs/design/color_architecture.md), [`packages/ui_kit/docs/feedback_system.md`](packages/ui_kit/docs/feedback_system.md).

---

## Visual theme and atmosphere

- **Material 3** via **FlexColorScheme**, refined in `AppTheme` with palette from `AppColors`.
- **Calm, content-first:** small palette, porcelain-green canvas (`#F3F6F4`), white cards (`#FFFFFF`), one **green global accent** (`#1DAB61`) for CTAs and active chrome. No legacy purple. Brown/warm tones appear only as approved secondary micro-accents (gold featured cards, warm hero gradients, metadata browns) — never as a new primary.
- **Not e-commerce / admin:** avoid dense data grids, heavy gradients on chrome, stacked shadows, or crowded multi-accent layouts.
- **Readable Arabic:** `textHeightLoose` (2.0) for dense script; bundled **IBM Plex Sans Arabic** on all M3 roles.
- **Comfortable density:** `FlexColorScheme.comfortablePlatformDensity` — not compact.
- **Premium but quiet depth:** layered elevation tiers (`tokens.elevationRaised` / `elevationFloating` — tight contact shadow + soft ambient bloom, ink-tinted via `ColorScheme.shadow`); legacy low-alpha singles (`opacityShadow` 0.04, `opacityShadowStrong` 0.08) remain on existing chrome; optional glass tokens for floating chrome only.
- **Surface tint off:** `surfaceTintColor` → transparent on cards, dialogs, sheets, app bars so user primary does not wash neutrals.

---

## Color palette and roles

### Production primary (brand-locked green)

| Token | Hex | Usage |
|-------|-----|--------|
| `brandActionGreen` | `#1DAB61` | **Default primary** — CTAs, active nav, selected pills, switch ON, progress |
| `brandActionGreenAccessible` | `#148048` | Solid buttons/links needing higher contrast |
| `lightSchemeOnPrimary` | `#003317` | Labels/icons on green fills (AA on `#1DAB61`) |
| `darkDefaultPrimary` | `#6BC992` | Lifted green on dark surfaces |

Production locks `PrimaryColorPreset.brandGreen` (`#1DAB61`). Legacy purple (`#7A5C89`), brown (`#8B5E3C`), sage (`#219653`), and teal (`#00897B`) presets migrate to brand green on read — **do not reintroduce purple** or add new accent hues.

Dev/QA only (`TILAWA_SHOW_COLOR_PICKER=true`): coral, teal, sage, forest presets remain for testing; never ship new UI assuming a user-picked primary other than green.

### Semantic colors

| Role | Light | Dark | Access |
|------|-------|------|--------|
| Success | `#43A047` | `#6BCF7F` | `colorScheme.success` |
| Warning | `#C2410C` | `#FB923C` | `colorScheme.warning` |
| Error | `#C74545` | `#FFB4AB` | `colorScheme.error` |

### Light neutral ramp (60-30-10)

~60% warm canvas, ~30% white elevated surfaces, ~10% green accent.

| Role | Hex | `ColorScheme` / API |
|------|-----|-------------------|
| Canvas / scaffold | `#F3F6F4` | `surfaceContainerLowest` |
| Cards, sheets | `#FFFFFF` | `surface` |
| Ink / onSurface | `#1A2E24` | `onSurface` |
| Muted labels | `#6B7F74` | `onSurfaceVariant` |
| Idle chips / search rest | `#F0F7F2` | `surfaceContainerHigh` |
| Hairline | `#EEEEEE` | `outlineVariant` |
| Strong outline | `#E0E0E0` | `outline` |

### Warm / gold accents (secondary, not CTAs)

| Role | Hex | Usage |
|------|-----|--------|
| Featured gradient | `#FFD28E` → `#FF9E44` | Last Read, hero resume cards — ceremonial, not purchase chrome |
| `brandGoldAccent` | `#F2AC1F` | Verses, quiet alerts — maps to `colorScheme.tertiary` |
| Home hero gradients | prayer-period tokens in `AppColors.homeNextPrayerGradient*` | Home hero only |

**Rule:** Widgets consume `Theme.of(context).colorScheme`, `theme.productColors`, and `theme.componentTokens` — not raw `AppColors` hex (except documented platform-fixed cases).

### Dark mode

Deep green-tinted stack: background `#0E1413`, surface `#141D1B`, containers stepping through `#1A2624` → `#2A3432`. Optional **true-black OLED** preset (`AppThemePreset.trueBlack`).

### Accent discipline (one-accent rule)

Green primary for **one emphasis lane per screen** — primary CTA, active bottom nav, selected filter, switch ON. **Not** for catalog search fills, chip idle backgrounds, or app-bar washes (stay neutral).

---

## Typography

- **Font:** bundled **IBM Plex Sans Arabic** (`AppTheme` → `_fontFamily`).
- **Roles:** Material 3 `TextTheme` (`display*` … `label*`). Use `Theme.of(context).textTheme`, not hard-coded sizes.
- **Titles:** `titleLarge` / `titleMedium`, `FontWeight.w700` for screen and section headers.
- **Arabic content:** `titleSmall` w700 + `textHeightLoose` (2.0).
- **Metadata:** `bodySmall`, `onSurfaceVariant`.
- **Scaling:** `tilawaProductTextScaler` on `MaterialApp.builder`; clamped **1.0–1.0** globally (`tilawa_app.dart`). Home prayer hero uses **1.0–1.3** for extent math. Quran reader mushaf uses dedicated reader settings — not global scale.
- **Tests/previews:** `AppTheme.useGoogleFonts = false` in goldens for CI stability.

---

## Spacing, radii, and motion

Access via `Theme.of(context).extension<MeMuslimDesignTokens>()` or `context.tokens`.

### Spacing scale (dp)

| Token | Value |
|-------|-------|
| `spaceTiny` | 2 |
| `spaceExtraSmall` | 4 |
| `spaceSmall` | 8 |
| `spaceMedium` | 12 |
| `spaceLarge` | 16 |
| `spaceExtraLarge` | 24 |
| `spaceSection` | 20 |
| `spaceXXL` | 32 |
| `spaceHuge` | 48 |

**Home rhythm:** within zone `spaceLarge`; between zones `spaceExtraLarge`.

### Corner radii (dp)

| Token | Value | Use |
|-------|-------|-----|
| `radiusSmall` | 8 | Chips, decorative |
| `radiusMedium` | 12 | Nested controls |
| `radiusLarge` | 20 | Search, segment tracks |
| `radiusExtraLarge` / `radiusCard` | 24 | Content cards, pills |
| `radiusHero` | 28 | Hub summary groups |

Use `tokens.resolveRadius(family: TilawaRadiusFamily.*)` — do not hardcode radii.

### Motion

| Token | Value |
|-------|-------|
| `durationFast` | 200 ms |
| `durationMedium` | 400 ms |
| `durationSlow` | 600 ms |
| `curveStandard` | `Curves.easeOut` |
| `curveEmphasized` | `Curves.easeOutCubic` |
| `curveSymmetric` | `Curves.easeInOut` |

Reader page-turn stays slowest in the app.

### Content max widths

| Kind | Max (px) | Use |
|------|----------|-----|
| Reader | 720 | Quran body |
| Form | 560 | Sheets, auth |
| Media | 1200 | Share / gallery |
| Settings | 760 | Settings columns |

---

## Layout and breakpoints

- **Window classes** (`TilawaWindowSize`): narrow `< 600`, medium `< 840`, expanded `< 1200`, large `≥ 1200`.
- Branch on `context.windowSize`, not raw widths.
- **Adaptive shell** (`TilawaAdaptiveShell`): bottom nav with labels; floating pill on `#212528`; sync system nav bar color for continuity.
- **Min touch target:** **48 dp** (`kMeMuslimMinInteractiveDimension`) — WCAG 2.5.5 AAA target size.

---

## Components

Component styling lives in `MeMuslimComponentTokens` (access: `theme.componentTokens`).

**Prefer kit widgets:** `TilawaButton`, `TilawaCard`, `TilawaEmptyState`, `TilawaErrorState`, `TilawaSkeleton`, `TilawaAsyncContent`, `TilawaCatalogAppBar`, `TilawaSearchField`, `TilawaSelectionPill`, `TilawaSettingsGroup`, `TilawaAdaptiveShell`, `TilawaMediaPlayerBar`.

### Catalog chrome (frozen)

`TilawaCatalogAppBar` on list/catalog screens:

- Surface: `TilawaAppBarSurface.parchment`
- Title: left-aligned `titleLarge` w700
- Search: catalog variant — white fill + hairline, not primary-tinted
- Filters: `TilawaSelectionPillStyle.catalog` — selected `primary` + `onPrimary`; unselected `surfaceContainerHigh`

### Cards and interaction

- **TilawaCard:** parent `onTap` from blank areas only; nested enabled controls keep their action. Conflicting actions → sibling `Row` (see `CLAUDE.md`).
- **TilawaInteractiveSurface:** ink splash 0.08 primary, highlight 0.04 onSurface, state layers 0.12 pressed / 0.08 hover.

### Empty, error, loading

| State | Component | Contract |
|-------|-----------|----------|
| Empty | `TilawaEmptyState` | Icon + title + optional subtitle + optional action |
| Error | `TilawaErrorState` | Icon + title + retry |
| Loading (structured) | `TilawaSkeleton` + bones | Mirror loaded layout; RTL-aware shimmer |
| Region swap | `TilawaAsyncContent` | Cross-fade over `durationFast`; static under reduced motion |
| Spinner | `TilawaLoadingIndicator` | Indeterminate work without stable geometry only |

### Feedback / toasts

Use **`TilawaFeedback.showToast`** / **`showActionable`** — not `SnackBar` or third-party toast packages.

| Channel | Component |
|---------|-----------|
| Success confirmation | `TilawaFeedbackVariant.success` toast |
| Destructive undo | Actionable toast, 4 s default |
| Field validation | Inline under field — **never** toast |
| Network failure | `TilawaFeedbackVariant.error` toast |

Host: `TilawaFeedbackHost` wraps `MaterialApp.builder` child.

---

## Depth and elevation

- **Layered elevation:** resting cards use `tokens.elevationRaised(colorScheme.shadow)` — contact (0.05 / blur 3 / y1) + ambient (0.07 / blur 24 / y10); floating chrome uses `elevationFloating` — contact (0.06 / blur 6 / y2) + ambient (0.11 / blur 32 / y14). Shadows tint with brand ink via `ColorScheme.shadow`, never gray-black. Global tuning knob: `kElevationMultiplier` (1.0, safe ≈ 0.8–1.3).
- **Borders:** `borderWidthThin` **0.5** hairlines where tokens apply.
- **No heavy elevation stacks** or decorative gradients on standard chrome — depth comes from the two calibrated layers, not stacked effects.

---

## Screen-specific guidance

### Home dashboard

**Product-approved layout — do not redesign or reorder** unless explicitly requested.

Technical: [home-dashboard-patterns.md](.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md). Design intent: [home_screen_design_artifacts.md](docs/design/home_screen_design_artifacts.md).

Approved stack: `HomeNextPrayerTime` → optional tutor sliver → `HomePrimaryActionsSection` → `HomeQuickToolsSection` → deferred More / listening / inspiration / closing mark. Two primary tiles (Mushaf, Athkar), three quick tools — not a multi-tab launcher grid.

### Quran Sessions

Package: `packages/quran_sessions/`. Performance → UX → UI (see [`docs/quran_sessions/performance_first_review_framework.md`](docs/quran_sessions/performance_first_review_framework.md)).

- Reuse kit empty/error/offline: `QuranSessionsOfflineState`, `buildQuranSessionsFailureBody`, `TilawaEmptyState`.
- Teacher dashboard: overview card, schedule section, summary stats, week-scope pills, next-action resolver — calm hierarchy, grouped sections, inline empty states per tab.
- Session cards: `TutorSessionCompactCard` — compact, scannable metadata.
- No raw hex in presentation chrome; no amber/debug colors in production paths.
- Toasts for undo/cancel flows via `TilawaFeedback`, not ad-hoc `SnackBar`.

### Teacher Dashboard

- **Hierarchy:** summary stats → next action → schedule timeline → pending/upcoming lists.
- **Empty states:** `TeacherDashboardInlineEmptyState` — icon + title + description + optional CTA.
- **Offline:** `QuranSessionsOfflineState` centered with retry.
- **Week scope:** pills use catalog selection pattern (green selected, neutral idle).

### Settings

- `TilawaSettingsGroup` + list rows; catalog app bar on list screens.
- Support MeMuslim: calm surfaces, brown/green Ink CTA, no gold pay heroes (see § Support).
- Form sheets: cap width with `contentMaxWidthForm` (560).

### Empty states (global rule)

Every empty region: **`TilawaEmptyState`** or **`TilawaIllustratedState`** — icon + title + description (+ optional single primary action). No bare text-only placeholders.

---

## Accessibility

- **Touch targets:** ≥ **48 dp** on all in-app interactive elements.
- **Contrast:** body text vs surface ≥ WCAG AA; green `#1DAB61` uses `#003317` on-primary for labels.
- **RTL / Arabic:** use `EdgeInsetsDirectional`, `AlignmentDirectional`, skeleton sweep follows reading direction; test Arabic layouts.
- **State:** never color-only — pair with icon, label, or pattern (selected pill fill + label weight).
- **Loading / empty / error / disabled:** distinct visuals; announce skeleton regions via `semanticLabel`.
- **Text scale:** test layouts at system max within app clamp; Home hero at 1.3.
- **Reduced motion:** skeletons freeze to static blocks; `TilawaAsyncContent` instant swap.

---

## Support MeMuslim (voluntary contribution)

Product: [`specs/016-support-tilawa/spec.md`](specs/016-support-tilawa/spec.md). Visuals: [`packages/ui_kit/docs/support_visual_system.md`](packages/ui_kit/docs/support_visual_system.md).

| Avoid | Use |
|-------|-----|
| Premium, Pro, VIP | Support MeMuslim, Supporter |

Calm parchment surfaces; one green CTA per screen; no gold pay chrome; no worship-surface entry points.

---

## AI agent rules

**Mandatory before any UI change:**

1. Read **this file** and [`packages/ui_kit/docs/design_system.md`](packages/ui_kit/docs/design_system.md).
2. Use **`ColorScheme`**, **`context.tokens`**, **`theme.componentTokens`**, **`theme.productColors`** — no new hex, spacing, radius, or typography unless explicitly requested and added to tokens first.
3. **Green `#1DAB61`** is the production primary for CTAs (Start, Continue, Save, Book, etc.). **No legacy purple.** Brown/warm/gold only where already tokenized.
4. **Prefer UI Kit components.** New reusable widgets go in `packages/ui_kit` first, then consume from features.
5. **No hardcoded** `Color(0x…)`, raw dp, or `Curves.*` in feature code — extend tokens/theme.
6. **Dashboard / complex screens:** clear hierarchy, grouped sections, scannable rows, approved empty states, skeleton loading.
7. **Home:** preserve approved order — link [home-dashboard-patterns.md](.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md); do not wire stale Home widgets listed there.
8. **Feedback:** `TilawaFeedback` toasts only; inline validation stays inline.
9. **l10n:** `context.l10n` / feature delegates — no hard-coded user strings in presentation.
10. **External moodboards** (`design-md/`): inspiration only — never paste reference hex into features.

**Prompt templates:**

- *"Implement with MeMuslim UI Kit — `colorScheme`, `context.tokens`, `componentTokens`; no raw hex."*
- *"Primary CTA uses `colorScheme.primary` / brand green; catalog chrome stays neutral."*
- *"Empty state: `TilawaEmptyState` with icon, title, subtitle."*
- *"Loading: `TilawaSkeleton` mirroring final layout via `TilawaAsyncContent`."*

---

## Do's and don'ts

**Do**

- Use tokens and kit components for all chrome.
- Respect **48 dp** minimum interactive sizes.
- Cap wide content with `TilawaContentBounds` / `resolveContentWidth`.
- Branch layout on `context.windowSize`.
- Match catalog app bar + neutral search/pills on list screens.

**Don't**

- Add purple, random accent colors, or e-commerce-style dense dashboards.
- Use heavy gradients, excessive shadows, or primary-tinted catalog backgrounds.
- Toast field validation errors.
- Flatten scaffold to pure white — use porcelain canvas `#F3F6F4` so white cards lift.
- Put support/donation UI on worship surfaces (reader, prayer, athkar).

---

## Validation

Validate this file after edits:

```bash
# From repo root — requires network for first npx fetch
npx @google/design.md lint --format=text DESIGN.md

# Structured output for CI/agents
npx @google/design.md lint --format=json DESIGN.md

# macOS/Linux: exit 0 = pass (warnings OK); exit 1 = errors
```

Windows PowerShell (if `design.md` opens as a file):

```bash
npx -p @google/design.md designmd lint DESIGN.md
```

Manual YAML check:

```bash
python3 -c "import yaml, pathlib; yaml.safe_load(pathlib.Path('DESIGN.md').read_text().split('---',2)[1])"
```

Theme compliance tests (code vs spec):

```bash
cd packages/ui_kit && flutter test test/theme/
```

---

## Key file map

| Area | Path |
|------|------|
| Theme assembly | `packages/ui_kit/lib/src/foundation/app_theme.dart` |
| Core palette | `packages/ui_kit/lib/src/foundation/app_colors.dart` |
| Spatial / motion tokens | `packages/ui_kit/lib/src/foundation/design_tokens.dart` |
| Component tokens | `packages/ui_kit/lib/src/foundation/component_tokens/` |
| Product semantic colors | `packages/ui_kit/lib/src/foundation/memuslim_product_colors.dart` |
| Content width | `packages/ui_kit/lib/src/foundation/content_bounds.dart` |
| Breakpoints | `packages/ui_kit/lib/src/foundation/breakpoints.dart` |
| Feedback / toasts | `packages/ui_kit/lib/src/foundation/tilawa_feedback.dart` |
| Primary presets | `apps/tilawa/lib/features/theme/domain/primary_color_preset.dart` |
| App theme wiring | `apps/tilawa/lib/tilawa_app.dart` |
| UI kit freeze contract | `packages/ui_kit/docs/design_system.md` |
| Brand intent | `docs/tilawa_brand.md` |
| Home dashboard patterns | `.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md` |
| External moodboard library | `design-md/` (index: `docs/design/awesome-design-md-readme.md`) |

---

## Theme freeze status

**Frozen baseline** (2026-05-23): [`specs/017-catalog-theme-freeze/spec.md`](specs/017-catalog-theme-freeze/spec.md). Allowed: new kit components, critical bugs, documented feature palettes (Quran reader, share output). Enforcement: `app_theme_color_roles_test.dart`, `app_theme_spec_compliance_test.dart`, `test/goldens/`.

---

## Document format

Follows [Google design.md](https://stitch.withgoogle.com/docs/design-md/overview/) (YAML frontmatter + human spec). Machine-readable tokens in frontmatter mirror `AppColors` and `MeMuslimDesignTokens`; prose sections add agent-enforceable rules. Update frontmatter when token values change in code.
