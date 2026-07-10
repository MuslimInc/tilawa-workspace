# Feature Specification: Islamic Home Screen Widget Suite (v1)

**Feature Branch**: `041-islamic-widget-suite`

**Created**: 2026-07-11

**Status**: Ready for Planning

**Input**: User description: "Build a premium Arabic-first widget suite (prayer times countdown, Ayah of the Day in authentic Mushaf QCF script, morning/evening adhkar, Hijri date) plus shareable QCF ayah cards, as the app's primary acquisition feature — competing with and differentiating from Glassify (100K+ installs on widgets alone) by owning what no competitor can copy: verses rendered in the authentic King Fahd Complex (QCF V4) Mushaf script."

## Strategic Context

The app sits at ~50 installs in the crowded Quran and prayer-app category. Growth requires a wedge feature that (a) creates a visible daily home-screen presence, (b) is demonstrably better than incumbent offerings, and (c) produces organically shareable artifacts. The Arabic widget market is proven (Glassify: 100K+ installs and 7K+ reviews), and its primary selling point is Arabic typography. Tilawa can differentiate through its existing authentic QCF V4 Mushaf presentation, giving users verse widgets and share cards that visually match the Madinah Mushaf rather than generic Arabic text.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Prayer Times Countdown Widget (Priority: P1)

A Muslim user places a prayer times widget on their home screen. It shows all five prayers for today, highlights the next prayer, and displays a live countdown to it. Times update automatically at midnight and when the user's location or calculation settings change. Tapping the widget opens the app's prayer screen.

**Why this priority**: Prayer times with countdown is the single most demanded widget in the Islamic app category and the strongest install driver — it delivers value five times a day without opening the app. It must ship first because it anchors the suite's daily utility.

