# Research: Islamic Home Screen Widget Suite (v1)

## Existing Prayer Widget as the Baseline

**Decision**: Extend the existing `AppWidgetProvider` + `RemoteViews` + versioned local snapshot approach used by the prayer widget.

**Rationale**: P1 is already implemented, tested, and integrated with reboot/time-change behavior. Reusing that boundary minimizes dependencies and allows launcher rendering without a Flutter engine.

**Alternatives considered**: A third-party Flutter widget plugin or Jetpack Glance. Both would create a second pattern beside the shipped provider, add migration risk, and do not remove the need for pre-rendered QCF content.

## Flutter/Native Responsibility Boundary

**Decision**: Flutter domain/application code owns religious-content selection, Hijri adjustment, schedule calculation, localization inputs, and image generation. Kotlin owns persistence of display-ready snapshots, widget-instance actions, lifecycle broadcasts, and `RemoteViews` rendering.

**Rationale**: This preserves the app's single sources of truth and Clean Architecture while keeping widgets usable after process death and reboot.

**Alternatives considered**: Reimplementing prayer, Hijri, Ayah, or Athkar rules in Kotlin. Rejected because duplicated religious logic would drift from the app and be harder to verify.

## QCF Ayah Rendering

**Decision**: Add a reusable bounded-artifact service around the existing `quran_qcf` rendering primitives. Flutter generates PNGs for exact widget dimensions and share-card presets, writes them atomically to app-private storage, and publishes the path only after validation.

**Rationale**: Android `RemoteViews` cannot host Flutter widgets or reliably reproduce the page-specific QCF typography. Pre-rendered images preserve glyphs, diacritics, verse markers, RTL order, and offline behavior.

**Alternatives considered**: Generic Arabic text in native TextViews (fails the differentiator), bundling all possible rendered verses (larger and inflexible), or starting Flutter for every refresh (slow and unreliable under OEM restrictions).

## Refresh and Scheduling Policy

**Decision**: Refresh on semantic boundaries—prayer boundary, local midnight, Athkar period boundary, settings/content change—and retain an OS-managed periodic backstop. Use visible chronometer behavior for prayer countdown and never schedule per-second work.

**Rationale**: It meets freshness needs with low battery impact and degrades to last-known content when OEM scheduling is delayed.

**Alternatives considered**: Frequent periodic workers or exact alarms for every visual update. Rejected for battery and policy cost.

## Daily Ayah Rotation

**Decision**: Choose deterministically from a versioned curated pool using local date and a stable installation seed, persisting the result for that date. Track recently used entries and do not repeat until the pool is exhausted.

**Rationale**: Selection remains stable through reboot, works offline, distributes content across users, and honors the no-repeat requirement.

**Alternatives considered**: Network-fed or purely random selection. Both can change during a day and fail offline.

## Widget Instance Configuration

**Decision**: Store theme, size/layout class, and interaction progress by Android widget ID; keep Hijri adjustment and religious-content settings app-wide.

**Rationale**: Multiple placements can look and behave independently without fragmenting religious settings.

**Alternatives considered**: One global theme/progress value. Rejected because it makes multiple instances interfere with each other.

## Sharing and Temporary Files

**Decision**: Build cards in the existing Flutter share feature, validate one-to-five consecutive Ayat before rendering, expose files through the existing secure share mechanism, and delete abandoned/expired artifacts through bounded cache cleanup.

**Rationale**: This reuses the current preview/share lifecycle and avoids permanent storage growth or broad file permissions.

**Alternatives considered**: Native card composition or saving every card to the gallery. Rejected due to duplicated QCF rendering and unwanted persistence/permissions.

## Accessibility and Localization

**Decision**: Maintain Arabic and English Android resources, explicit content descriptions, non-color next-prayer indicators, mirrored layouts, and compact fallbacks for large text. QCF artwork includes a localized accessible description containing the Surah and Ayah reference rather than duplicating the entire verse.

**Rationale**: Launcher accessibility support varies, so semantic references and robust layouts provide a predictable minimum without exposing excessive private content.

**Alternatives considered**: Relying only on the image or color highlight. Rejected as inaccessible.

## Analytics and Privacy

**Decision**: Record widget type, size class, theme, action, freshness bucket, and success/failure category. Do not record verse text/reference, Athkar body/index, precise location, raw widget ID, or reading history.

**Rationale**: These fields measure adoption and reliability while honoring FR-016.

**Alternatives considered**: Content-level analytics. Rejected because it is unnecessary and privacy-sensitive.
