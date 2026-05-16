# Feature Specification: Tilawa Skeleton Loading

**Feature Branch**: `008-skeleton-loading`  
**Created**: 2026-05-04  
**Status**: Planning  
**Depends On**: UI Kit foundation (tokens, theming)

---

## Context

Loading states in the Tilawa app currently use `TilawaLoadingIndicator` (spinner) for most async operations. While functional, spinners provide no preview of the content shape, causing layout shift and reducing perceived performance. Skeleton loading is a modern UX pattern that displays placeholder shapes matching the final content layout, improving perceived speed and reducing cognitive load.

This feature adds a complete skeleton loading system to the Tilawa UI Kit, starting with foundational components and later expanding to reusable patterns for common screen types.

---

## Problem Statement

1. **Perceived Performance**: Spinners provide no content preview; users wait without knowing what will appear
2. **Layout Shift**: Content popping in after spinner disappears causes visual jarring
3. **Inconsistency**: No standardized placeholder styling across screens
4. **Accessibility**: Pure spinners may not communicate "content loading" well to screen readers

---

## Goals

1. Provide a foundation skeleton component (`TilawaSkeletonBlock`) that matches the app's visual design system
2. Support shimmer animation with reduced motion fallback
3. Enable theme-aware colors (light/dark) and surface hierarchy
4. Create reusable patterns for lists, cards, and common UI structures (Phase S1-C)
5. Gradually replace appropriate spinner loading states in app screens (Phase S1-D)

---

## Non-Goals

1. **Do not** replace all loading indicators globally — spinners remain appropriate for:
   - Unknown content shape (search results, dynamic lists)
   - Blocking operations (authentication, payment)
   - Short operations (< 300ms)
   - Error retry states

2. **Do not** implement app integration in S1-A/S1-B — UI Kit foundation only

3. **Do not** create complex animated skeletons (staggered reveals, wave effects) — keep it simple

4. **Do not** implement skeleton-to-content morph animations — out of scope

---

## User Experience Principles

### When to Use Skeleton vs Loading Indicator

| Scenario | Use Skeleton | Use Loading Indicator |
|----------|--------------|----------------------|
| Predictable layout (list, card grid) | ✅ | ❌ |
| Known content structure (profile, settings) | ✅ | ❌ |
| Unknown/dynamic content | ❌ | ✅ |
| Blocking operation | ❌ | ✅ |
| Error state with retry | ❌ | ✅ |
| Operation < 300ms | ❌ | ✅ (or none) |

### Design Principles

1. **Match the shape**: Skeleton should mirror the final content's approximate layout
2. **Subtle animation**: Shimmer should be gentle, not distracting
3. **Respect motion preferences**: Reduced motion must disable animations
4. **Theme aware**: Colors adapt to light/dark and surface hierarchy
5. **Responsive layouts**: Skeleton patterns may follow narrow vs wide breakpoints where product needs it; there is **no** global comfortable/compact token axis (see [007 supersession](../007-compact-ui-coverage/spec.md))

---

## Accessibility Requirements

### Reduced Motion Behavior

| Setting | Behavior |
|---------|----------|
| `MediaQuery.disableAnimationsOf(context) == true` | Static skeleton, no shimmer |
| `MediaQuery.accessibleNavigationOf(context) == true` | Static skeleton, proper semantics |
| Default | Animated shimmer |

### Screen Reader Support

- Skeleton containers should announce "Loading content" via `Semantics`
- Individual blocks should not be focusable (`excludeFromSemantics: true`)
- Live region announcements when content replaces skeleton

### Visual Accessibility

- Skeleton colors must maintain 3:1 contrast against background
- Do not rely on animation alone to convey loading state
- Static fallback must be visually distinct from empty state

---

## RTL Behavior

- Shimmer direction should follow text direction
- LTR: Shimmer moves left-to-right
- RTL: Shimmer moves right-to-left
- Implementation: Use `Directionality.of(context)` in widget, not in tokens

---

## Performance Constraints

| Constraint | Limit | Rationale |
|------------|-------|-----------|
| Max concurrent animated skeletons | 20 | Prevent GPU overload on lists |
| Animation frame rate | 60fps | Flutter default |
| Stop animation when off-screen | Required | Battery and GPU preservation |
| Stop animation when backgrounded | Required | App lifecycle awareness |
| Use `RepaintBoundary` | Recommended | Isolate skeleton animations |

