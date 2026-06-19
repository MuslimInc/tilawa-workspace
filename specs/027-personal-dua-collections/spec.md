# Spec 027 — Personal Du'a Collections

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P2 — high emotional stickiness, low engineering cost; candidate for Support tier gating

---

## Problem

Users want a private space to collect du'as for personal intentions — a sick
parent, a deceased relative, a life goal — and be gently reminded to recite
them. This is one of Athkar iOS's highest-rated features: user-created sections
with autonomous daily reminders. MeMuslim has no equivalent. The feature creates
irreplaceable data gravity (users won't leave an app that holds their personal
du'as for loved ones).

---

## Goal

Allow users to create named du'a collections (e.g. "للوالدة — For my mother"),
add du'as from the athkar library or write their own, and optionally attach a
daily reminder.

**Success criteria**

- User can create, rename, and delete a personal collection in ≤ 3 taps
- User can add any athkar item from the library to a collection
- User can write a free-text du'a (Arabic or any language) and add it to a
  collection
- Each collection can have an optional daily reminder at a user-defined time
- Collections are visible on the Athkar tab (dedicated "My Du'as" section)
- Data persists locally; cloud sync deferred to spec 008
- `dart analyze` clean

---

## Entities

```dart
// domain/entities/personal_collection.dart
class PersonalCollection {
  final String id;           // UUID
  final String name;         // e.g. "للوالدة"
  final String? intention;   // optional subtitle / reminder of why
  final List<String> itemIds; // ordered list of PersonalDuaItem IDs
  final ReminderTime? reminder; // null = no reminder
  final DateTime createdAt;
}

// domain/entities/personal_dua_item.dart
sealed class PersonalDuaItem {
  // either a reference to an athkar library item
  const factory PersonalDuaItem.library({required int athkarItemId}) = _LibraryDuaItem;
  // or user-authored text
  const factory PersonalDuaItem.custom({
    required String id,
    required String arabicText,
    String? transliteration,
    String? meaning,
  }) = _CustomDuaItem;
}
```

---

## Architecture

```
features/personal_dua/
  data/
    datasources/personal_dua_local_datasource.dart   # Hive
    repositories/personal_dua_repository_impl.dart
  domain/
    entities/personal_collection.dart
    entities/personal_dua_item.dart
    repositories/personal_dua_repository.dart
    usecases/
      get_collections_use_case.dart
      create_collection_use_case.dart
      add_item_to_collection_use_case.dart
      remove_item_from_collection_use_case.dart
      delete_collection_use_case.dart
      set_collection_reminder_use_case.dart
  presentation/
    cubit/personal_dua_cubit.dart
    cubit/personal_dua_state.dart
    screens/
      my_duas_screen.dart           # list of collections
      collection_detail_screen.dart # items in one collection
    widgets/
      personal_collection_card.dart
      add_to_collection_sheet.dart  # pick collection when adding from athkar
      new_dua_editor.dart           # free-text du'a entry
```

**Athkar integration**: On any `AthkarItemScreen`, add an "Add to My Du'as"
action (long-press or overflow menu) that opens `AddToCollectionSheet`.

**Reminders**: Reuse `ReminderConfig` infrastructure from spec 026. Each
collection maps to one `ReminderConfig` with `type: ReminderType.personalDua`
and a `collectionId` payload in the notification.

---

## UX notes

- Entry point: Athkar tab → "My Du'as" section at top, above categories
- Empty state: warm, personal copy — "Start a collection for someone you love"
- Collection detail: ordered list of du'as with swipe-to-remove; drag to reorder
- Intention field (optional): a private note shown at the top of the collection
  screen — "You created this for your mother's recovery"
- Reminder badge: if a collection has a reminder, show a small clock icon on
  the card

---

## Out of scope (MVP)

- Sharing collections with other users
- Cloud backup (defer to spec 008)
- AI-generated du'a suggestions

### Post-MVP (Support tier candidates)

- **PDF booklet export**: user adds a dedication line ("For my mother's
  recovery") and the app generates a personalised PDF of the collection's
  du'as, ready to share via any platform. Reuses existing `ShareService`
  infrastructure; requires a PDF rendering package (e.g. `pdf: ^3.x`).
- **Unlimited collections**: free tier capped at 3 collections; Support
  tier removes the cap. Matches Athkar iOS "Unlimited du'as" Pro feature.
- **Voice tasbih inside collection**: recite a du'a aloud and the app
  advances to the next item automatically (speech recognition). Support tier.

---

## References

- Athkar iOS: "My Adhkar" personal collections + per-loved-one sections with autonomous daily reminders
- Athkar feature: `apps/tilawa/lib/features/athkar/`
- Spec 026: granular reminders (reminder infrastructure)
- Spec 008: cloud sync (eventual backup)
