# Tilawa UI Kit Inventory

**Spec Area**: `006-ui-kit-expansion`
**Created**: 2026-05-10
**Status**: Draft for review
**Scope**: Documentation only. No component refactors, app UI changes, or commits.

## Overview

Tilawa UI Kit is the shared Flutter design system package for Tilawa. It provides reusable UI primitives, composed controls, larger app surfaces, and theme/token foundations for a consistent Material 3 experience across mobile, tablet, foldable, light theme, dark theme, and Arabic/English layouts.

The kit follows Atomic Design:

- **Atoms**: smallest reusable visual primitives, such as cards, buttons, dividers, loading indicators, and sheet handles.
- **Molecules**: composed controls made from atoms and Material primitives, such as chips, search fields, selection tiles, segmented controls, and media seek bars.
- **Organisms**: larger UI sections or surfaces that coordinate multiple pieces, such as adaptive navigation, media player bars, and immersive composer scaffolds.
- **Templates**: page-level layout patterns. No public `templates` folder or template barrel exists today; some current organisms are template-like and are noted in the backlog.
- **Tokens**: theme extensions and constants that define spacing, radii, sizes, colors, durations, shadows, component sizing, and responsive layout decisions.

### Theme And Token Relationship

`AppColors` is the centralized color constant source for brand colors, surface bases, status colors, settings colors, Quran colors, and native/theme alignment references. New reusable colors should be added here only when they represent a cross-app design role.

`AppTheme` builds the light and dark `ThemeData` objects using `FlexColorScheme`, `GoogleFonts.alexandriaTextTheme`, refined `ColorScheme` surfaces, and theme extensions. It installs both `TilawaDesignTokens` and `TilawaComponentTokens`.

`TilawaDesignTokens` contains global design values: spacing, radii, opacity, blur, shadow offsets, border width, icon sizes, durations, content max widths, and player behavior thresholds. Widgets should consume these through `Theme.of(context).tokens`.

`TilawaComponentTokens` contains component-family values grouped into atoms, molecules, and organisms. Widgets should consume these through `Theme.of(context).componentTokens`, not by inventing local dimensions.

Rule: reusable widgets consume `ThemeData`, `ColorScheme`, `TilawaDesignTokens`, and `TilawaComponentTokens`. UI Kit widgets must not invent hardcoded colors, spacing, radii, shadows, or typography when a token or theme role exists.

### Catalog chrome (frozen 2026-05-23)

List/catalog screens should use **`TilawaCatalogAppBar`** with **`TilawaSearchFieldVariant.catalog`** and **`TilawaSelectionPillStyle.catalog`**. Default primary is coral (`AppColors.defaultPrimary`). See [`packages/ui_kit/docs/design_system.md`](../../packages/ui_kit/docs/design_system.md) and [`specs/017-catalog-theme-freeze/spec.md`](../017-catalog-theme-freeze/spec.md).

## Public Exports

Public entrypoint:

- `packages/ui_kit/lib/tilawa_ui_kit.dart`

Public barrels:

- `packages/ui_kit/lib/src/atoms/atoms.dart`
- `packages/ui_kit/lib/src/molecules/molecules.dart`
- `packages/ui_kit/lib/src/organisms/organisms.dart`
- `packages/ui_kit/lib/src/foundation/foundation.dart`

Current exported inventory:

- Atoms: 12 exported atom files/classes.
- Molecules: 16 exported molecule files, 17 public molecule widgets because `tilawa_settings_tile.dart` exports both `TilawaSettingsTile` and `TilawaSettingsSwitchTile`.
- Organisms: 6 exported organism widgets.
- Templates: 0 exported template widgets.

## Atoms

### `TilawaButton`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_button.dart`
- **Purpose**: Design-system button with variants, sizes, loading state, optional leading/trailing icons, and full-width mode.
- **Main API**: `text`, `onPressed`, `variant`, `size`, `leadingIcon`, `trailingIcon`, `isLoading`, `isFullWidth`, `semanticLabel`; enums `TilawaButtonVariant` and `TilawaButtonSize`.
- **Typical usage**: Primary CTA, secondary action, outline action, ghost action, or destructive action inside app screens and sheets.
- **Tokens/theme**: Uses `ColorScheme`, `TilawaDesignTokens.radiusMedium`, button sizing constants in the widget, and `TilawaLoadingIndicator`.
- **RTL/LTR**: Uses `Row` order from ambient direction; leading/trailing icon semantics follow Flutter layout direction.
- **Accessibility**: Wraps content in `Semantics` with `button`, `enabled`, and loading-aware label; enforces minimum 48x48 target.
- **Known limitations**: Size dimensions are currently local to the widget rather than component-tokenized.
- **Recommended usage / avoid usage**: Use for generic actions. Avoid for icon-only actions; use `TilawaIconActionButton` or `TilawaIconToggle`.

### `TilawaCard`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_card.dart`
- **Purpose**: Standard card/container with optional tap handling, border, gradient, shadow, splash, and flat mode.
- **Main API**: `child`, `padding`, `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `gradient`, `onTap`, `splashColor`, `highlightColor`, `flat`.
- **Typical usage**: Feature cards, settings rows, dashboard containers, and tappable surface wrappers.
- **Tokens/theme**: Uses `componentTokens.card` and global design tokens for shadow alpha/blur/offset.
- **RTL/LTR**: Neutral container; child owns direction behavior.
- **Accessibility**: Tappable cards rely on child semantics; no automatic button/container semantic label.
- **Known limitations**: Consumers can override many visual values; review overrides to avoid drifting from the system.
- **Recommended usage / avoid usage**: Use for reusable card surfaces. Avoid nesting shadowed cards; set `flat: true` for nested rows.

### `TilawaDivider`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_divider.dart`
- **Purpose**: Token-backed wrapper around `Divider`.
- **Main API**: `height`, `thickness`, `indent`, `endIndent`, `color`.
- **Typical usage**: Separators inside sheets, groups, lists, and section boundaries.
- **Tokens/theme**: Uses `componentTokens.divider` and `colorScheme.outlineVariant`.
- **RTL/LTR**: Supports directional layout through Flutter divider indents.
- **Accessibility**: Decorative by default, like `Divider`.
- **Known limitations**: None identified.
- **Recommended usage / avoid usage**: Prefer over raw `Divider` when using design-system surfaces.

