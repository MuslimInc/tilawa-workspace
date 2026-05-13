# Migration guide: UI Kit accessibility audit (2026)

## Overview

Tilawa UI Kit was updated to resolve accessibility audit findings (minimum touch targets, semantics for controls and transient content, structured feedback variants) and to align spacing with the **8dp grid** via design and component tokens. **No breaking API removals** were made for the audited widgets; three **deprecated typedefs** remain available from the public barrel so consumers can migrate gradually.

## Deprecated components

| Old name (typedef)   | New name                 | API / behavior notes |
|----------------------|--------------------------|----------------------|
| `LanguageSwitcher`   | `TilawaLanguageSwitcher` | Same constructor parameters. Segments expose clearer `Semantics` (`button`, `selected`). |
| `SelectionPill`      | `TilawaSelectionPill`    | Same constructor parameters. |
| `MetadataChip`       | `TilawaMetadataChip`     | Same constructor parameters. |

Import `package:tilawa_ui_kit/tilawa_ui_kit.dart` and replace the typedef with the `Tilawa*` class name.

## Touch target changes

The following **gained or enforce a higher minimum interactive size** (typically **48×48 logical pixels** or a **48dp-tall** strip). Dense toolbars, player chrome, and stacked icon rows may need **extra horizontal space** or fewer visible actions per row.

- **`TilawaIconToggle`** — `ConstrainedBox` enforces ≥48×48 for the whole control.
- **`TilawaPermissionBanner`** — trailing `TextButton` uses Material minimum tap target behavior.
- **`SeekBar`** — track area height from `touchExtent` token (≥48dp).
- **`TilawaMediaPlayerBar`** — previous / next / sleep `IconButton` regions sized via `controlButtonSize`; play/pause via `playPauseButtonSize` (both ≥48dp in defaults).
- **`TilawaIconActionButton`** — icon-only hit region and semantics label expectations.
- **List-style tokens** — settings-style lists may use **`itemExtent: 48`** (or equivalent) for row height floors; affects **`TilawaSettingsTile`** and similar lists.
- **`ArabicAlphabetScrollbar`** — letter rows follow scrollbar / list **item extent** tokens (taller rows when 48dp is enforced).

**Shell layouts:** bottom bars, mini players, and app bars that assumed **40dp** or icon-only **dense** buttons should be checked for **horizontal overflow** or overlapping gestures after token bumps.

## Semantics additions

These components **emit or relocate `Semantics` / roles** so screen readers and integration tests see clearer trees:

- **`TilawaChip`** — explicit `Semantics(button:)` + label (avoided fragile `MergeSemantics` around the tap target).
- **`TilawaLanguageSwitcher`** / **`TilawaSegmentedControl`** — per-segment `Semantics` (`button`, `selected`, `label`) **inside** the `InkWell` tap target.
- **`TilawaSelectionTile`** — `Semantics(selected:, button:, label:)` on the row.
- **`TilawaFeedbackStrip`** — message wrapped with **`Semantics(liveRegion: true)`** for transient announcements; optional **`variant`** drives default border color (info / warning / error).
- **`TilawaIconActionButton`** / **`TilawaIconToggle`** — labeled / button semantics for icon controls.
- **`TilawaModalBottomSheet`** — optional sheet title and barrier semantics parity with Material patterns.

**Consumer test suites:** tests that assume **no** `SemanticsNode`, old **merge** behavior, or exact **node counts** may need updates after `pumpWidget` / `pumpAndSettle`. Prefer asserting **`flagsCollection`** (or stable `SemanticsProperties`) rather than brittle tree shapes.

## `TilawaButton` label behavior

The label row does **not** use `LayoutBuilder` (intrinsic-safe for golden and table layouts). The label is a single-line `Text` with `TextOverflow.ellipsis`. **Non–full-width** buttons wrap the label in **`Flexible(fit: FlexFit.loose)`** so a **bounded** parent supplies a finite max width and long copy **ellipsize** instead of **`RenderFlex` overflowing**. **`isFullWidth: true`** is unchanged: the label remains in **`Expanded`**.

If you temporarily wrapped **`TilawaButton`** in **`SingleChildScrollView`** only to avoid the pre-fix overflow, you can **remove** that workaround; the component now handles narrow constraints on its own.

See **`CHANGELOG.md` (`### Changed`)** and **`test/atoms/tilawa_button_test.dart`**.

## Settings rows and RTL

`TilawaSettingsGroupTokens` uses **`EdgeInsetsDirectional`** for **`groupHeaderPadding`** and **`tileDividerPadding`** so inset alignment mirrors under RTL. **`ListTile`** rows sit in a **`ConstrainedBox`** with **`minHeight: kMinInteractiveDimension`** so single-line tiles meet the 48dp row floor without changing tokenized padding values. **`TilawaSettingsTile`** keeps a **right-pointing** trailing chevron; **`ListTile`** positions the trailing slot on the correct edge in RTL.
