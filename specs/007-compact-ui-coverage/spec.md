# Feature Specification: Compact UI — Complete Coverage Across UI Kit

**Feature Branch**: `007-compact-ui-coverage`  
**Created**: 2026-05-04  
**Status**: **Superseded / retired (2026)**  
**Input (historical)**: [docs/update-direction-i-want-clever-moonbeam.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/docs/update-direction-i-want-clever-moonbeam.md)

---

## Current status (authoritative)

This specification described a **dual-density** product (`TilawaDensity` comfortable vs compact), a **user-visible “compact design”** setting, and **per-family `density` parameters** on component tokens.

That approach was **fully removed** from the Tilawa codebase in favor of:

- **Single token defaults** — no `density` argument on token factories; no parallel comfortable/compact value sets in `TilawaComponentTokens`.
- **Removed app setting** — no runtime toggle for a global “compact UI” mode tied to token density.
- **Renamed layout vocabulary** — window class `compact` → **`narrow`**; breakpoint `TilawaBreakpoints.compact` → **`narrowUpperBound`**; `isCompact` → **`isNarrow`**; phone bottom navigation tokens use **`phone*`**; short-height composer tokens use **`shortWindow*`**; chip tight padding uses **`inline*`**; `TilawaButton.compact` → **`shrinkWrapTapTarget`** (same Material behavior, different name).
- **Removed token fields** — e.g. `TilawaLoadingIndicatorTokens.compactStrokeWidth` removed; one-off dimensions live next to their widget when needed.

The sections below are **retained for history** (what was built and later backed out). Do not treat functional requirements as active contract.

---

## Is the word “compact” gone 100% from the project?

**No — not as a substring everywhere**, and that is intentional:

| Remains | Reason |
|--------|--------|
| `VisualDensity.compact` | Flutter **framework** API (Material). Tilawa code may still pass this constant where a denser Material control is desired. |
| `androidCompactActionIndices` | **Android platform** media-session API name. |
| Vendored **`packages/flex_color_scheme`** | Third-party docs mentioning “compactness” / `VisualDensity`. |
| English prose in older specs/docs | Words like “compact location” meaning *short copy*, not the removed API. |

**Yes — for Tilawa-owned *compact density / compact UI* APIs**: there is no `TilawaDensity`, no `density:` on component token `defaults()`, no `TILAWA_COMPACT_UI` product path, and no `compactStrokeWidth` / `compactBottomNav*` / `TilawaWindowSize.compact` / `isCompact` in first-party libraries.

---

## Historical context (frozen)

Compact UI was previously described as the app default (`TILAWA_COMPACT_UI=true`). The work expanded density awareness across component token families while preserving comfortable behavior and maintaining touch targets above 48dp.

That entire dual-mode token layer was later removed to simplify the system (DRY/KISS/YAGNI).

---

## Historical user scenarios & requirements

The following applied **only while the dual-density system existed**. They are not current acceptance criteria.

### User Story 1 - Consistent compact visual density (historical)

As a user with compact UI preference enabled, all components should have proportionally reduced spacing where safe.

### User Story 2 - Preserved touch accessibility (still true as engineering rule)

Interactive elements should respect `kMeMuslimMinInteractiveDimension` / Material guidance; shrinking unsafe controls was always avoided.

### User Story 3 - Comfortable mode (historical)

User toggle between comfortable and compact token modes — **removed** with the setting and density API.

### Functional requirements (historical)

FR-001–FR-006 required `density` on factories, divergent families, tests, etc. **Obsolete.**

---

## Historical component inventory

Tables in the original spec listed which token families diverged in compact mode. Those divergences are **no longer in code**; token files carry a single set of values.