### `TilawaEmptyState`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_empty_state.dart`
- **Purpose**: Generic centered empty-state with icon, title, optional subtitle, and optional action.
- **Main API**: `icon`, `title`, `subtitle`, `action`, `iconColor`.
- **Typical usage**: Empty lists, missing content, search with no results.
- **Tokens/theme**: Uses `componentTokens.emptyState`, `TextTheme`, and `ColorScheme`.
- **RTL/LTR**: Text alignment is centered and works for Arabic/English.
- **Accessibility**: Text is exposed naturally; no wrapper semantics.
- **Known limitations**: Caller must provide localized copy and accessible action widgets.
- **Recommended usage / avoid usage**: Use for feature-agnostic empty states. Avoid hardcoding feature-specific empty states into UI Kit.

### `TilawaErrorState`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_error_state.dart`
- **Purpose**: Generic error-state with icon, title, optional subtitle, and optional retry button.
- **Main API**: `icon`, `title`, `subtitle`, `retryLabel`, `onRetry`, `iconColor`.
- **Typical usage**: Failed content loads, retryable screen states.
- **Tokens/theme**: Uses `componentTokens.errorState`, `TextTheme`, and `ColorScheme`.
- **RTL/LTR**: Centered text works for both directions.
- **Accessibility**: Text and `ElevatedButton` semantics come from Flutter.
- **Known limitations**: Retry button uses local `ElevatedButton.styleFrom`; could be aligned with `TilawaButton`.
- **Recommended usage / avoid usage**: Use for generic retry states. Avoid embedding feature-specific error recovery logic.

### `TilawaIconBox`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_icon_box.dart`
- **Purpose**: Standard background container for an icon or custom child.
- **Main API**: `icon`, `size`, `backgroundColor`, `iconColor`, `borderRadius`, `padding`, `child`.
- **Typical usage**: Leading icons in tiles, section headers, compact visual accents.
- **Tokens/theme**: Uses `componentTokens.iconBox` and `ColorScheme`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Icon semantics depend on caller and child; decorative icons should remain semantic-neutral.
- **Known limitations**: Requires an `icon` even when `child` is provided.
- **Recommended usage / avoid usage**: Use for reusable icon containers. Avoid feature-only icon badges with business state unless composed outside the kit.

### `TilawaIconToggle`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_icon_toggle.dart`
- **Purpose**: Boolean icon toggle with distinct active/inactive icons and surfaces.
- **Main API**: `icon`, `activeIcon`, `value`, `onChanged`, optional size/color/radius overrides, `semanticLabel`.
- **Typical usage**: Compact binary controls such as favorite, bookmark, alert enabled, or visibility toggles.
- **Tokens/theme**: Uses `componentTokens.iconToggle`, `ColorScheme`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Wraps itself with `Semantics(button: true, toggled: value)`.
- **Known limitations**: Does not expose disabled state; `onChanged` is required.
- **Recommended usage / avoid usage**: Use for intentional binary controls. Avoid when a text label is required for clarity; use a tile or switch row.

### `TilawaLoadingIndicator`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_loading_indicator.dart`
- **Purpose**: Token-backed circular progress indicator with centered or inline mode.
- **Main API**: `centered`, `strokeWidth`, `color`, `semanticsLabel`, `value`, `backgroundColor`, `valueColor`, `strokeCap`.
- **Typical usage**: Loading states, inline spinners, determinate progress rings.
- **Tokens/theme**: Uses `componentTokens.loadingIndicator`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Supports `semanticsLabel`; determinate value semantics come from `CircularProgressIndicator`.
- **Known limitations**: Animated visual coverage is deferred in existing spec notes due to golden stability risk.
- **Recommended usage / avoid usage**: Prefer over raw progress indicators for consistent stroke and centering behavior.

### `TilawaSectionTitle`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_section_title.dart`
- **Purpose**: Small section heading using theme typography and tokenized weight.
- **Main API**: `title`, `color`, `fontWeight`.
- **Typical usage**: Settings sections, grouped forms, dashboard labels.
- **Tokens/theme**: Uses `componentTokens.sectionTitle` and `TextTheme.titleSmall`.
- **RTL/LTR**: Text follows ambient direction.
- **Accessibility**: Plain text; no heading semantics.
- **Known limitations**: No semantic heading role. Needs confirmation whether app screen readers require explicit heading semantics.
- **Recommended usage / avoid usage**: Use for simple reusable section labels. Avoid custom hardcoded text styles for equivalent headings.

### `TilawaSheetHandle`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_sheet_handle.dart`
- **Purpose**: Centralized bottom sheet drag handle.
- **Main API**: `showHandle`, `width`, `height`, `margin`, `color`.
- **Typical usage**: First visual element in modal bottom sheets and draggable sheets.
- **Tokens/theme**: Uses `componentTokens.sheetHandle` and `ColorScheme.onSurface`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Decorative visual indicator; no semantics.
- **Known limitations**: No built-in bottom sheet scaffold yet, though `TilawaBottomSheetScaffoldTokens` exists.
- **Recommended usage / avoid usage**: Use instead of `showDragHandle` or local handle widgets. Avoid duplicating handle dimensions in app features.

### `TilawaTextField`

