# Tilawa Admin — UI design system

Web admin dashboard tokens and components mapped from `packages/ui_kit` and
`DESIGN.md`. Admin adapts mobile brand for data-dense layouts (tables, filters,
forms) without copying mobile chrome.

## Token source

CSS custom properties live in `src/styles/tokens.css`, imported from
`src/styles.css`. Tailwind `@theme` aliases expose common colors for utility
classes.

| UI Kit (`AppColors` / `ColorScheme`) | Admin CSS variable |
|--------------------------------------|--------------------|
| Primary brown `#8B5E3C` | `--tilawa-primary` |
| Secondary scholar `#65734F` | `--tilawa-secondary` |
| Tertiary gold `#8C681F` | `--tilawa-tertiary` |
| Canvas `#FAFAFA` | `--tilawa-canvas` |
| Surface `#FFFFFF` | `--tilawa-surface` |
| Idle chip `#F1F1EF` | `--tilawa-surface-high` |
| Ink `#30343C` | `--tilawa-ink` |
| Muted `#78736E` | `--tilawa-ink-muted` |
| Error / success / warning | `--tilawa-error`, `--tilawa-success`, `--tilawa-warning` |
| Spacing 2–24 | `--tilawa-space-*` |
| Radius 8–24 | `--tilawa-radius-*` |

Dark mode: `prefers-color-scheme: dark` overrides in `tokens.css`.

## Shared components

| Selector | Purpose |
|----------|---------|
| `app-tilawa-button` | Primary / secondary / danger / text actions |
| `app-status-chip` | Domain status → semantic chip color |
| `app-tilawa-card` | Elevated admin surface |
| `app-tilawa-empty-state` | Empty lists |
| `app-tilawa-loading-state` | List/detail loading |
| `app-tilawa-error-state` | Failed loads (+ optional retry) |
| `app-page-header` | Title, subtitle, action slot |
| `app-tilawa-filter-bar` | Filter grid + apply button |
| `app-tilawa-data-table` | Table wrapper (sticky header, zebra hover) |
| `app-tilawa-pagination` | Load-more pattern |
| `app-sortable-th` | Server sort UI (emits `sortChange` only) |

Legacy paths `page-header/` and `status-chip/` re-export the Tilawa
implementations.

## Form fields

Use class `tilawa-field` on inputs and selects inside filter bars and forms.

## Status chips

`resolveStatusVariant()` in `shared/utils/status-chip.util.ts` maps session,
report, dispute, teacher, and account statuses. Pass `[scholar]="true"` for
metadata chips (e.g. severity, profile completeness).

## Admin-specific rules

- One brown accent per viewport; no blue chrome.
- Scholar green for metadata; gold tertiary reserved (not used in admin MVP).
- Sidebar: warm dark brown, not cool navy.
- No client-side sort on paginated lists; `app-sortable-th` only emits sort
  requests to facades.
- Destructive flows: `app-confirm-dialog` with `[destructive]="true"` and
  `app-tilawa-button variant="danger"`.

## Typography

IBM Plex Sans Arabic (Google Fonts) with Alexandria fallback — aligned with
`docs/tilawa_brand.md`.