### Optimization Strategies

1. Single `AnimationController` per screen, not per block
2. `RepaintBoundary` around skeleton lists
3. Shader reuse for shimmer gradient
4. `TickerMode` to disable when parent is off-screen

---

## Theming Requirements

### Color Derivation

| Skeleton Element | Source Color |
|------------------|--------------|
| Base color | `ColorScheme.surfaceContainerHighest` |
| Highlight color | `ColorScheme.surfaceContainerHigh` |

### Token-Driven Values

All visual values must be token-driven:

- `baseColor`: Background of skeleton block
- `highlightColor`: Shimmer highlight color
- `borderRadius`: Corner radius (default: `tokens.radiusMedium`)
- `animationDuration`: Shimmer cycle duration (default: 1500ms)
- `pulseDuration`: Static pulse duration for reduced motion (default: 1000ms)

### Light/Dark Mode

- Colors derive from theme automatically via `ColorScheme`
- No hardcoded hex values
- Test goldens in both modes

---

## Density note (superseded)

An earlier draft required `TilawaDensity` and comfortable/compact token columns for skeleton blocks. **Dual-density mode was removed** from the UI Kit (see [007 spec supersession](../007-compact-ui-coverage/spec.md)). Skeleton components must use **theme-backed single defaults** (light/dark only for goldens unless a feature needs explicit width breakpoints).

Historical sizing table (do not implement dual factories):

| Property | Single default (illustrative) | Notes |
|----------|------------------------------|-------|
| Border radius | from design tokens | No separate compact column |
| Default height | from design tokens | |
| Line height (text) | legibility first | |

---

## Testing Requirements

### Unit/Widget Tests (S1-B)

| Test | Purpose |
|------|---------|
| Renders with explicit width/height | Verify layout |
| Supports circle shape | Avatar use case |
| Supports custom borderRadius | Card corners |
| Respects `animate: false` | Static mode |
| Reduced motion disables animation | Accessibility |

### Golden Tests (S1-B)

| Scenario | Variants |
|----------|----------|
| Rectangle block | Light, Dark |
| Circle/avatar block | Light, Dark |
| Text line block | Light, Dark, Compact |
| Reduced motion (static) | Light |
| Multiple blocks composition | Light |

### Test Mode

- Golden tests must use `animate: false` to prevent flakiness
- Widget tests should verify animation state, not visual frames

---

## Rollback Plan

### If Issues Discovered

1. **Disable shimmer globally**
   ```dart
   // Set default animate: false in component
   TilawaSkeletonBlock(..., animate: false)
   ```

2. **Revert to static blocks**
   - Remove `AnimationController` from widget
   - Keep container styling only

3. **Remove from UI Kit**
   - Delete `tilawa_skeleton_block.dart`
   - Remove from `atoms.dart` export
   - Remove from `TilawaComponentTokens`
   - Golden tests can remain (documented as removed)

4. **Revert app usage** (if any was added prematurely)
   - Replace with `TilawaLoadingIndicator`

---

## Dependencies

- **UI Kit Foundation**: Requires existing token architecture
- **Theming**: Light/dark `ColorScheme` and `TilawaComponentTokens` (no `TilawaDensity` axis)
- **Color Scheme**: Uses `surfaceContainer` colors from Material 3

---

## Success Criteria

### Phase S1-A (Foundation)
- [ ] `TilawaSkeletonBlock` renders rectangle, circle, rounded shapes
- [ ] Colors derive from theme correctly (light/dark)
- [ ] Animation respects reduced motion
- [ ] No analyzer errors
- [ ] Component test passes (unit level)

### Phase S1-B (Tests)
- [ ] Golden images generated and reviewed
- [ ] All 6 golden scenarios pass
- [ ] Widget tests pass
- [ ] Token tests pass

### Phase S1-C (Patterns)
- [ ] Design approved for `TilawaSkeletonListTile`
- [ ] Design approved for `TilawaSkeletonCard`
- [ ] Pattern library documented

### Phase S1-D (Integration)
- [ ] First app screen identified and approved
- [ ] UX testing confirms improved perceived performance
- [ ] No accessibility regressions

---

## Notes

- Skeleton is a **placeholder**, not a spinner replacement everywhere
- Keep `TilawaLoadingIndicator` for appropriate use cases
- Design for predictability: skeleton should suggest final content shape
- Prioritize content-heavy screens (lists, grids) for Phase S1-D integration