- **Level**: Atom
- **Path**: `packages/ui_kit/lib/src/atoms/tilawa_text_field.dart`
- **Purpose**: Design-system `TextFormField` wrapper with labels, helper/error text, password toggle, clear action, validation, and character limit support.
- **Main API**: `label`, `hintText`, `helperText`, `errorText`, `controller`, `focusNode`, `enabled`, `readOnly`, `isPassword`, `onClear`, `prefixIcon`, `suffixIcon`, keyboard/action/line callbacks, `validator`, `semanticLabel`, `autofocus`, `initialValue`, `maxLength`, `showCounter`.
- **Typical usage**: Forms, auth, settings input, search alternatives where full form validation is needed.
- **Tokens/theme**: Uses `TilawaDesignTokens`, `InputDecoration`, `TextTheme`, and `ColorScheme`.
- **RTL/LTR**: Relies on Flutter text field direction and caller-provided locale/direction.
- **Accessibility**: Supports `semanticLabel`; Flutter text field exposes input semantics.
- **Known limitations**: Some visual values may still be inside the widget rather than component-tokenized.
- **Recommended usage / avoid usage**: Use for form input. Avoid for lightweight search; use `TilawaSearchField`.

### `HiddenThumbComponentShape`

- **Level**: Atom utility
- **Path**: `packages/ui_kit/lib/src/atoms/hidden_thumb_shape.dart`
- **Purpose**: Slider thumb shape that paints nothing and reports zero size.
- **Main API**: Extends `SliderComponentShape`.
- **Typical usage**: Internal utility for `SeekBar` buffered track and disabled/no-duration slider states.
- **Tokens/theme**: None.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Used under `ExcludeSemantics` for decorative slider layers.
- **Known limitations**: Low-level utility rather than a user-facing atom.
- **Recommended usage / avoid usage**: Use only for slider composition. Avoid using directly in feature code unless building a UI Kit slider primitive.

## Molecules

### `ArabicAlphabetScrollbar`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/alphabet_scrollbar.dart`
- **Purpose**: Vertical Arabic letter index with tap, pan, long-press, haptics, overlay preview, and auto-scroll behavior.
- **Main API**: `letters`, `selectedLetter`, `onLetterSelected`, pan callbacks, optional long-press callbacks.
- **Typical usage**: Arabic-heavy indexed lists such as reciters or Quran-related lists.
- **Tokens/theme**: Uses `componentTokens.alphabetScrollbar`, `TilawaDesignTokens`, `ColorScheme`, `OverlayPortal`.
- **RTL/LTR**: Overlay positioning detects left/right screen placement; content is Arabic-specific.
- **Accessibility**: Needs confirmation; individual letter items and gesture overlay may need stronger semantics.
- **Known limitations**: Contains `debugPrint` and direct haptics; interactive/golden coverage is deferred in existing spec notes.
- **Recommended usage / avoid usage**: Use for Arabic alphabet index lists. Avoid for generic Latin A-Z lists without confirming behavior and copy.

### `LanguageSwitcher`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/language_switcher.dart`
- **Purpose**: Compact language toggle built as a segmented row.
- **Main API**: `currentLanguage`, `onLanguageChanged`, `languages`, `getLanguageName`.
- **Typical usage**: Language preference controls.
- **Tokens/theme**: Uses `componentTokens.segmentedControl`, `ColorScheme`.
- **RTL/LTR**: Explicitly sets `Row.textDirection` to LTR so language order is stable; RTL scenario was intentionally excluded from previous golden scope.
- **Accessibility**: Uses `GestureDetector` without explicit button/selected semantics.
- **Known limitations**: Overlaps conceptually with `TilawaSegmentedControl`; accessibility could be improved.
- **Recommended usage / avoid usage**: Use for app language switching if stable order is desired. Prefer `TilawaSegmentedControl` for generic segmented choices.

### `MetadataChip`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/metadata_chip.dart`
- **Purpose**: Compact non-selected metadata badge built on `TilawaChip`.
- **Main API**: `label`, optional `icon`, `foregroundColor`, `backgroundColor`, `borderColor`.
- **Typical usage**: Duration, count, category, status metadata.
- **Tokens/theme**: Uses `componentTokens.chip`, `TilawaDesignTokens`, `ColorScheme`.
- **RTL/LTR**: Text follows ambient direction.
- **Accessibility**: Text/icon semantics depend on chip content; no wrapper semantics.
- **Known limitations**: Overlaps with `TilawaStatusChip`; choose based on meaning.
- **Recommended usage / avoid usage**: Use for informational metadata. Avoid for actionable or selected filters.

### `SeekBar`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/seek_bar.dart`
- **Purpose**: Media seek bar with current progress, buffered progress, dragging state, and duration callbacks.
- **Main API**: `duration`, `position`, `bufferedPosition`, color overrides, `onChanged`, `onChangeEnd`.
- **Typical usage**: Audio/media player progress controls.
- **Tokens/theme**: Uses `componentTokens.seekBar`, `HiddenThumbComponentShape`, `SliderTheme`.
- **RTL/LTR**: Inherits Flutter `Slider` direction behavior.
- **Accessibility**: Current progress slider keeps semantics; buffered slider is excluded from semantics.
- **Known limitations**: Media-specific; no visible time labels built in.
- **Recommended usage / avoid usage**: Use for media scrubbing. Avoid for generic numeric input sliders.

### `SelectionPill`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/selection_pill.dart`
- **Purpose**: Selected/unselected pill chip built on `TilawaChip`.
- **Main API**: `label`, `selected`, optional `icon`, `onTap`, selected/unselected color overrides.
- **Typical usage**: Filter chips, category selectors, compact mutually inclusive/exclusive choices.
- **Tokens/theme**: Uses `componentTokens.chip`, `TilawaDesignTokens`, `ColorScheme`.
- **RTL/LTR**: Text and icon flow through `TilawaChip`.
- **Accessibility**: No explicit selected/toggled semantics.
- **Known limitations**: Accessibility selection state should be added if used as a control.
- **Recommended usage / avoid usage**: Use for selection/filter pills. Avoid for passive metadata; use `MetadataChip` or `TilawaStatusChip`.

