# Pull request: `refactor/ui` → `main` (UI Kit accessibility audit)

## What changed

The shared UI kit was updated to close a full accessibility and consistency audit: larger minimum touch targets where required, clearer semantics for interactive controls and transient messages, design-token alignment on the 8dp spacing grid, and safer golden-test layout. Deprecated type aliases remain exported so existing apps keep compiling while they adopt the new `Tilawa*` names.

## Why

This work addresses the **2026 UI kit accessibility audit** (WCAG-oriented touch targets, semantics roles and live regions, focus on icon-only controls and segmented patterns) and related **consistency / spacing grid** gaps called out in that review. It reduces drift between Figma-style spacing and code by driving more layout from **component and design tokens**.

## Breaking changes

**None.** Behavior is backward compatible at the API level; visual and semantics behavior may differ slightly (see *Notable implementation detail*).

## Deprecations

| Deprecated (still exported) | Use instead |
|------------------------------|-------------|
| `LanguageSwitcher` typedef   | `TilawaLanguageSwitcher` |
| `SelectionPill` typedef        | `TilawaSelectionPill` |
| `MetadataChip` typedef       | `TilawaMetadataChip` |

**Migration:** replace the type name and constructor name with the `Tilawa*` equivalent; parameters are unchanged for these three.

## Notable implementation detail

**`TilawaButton`** no longer uses a `LayoutBuilder` around the label row (that pattern broke Alchemist’s intrinsic sizing). The inner `Row` still gives **unbounded horizontal max** to non-flex children, so **long labels with `isFullWidth: false` inside a narrow bounded parent** can **`RenderFlex` overflow** in debug rather than ellipsize; **`isFullWidth: true`** wraps the label in **`Expanded`** so tight widths ellipsize safely. See `CHANGELOG.md` (**Changed**), `doc/migration/accessibility_audit_2026.md`, and `test/atoms/tilawa_button_test.dart`.

## Testing

- **Widget / contract tests** under `packages/ui_kit/test/`: touch targets (e.g. permission banner, seek bar strip, media bar, icon toggle), semantics (`flagsCollection`, live region, selected segments), error state retry loading, selection tile `Semantics(selected:)`, deprecated barrel typedefs.
- **`tilawa_button_test.dart`**: `isFullWidth: true` in **120px** width (ellipsis, no overflow, `Expanded`); wide parent + `isFullWidth`; **non–full-width** long label in a **horizontal** `SingleChildScrollView` (unbounded main axis, no overflow, no `Expanded`).
- **`flutter test packages/ui_kit/test/foundation/component_tokens_test.dart`** — token regressions.
- **Goldens** — regenerated under `packages/ui_kit/test/goldens/` with bounded scenario constraints; see `test/goldens/REVIEW_CHECKLIST.md` for per-component expected visual deltas.

## Reviewer checklist

- [ ] Open regenerated **golden PNGs** (macOS / CI variant used by your pipeline) and compare against `test/goldens/REVIEW_CHECKLIST.md` expected deltas.
- [ ] **Product / design pass** on **`TilawaButton`** in **narrow** layouts (non–full-width, long labels)—confirm ellipsis is acceptable or adjust copy / `isFullWidth` / parent width.
- [ ] Confirm **deprecated typedef** migration path in **consumer apps** (grep for `LanguageSwitcher`, `SelectionPill`, `MetadataChip`) and plan renames to `Tilawa*` types.
- [ ] If consumer apps have **custom semantics tests** (e.g. `tester.getSemantics` on chips, segments, tiles, feedback strip), update expectations for new nodes / flags where applicable.
