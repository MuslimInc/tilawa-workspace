# Feature Specification: Catalog theme & UI kit freeze

**Feature Branch**: `017-catalog-theme-freeze`
**Created**: 2026-05-23
**Status**: Accepted (baseline frozen)
**Input**: Production-readiness review before long freeze on app theme and UI kit
(except new components and critical fixes).

## Intent

Lock the **Pinterest-inspired catalog chrome** and **default coral primary** so
product and agents can rely on stable neutrals, `TilawaCatalogAppBar`, and token
factories. Documentation, compliance tests, and goldens enforce the contract.

## Frozen behaviours

### FB-001 — Default primary

- App default primary is **coral** `#E60023` (`AppColors.defaultPrimary`).
- Native splash / Android colours align with coral.

### FB-002 — Light neutral surfaces

- Scaffold and `ColorScheme.surface` are **white** (`#FFFFFF`).
- `surfaceContainerHigh` is **`#E5E5E0`** for all primary presets (no
  primary harmonization on idle control surfaces).
- `surfaceTint` is transparent on elevated Material surfaces in `AppTheme`.

### FB-003 — Catalog chrome components

- List/catalog screens use **`TilawaCatalogAppBar`** with height helpers from
  **`TilawaAppBarConfig`**.
- Search uses **`TilawaSearchFieldVariant.catalog`** (default).
- Filter chips use **`TilawaSelectionPillStyle.catalog`** where Pinterest
  idle/selected contrast is required.

### FB-004 — Accent discipline

- User primary colours **CTAs, active nav, favorites, switches ON** — not
  search backgrounds, unselected chips, or app bar fills.

### FB-005 — Documentation

- Root [`DESIGN.md`](../../DESIGN.md) §2 neutrals and catalog section match code.
- [`docs/design/colors.md`](../../docs/design/colors.md) and
  [`packages/ui_kit/docs/design_system.md`](../../packages/ui_kit/docs/design_system.md)
  are the implementation spec kit.

### FB-006 — Tests

- `app_theme_color_roles_test.dart` and `app_theme_spec_compliance_test.dart`
  assert Pinterest neutrals and M3 elevation policy.
- Goldens cover catalog app bar, catalog selection pill, and catalog search
  field; `TilawaPreviewWrapper` uses `AppColors.defaultPrimary`.

## Allowed changes during freeze

| Allowed | Not allowed |
|---------|-------------|
| New atoms/molecules/organisms | Re-tinting global light ramp without spec |
| Critical a11y/contrast/overflow fixes | New decorative gradients in chrome |
| Quran reader / share composer palettes (documented exceptions) | Per-feature hex in list screens |
| Dark/true-black refinements if contrast fails | Renaming tokens without migration |

## Acceptance checklist

- [x] `AppColors` light ramp documents Pinterest hexes
- [x] `AppTheme` does not harmonize `surfaceContainerHigh` with primary (light)
- [x] `TilawaCatalogAppBar` exported and used on major catalog screens
- [x] Golden + theme tests updated
- [x] `DESIGN.md` and design_system.md synced

## Out of scope

- Quran reader Mushaf palette migration
- Dynamic-type golden matrix
- Full dark-mode Pinterest parity (dark keeps Tilawa green-tinted stack)