### `TilawaChip`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_chip.dart`
- **Purpose**: Base chip primitive with optional icon, tap, border, shadow, padding, radius, and text style overrides.
- **Main API**: `label`, `icon`, `onTap`, colors, `padding`, `borderRadius`, `iconSize`, `textStyle`, `showShadow`, `shadowColor`.
- **Typical usage**: Base for specialized chips or simple reusable badges.
- **Tokens/theme**: Uses `componentTokens.chip`, `TilawaDesignTokens`, `TextTheme`.
- **RTL/LTR**: `Row` follows ambient direction.
- **Accessibility**: If tappable, `InkWell` provides tap semantics but no explicit label beyond child text.
- **Known limitations**: Flexible override surface can allow visual drift.
- **Recommended usage / avoid usage**: Prefer specialized chip variants when they fit. Use raw `TilawaChip` for simple feature-agnostic badges.

### `TilawaCountProgressRing`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_count_progress_ring.dart`
- **Purpose**: Circular count/progress indicator with done state, animation, and optional progress label.
- **Main API**: `currentCount`, `totalCount`, `isDone`, `doneIcon`, color overrides, `showProgressLabel`.
- **Typical usage**: Multi-step flows, generation progress, completion counters.
- **Tokens/theme**: Uses `componentTokens.countProgressRing`, `TilawaDesignTokens`, `TilawaLoadingIndicator`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Needs confirmation; animated visual count may need an explicit semantics label.
- **Known limitations**: Animation made it deferred in previous golden scope until later coverage.
- **Recommended usage / avoid usage**: Use for count-based progress. Avoid for arbitrary continuous media progress; use `SeekBar`.

### `TilawaFeedbackStrip`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_feedback_strip.dart`
- **Purpose**: Inline feedback message row with icon or spinner.
- **Main API**: `icon`, `message`, `backgroundColor`, `foregroundColor`, `showSpinner`, optional border/padding/radius.
- **Typical usage**: Status messages, transient inline progress, save/sync feedback.
- **Tokens/theme**: Uses `componentTokens.feedbackStrip` and `TilawaLoadingIndicator`.
- **RTL/LTR**: Row follows ambient direction.
- **Accessibility**: Text is exposed; no live-region semantics.
- **Known limitations**: Caller must choose semantic colors; no built-in success/warning/error variants.
- **Recommended usage / avoid usage**: Use for inline feedback. Avoid for global toasts/snackbars.

### `TilawaGlassPanel`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_glass_panel.dart`
- **Purpose**: Frosted/elevated panel container with optional backdrop blur.
- **Main API**: `child`, `padding`, `borderRadius`, `backgroundColor`, `borderColor`, `enableBackdropBlur`.
- **Typical usage**: Floating overlays, media composer panels, premium surfaces.
- **Tokens/theme**: Uses `componentTokens.glassPanel`, `TilawaDesignTokens`, `ColorScheme`.
- **RTL/LTR**: Child owns direction behavior.
- **Accessibility**: Container only; caller owns semantics.
- **Known limitations**: Backdrop blur is off by default due to render cost.
- **Recommended usage / avoid usage**: Use for floating visual panels. Avoid enabling blur inside high-frequency scrolling or animation unless profiled.

### `TilawaIconActionButton`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_icon_action_button.dart`
- **Purpose**: Icon-only action button with press scale animation and active tint.
- **Main API**: `icon`, `onTap`, `isActive`, optional `size`, `iconSize`.
- **Typical usage**: Toolbar actions, media controls, compact repeated actions.
- **Tokens/theme**: Uses `componentTokens.iconActionButton`, `TilawaDesignTokens`, `ColorScheme`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Needs confirmation; no explicit semantic label parameter.
- **Known limitations**: Required `onTap`; no disabled state or semantic label.
- **Recommended usage / avoid usage**: Use for recognizable icon actions when surrounding context is clear. Avoid for critical actions without labels or semantics.

### `TilawaPermissionBanner`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_permission_banner.dart`
- **Purpose**: Inline permission/capability banner with icon, message, and single trailing CTA.
- **Main API**: `message`, `actionLabel`, `onAction`, optional `icon`, colors, padding, radius.
- **Typical usage**: Notification permission prompts, capability warnings, settings entry points.
- **Tokens/theme**: Uses `componentTokens.permissionBanner`, `ColorScheme.tertiaryContainer`.
- **RTL/LTR**: Row follows ambient direction.
- **Accessibility**: Text and `TextButton` semantics are exposed.
- **Known limitations**: CTA uses shrink-wrapped tap target; verify minimum target where used.
- **Recommended usage / avoid usage**: Use for one-action inline remediation. Avoid for complex permission education flows.

### `TilawaSearchField`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_search_field.dart`
- **Purpose**: Search-specific input with prefix icon, optional clear action, focus/listenable rebuilds, shadow, and tokenized container styling.
- **Main API**: `hintText`, optional controller/focus/callbacks, icons, `margin`, `height`, input action, scroll padding, colors, styles, enabled state, `onTapOutside`.
- **Typical usage**: Search bars in pickers, lists, and bottom sheets.
- **Tokens/theme**: Uses `componentTokens.searchField`, `ColorScheme`, `TextTheme`.
- **RTL/LTR**: Text field follows ambient direction.
- **Accessibility**: Flutter input semantics apply; hint text should be localized.
- **Known limitations**: No explicit semantic label beyond hint/field semantics.
- **Recommended usage / avoid usage**: Use for search. Avoid using it as a generic form field.

