# Phase 4 Rollout: Adaptive Shell

This document summarizes the implementation of the adaptive navigation shell in Tilawa.

## Files Changed
- `packages/ui_kit/lib/src/organisms/tilawa_adaptive_shell.dart` [NEW]
- `packages/ui_kit/lib/src/organisms/organisms.dart` [MODIFY]
- `apps/tilawa/lib/screens/main_screen.dart` [MODIFY]

## Shell API

### `TilawaAdaptiveShell`
A top-level navigation container that switches between mobile and tablet patterns.

| Property | Type | Description |
| --- | --- | --- |
| `destinations` | `List<TilawaNavDestination>` | List of navigation items (label, icon, svg). |
| `selectedIndex` | `int` | Currently active tab index. |
| `onDestinationSelected` | `ValueChanged<int>` | Callback when a tab is tapped. |
| `child` | `Widget` | The main content area (e.g., `IndexedStack`). |
| `bottomPlayer` | `Widget` | Explicit slot for floating overlays like the mini-player. |
| `avoidDisplayFeatures` | `bool` | Whether to avoid hinges/folds on foldables (default: `true`). |

## Navigation Behavior by Window Class

### Compact (Width < 600)
- **Pattern**: Bottom Navigation Bar.
- **Visuals**: Custom animated bar with SVG/Icon support.
- **Player**: Sits above the navigation bar using `bottomNavBarHeight` padding.

### Medium (600 ≤ Width < 840)
- **Pattern**: Navigation Rail (Icons + Labels).
- **Placement**: Fixed on the start edge (left in LTR, right in RTL).
- **Player**: Bounded by the rail's width. Sits at the bottom of the body area.

### Expanded (Width ≥ 840)
- **Pattern**: Extended Navigation Rail (Icons + Labels side-by-side).
- **Placement**: Fixed on the start edge.
- **Player**: Bounded by the extended rail's width.

## Player & Layout Caveats
- **Bounding**: The `bottomPlayer` slot is placed inside a `Stack` that is itself inside an `Expanded` area (on tablets). This ensures the player never overlaps the navigation rail.
- **Spacing**: The `child` area receives `contentBottomPadding` (nav bar height + player height) to ensure scrollable content isn't obscured.
- **Safe Area**: The shell uses `SafeArea` appropriately. On tablets, the rail extends to the screen edge, while the content respects system insets.

## Foldables Support
- **Display Features**: The shell consumes `MediaQuery.displayFeaturesOf(context)` to detect hinges/folds on foldable devices.
- **Hinge Avoidance**: Added `getHingeAvoidancePadding()` extension that calculates padding to avoid placing the navigation rail over hinge/fold regions.
- **Configurable**: The `avoidDisplayFeatures` parameter (default `true`) allows disabling foldable-aware padding if needed.
- **Row Layout**: The shell uses a `Row`-based layout which naturally respects vertical hinges, with content placed in an `Expanded` region.

## Verification Notes
- **Tab Persistence**: Verified that `selectedIndex` is preserved during breakpoint transitions (e.g., rotation).
- **RTL**: Confirmed that the `Row` and `NavigationRail` flip correctly based on locale direction.
- **Player Placement**: Verified the player stays bounded by the rail on wide displays.
