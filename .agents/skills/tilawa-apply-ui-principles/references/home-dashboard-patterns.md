# Home dashboard UI patterns

Reference: `apps/tilawa/lib/features/home/presentation/screens/home_screen.dart`

## Structure (current)

```
CustomScrollView
├── HomeDashboardHeroSliver (pinned app bar, prayer gradient)
└── HomeDashboardContentSliver
    └── Column
        ├── HomeTodaySection
        │   ├── HomePrayerDayStrip (glance-only catalog pills)
        │   ├── HomeQuranResumeCard (primary Mushaf accent)
        │   ├── PinnedAthkarHomeSection
        │   ├── [flag] SmartKhatmaHomeEntryCard
        │   └── [flag] TodayPlanCard
        ├── HomeDailyInspirationSection   ← ayah + dua in one card
        └── HomeMoreActionsGroup          ← Reciters + Tasbeeh + Qibla
```

## IA zones (top → bottom)

1. **Now** — hero (prayer, greeting, profile)
2. **Today** — prayer glance, Mushaf, pinned athkar, khatma, today plan
3. **Inspiration** — daily ayah and dua (non-interactive retention)
4. **More** — secondary destinations **not** in bottom navigation

## Bottom navigation (do not duplicate on Home)

Shell tabs (`app_shell_screen.dart` → `app_shell_nav_destinations.dart`):
**Home**, **Prayer**, **Quran** (push), **Athkar**, **Settings**.
Viewport index `kAppShellRecitersTabIndex` (1) = Reciters — not in the bar.

**Never** add Home tiles for: Home, Prayer, Quran, Athkar, Settings.

**More row** is for destinations outside the bar — **Reciters**, **Tasbeeh**,
and **Qibla** (`HomeMoreActionsGroup`).

## Prayer day strip

File: `home_prayer_day_strip.dart`

- Pills use `TilawaSelectionPillStyle.catalog` — **glance only** (no per-pill tap)
- Next prayer is indicated with neutral catalog selected fill, not primary mint
- **View all** text link opens the Prayer tab; do not route every pill there

## Today hierarchy

| Priority | Widget | Surface / accent |
|----------|--------|------------------|
| Primary | `HomeQuranResumeCard` | Raised card + tinted `ink` icon (one accent) |
| Contextual | `HomeFeaturedRitualCard` | Raised card + `titleMedium` prompt |
| Secondary | `HomePinnedAthkarGroup` | **Flat** grouped rows + outline icons |
| Utility | `HomeMoreActionsGroup` | **Flat** grouped rows + outline icons |

## More row layout (grouped card)

- Widget: `HomeMoreActionsGroup` + `HomeGroupedListRow`
- One flat `TilawaCard` with hairline dividers between rows
- Row: small outline icon box + title + optional subtitle + RTL chevron
- Min height: `tokens.minInteractiveDimension` (44 dp)

## Pinned athkar section (canonical customizable block)

File: `pinned_athkar_home_section.dart`

- **Section header:** `Row` with `Expanded(TilawaSectionTitle(...))` + edit
  `TilawaIconActionButton` (`Icons.edit_outlined`)
- **Picker:** `showTilawaModalBottomSheet` + flat grouped rows (`TilawaCheckbox`)
- **Populated:** featured ritual card + flat grouped list via `HomeGroupedListRow`
- **Empty / loading / error:** `_PinnedAthkarEmptyCard`, loading card,
  `_PinnedAthkarFailureCard`

## Daily inspiration

File: `home_daily_inspiration_section.dart`

- One raised `TilawaCard` with ayah and dua blocks separated by `TilawaDivider`
- Arabic line height only when `context.isArabic`
- Reference labels (`Quran 2:43`) use `bodySmall` w500 — not bold badges

## Adding another Today section

Insert inside `HomeTodaySection`, before optional khatma/plan flags:

```dart
const YourTodaySection(),
SizedBox(height: tokens.spaceLarge),
```

## Patterns to reuse

| Pattern | File |
|---------|------|
| Home entry card + bloc | `smart_khatma_home_entry_card.dart` |
| Pinned section + sheet picker | `pinned_athkar_home_section.dart` |
| Grouped list row | `home_grouped_list_row.dart` |
| More actions group | `home_more_actions_group.dart` |
| Daily inspiration | `home_daily_inspiration_section.dart` |
| Category card | `athkar_category_card.dart` |
| Content sheet padding | `home_dashboard_content_sliver.dart` |

## Hero scroll

- Snap threshold: 35% of `HomeDashboardHeroSliver.collapseScrollExtent`
- Duration: `tokens.durationFast`, `Curves.easeOutCubic`

## Feature flags

`isSmartKhatmaEnabled()`, `isTodayPlanEnabled()` — gate optional Today cards the same way.