### `TilawaSegmentedControl<T>` And `TilawaSegment<T>`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_segmented_control.dart`
- **Purpose**: Generic segmented control for 2-5 mutually exclusive options.
- **Main API**: `segments`, `selectedValue`, `onValueChanged`, optional background/selected/text colors; helper `TilawaSegment<T>(value, label)`.
- **Typical usage**: Display mode, filter mode, theme mode, compact option switching.
- **Tokens/theme**: Uses `componentTokens.segmentedControl`, `ColorScheme`, `TextTheme`.
- **RTL/LTR**: Row follows ambient direction.
- **Accessibility**: Uses tappable segments but no explicit selected semantics.
- **Known limitations**: No disabled segments; no semantic selected role.
- **Recommended usage / avoid usage**: Use for generic segmented choices. Avoid for language switching if stable LTR language order is required; current `LanguageSwitcher` handles that separately.

### `TilawaSelectionTile`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_selection_tile.dart`
- **Purpose**: Bottom-sheet/dialog option row with optional leading widget and selected checkmark.
- **Main API**: `title`, `leading`, `isSelected`, `onTap`, `showDivider`.
- **Typical usage**: Pickers, modal selection sheets, single-choice lists.
- **Tokens/theme**: Uses `componentTokens.settingsGroup`, `ColorScheme`.
- **RTL/LTR**: Row follows ambient direction.
- **Accessibility**: Tappable row semantics from `InkWell`; selected state is visual only.
- **Known limitations**: No subtitle/trailing custom action; no explicit selected semantics.
- **Recommended usage / avoid usage**: Use for simple single-choice lists. Avoid for complex settings rows; use `TilawaSettingsTile`.

### `TilawaSettingsTile`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_settings_tile.dart`
- **Purpose**: Settings navigation row with leading icon, title, optional subtitle, divider, and trailing widget/chevron.
- **Main API**: `icon`, `title`, `onTap`, optional `iconColor`, `subtitle`, `showDivider`, `borderRadius`, `trailing`.
- **Typical usage**: Settings pages and grouped settings sections.
- **Tokens/theme**: Uses `componentTokens.settingsGroup`, `ColorScheme`.
- **RTL/LTR**: Row follows ambient direction, but trailing chevron currently uses `FluentIcons.chevron_right_24_filled`.
- **Accessibility**: Tappable row semantics from `InkWell`; caller copy is exposed.
- **Known limitations**: Chevron may not mirror automatically in RTL. Needs confirmation in Arabic settings screens.
- **Recommended usage / avoid usage**: Use for navigational settings rows. Avoid for switches; use `TilawaSettingsSwitchTile`.

### `TilawaSettingsSwitchTile`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_settings_tile.dart`
- **Purpose**: Settings row with leading icon, title/subtitle, and switch control.
- **Main API**: `icon`, `title`, `value`, `onChanged`, optional `iconColor`, `subtitle`, `showDivider`, `borderRadius`.
- **Typical usage**: Boolean settings inside `TilawaSettingsGroup`.
- **Tokens/theme**: Uses `componentTokens.settingsGroup`, `ColorScheme`, Flutter `Switch`.
- **RTL/LTR**: Row follows ambient direction.
- **Accessibility**: Switch exposes toggle semantics; row also toggles on tap.
- **Known limitations**: No disabled state.
- **Recommended usage / avoid usage**: Use for boolean settings. Avoid for multi-state settings; use a picker or segmented control.

### `TilawaStatusChip`

- **Level**: Molecule
- **Path**: `packages/ui_kit/lib/src/molecules/tilawa_status_chip.dart`
- **Purpose**: Compact status badge built on `TilawaChip`.
- **Main API**: `label`, optional `backgroundColor`, `foregroundColor`, `icon`, `padding`.
- **Typical usage**: Alert status, download status, active/inactive labels.
- **Tokens/theme**: Uses `componentTokens.chip`, `ColorScheme`.
- **RTL/LTR**: Inherits `TilawaChip` behavior.
- **Accessibility**: Text exposed; feature wrappers can add `Semantics` for richer labels.
- **Known limitations**: No predefined status variants.
- **Recommended usage / avoid usage**: Use for passive state labels. Avoid as a toggle/control.

## Organisms

### `ImmersiveComposerScaffold`

- **Level**: Organism, template-like
- **Path**: `packages/ui_kit/lib/src/organisms/immersive_composer_scaffold.dart`
- **Purpose**: Full-bleed composer scaffold with preview, top app bar overlay, bottom panel overlay, optional background, optional FAB, visibility toggling, and blur control.
- **Main API**: `title`, `preview`, `bottomPanel`, optional `subtitle`, close/leading/trailing widgets, `background`, `backgroundGradient`, `floatingActionButton`, controlled `overlaysVisible`, `onVisibilityChanged`, `disableBlur`, `backgroundIntent`.
- **Typical usage**: Share/video composer and immersive preview flows.
- **Tokens/theme**: Uses `componentTokens.immersiveComposer`, `TilawaDesignTokens`, `TilawaSafeAreaX`, `ColorScheme`, `SystemUiOverlayStyle`.
- **RTL/LTR**: Uses directional-safe areas and regular Flutter text layout; needs feature QA in Arabic.
- **Accessibility**: Overlay buttons use Flutter controls; preview tap toggles overlays and may need clear semantics per feature.
- **Known limitations**: Template-like scope, animation/blur complexity, and system UI behavior make it heavier than most organisms.
- **Recommended usage / avoid usage**: Use for full-screen composer flows. Avoid for ordinary screens or sheets.

### `TilawaAdaptiveShell`

