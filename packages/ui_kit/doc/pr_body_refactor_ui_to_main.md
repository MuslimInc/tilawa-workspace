# Pull request: `refactor/ui` → `stable` (UI Kit accessibility audit + button fix)

## What changed

The shared UI kit was updated to close a full accessibility and consistency audit: larger minimum touch targets where required, clearer semantics for interactive controls and transient messages, design-token alignment on the 8dp spacing grid, and safer golden-test layout. Deprecated type aliases remain exported so existing apps keep compiling while they adopt the new `Tilawa*` names. A follow-up commit restores correct **non–full-width** `TilawaButton` label layout using **`Flexible(fit: FlexFit.loose)`** so long labels ellipsize in narrow parents without `RenderFlex` overflow.

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

- **Audit step:** **`TilawaButton`** dropped **`LayoutBuilder`** from the label row so Alchemist golden **`Table`** intrinsic sizing no longer fails on that widget.
- **Follow-up (`77e1223`):** non–full-width labels use **`Flexible(fit: FlexFit.loose)`** around the **`Text`** so bounded parents give a finite max width, **single-line ellipsis** applies, and **`isFullWidth: true`** still uses **`Expanded`** unchanged.

## Testing

- **Widget / contract tests** under `packages/ui_kit/test/`: touch targets (e.g. permission banner, seek bar strip, media bar, icon toggle), semantics (`flagsCollection`, live region, selected segments), error state retry loading, selection tile `Semantics(selected:)`, deprecated barrel typedefs.
- **`tilawa_button_test.dart`**: non–full-width long/short in **120px**; **`isFullWidth`** long in **120px** (`Expanded`); non–full-width long in a **wide** parent (`didExceedMaxLines` / no ellipsis).
- **`flutter test packages/ui_kit/test/foundation/component_tokens_test.dart`** — token regressions.
- **Goldens** — regenerated under `packages/ui_kit/test/goldens/` with bounded scenario constraints; see `test/goldens/REVIEW_CHECKLIST.md` for per-component expected visual deltas.

## Commits

- `97824d4` — chore(ui_kit): goldens, a11y contract tests, and changelog (audit harness + docs batch).
- `bdd1774` — fix(ui_kit): improve TilawaButton label handling for non–full-width cases.
- `77e1223` — fix(ui_kit): TilawaButton non–full-width label uses **`Flexible(fit: FlexFit.loose)`**.

## Reviewer checklist

- [ ] Open regenerated **golden PNGs** (macOS / CI variant used by your pipeline) and compare against `test/goldens/REVIEW_CHECKLIST.md` expected deltas.
- [ ] **Product / design pass** on **`TilawaButton`** in narrow layouts (long labels, non–full-width and full-width).
- [ ] Confirm **deprecated typedef** migration path in **consumer apps** (grep for `LanguageSwitcher`, `SelectionPill`, `MetadataChip`) and plan renames to `Tilawa*` types.
- [ ] If consumer apps have **custom semantics tests** (e.g. `tester.getSemantics` on chips, segments, tiles, feedback strip), update expectations for new nodes / flags where applicable.
