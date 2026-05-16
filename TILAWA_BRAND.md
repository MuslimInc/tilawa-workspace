# Tilawa — TILAWA_BRAND.md

Islamic-brand identity layer for **Tilawa**. Sits **on top of** `DESIGN.md` and `AGENTS.md` — it does not replace tokens, redefine the palette, or introduce a new scheme. It names the *feeling* and the *cultural anchor*, and binds those to the tokens and `ColorScheme` roles that already exist.

**Read order:** `AGENTS.md` (how to build) → `DESIGN.md` (what tokens exist) → **this file** (how to make it feel like Tilawa). When this file conflicts with `DESIGN.md`, `DESIGN.md` wins on implementation; this file wins on intent.

**Reference moodboard:** [`design-md/apple/DESIGN.md`](design-md/apple/DESIGN.md) — for **rhythm, restraint, and reverence** only. We borrow Apple's discipline (the artifact speaks, the chrome recedes, exactly one shadow on the artifact, surface-color change as the divider). We do **not** borrow Apple's palette, type, or pill grammar. Tilawa's accent is teal; the artifact is the Mushaf page, not a phone.

---

## 1. Brand essence

Tilawa is a **Mushaf-first reading and listening companion**. The reader opens it for the same reason they open a physical Mushaf: to read, to hear recitation, to remember. Everything in the UI either serves that act or gets out of its way.

Three words anchor every visual decision:

| Word | What it means in pixels |
|---|---|
| **Reverent** | No decorative chrome competes with Arabic text. Gradients are atmospheric, never branding. The reader frame is the quietest surface in the app. |
| **Scholarly** | Type is calm, neutral, dense-friendly. Layouts cap at `TilawaContentBounds.reader` (720) so lines breathe like a printed page. Color is muted; the page is the loudest object. |
| **Welcoming** | Warm Mushaf gold and scholarly sage as supporting accents — never neon. Empty states and onboarding feel like an invitation, not a feature pitch. |

If a screen does not feel like at least two of these, it is off-brand.

---

## 2. Cultural anchor (what makes it Islamic, not just "calm")

We resist the temptation to bolt on stereotype motifs (arches, lanterns, crescents in chrome). Islamic identity comes from **typography**, **restraint**, and **manuscript-derived color**, not iconography:

