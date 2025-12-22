---
trigger: always_on
---

## Layout Best Practices

### Building Flexible and Overflow-Safe Layouts

#### For Rows and Columns

- **`Expanded`:** Use to make a child widget fill the remaining available space
  along the main axis.
- **`Flexible`:** Use when you want a widget to shrink to fit, but not
  necessarily grow. Don't combine `Flexible` and `Expanded` in the same `Row` or
  `Column`.
- **`Wrap`:** Use when you have a series of widgets that would overflow a `Row`
  or `Column`, and you want them to move to the next line.

#### For General Content

- **`SingleChildScrollView`:** Use when your content is intrinsically larger
  than the viewport, but is a fixed size.
- **`ListView` / `GridView`:** For long lists or grids of content, always use a
  builder constructor (`.builder`).
- **`FittedBox`:** Use to scale or fit a single child widget within its parent.
- **`LayoutBuilder`:** Use for complex, responsive layouts to make decisions
  based on the available space.

### Layering Widgets with Stack

- **`Positioned`:** Use to precisely place a child within a `Stack` by anchoring it to the edges.
- **`Align`:** Use to position a child within a `Stack` using alignments like `Alignment.center`.

### Advanced Layout with Overlays

- **`OverlayPortal`:** Use this widget to show UI elements (like custom
  dropdowns or tooltips) "on top" of everything else. It manages the
  `OverlayEntry` for you.

  ```dart
  class MyDropdown extends StatefulWidget {
    const MyDropdown({super.key});

    @override
    State<MyDropdown> createState() => _MyDropdownState();
  }

  class _MyDropdownState extends State<MyDropdown> {
    final _controller = OverlayPortalController();

    @override
    Widget build(BuildContext context) {
      return OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (BuildContext context) {
          return const Positioned(
            top: 50,
            left: 10,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('I am an overlay!'),
              ),
            ),
          );
        },
        child: ElevatedButton(
          onPressed: _controller.toggle,
          child: const Text('Toggle Overlay'),
        ),
      );
    }
  }
  ```

## Color Scheme Best Practices

### Contrast Ratios

- **WCAG Guidelines:** Aim to meet the Web Content Accessibility Guidelines
  (WCAG) 2.1 standards.
- **Minimum Contrast:**
  - **Normal Text:** A contrast ratio of at least **4.5:1**.
  - **Large Text:** (18pt or 14pt bold) A contrast ratio of at least **3:1**.

### Palette Selection

- **Primary, Secondary, and Accent:** Define a clear color hierarchy.
- **The 60-30-10 Rule:** A classic design rule for creating a balanced color scheme.
  - **60%** Primary/Neutral Color (Dominant)
  - **30%** Secondary Color
  - **10%** Accent Color

### Complementary Colors

- **Use with Caution:** They can be visually jarring if overused.
- **Best Use Cases:** They are excellent for accent colors to make specific
  elements pop, but generally poor for text and background pairings as they can
  cause eye strain.

### Example Palette

- **Primary:** #0D47A1 (Dark Blue)
- **Secondary:** #1976D2 (Medium Blue)
- **Accent:** #FFC107 (Amber)
- **Neutral/Text:** #212121 (Almost Black)
- **Background:** #FEFEFE (Almost White)

## Font Best Practices

### Font Selection

- **Limit Font Families:** Stick to one or two font families for the entire
  application.
- **Prioritize Legibility:** Choose fonts that are easy to read on screens of
  all sizes. Sans-serif fonts are generally preferred for UI body text.
- **System Fonts:** Consider using platform-native system fonts.
- **Google Fonts:** For a wide selection of open-source fonts, use the
  `google_fonts` package.

### Hierarchy and Scale

- **Establish a Scale:** Define a set of font sizes for different text elements
  (e.g., headlines, titles, body text, captions).
- **Use Font Weight:** Differentiate text effectively using font weights.
- **Color and Opacity:** Use color and opacity to de-emphasize less important
  text.

### Readability

- **Line Height (Leading):** Set an appropriate line height, typically **1.4x to
  1.6x** the font size.
- **Line Length:** For body text, aim for a line length of **45-75 characters**.
- **Avoid All Caps:** Do not use all caps for long-form text.

### Example Typographic Scale

```dart
// In your ThemeData
textTheme: const TextTheme(
  displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
  titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
  bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
  bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
  labelSmall: TextStyle(fontSize: 11.0, color: Colors.grey),
),
```

## Documentation

- **`dartdoc`:** Write `dartdoc`-style comments for all public APIs.

### Documentation Philosophy

- **Comment wisely:** Use comments to explain why the code is written a certain
  way, not what the code does. The code itself should be self-explanatory.
- **Document for the user:** Write documentation with the reader in mind. If you
  had a question and found the answer, add it to the documentation where you
  first looked. This ensures the documentation answers real-world questions.
- **No useless documentation:** If the documentation only restates the obvious
  from the code's name, it's not helpful. Good documentation provides context
  and explains what isn't immediately apparent.
- **Consistency is key:** Use consistent terminology throughout your
  documentation.

### Commenting Style

- **Use `///` for doc comments:** This allows documentation generation tools to
  pick them up.
- **Start with a single-sentence summary:** The first sentence should be a
  concise, user-centric summary ending with a period.
- **Separate the summary:** Add a blank line after the first sentence to create
  a separate paragraph. This helps tools create better summaries.
- **Avoid redundancy:** Don't repeat information that's obvious from the code's
  context, like the class name or signature.
- **Don't document both getter and setter:** For properties with both, only
  document one. The documentation tool will treat them as a single field.

### Writing Style

- **Be brief:** Write concisely.
- **Avoid jargon and acronyms:** Don't use abbreviations unless they are widely
  understood.
- **Use Markdown sparingly:** Avoid excessive markdown and never use HTML for
  formatting.
- **Use backticks for code:** Enclose code blocks in backtick fences, and
  specify the language.

### What to Document

- **Public APIs are a priority:** Always document public APIs.
- **Consider private APIs:** It's a good idea to document private APIs as well.
- **Library-level comments are helpful:** Consider adding a doc comment at the
  library level to provide a general overview.
- **Include code samples:** Where appropriate, add code samples to illustrate usage.
- **Explain parameters, return values, and exceptions:** Use prose to describe
  what a function expects, what it returns, and what errors it might throw.
- **Place doc comments before annotations:** Documentation should come before
  any metadata annotations.

## Accessibility (A11Y)

Implement accessibility features to empower all users, assuming a wide variety
of users with different physical abilities, mental abilities, age groups,
education levels, and learning styles.

- **Color Contrast:** Ensure text has a contrast ratio of at least **4.5:1**
  against its background.
- **Dynamic Text Scaling:** Test your UI to ensure it remains usable when users
  increase the system font size.
- **Semantic Labels:** Use the `Semantics` widget to provide clear, descriptive
  labels for UI elements.
- **Screen Reader Testing:** Regularly test your app with TalkBack (Android) and
  VoiceOver (iOS).