- **Level**: Organism, template-like
- **Path**: `packages/ui_kit/lib/src/organisms/tilawa_adaptive_shell.dart`
- **Purpose**: Responsive app shell that switches between **phone** bottom navigation (narrow window class) and medium/expanded side navigation rail while hosting content and bottom player.
- **Main API**: `destinations`, `selectedIndex`, `onDestinationSelected`, `child`, `bottomPlayer`, optional bottom bar padding/decoration, `avoidDisplayFeatures`; helper `TilawaNavDestination`.
- **Typical usage**: Main app shell.
- **Tokens/theme**: Uses `componentTokens.adaptiveShell`, `TilawaDesignTokens`, breakpoints, content bounds, display feature insets, safe-area extensions.
- **RTL/LTR**: Handles RTL by changing rail side and display-feature padding direction.
- **Accessibility**: Destinations support optional `Semantics.identifier`; nav buttons expose labels and selected state internally.
- **Known limitations**: App-shell responsibility makes it a candidate for a future Templates layer.
- **Recommended usage / avoid usage**: Use for app-wide navigation chrome. Avoid embedding feature-specific navigation or business logic.

### `TilawaBackdropImageLayer`

- **Level**: Organism
- **Path**: `packages/ui_kit/lib/src/organisms/tilawa_player_background_layer.dart`
- **Purpose**: Full-size backdrop image with cache resizing, optional blur, and overlay tint.
- **Main API**: `image`, `blurAmount`, `overlayOpacity`, `overlayColor`, `fit`.
- **Typical usage**: Player background and immersive media surfaces.
- **Tokens/theme**: Uses `componentTokens.playerBackground` and `MediaQuery`.
- **RTL/LTR**: Direction-neutral.
- **Accessibility**: Decorative background; no semantics.
- **Known limitations**: Player naming is feature-adjacent; should remain UI-only and avoid audio/player dependencies.
- **Recommended usage / avoid usage**: Use for decorative image backdrops. Avoid for meaningful images that need alt text.

### `TilawaMediaPlayerBar`

- **Level**: Organism
- **Path**: `packages/ui_kit/lib/src/organisms/tilawa_media_player_bar.dart`
- **Purpose**: UI-only bottom media player bar with artwork, title/subtitle, progress, playback controls, sleep timer, tap, and close.
- **Main API**: `title`, `subtitle`, `artwork`, `progress`, `progressBarOverride`, playback booleans, sleep timer booleans, action callbacks.
- **Typical usage**: App-level mini player preview or UI kit previews without BLoC dependencies.
- **Tokens/theme**: Uses `componentTokens.mediaPlayerBar`, `TilawaDesignTokens`, `ColorScheme`.
- **RTL/LTR**: Row follows ambient direction; media control order needs Arabic QA.
- **Accessibility**: Icon controls rely on underlying buttons; labels need confirmation.
- **Known limitations**: UI-only but media-specific; should not import app audio state.
- **Recommended usage / avoid usage**: Use as a reusable media player surface. Avoid coupling it to app services or BLoC.

### `TilawaSettingsGroup`

- **Level**: Organism
- **Path**: `packages/ui_kit/lib/src/organisms/tilawa_settings_group.dart`
- **Purpose**: Settings section wrapper with title and grouped child rows.
- **Main API**: `title`, `children`.
- **Typical usage**: Settings screens containing `TilawaSettingsTile`, `TilawaSettingsSwitchTile`, or compatible rows.
- **Tokens/theme**: Uses `componentTokens.settingsGroup`, `ColorScheme`.
- **RTL/LTR**: Column and text follow ambient direction.
- **Accessibility**: Title is plain text; no explicit section/heading semantics.
- **Known limitations**: Does not manage row border radius for first/last children.
- **Recommended usage / avoid usage**: Use for settings groups. Avoid adding feature-specific settings logic inside it.

### `TilawaShareFooterBar`

- **Level**: Organism
- **Path**: `packages/ui_kit/lib/src/organisms/tilawa_share_footer_bar.dart`
- **Purpose**: Fixed-height footer label bar for share output surfaces.
- **Main API**: `primaryLabel`, `secondaryLabel`, optional background/foreground colors.
- **Typical usage**: Share graphics/footer branding.
- **Tokens/theme**: Uses `componentTokens.footerBar`, `ColorScheme`, `TextTheme`.
- **RTL/LTR**: Primary label is forced `TextDirection.rtl`; secondary label is right-aligned.
- **Accessibility**: Text is exposed; intended mostly for rendered visual output.
- **Known limitations**: RTL forcing makes it Quran/share-specific. Needs confirmation whether this should stay in UI Kit or remain share-feature scoped.
- **Recommended usage / avoid usage**: Use for share artifacts that need Arabic primary text. Avoid for generic app footers.

## Templates

There is no exported `templates` layer today. Candidate future templates:

- `TilawaAdaptiveShell`: app shell template candidate.
- `ImmersiveComposerScaffold`: immersive composer template candidate.
- A future bottom sheet scaffold could wrap `TilawaSheetHandle`, surface radius, safe area, max height, and padding using existing `TilawaBottomSheetScaffoldTokens`.

Until a templates layer exists, do not create one-off page scaffolds in UI Kit unless at least two features share the same layout contract and the API can remain feature-agnostic.

## Foundation

### `AppColors`

- **Path**: `packages/ui_kit/lib/src/foundation/app_colors.dart`
- **Purpose**: Central color constants and named design roles.
- **Includes**: Primary presets, brand secondary/tertiary, light/dark surfaces, outline roles, theme refinement colors, true-black dark roles, status colors, settings category colors, and Quran-related colors.
- **Usage rule**: Add colors only for reusable semantic roles. Feature-only colors should first be expressed through `ColorScheme` or feature-scoped presentation mapping.

### `AppTheme`

- **Path**: `packages/ui_kit/lib/src/foundation/app_theme.dart`
- **Purpose**: Central light/dark theme factory.
- **Key APIs**: `AppTheme.getLightTheme(...)`, `AppTheme.getDarkTheme(...)`, `AppTheme.useGoogleFonts`.
- **Responsibilities**: Build FlexColorScheme themes, refine surfaces, configure typography, install `TilawaDesignTokens` and `TilawaComponentTokens`.
- **Usage rule**: App theme changes must be reviewed as system-wide changes and validated in light/dark modes.

