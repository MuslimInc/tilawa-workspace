# Home dashboard UI patterns

Reference: `apps/tilawa/lib/features/home/presentation/screens/home_screen.dart`

## Structure (current)

```
CustomScrollView
├── HomeDashboardHeroSliver (pinned prayer hero, Variant B by default)
└── HomeDashboardContentSliver
    └── Column
        ├── HomePrimaryActionZone         ← Quran / listening / urgent athkar
        ├── [flag] TodayPlanCard
        ├── HomeDailyPracticeSection      ← contextual + pinned athkar
        ├── HomeDailyInspirationSection   ← ayah + dua in one card
        ├── HomeDiscoverShortcuts         ← supporting shortcuts grid
        ├── HomeMoreActionsGroup          ← library / setup destinations
        └── [conditional] HomeListeningResumeRow
```

## IA zones (top → bottom)

1. **Now** — hero (prayer, greeting, profile)
2. **Primary action** — the next useful action: Quran resume, listening resume,
   or urgent athkar
3. **Today / practice** — optional Today Plan, contextual athkar, pinned athkar
4. **Inspiration** — daily ayah and dua in one raised card
5. **Discover** — supporting shortcuts in a compact grid
6. **More** — lower-frequency library, account, and setup destinations
7. **Listening resume** — conditional row only when listening is not primary

## Bottom navigation (do not duplicate on Home)

Shell tabs (`app_shell_screen.dart` → `app_shell_nav_destinations.dart`):
**Home**, **Quran** (push), **Reciters**, **Settings / Profile**.
Viewport index `kAppShellRecitersTabIndex` (1) = Reciters.

**Never** add Home tiles for: Home, Quran, Prayer, Athkar, Settings.

**Current exception:** `HomeDiscoverShortcuts` keeps **Reciters** on Home
because listening is a several-times-daily behavior in Tilawa. It selects the
Reciters tab instead of pushing a duplicate route.

## Hero

File: `home_dashboard_hero_variant_b.dart`

- Compact pinned SliverPersistentHeader with prayer-period photo/gradient tokens.
- Expanded state shows context row + featured next-prayer card.
- Collapsed toolbar preserves prayer context while scrolling.
- Hero snap threshold is 35% of collapse extent; animation uses
  `tokens.durationFast` and `Curves.easeOutCubic`.
- The old prayer day strip is removed from Home; the hero owns prayer context.

## Primary action hierarchy

| Priority | Widget | Surface / accent |
|----------|--------|------------------|
| Primary Quran | `HomeQuranResumeCard(featured: true)` | Gold featured gradient, progress ring when resumable |
| Primary listening | `_HomePrimaryListeningCard` | Raised neutral card, headphones icon |
| Primary athkar | `_HomePrimaryAthkarCard` | Raised neutral card, urgent athkar row |
| Daily practice | `HomeDailyPracticeSection` | Section title + edit action + contextual card + pinned list |
| Secondary library | `HomeMoreActionsGroup` | Flat grouped list with hairline dividers |

`HomePrimaryActionSyncListener` keeps the primary card aligned with Quran,
listening, and athkar cubits.

## Discover shortcuts

File: `home_discover_shortcuts.dart`

- Neutral section treatment; no gradient shell.
- Uses `HomeDashboardShortcutGrid`: 2 columns on narrow, 4 columns on medium+.
- Current items: Reciters, Qibla, Tasbeeh, Bookmarks, plus Quran Sessions when
  `quranSessionsFeatureConfig().quranSessionsEnabled`.
- Excludes Prayer, Quran, Athkar, Home, and Settings tiles.

## More list layout (grouped card)

- Widget: `HomeMoreActionsGroup` + `HomeGroupedListRow`
- One flat `TilawaCard` with hairline dividers between rows
- Row: small outline icon box + title + optional subtitle + RTL chevron
- Min height: `tokens.minInteractiveDimension` (44 dp)
- Current items: History, Favorites, Downloads, Smart Khatma when enabled, and
  Support Tilawa.

## Pinned athkar section (canonical customizable block)

Files: `home_today_section.dart`, `pinned_athkar_home_section.dart`

- **Section header:** `HomeDashboardSection` title row with trailing edit
  `TilawaIconActionButton` (`Icons.edit_outlined`).
- **Picker:** `showTilawaModalBottomSheet` + flat grouped rows (`TilawaCheckbox`)
- **Populated:** contextual featured ritual card + pinned athkar list
- **Empty / loading / error:** `_PinnedAthkarEmptyCard`, loading card,
  `_PinnedAthkarFailureCard`

## Daily inspiration

File: `home_daily_inspiration_section.dart`

- One raised `TilawaCard` with ayah and dua blocks separated by `TilawaDivider`
- Arabic line height only when `context.isArabic`
- Reference labels (`Quran 2:43`) use `bodySmall` w500 — not bold badges

## Adding another Today section

Insert a new daily module in `HomeDashboardBody` near the existing
`TodayPlanCard` or before `HomeDailyInspirationSection` if it is part of the
daily ritual surface:

```dart
const YourTodaySection(),
SizedBox(height: tokens.spaceLarge),
```

## Patterns to reuse

| Pattern | File |
|---------|------|
| Primary card selection | `home_primary_action_zone.dart` |
| Featured Quran resume | `home_quran_resume_card.dart` |
| Discover shortcuts | `home_discover_shortcuts.dart` |
| Pinned section + sheet picker | `pinned_athkar_home_section.dart` |
| Grouped list row | `home_grouped_list_row.dart` |
| More actions group | `home_more_actions_group.dart` |
| Daily inspiration | `home_daily_inspiration_section.dart` |
| Category card | `athkar_category_card.dart` |
| Content sheet padding | `home_dashboard_content_sliver.dart` |

## Feature flags

`isSmartKhatmaEnabled()`, `isTodayPlanEnabled()`, and
`quranSessionsFeatureConfig().quranSessionsEnabled` gate optional Home modules.
