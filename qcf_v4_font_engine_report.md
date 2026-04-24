# QCF v4 Font Engine & Layout Architecture

This document outlines the architectural approach, rendering mechanics, and layout strategies used by the Tilawa application to flawlessly render the King Fahd Complex (QCF v4) Quran fonts. The system achieves identical visual parity with the physical Madinah Mushaf and modern leading applications (like the Ayah app) by relying exclusively on mathematically precise native font glyphs rather than artificial UI padding.

## 1. The QCF v4 Font Mapping Strategy

Unlike conventional text rendering where a single universal font contains the entire Arabic alphabet, the King Fahd Complex layout (QCF v4) uses **Page-Specific Fonts**. 

Every single page of the Mushaf (from 1 to 604) is governed by its own dedicated `.woff` or `.ttf` binary file.
- **Page 1 (Al-Fatihah)**: Powered exclusively by `QCF4001_X-Regular.woff` (loaded into memory as font family `QCF_P001`).
- **Page 2 (Al-Baqarah)**: Powered exclusively by `QCF4002_X-Regular.woff` (loaded into memory as font family `QCF_P002`).

Because each page is a distinct font family, the text characters provided by the API (or local JSON) are not standard Arabic unicode characters. Instead, they are specific arbitrary scalar values (Hex codes) that map directly to the pre-composed, handcrafted vector glyphs inside that exact page's font file.

## 2. Dynamic Font Registration

Flutter natively requires fonts to be declared in `pubspec.yaml`. However, loading 604 different font files would obliterate the app's memory profile. To solve this, Tilawa uses a dynamic **`FontLoader`**.

Inside `QuranFontService`, the application observes which page the user is currently reading. When a page is requested (e.g., Page 1), the service dynamically plucks `QCF4001_X-Regular.woff` from the assets directory and injects its bytes directly into the Flutter Engine's typography cache. 

```dart
final fontLoader = FontLoader('QCF_P$formattedPageStr');
fontLoader.addFont(fetchFontBytes(pageNumber));
await fontLoader.load();
```
This guarantees ultra-smooth, high-fidelity rendering without bloat.

## 3. The 15-Line Grid System (Layout & Vertical Rhythm)

The core structure of the printed Madinah Mushaf relies on a strict **15-line** vertical grid block. Every page of the Quran adheres to this mathematical baseline rhythm. In Tilawa, `PageContent` enforces this 15-line grid structure natively by rendering a vertical `Column` containing exactly 15 `QuranLine` wrappers.

We load the exact verse layout for a specific page from `quran_page_index.json`. A typical page contains 15 lines of content:
`Line 1: [word1, word2, word3]`
`Line 2: [word4, word5, word6]`

### Utilizing Native Whitespace Glyph Mapping

If a line index from the JSON is empty (`[]`), Tilawa explicitly *refrains* from using Flutter widgets like `SizedBox` or `Padding`. Introducing structural Flutter UI widgets breaks the mathematical typographic rhythm of the font's baseline metric measurements. 

Instead, the engine falls back to the native font mapping internal to the QCF binary itself:

```dart
// If the JSON row has no verse data, fill it with the font's Native space block.
if (spans.isEmpty) {
  spans.add(TextSpan(text: '\u0020', style: baseStyle));
}
```
By analyzing the `.woff` binary via CMAP extraction, we verified that `U+0020` evaluates explicitly to the native `space` glyph created by the King Fahd developers. Injecting `\u0020` ensures the empty block sits on the exact pixel-perfect baseline, stretching exactly one uniform row high.

## 4. Perfect Vertical Centering (Pages 1 & 2)

Surah Al-Fatihah (Page 1) and the beginning of Surah Al-Baqarah (Page 2) are unique because their text does not natively span 15 rows. The JSON payload tightly packs their verses at the top of the grid `[Lines 1-8]`, leaving `[Lines 9-15]` empty.

If rendered natively, these pages would squash awkwardly against the top edge of the screen, ruining the beautiful centering seen in printed editions and premium apps.

### Dynamic Shifting and White Space Padding

To achieve the gorgeous, organic centering with the 2-row margin gap separating the **Surah Header** and the **Bismillah**, the reading engine structurally *reshuffles* the JSON array before the UI even renders:

| Grid Line Index | Native Data Map                           | Rendered Element               |
| --------------- | ----------------------------------------- | ------------------------------ |
| **Grid Line 1** | `[]`                                      | Native `\u0020` Gap            |
| **Grid Line 2** | `[]`                                      | Native `\u0020` Gap            |
| **Grid Line 3** | `rawLines[0]` (Mapped to _Surah Header_)  | Surah Header Banner            |
| **Grid Line 4** | `[]`                                      | Native `\u0020` Gap            |
| **Grid Line 5** | `[]`                                      | Native `\u0020` Gap            |
| **Grid Line 6** | `rawLines[1]` (Bismillah or Verse)        | Bismillah Widget / Ayah 1 Text |
| **Grid Line 7+**| `rawLines[2-7]`                           | Verse Texts                    |

By forcing the empty `[]` lines into the physical memory index of the page list, the `isScrollable` layouts—even horizontal Landscape screen orientations—faithfully render the native unicode whitespace constraints, maintaining symmetrical perfection. 

## 5. Bismillah Font Logic

While the core verses strictly use the `QCF_P###` font, the standard calligraphy **Bismillah** banner natively lives in its own standalone font: `QCF_BSML`. 

However, the Ayah app requires Page 1 & Page 2 Bismillahs to visually match the exact word-by-word font engine rather than the calligraphic banner. To solve this, `BismillahStyleConfig` implements centralized configuration:
- For **Pages 1 and 2**, the engine uses the native page font (`QCF_P001` / `QCF_P002`) and manually weaves in a thin unicode space block (`\u200A`) after the sequence "بسم" for pixel parity.
- For **Pages 3-604**, the engine falls back securely to the beautiful `QCF_BSML` global calligraphic header font.