### `TilawaDesignTokens`

- **Path**: `packages/ui_kit/lib/src/foundation/design_tokens.dart`
- **Purpose**: Global theme extension for reusable design values.
- **Includes**: Spacing, radii, opacity, blur, shadow offsets, border width, progress height, icon sizes, text height, durations, content max widths, player thresholds, `copyWith`, `lerp`, and `ThemeData.tokens` extension.
- **Usage rule**: Use these tokens for cross-component spacing/sizing before adding component-specific values.

### `TilawaComponentTokens`

- **Path**: `packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart`
- **Purpose**: Theme extension that groups component-family tokens.
- **Key APIs**: `TilawaComponentTokens.light(...)`, `TilawaComponentTokens.dark(...)`, `copyWith`, `lerp`, and `ThemeData.componentTokens` extension.
- **Usage rule**: Add component tokens when a reusable UI Kit component needs stable dimensions, opacity, sizing, or colors beyond global design tokens.

### Component Token Groups

Atoms token file:

- `packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart`
- Groups: `TilawaSectionTitleTokens`, `TilawaSheetHandleTokens`, `TilawaCardTokens`, `TilawaIconBoxTokens`, `TilawaLoadingIndicatorTokens`, `TilawaIconToggleTokens`, `TilawaDividerTokens`, `TilawaEmptyStateTokens`, `TilawaErrorStateTokens`.

Molecules token file:

- `packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart`
- Groups: `TilawaAlphabetScrollbarTokens`, `TilawaFeedbackStripTokens`, `TilawaGlassPanelTokens`, `TilawaIconActionButtonTokens`, `TilawaChipTokens`, `TilawaSegmentedControlTokens`, `TilawaSeekBarTokens`, `TilawaSearchFieldTokens`, `TilawaCountProgressRingTokens`, `TilawaPermissionBannerTokens`, `TilawaPrayerAlertRowTokens`.

Organisms token file:

- `packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart`
- Groups: `TilawaPlayerBackgroundTokens`, `TilawaFooterBarTokens`, `TilawaMediaPlayerBarTokens`, `TilawaAdaptiveShellTokens`, `TilawaSettingsGroupTokens`, `TilawaImmersiveComposerTokens`, `TilawaBottomSheetScaffoldTokens`.

Token helpers:

- `packages/ui_kit/lib/src/foundation/component_tokens/token_lerp.dart`

Foundation layout and extension utilities:

- `TilawaBreakpoints`, `TilawaWindowSize`, `TilawaWindowSizeX`
- `TilawaContentBounds`, `TilawaContentKind`
- `TilawaContentGrid`
- `TilawaDensity`
- `DisplayFeatureInsets`
- `TilawaResponsiveTypography`
- `TilawaSafeAreaX`
- `TilawaSettingsScreenTokens`
- `TilawaShellPadding`
- `ColorSchemeExtension`
- `TextThemeExtension`

### Color, Spacing, Radius, And Typography Rules

- Use `ColorScheme` for Material roles first.
- Use `AppColors` only for named cross-app colors that cannot be expressed by `ColorScheme`.
- Use `theme.tokens` for global spacing, radius, opacity, shadow, icon size, duration, and content width.
- Use `theme.componentTokens` for component-specific sizing and surface details.
- Use `Theme.of(context).textTheme` or `context.responsiveTextTheme` for typography.
- Do not add hardcoded spacing/radius/color values to reusable UI Kit widgets when a token exists.

## Usage Rules

- Use an existing UI Kit component when the UI need matches its purpose and API.
- Compose feature UI from UI Kit atoms/molecules before creating a new reusable component.
- Create a feature-only widget when copy, layout, state mapping, or behavior is feature-specific.
- Promote a feature widget to UI Kit only after at least two features need the same visual contract and the API can be feature-agnostic.
- Do not add business logic, BLoC, repositories, services, localizations, routing, or app feature dependencies to UI Kit.
- Do not add one-off widgets to UI Kit for a single screen.
- Do not duplicate existing atoms such as sheet handles, cards, dividers, loading indicators, chips, or settings rows.
- Preserve RTL/LTR behavior. Use directional padding/alignment where layout mirrors by locale.
- Preserve accessibility. Interactive components should expose labels, selected/toggled states, disabled states, and minimum tap targets where applicable.
- Prefer immutable widgets and explicit constructor dependencies.
- Keep UI Kit components UI-only; callers own state, side effects, analytics, permission requests, and scheduling.

## Contribution Guidelines

### Checklist Before Adding A Component

- Confirm no existing component can satisfy the need through composition.
- Confirm the component is feature-agnostic and reusable.
- Pick the smallest correct Atomic Design level.
- Define a focused API with no business-specific props.
- Use `ThemeData`, `ColorScheme`, `TilawaDesignTokens`, and `TilawaComponentTokens`.
- Add component tokens if the component introduces reusable sizing, spacing, or color roles.
- Confirm RTL/LTR behavior.
- Confirm accessibility semantics, tap target size, and text scaling behavior.
- Export the component from the correct barrel only after review.
- Add or update previews and tests when applicable.

### Tests And Previews

- Add widget tests for behavior, states, callbacks, assertions, and accessibility where meaningful.
- Add golden coverage for stable visual components.
- Avoid golden coverage for highly animated or overlay-heavy components unless stabilized.
- Add preview scenarios for default, dark, RTL where relevant, and representative states.
- Keep generated golden failure artifacts out of commits.

### Naming

- Public reusable widgets should use the `Tilawa` prefix unless they are already established (`MetadataChip`, `SelectionPill`, `SeekBar`, `LanguageSwitcher`, `ArabicAlphabetScrollbar`).
- Files should use `snake_case`.
- Component token classes should match the component family name and end with `Tokens`.
- Feature-specific naming should stay outside UI Kit.

### Good Additions

