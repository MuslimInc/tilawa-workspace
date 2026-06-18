# Tilawa Brand

Visual identity layer for **Tilawa**, aligned with the warm Islamic lifestyle
reference: [Behance — Islamic App Mobile UI/UX Design for Muslim Lifestyle](https://www.behance.net/gallery/230050359/Islamic-App-Mobile-UIUX-Design-for-Muslim-Lifestyle)
(Deen Muslim concept by SpineEdge Studio).

**Read order:** `AGENTS.md` → `DESIGN.md` (tokens) → **this file** (intent) →
[`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md).
When this file conflicts with `DESIGN.md`, `DESIGN.md` wins on implementation;
this file wins on intent.

---

## 1. Brand essence

Tilawa is a **daily Muslim lifestyle companion** — prayer, Quran, Qibla, dhikr,
and calm home rituals in one warm, approachable shell. The product name stays
**Tilawa / تلاوة**; the visual language follows the Behance warm parchment +
brown + gold system.

| Word | What it means in pixels |
|---|---|
| **Warm** | Soft neutral canvas (`#F7F7F5`), brown ink (`#8B5E3C`), gold featured cards (`#FFD28E`→`#FF9E44`). No cool porcelain, no sage-green chrome. |
| **Clear** | One primary accent per screen. Generous radius (20–24 dp cards). Readable metadata in warm grey-brown. |
| **Faithful** | Arabic typography care (`textHeightLoose`), reverent reader surfaces, no stereotype chrome (mosques/crescents in app bars). |

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
| **Brown ink** | `colorScheme.primary` (`#8B5E3C`) | CTAs, active nav, selected pills/segments, link icons |
| **Gold gilding** | `colorScheme.tertiary` / featured gradient stops | Hero cards, Last Read, surah header banners — not purchase buttons |
| **Parchment** | `colorScheme.surfaceContainerLowest` (`#F7F7F5`) | Scaffold, canvas |
| **Card white** | `colorScheme.surface` | List rows, settings tiles |
| **Warm beige** | `colorScheme.surfaceContainerHigh` | Idle chips, search rests |
| **Hairline** | `colorScheme.outlineVariant` | Dividers at `borderWidthThin` |
| **Featured text** | `AppColors.featuredGradientForeground` | Copy on gold gradient cards |

**Anti-patterns:**
- Don't reintroduce sage green (`#219653`) as production primary.
- Don't use cool grey porcelain (`#F4F5F7`) on lifestyle surfaces.
- Don't use gold gradient on Support Tilawa CTAs.

---

## 4. Typography

- UI: bundled **IBM Plex Sans Arabic** via `AppTheme` (M3 roles).
- Screen titles: `titleLarge` / `titleMedium`, `FontWeight.w700`; catalog screens
  may use centered uppercase for Quran/Qibla hubs when specified in feature UI.
- Arabic content: `titleSmall` `w700`, `textHeightLoose`.
- Metadata: `bodySmall`, `onSurfaceVariant`.

---

## 5. Rhythm and elevation (Behance lifestyle)

- **Cards:** white fill on parchment, **24 dp** radius (`radiusCard`), **warm
  shadow** (`opacityShadow` / `opacityShadowStrong` on brown-tinted `shadow`).
- **Featured cards:** gold linear gradient, no hairline border.
- **Segmented controls / filter pills:** active = solid `primary` + `onPrimary`;
  inactive = parchment/beige track + brown or `onSurface` text.
- **Floating chrome** (bottom nav, player): layered shadow tokens + optional glass.
- **Reader page:** strongest shadow band reserved for Mushaf frame only.

| Family | Token | Use |
|---|---|---|
| `card` / `pill` | `radiusExtraLarge` (24 dp) | Cards, buttons, chips |
| `chrome` | `radiusLarge` (20 dp) | Search, segment tracks |
| `hero` | `radiusHero` (28 dp) | Hub summary groups |

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
8. Settings + Support Tilawa

---

## 9. External reference

| Source | Role |
|---|---|
| [Behance gallery 230050359](https://www.behance.net/gallery/230050359/Islamic-App-Mobile-UIUX-Design-for-Muslim-Lifestyle) | **Primary visual north star** (palette, cards, lifestyle IA mood) |
| `design-md/apple/DESIGN.md` | Rhythm/restraint reference only — not palette |

---

## 10. Support Tilawa

Unchanged ethics — see [`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md)
and [`packages/ui_kit/docs/support_visual_system.md`](../packages/ui_kit/docs/support_visual_system.md).
Calm parchment surfaces; brown Ink CTA; no gold pay heroes.
