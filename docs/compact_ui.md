# Compact UI (retired)

**Status**: This document described a **dual-density** UI Kit (`TilawaDensity` comfortable vs compact), global compact goldens, and an app-level compact design preference. That system has been **removed**.

**Authoritative Spec Kit record**: [specs/007-compact-ui-coverage/spec.md](../specs/007-compact-ui-coverage/spec.md) (superseded), [plan.md](../specs/007-compact-ui-coverage/plan.md), [tasks.md](../specs/007-compact-ui-coverage/tasks.md).

## What replaced it

- **One set of component token values** per theme brightness — no `density` parameter on token factories.
- **Layout naming**: `TilawaWindowSize.narrow`, `TilawaBreakpoints.narrowUpperBound`, `context.isNarrow`, phone bottom nav `phone*` tokens, composer `shortWindow*` tokens, chip `inline*` padding/icon sizes where a tighter row is intentional.
- **`TilawaButton.shrinkWrapTapTarget`** — optional smaller Material tap target for inline actions (replaces the old `compact` flag name only).

## “100% removed?”

- **Tilawa compact-density API**: yes — removed (no dual mode, no removed-token aliases kept in parallel).
- **The substring `compact` everywhere in the repo**: no — Flutter (`VisualDensity.compact`), Android (`androidCompactActionIndices`), vendored packages, and plain-English docs may still contain the word. See the spec for the table.

## Historical detail

The long inventory, phase list, and golden naming that used to live in this file are obsolete. Refer to **git history** of this file if you need the old tables.