- A generic bottom sheet scaffold that centralizes handle, radius, safe area, max height, and padding because multiple sheets use that pattern.
- A generic status/feedback component that accepts caller-provided copy and semantic role without feature dependencies.
- A generic layout primitive backed by tokens and tested across window sizes.

### Bad Additions

- A Prayer Times row with prayer-specific alert rules inside UI Kit.
- A component that imports app BLoCs, routes, repositories, services, l10n, or feature entities.
- A duplicate card/chip/sheet handle with slightly different dimensions.
- A one-screen widget moved to UI Kit before another feature needs it.

## Gaps And Backlog

- **Docs**: `packages/ui_kit/README.md` documents only a subset of atoms and should link to this inventory after review.
- **Templates**: No templates layer exists. `TilawaAdaptiveShell` and `ImmersiveComposerScaffold` are template-like organisms and may need reclassification later.
- **Bottom sheets**: `TilawaSheetHandle` is centralized, and `TilawaBottomSheetScaffoldTokens` exists, but there is no public bottom sheet scaffold component yet.
- **Tokenization**: `TilawaButton` and `TilawaTextField` still appear to keep some sizing/styling decisions inside the widget. Consider component-tokenizing if those values need reuse or density support.
- **Accessibility**: `TilawaIconActionButton`, `SelectionPill`, `TilawaSegmentedControl`, `TilawaSelectionTile`, `LanguageSwitcher`, and `TilawaCountProgressRing` may need explicit semantics for labels, selected/toggled states, or progress values.
- **RTL**: `TilawaSettingsTile` uses a right chevron that may not mirror in RTL. `LanguageSwitcher` intentionally forces LTR order. `TilawaShareFooterBar` forces the primary label to RTL and may be share/Quran-specific rather than generic.
- **Duplication pressure**: `TilawaChip`, `MetadataChip`, `SelectionPill`, and `TilawaStatusChip` overlap by design. Developers should choose by meaning: base chip, metadata, selection, or passive status.
- **Feature-specific risk**: `TilawaShareFooterBar` and `TilawaBackdropImageLayer` are UI-only but feature-adjacent. Keep them free of app dependencies or move feature-specific variants back to feature modules.
- **Debug/side effects**: `ArabicAlphabetScrollbar` contains direct haptics and debug output; review whether these belong in UI Kit or should be configurable.
- **Unused/missing component relation**: `TilawaPrayerAlertRowTokens` exists in molecule tokens but no public `TilawaPrayerAlertRow` component is exported. Needs confirmation before adding or removing tokens.

## Files Inspected

- `packages/ui_kit/README.md`
- `packages/ui_kit/lib/tilawa_ui_kit.dart`
- `packages/ui_kit/lib/src/atoms/atoms.dart`
- `packages/ui_kit/lib/src/atoms/hidden_thumb_shape.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_button.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_card.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_divider.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_empty_state.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_error_state.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_icon_box.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_icon_toggle.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_loading_indicator.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_section_title.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_sheet_handle.dart`
- `packages/ui_kit/lib/src/atoms/tilawa_text_field.dart`
- `packages/ui_kit/lib/src/molecules/molecules.dart`
- `packages/ui_kit/lib/src/molecules/alphabet_scrollbar.dart`
- `packages/ui_kit/lib/src/molecules/language_switcher.dart`
- `packages/ui_kit/lib/src/molecules/metadata_chip.dart`
- `packages/ui_kit/lib/src/molecules/seek_bar.dart`
- `packages/ui_kit/lib/src/molecules/selection_pill.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_chip.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_count_progress_ring.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_feedback_strip.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_glass_panel.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_icon_action_button.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_permission_banner.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_search_field.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_segmented_control.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_selection_tile.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_settings_tile.dart`
- `packages/ui_kit/lib/src/molecules/tilawa_status_chip.dart`
- `packages/ui_kit/lib/src/organisms/organisms.dart`
- `packages/ui_kit/lib/src/organisms/immersive_composer_scaffold.dart`
- `packages/ui_kit/lib/src/organisms/tilawa_adaptive_shell.dart`
- `packages/ui_kit/lib/src/organisms/tilawa_media_player_bar.dart`
- `packages/ui_kit/lib/src/organisms/tilawa_player_background_layer.dart`
- `packages/ui_kit/lib/src/organisms/tilawa_settings_group.dart`
- `packages/ui_kit/lib/src/organisms/tilawa_share_footer_bar.dart`
- `packages/ui_kit/lib/src/foundation/foundation.dart`
- `packages/ui_kit/lib/src/foundation/app_colors.dart`
- `packages/ui_kit/lib/src/foundation/app_theme.dart`
- `packages/ui_kit/lib/src/foundation/breakpoints.dart`
- `packages/ui_kit/lib/src/foundation/color_scheme_ext.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens/atoms_tokens.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens/component_tokens_theme.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens/molecules_tokens.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens/organisms_tokens.dart`
- `packages/ui_kit/lib/src/foundation/component_tokens/token_lerp.dart`
- `packages/ui_kit/lib/src/foundation/content_bounds.dart`
- `packages/ui_kit/lib/src/foundation/content_grid.dart`
- `packages/ui_kit/lib/src/foundation/density.dart`
- `packages/ui_kit/lib/src/foundation/design_tokens.dart`
- `packages/ui_kit/lib/src/foundation/display_feature_insets.dart`
- `packages/ui_kit/lib/src/foundation/responsive_typography.dart`
- `packages/ui_kit/lib/src/foundation/safe_area_ext.dart`
- `packages/ui_kit/lib/src/foundation/settings_screen_tokens.dart`
- `packages/ui_kit/lib/src/foundation/shell_padding.dart`
- `packages/ui_kit/lib/src/foundation/text_theme_ext.dart`
- `specs/006-ui-kit-expansion/spec.md`
- `specs/006-ui-kit-expansion/plan.md`
