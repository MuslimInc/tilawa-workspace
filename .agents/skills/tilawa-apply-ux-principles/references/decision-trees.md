# UX decision trees

Quick choices for coding agents. When in doubt, grep a sibling feature first.

## Picker: bottom sheet vs full screen

```
User picks from a short, local list (≤10 items, no search)?
├─ Yes, reversible, no account sync → Bottom sheet
│     showTilawaModalBottomSheet + TilawaBottomSheetScaffold.modalShape
│     Example: pinned_athkar_home_section.dart → _PinnedAthkarPickerSheet
└─ No → Full screen or catalog route
      Search, filter, long comparison, or deep navigation
      Example: AthkarCategoriesRoute, RecitersSearchRoute
```

**Sheet rules:** one primary action (Done / Save), dismiss on save or explicit
Cancel; `sheetSemanticsLabel` for screen readers.

## Home shortcut: horizontal scroll vs grid

```
Item count on Home?
├─ ≤4 pinned shortcuts → 2-column compact grid OR horizontal scroll row
├─ 5–6 → horizontal scroll (avoid tall Home stack)
└─ Never a 6-tile launcher grid — bottom nav owns primary destinations
```

## Destructive action

```
Action removes user data irreversibly?
├─ Yes → Confirm dialog OR undo snackbar if repo supports undo
│     Copy: calm, states what is deleted, Cancel + destructive label
└─ No → Direct action OK
```

## Notification / deep-link entry

```
Opens worship surface (reader, athkar count, prayer)?
├─ Yes → Land directly on task; no intermediate promo or tour
└─ No → Standard route; respect cold-start calm (no popup)
```

## Pull-to-refresh on Home

```
Does the bloc reload data this section displays?
├─ Yes → RefreshIndicator OK (HomeDashboardBloc, etc.)
└─ No → Do not wire refresh that only reloads unrelated sections
```