- **Mushaf as the artifact.** The Quran reader page receives the *single* shadow in the app (`TilawaDesignTokens.opacityShadowStrong` band, layered per the existing reader theme). Cards, sheets, buttons get **flat or hairline** treatment — no elevation arms-race around the page.
- **Arabic-first typography care.** UI is **Alexandria** (per DESIGN §3); Arabic content uses the QCF/Mushaf families already wired in `packages/quran` (DESIGN §13 file map). Line-height token `textHeightLoose` (2.0) is the default for any surface that renders Arabic prose (surah lists, ayah meta, du'a strips).
- **Manuscript-derived palette.** The presets in DESIGN §2 already carry this lineage — **Teal** (calligrapher's ink shimmer), **Gold** `#8C681F` (Mushaf gilding), **Sage** `#6F7F58` (scholar's cloth), **Brown** `#7B5E3B` (parchment age). This file makes them **named roles**, see §3.
- **Geometric ornament as accent, never frame.** Existing ambient line work (e.g. `_RecitersAmbientPainter` arcs) is fine — thin, primary-tinted at ≤ `opacitySubtle × 0.4`, never closed shapes, never replacing whitespace.
- **No imagery of people, no flags, no national symbols.** Photography, when it appears (reciter portraits, share composer), is silhouette/initial-based or content-only.

---

## 3. Brand color roles

These are **names for existing tokens**, not new hexes. Feature code still reads `Theme.of(context).colorScheme.*` — this table just clarifies *intent*.

| Brand role | Maps to | When to use |
|---|---|---|
| **Ink** (the calligrapher's stroke) | `colorScheme.primary` (any user preset) | Every "tap me" signal: primary CTAs, selected state, active toggles, link-tinted icons. Single accent rule — no second action color on a screen. |
| **Gilding** (Mushaf gold accent) | `colorScheme.tertiary` (assembled from `#8C681F`) | **Rare**, ceremonial moments only: surah number medallion border, juz/hizb markers, "finished reading" celebratory state, milestone counters. Not for buttons. |
| **Scholar** (sage neutral-warm) | `colorScheme.secondary` | Supporting metadata: moshaf labels, recitation-style tags, secondary chips. Never primary CTA. |
| **Parchment** (page rest) | `colorScheme.surface` / `surfaceContainerLow` | The default reading and listing surface. In light mode this is near-white (DESIGN §2); in dark mode it is the deep green-tinted neutral — both read as "the page." |
| **Hairline** (manuscript rule) | `colorScheme.outlineVariant` at `borderWidthThin` | The *only* divider grammar. No drop shadows on cards, no inset rules. One thin line is enough. |
| **Vellum** (raised quiet container) | `colorScheme.surfaceContainerHigh` | Header bars, search field surrounds, action-button rests. Reads as "slightly above the page," never as "elevated card." |

**Anti-patterns:**
- Don't paint Gilding (`tertiary`) onto a button — it becomes a gold CTA that screams "premium." Gilding is decorative, never interactive.
- Don't use Scholar (`secondary`) as a co-primary. There is one accent per screen.
- Don't introduce a second neutral ramp. Parchment + Vellum are the only surface tiers in feature code.

---

## 4. Typography intent

`DESIGN.md` §3 specifies Alexandria via Google Fonts and Material 3 roles. This layer adds *when each role carries brand voice*:

| Use | Role | Brand intent |
|---|---|---|
| Screen title (Reciters, Surahs, Settings) | `titleLarge` or `titleMedium` w/ `FontWeight.w700` | Confident but quiet. No tracking changes — Alexandria's default cadence is the brand. |
| Body, list items | `bodyMedium` / `bodyLarge` | The reading pace. Never bump weight to 500 to "fix" softness — use the existing 400/600 ladder. |
| Arabic surah name / reciter name (Arabic locale) | `titleSmall` w/ `w700`, `textHeightLoose` | Loose line-height is non-negotiable for Arabic legibility. |
| Moshaf / metadata strip | `bodySmall`, `onSurfaceVariant`, `w600` | Speaks softly. Always second to the name above it. |
| Numeric counters (favorites count, juz number) | `labelSmall` `w700` | Numeric weight earns its loudness only inside a chip/badge. |

**Anti-patterns:**
- Don't hard-code `fontSize:` in feature code. Reach for `theme.textTheme.<role>` and adjust weight if needed.
- Don't use `displayLarge` outside marketing-density empty states. The app's actual hero is the Arabic text it renders, not a 56 px headline.

---

## 5. Rhythm and elevation (Apple's discipline, Tilawa's voice)

Apple's lesson: **the color change is the divider; the artifact gets the single shadow; everything else is flat.** Translate:

- **Cards (reciter, surah, settings tile):** flat fill (`surfaceContainerLow`) + 1px hairline (`outlineVariant` at `borderWidthThin`). **No box shadow.** (Existing `ReciterCard` already does this — keep it.)
- **Floating chrome** (bottom nav, player bar): use the existing layered shadow tokens (`opacityShadow` / `opacityShadowStrong`) and `blurGlass` / `opacityGlass` *consistently in the same family of components* — not sprinkled.
- **Section dividers inside long lists:** prefer a **change in surface tier** (`surface` → `surfaceContainerLow`) over an explicit divider line. Falls back to a hairline only when tiers can't change.
- **The reader page (Mushaf):** the **only** surface allowed a full layered shadow on its frame. Other screens may use the *strong* shadow token only on the player/nav float, never on lists.

**Touch targets:** 44 dp minimum (`kTilawaMinInteractiveDimension`) — same as DESIGN §4. Brand-level: prefer **wide, generous** hit zones over packed grids. Density is the enemy of reverence.

---

## 6. Motion intent

- **Defaults:** `tokens.durationFast` (200 ms) for state toggles; `durationMedium` (400 ms) for screen transitions; `durationSlow` (600 ms) only for narrative moments (first-launch reveal, "khatm" completion).
- **No spring overshoot on chrome.** Bottom-sheet expansion, list scroll-jump, and tab switches use `Curves.easeOutCubic` — calm, not playful.
- **The Mushaf page transition is sacred** — keep the existing reader page-turn timing. Brand rule: never let any other animation feel *faster* than a page turn. Speed implies hierarchy; the page is highest.

---

## 7. Imagery, illustration, ornament

- **Reciter avatars:** initials or content-only stand-ins. No stock photography. If portraits ever ship, they need explicit reciter consent and an accessibility caption.
- **Empty-state illustration:** monoline, primary-tinted, **no full color illustrations**. The state matters; the drawing should not.
- **Ornament:** geometric line work (the `_RecitersAmbientPainter` arcs are the canonical example) — thin, primary or tertiary tinted at ≤ `opacitySubtle * 0.4`, only as **ambient atmosphere**, never as a frame or chrome border.

---

## 8. Voice and copy (UI strings)

- **Calm, second-person, no exclamation marks in chrome.** "Search reciters", not "Find your favorite reciter!"
- **Respectful religious vocabulary.** "Surah", "Juz", "Hizb", "Mushaf" stay capitalized in English copy. Arabic UI uses native diacritics where the localization already supplies them.
- **Errors apologize gently, suggest the next step.** "We couldn't reach the audio server. Try again in a moment." Not "Error 500." (Concrete error codes belong in logs, not chrome.)
- **No marketing superlatives.** "Premium", "AI-powered", "best-in-class" do not appear.

(Concrete strings live in `*.arb` files; this is the voice they should land in.)

---

## 9. Brand-bearing components (priority order for upgrades)

The screens and components that most define the Tilawa feeling — invest brand polish here first:

1. **Quran Reader page chrome** — the actual artifact; already the lowest-elevation surface.
2. **Reciters list / detail** — first-time impression for the audio side of the app.
3. **Surah list & jumpers** — the most-used navigator; Arabic typography rule applies hardest here.
4. **Player bar** — the persistent floating chrome; only the player + nav get the strong layered shadow.
5. **Bottom-sheet scaffold** — already standardized (`TilawaBottomSheetScaffold`); brand rule is *Hairline only*, no card shadow inside sheets.
6. **Settings** — calm, grouped, parchment-on-parchment with surface-tier change as the section break.

Everything else inherits.

---

## 10. Do's and don'ts (this layer)

**Do**
- Treat `DESIGN.md` as the implementation contract; this file as the *why*.
- Map every color you reach for back to a brand role in §3, even if you write `colorScheme.primary`.
- Keep one accent per screen, one shadow per page, one hairline per divider.
- Make the Arabic content the loudest object on the screen.

**Don't**
- Don't introduce Islamic-themed iconography (mosques, crescents, lanterns) into chrome. Identity comes from typography and restraint.
- Don't use gold (Gilding) as a CTA color, ever.
- Don't add a second accent because "the screen feels flat." Flat is the brand.
- Don't paste an external brand's palette (Apple Action Blue, Starbucks green) — see DESIGN §13.

---

## 11. Active brand initiative (rolling)

| Field | Detail |
|---|---|
| **Initiative** | Reciters screen brand exemplar |
| **Status** | In progress on branch `fix/reciters-screen-ui-ux`. Surface tier and hairline grammar already in place; ambient ornament present and on-brand. |
| **Brand check** | Reverent ✓ (no shadows on cards, ambient arcs subtle) · Scholarly ✓ (Alexandria, `textHeightLoose` ready) · Welcoming — improve via section breathing and warmer surface tier rhythm. |
| **Next** | Apply §5 rhythm rule to the reciter list: lean on surface-tier change instead of hairlines for section grouping; ensure header bar uses Vellum (`surfaceContainerHigh`) consistently with bottom-nav family. |

Replace or extend this section when the initiative completes or a new one begins.
