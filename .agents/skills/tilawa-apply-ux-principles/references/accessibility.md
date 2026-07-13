# Tilawa accessibility minimums

## Touch & motor

- Minimum interactive size: **44 dp** (`kMeMuslimMinInteractiveDimension` /
  `tokens.minInteractiveDimension` in `design_tokens.dart`)
- Prefer wide tap zones on daily actions (athkar shortcuts, player controls)
- Do not rely on hover-only affordances (mobile-first)

## Text scaling

App clamps `TextScaler` to **1.0–1.4**. When designing:

- Allow titles to wrap (`maxLines` + `overflow`) — do not clip at 1.4
- Avoid fixed-height rows that truncate scaled text
- Test widget tests or manual check at `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4)`

## Screen readers

- `Semantics` or `semanticLabel` on icon-only `IconButton` / quick tiles
- Section titles should label grouped content where Flutter does not infer it
- Loading: announce progress or use `Semantics(liveRegion: ...) ` for critical errors only

## RTL

- `AlignmentDirectional`, `EdgeInsetsDirectional`, `BorderRadiusDirectional`
- Trailing actions stay on the **end** edge in RTL
- Icons that imply direction (chevrons) use `Icons.chevron_right` with `matchTextDirection: true` or directional equivalents

## Color & contrast

- Body text on surface: target WCAG AA where feasible
- Do not convey state by color alone — pair with icon, label, or weight
- Custom user primaries are soft-clamped in light theme — still verify `onPrimary` contrast for CTAs

## Motion

- Respect platform "reduce motion" when adding non-essential animation
- No spring overshoot on sheets/tabs (`Curves.easeOutCubic` per brand doc)
