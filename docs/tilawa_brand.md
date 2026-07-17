# MeMuslim Brand

Visual identity layer for **MeMuslim / أنا مسلم**, aligned with the warm Islamic lifestyle
reference: [Behance — Islamic App Mobile UI/UX Design for Muslim Lifestyle](https://www.behance.net/gallery/230050359/Islamic-App-Mobile-UIUX-Design-for-Muslim-Lifestyle)
(Deen Muslim concept by SpineEdge Studio).

**Read order:** `AGENTS.md` → `DESIGN.md` (tokens) → **this file** (intent) →
[`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md).
When this file conflicts with `DESIGN.md`, `DESIGN.md` wins on implementation;
this file wins on intent.

---

## 1. Brand essence

MeMuslim is a **daily Muslim lifestyle companion** — prayer, Quran, Qibla, dhikr,
and calm home rituals in one warm, approachable shell. The product name is
**MeMuslim / أنا مسلم**; the visual language follows the Behance cool off-white +
**orange accent** + gold featured-card system (implementation in `DESIGN.md`).

| Word | What it means in pixels |
|---|---|
| **Clear** | Soft parchment canvas (`#F4F4F4`), warm ink (`#050505`), **brand orange** accent (`#FA5B2E`), gold featured cards (`#FFD28E`→`#FF9E44`). No cool porcelain; brown/warm tones only as secondary micro-accents — never as production primary. |
| **Clear** | One primary accent per screen (green). Generous radius (20–24 dp cards). Readable metadata in warm grey-green (`#6B6B6B`). |
| **Faithful** | Bundled **IBM Plex Sans Arabic**, `textHeightLoose` (2.0), reverent reader surfaces, no stereotype chrome (mosques/crescents in app bars). |

---

## 2. Cultural anchor

- **Typography over ornament.** Islamic identity comes from Arabic script quality
  and calm layout — not decorative icons in chrome.
- **Featured gold gradient** for resume/hero cards (Last Read, prayer hub) —
  ceremonial, welcoming, not a paywall CTA.
- **Mushaf reader** stays content-first: the page is the loudest object in the
  reader; lifestyle chrome uses the warm hub palette.
- **No people photography, flags, or national symbols** in product chrome.

---

## 3. Brand color roles

| Brand role | Maps to | When to use |
|---|---|---|
| **Brand orange** | `colorScheme.primary` (`#FA5B2E`) | CTAs, active nav, selected pills/segments, switch ON, progress |
| **On-primary** | `colorScheme.onPrimary` (`#FFFFFF`) | Labels/icons on orange fills |
| **Gold gilding** | `colorScheme.tertiary` / featured gradient stops | Hero cards, Last Read, surah header banners — not purchase buttons |
| **Canvas** | `colorScheme.surfaceContainerLowest` (`#F4F4F4`) | Scaffold, canvas (~60% neutral) |
| **Card white** | `colorScheme.surface` (`#FFFFFF`) | List rows, settings tiles (~30% secondary) |
| **Warm chip rest** | `colorScheme.surfaceContainerHigh` (`#F4F4F4`) | Idle chips, search rests |
| **Body ink** | `colorScheme.onSurface` (`#050505`) | Headings, primary copy |
| **Muted labels** | `colorScheme.onSurfaceVariant` (`#6B6B6B`) | Metadata, captions |
| **Hairline** | `colorScheme.outlineVariant` (`#EEEEEE`) | Dividers at `borderWidthThin` (0.5) |
| **Featured text** | `AppColors.featuredGradientForeground` | Copy on gold gradient cards |

**Anti-patterns:**
- Don't flatten scaffold/canvas to pure white (`#FFFFFF`) — use cool off-white (`#F4F4F4`) so white cards lift.
- Don't reintroduce legacy purple (`#7A5C89`), brown (`#8B5E3C`), sage (`#219653`), or teal (`#00897B`) as production primary.
- Canvas is cool off-white (`#F4F4F4`); keep white cards for lift.
- Don't use gold gradient on Support MeMuslim CTAs.

---

## 4. Typography

- UI: bundled **IBM Plex Sans Arabic** (`packages/tilawa_ui_kit/IBMPlexSansArabic`) via
  `AppTheme` — not Alexandria, not runtime Google Fonts fetch in production.
- Screen titles: `titleLarge` / `titleMedium`, `FontWeight.w700`; catalog screens
  may use centered uppercase for Quran/Qibla hubs when specified in feature UI.
- Arabic content: `titleSmall` `w700`, `textHeightLoose` (2.0).
- Metadata: `bodySmall`, `onSurfaceVariant`.
- **Text scale:** global clamp **1.0–1.0** via `tilawaProductTextScaler` on
  `MaterialApp.builder`; Home prayer hero extent math may assume up to **1.3** for
  layout slack (Quran reader uses dedicated reader settings).

---

## 5. Rhythm and elevation (Behance lifestyle)

- **Cards:** white fill on the neutral canvas, **28 dp** radius (`radiusCard`), restrained
  shadow (`opacityShadow` **0.04**, `opacityShadowStrong` **0.08** on `colorScheme.shadow`;
  offsets `(0, 1)` / `(0, 2)`, blur **8** — not heavy 0.18/0.28 stacks).
- **Featured cards:** gold linear gradient, no hairline border.
- **Segmented controls / filter pills:** active = solid `primary` + `onPrimary`;
  inactive = neutral track + `onSurface` text.
- **Floating chrome** (bottom nav, player): `opacityShadowStrong` + optional glass tokens.
- **Reader page:** strongest shadow band reserved for Mushaf frame only.
- **Touch targets:** minimum **48 dp** (`kMeMuslimMinInteractiveDimension`) on all
  in-app interactive elements.

| Family | Token | Use |
|---|---|---|
| `card` / `pill` | `radiusExtraLarge` (28 dp) | Cards, buttons, chips |
| `chrome` | `radiusLarge` (24 dp) | Search, segment tracks |
| `hero` | `radiusHero` (32 dp) | Hub summary groups |

---

## 6. Motion

- `durationFast` (200 ms) toggles; `durationMedium` (400 ms) transitions.
- `Curves.easeOutCubic` on chrome — calm, not playful.
- Reader page-turn timing stays slowest in the app.

---

## 7. Voice and copy

Unchanged from prior brand: calm, respectful, no exclamation marketing, Support
not Premium. See §8 in prior revision — strings live in `*.arb`.

---

## 8. Brand-bearing surfaces (priority)

1. Home hub + Last Read gold card
2. Quran index / surah list
3. Qibla finder
4. Prayer times
5. Bottom navigation shell
6. Mushaf reader
7. Athkar / dhikr
8. Settings + Support MeMuslim

---

## 9. External reference

| Source | Role |
|---|---|
| [Behance gallery 230050359](https://www.behance.net/gallery/230050359/Islamic-App-Mobile-UIUX-Design-for-Muslim-Lifestyle) | **Primary visual north star** (palette, cards, lifestyle IA mood) |
| `design-md/apple/DESIGN.md` | Rhythm/restraint reference only — not palette |

---

## 10. Support MeMuslim

Unchanged ethics — see [`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md)
and [`packages/ui_kit/docs/support_visual_system.md`](../packages/ui_kit/docs/support_visual_system.md).
Calm parchment surfaces; orange Ink CTA; no gold pay heroes.