**Independent Test**: Can be fully tested by adding the widget to a home screen, verifying the five prayer times match the in-app times, watching the countdown advance to the next prayer, crossing a prayer boundary (next prayer rotates), crossing midnight (new day's times load), and tapping through to the app.

**Acceptance Scenarios**:

1. **Given** the widget is placed and location is set, **When** the user views the home screen, **Then** all five prayer times for the current day are shown with the next prayer visually highlighted and a countdown to it.
2. **Given** a prayer time passes, **When** the widget next refreshes, **Then** the highlight and countdown move to the following prayer within one minute of the boundary.
3. **Given** midnight passes, **When** the widget next refreshes, **Then** the new day's prayer times are displayed without opening the app.
4. **Given** the user changes calculation method or location in the app, **When** they return to the home screen, **Then** the widget reflects the new times.
5. **Given** the device rebooted, **When** the home screen loads, **Then** the widget shows current data (not a blank or stale frame).
6. **Given** the user taps the widget, **When** the app opens, **Then** it lands on the prayer times screen.

---

### User Story 2 - Ayah of the Day in Authentic Mushaf Script (Priority: P2)

A user places an "Ayah of the Day" widget that displays a Quranic verse rendered in the authentic QCF V4 Mushaf script — pixel-identical to the printed Madinah Mushaf — on an elegant background. The verse rotates daily. Tapping it opens the Mushaf at that verse.

**Why this priority**: This is the differentiation flagship — no competitor (including Glassify) can render verses in the true Mushaf script inside a widget. It is the screenshot that sells the app on the Play listing and in social content. It ships second only because P1 carries the daily-utility load.

**Independent Test**: Can be fully tested by adding the widget, visually confirming the verse renders in QCF Mushaf script (correct glyphs, diacritics, verse-end marks), waiting for (or simulating) the daily rotation, and tapping through to the exact verse in the Mushaf.

**Acceptance Scenarios**:

1. **Given** the widget is placed, **When** the user views it, **Then** the verse is rendered in authentic QCF script with correct RTL layout, diacritics, and verse markers — not in a generic Arabic font.
2. **Given** a new calendar day begins, **When** the widget refreshes, **Then** a different verse is displayed following the rotation policy.
3. **Given** the user taps the widget, **When** the app opens, **Then** the Mushaf opens at that verse's page.
4. **Given** the device has no network, **When** the daily rotation occurs, **Then** the verse still renders (all content is bundled offline).
5. **Given** the widget is resized between supported sizes, **When** it re-renders, **Then** the verse re-lays out legibly without clipping.

---

### User Story 3 - Morning/Evening Adhkar Widget (Priority: P3)

A user places an adhkar widget that surfaces morning adhkar in the morning window and evening adhkar in the evening window, showing one dhikr at a time with a tap-to-advance interaction. Tapping the dhikr text opens the full adhkar flow in the app.

**Why this priority**: Creates two additional daily engagement windows beyond prayers and connects the widget suite to the app's existing adhkar content. Lower than P1/P2 because it drives retention more than acquisition.

**Independent Test**: Can be fully tested by adding the widget during a morning window (shows morning adhkar), checking again in the evening window (shows evening adhkar), advancing through items, and tapping through into the in-app adhkar flow.

**Acceptance Scenarios**:

1. **Given** the local time is within the morning window, **When** the user views the widget, **Then** morning adhkar content is shown; likewise evening content in the evening window.
2. **Given** the user taps the advance control, **When** the widget updates, **Then** the next dhikr in the set is displayed with progress indication (e.g., 3/12).
3. **Given** the user taps the dhikr body, **When** the app opens, **Then** the corresponding adhkar flow opens at that set.

---

### User Story 4 - Hijri Date Widget (Priority: P4)

A user places a Hijri date widget showing today's Hijri and Gregorian dates with elegant Arabic typography. A per-user adjustment setting (±2 days) corrects regional moon-sighting differences and applies everywhere the app shows Hijri dates.

**Why this priority**: Simple, high-satisfaction, low-effort. Competitor reviews (Glassify) show recurring complaints about broken Hijri adjustment — shipping it correct is an easy review-bait win. Lowest priority because it is the least differentiated.

**Independent Test**: Can be fully tested by adding the widget, verifying today's Hijri date, changing the adjustment offset in settings, and confirming the widget and in-app dates shift consistently.

**Acceptance Scenarios**:

1. **Given** the widget is placed, **When** viewed, **Then** the correct Hijri date (month name in Arabic script) and Gregorian date are shown.
2. **Given** the user sets a +1 day Hijri adjustment, **When** the widget refreshes, **Then** the displayed Hijri date shifts by +1 day and matches the in-app Hijri display.
3. **Given** local midnight passes, **When** the widget refreshes, **Then** both displayed dates advance according to the device's current timezone and the saved Hijri adjustment.

---

### User Story 5 - Shareable QCF Ayah Cards (Priority: P5)

From the Mushaf or the Ayah widget's detail view, a user generates a beautiful share card: the selected verse(s) rendered in QCF Mushaf script on a curated background with subtle app attribution, and shares it to WhatsApp/Facebook/Instagram.

**Why this priority**: The organic acquisition loop — every shared card is a targeted ad reaching exactly the right audience. Ranked P5 only because it depends on the same QCF bitmap rendering engine that P2 builds; once P2 exists, this story is a thin layer over it.

**Independent Test**: Can be fully tested by selecting a verse, generating a card, verifying script fidelity and attribution, and completing a share to an external app.

**Acceptance Scenarios**:

1. **Given** a verse is selected, **When** the user taps share-as-card, **Then** a card preview renders in QCF script with a choice of at least 3 background styles.
2. **Given** a card preview, **When** the user confirms share, **Then** the system share sheet opens with the rendered image and the card carries discreet app attribution.
3. **Given** a multi-verse selection within a reasonable limit, **When** the card renders, **Then** all verses appear correctly ordered RTL without truncation, or the user is told the selection is too long.

---

### Edge Cases

- Battery optimization / OEM background restrictions (Xiaomi, Oppo, Realme — dominant in Egypt) prevent scheduled widget refreshes → widget must degrade gracefully (show last-known data + staleness cue, never a blank frame) and refresh opportunistically.
- Location permission revoked after widget placement → widget shows last-known times with a "location needed" affordance, never crashes or blanks.
- Countdown display across process death: minute-level countdown must not depend on a live process (no per-second updates; battery-safe cadence).
- Timezone change / travel / DST → times and countdown recompute on next refresh.
- Widget host re-creation after launcher restart or app update → widget re-renders from persisted state.
- Very small widget sizes → each widget defines a minimum size and a reduced layout variant; text never clips mid-glyph.
- Light/dark launcher wallpapers → each widget offers light/dark/auto theme variants.
- RTL device locale vs LTR locale → layouts mirror correctly in both.
- QCF glyph rendering failure (missing page font) → fallback to bundled Uthmanic hafs text style, never tofu boxes.
- Ramadan: prayer widget must correctly reflect Fajr/Maghrib prominence without a special mode in v1 (explicitly out of scope: Imsak row).
- Storage-constrained devices → generated widget artwork remains size-bounded and old temporary artwork is removed without blanking placed widgets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide four home-screen widget types: Prayer Times Countdown, Ayah of the Day, Morning/Evening Adhkar, and Hijri Date, each discoverable in the launcher's widget picker with a preview image.
- **FR-002**: Prayer widget MUST show all five daily prayers, highlight the next prayer, and show time-remaining at minute granularity, updating on a battery-safe schedule (no per-second background work).
- **FR-003**: Prayer widget MUST source times from the same calculation pipeline as the in-app prayer screen (single source of truth; no drift between widget and app).
- **FR-004**: Ayah widget MUST present verses using the authentic QCF V4 glyph set; generic-font presentation of the verse body is not acceptable for the primary display path.
- **FR-005**: Ayah rotation MUST be deterministic per day, work fully offline, and be curated (rotation pool excludes verses that render poorly at widget sizes).
- **FR-006**: Adhkar widget MUST switch between morning and evening sets based on local time windows and support in-widget advancement through items.
- **FR-007**: Hijri adjustment (±2 days) MUST be a single user setting honored by the widget, the app, and any notification surface that shows Hijri dates.
- **FR-008**: Every widget MUST deep-link on tap to its corresponding in-app surface (prayer screen, Mushaf page, adhkar flow, calendar/home).
- **FR-009**: Every widget MUST offer at least light and dark theme variants and at least two size classes, all consistent with the app's design tokens.
- **FR-010**: Widgets MUST survive device reboot, launcher restart, and app update by re-rendering from persisted state without requiring the app to be opened.
- **FR-011**: Share-card generation MUST produce a high-resolution image of the selected verse(s) in QCF script with selectable backgrounds and discreet app attribution, delivered through the system share sheet.
- **FR-012**: System MUST emit analytics for: widget added/removed (by type), widget tapped (by type), share card generated, share card shared (by destination where available) — sufficient to compute the Success Criteria below.
- **FR-013**: All widget text (labels, prayer names, dhikr content) MUST be localized in Arabic and English at launch, following the device or in-app language setting.
- **FR-014**: Widget refresh scheduling MUST tolerate OEM background restrictions: last-known data is always shown, and a staleness indicator appears when data is older than one day.
- **FR-015**: Each widget MUST expose meaningful accessibility labels, preserve a logical reading order in Arabic and English, and remain legible at supported system text-scaling settings.
- **FR-016**: Widget previews and placed widgets MUST not expose precise location coordinates, private reading history, or other sensitive user data; analytics MUST identify widget type and interaction without recording displayed Quran or adhkar content.
- **FR-017**: The prayer widget MUST visibly distinguish the next prayer without relying on color alone.
- **FR-018**: The adhkar widget MUST use 04:00–11:59 local time for the morning set and 16:00–23:59 for the evening set; outside those windows it MUST retain the most recently applicable set and label it clearly.
- **FR-019**: Adhkar progress MUST reset when the applicable morning/evening period changes and MUST persist across launcher or process restarts within the same period.
- **FR-020**: Share cards MUST support one to five consecutive verses; selections outside that range MUST be rejected before preview with a clear, localized explanation.
- **FR-021**: Share-card preview MUST allow the user to cancel without creating a share artifact, and generated temporary artifacts MUST be removed after the share flow or during routine cleanup.
- **FR-022**: All four widgets MUST present a non-blank first-use state when required setup is incomplete, with a localized action that opens the exact in-app setup surface.
- **FR-023**: A daily Ayah selection MUST remain stable for the entire local calendar day, including after reboot, and MUST not repeat until the available curated rotation pool has been exhausted.
- **FR-024**: The suite MUST define supported minimum dimensions for every size class and prevent clipped Quranic glyphs, prayer names, dates, or primary controls at those dimensions.

### Key Entities

- **WidgetInstance**: A placed widget — type, size class, theme variant, per-instance configuration; persisted so re-renders need no app launch.
- **PrayerScheduleSnapshot**: The day's computed prayer times (with calculation settings fingerprint) persisted for widget consumption.
- **DailyAyahSelection**: The verse chosen for a given date — verse reference, rendered-asset cache key, rotation-pool version.
- **AdhkarSetProgress**: Current set (morning/evening), item index, and last-interaction timestamp for the adhkar widget.
- **ShareCard**: A generated artifact — verse range, background style, rendered image reference; transient except analytics.
- **HijriAdjustment**: Single signed day-offset setting shared app-wide.
- **WidgetThemePreference**: The selected light, dark, or automatic appearance for one widget instance.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: ≥ 35% of active users have at least one widget placed within 30 days of release.
- **SC-002**: D7 retention of users with a widget placed is at least 15 percentage points higher than users without (validates the suite as a retention engine).
- **SC-003**: Widget taps account for ≥ 20% of daily app opens among widget users within 60 days.
- **SC-004**: ≥ 500 share cards generated in the first 60 days, with share-completion rate ≥ 60% of previews.
- **SC-005**: Play Store listing conversion (store visit → install) improves measurably after widget screenshots replace the current first-three screenshots (baseline captured before release).
- **SC-006**: At least 10 new Play reviews mentioning widgets within 90 days, with widget-related review sentiment ≥ 4.5 average.
- **SC-007**: Widget-attributed battery complaints: zero sustained (no review or support pattern attributing battery drain to widgets).
- **SC-008**: Crash-free sessions remain ≥ 99.5% after release (widgets add no stability regression).
- **SC-009**: Across the release device matrix, 100% of widgets show usable current or explicitly stale content within 10 seconds of being placed, after reboot, and after launcher restart; no tested state produces a blank widget.
- **SC-010**: All verses in the launch rotation pool and all supported one-to-five-verse share selections pass visual review with correct glyphs, diacritics, verse markers, RTL order, and no clipping at every supported size.
- **SC-011**: In moderated Arabic-first usability testing, at least 90% of participants can place any widget, understand its primary state, and reach its corresponding in-app destination without assistance.
- **SC-012**: Widget content and controls meet WCAG 2.1 AA contrast requirements, remain usable at 200% text scaling where the launcher supports scaling, and convey state without color alone.

## Assumptions

- The existing QCF V4 Quran presentation capability and licensed assets are available for reuse by widget and share-card experiences.
- Prayer time calculation, adhkar content, and Hijri conversion already exist in the app and expose (or can expose) their outputs to a native widget layer without duplicating business logic.
- v1 targets Android home-screen widgets only. Samsung lock-screen widgets, iOS widgets, and a paid "Pro designs" tier are explicitly out of scope for v1 (Pro tier is a candidate for v2 monetization, following the competitor's validated model).
- Huawei devices without Google services are out of scope for v1.
- Egypt-first launch: Arabic content quality is the bar; English is required but secondary.
- Group Khatma, memorization path, and teacher marketplace are separate future specs; this spec deliberately excludes them.
- The rotation pool for Ayah of the Day is editorially curated before launch (initial pool of ~90 verses, enough for a quarter without repetition).
- Hijri dates roll over at local midnight in v1. Maghrib-based rollover is deferred because a single predictable convention is easier to explain and verify across the app and widgets.
- Morning adhkar is applicable from 04:00 through 11:59 local time and evening adhkar from 16:00 through 23:59. Between these windows, the widget retains and labels the most recently applicable set.
- Share cards support one to five consecutive verses in v1; longer or non-consecutive selections remain available through existing text-sharing flows, if present.
- Users may place multiple instances of each widget type, and theme and size choices are stored per instance; shared religious-content settings remain app-wide.
- The device timezone is authoritative for daily rotation, date rollover, adhkar windows, and prayer countdown boundaries.

## Dependencies

- Accurate prayer schedules require the user to complete location and prayer-calculation setup in the app.
- Authentic verse presentation depends on the existing licensed QCF V4 content and its verified Quran-text mapping remaining available for offline use.
- Adhkar content, translations, and Hijri conversion must be approved and available offline in Arabic and English before release.
- Launcher capabilities differ by device; supported size classes and automatic appearance behavior are limited to capabilities exposed by the host launcher.
- Store-listing measurement requires a conversion baseline captured before widget-first screenshots are published.

## Out of Scope (v1)

- Per-second live countdown (battery cost outweighs value; minute granularity only).
- Widget customization studio (Glassify-style color/font editors) — v1 ships curated variants only.
- Paid/Pro widget tier, seasonal packs, lock-screen widgets, weather or non-Islamic utility widgets.
- Imsak/Ramadan-specific rows, Qibla widget, audio playback from widgets.
- Editing verse text, removing required attribution, arbitrary user-uploaded backgrounds, and sharing more than five verses in one card.

## Rollout & Measurement Plan

1. Internal build → device matrix QA (must include at least one Xiaomi/Redmi and one Samsung device; Egypt's dominant OEMs).
2. Play internal track → staged production rollout (20% → 100%) watching SC-007/SC-008 gates.
3. Marketing sync at 100%: new Play screenshots (widget-first), one short-form video per widget type, share-card social seeding.
4. 30/60/90-day checkpoint reviews against SC-001…SC-008; failing criteria trigger iterate-or-kill decisions per widget type rather than suite-wide.
