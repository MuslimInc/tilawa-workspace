# Spec 029 — Friday Section (Jumu'ah Hub)

**Created**: 2026-06-20
**Status**: Draft
**Priority**: P2 — high ritual value, very low engineering cost; pure content + one screen

---

## Problem

Friday is the most ritually significant day of the week in Islam, with specific
sunnah acts (reading Surah al-Kahf, extra salawat, Jumu'ah prayer sunan) and
du'as tied to it. MeMuslim has no dedicated Friday experience. Athkar iOS
surfaces a dedicated Friday section as a first-class destination. The absence
is a noticeable gap for any Muslim user on a Friday.

---

## Goal

A dedicated Friday hub screen that gathers everything a user needs for Jumu'ah
in one place — accessible from the home screen on Fridays and always from the
Athkar tab.

**Success criteria**

- Screen is reachable from Athkar tab at all times
- A contextual entry point appears on the home screen **on Fridays only**
  (Today zone or Discover section)
- All content is available offline
- Arabic and English localized
- `dart analyze` clean

---

## Content sections

| Section | Content | Source |
|---|---|---|
| Surah al-Kahf | Deep link to Quran reader at Surah 18 | Existing quran reader |
| Salawat on the Prophet | Text + audio (short salawat formulas) | Athkar data |
| Jumu'ah sunan | List: ghusl, early arrival, dhikr between athan/iqamah, dua after | Athkar data |
| Hour of acceptance | Dua for the blessed hour (last hour before Maghrib on Friday) | Athkar data |
| Jumu'ah du'as | Curated collection of Friday-specific du'as | Athkar data |

---

## Architecture

Minimal — presentation layer only, no new domain or data layer.

```
features/athkar/presentation/
  screens/
    friday_hub_screen.dart        # new screen; composes existing widgets
  widgets/
    friday_section_card.dart      # reusable card for each section above
```

**Route**: `FridayHubRoute()` via go_router_builder, nested under the Athkar
navigator.

**Home integration**: `HomeTodaySection` checks `DateTime.now().weekday == DateTime.friday`
and renders a `FridayHubCard` entry (similar to contextual athkar card pattern
already in that zone). Hidden on other days.

**Data**: New entries in `athkar.json` under a `jumu_ah` category. Surah al-Kahf
entry is a nav deep-link, not raw athkar text.

---

## Localization strings needed

```
fridaySectionTitle        = "Friday" / "الجمعة"
fridaySectionSubtitle     = "Sunnah acts and du'as for Jumu'ah" / "سنن وأدعية الجمعة"
fridayKahfTitle           = "Surah al-Kahf" / "سورة الكهف"
fridaySalawatTitle        = "Salawat on the Prophet ﷺ" / "الصلاة على النبي ﷺ"
fridaySunanTitle          = "Sunan of Jumu'ah" / "سنن الجمعة"
fridayDuaHourTitle        = "Hour of acceptance" / "ساعة الإجابة"
fridayDuasTitle           = "Friday du'as" / "أدعية الجمعة"
```

---

## Out of scope (MVP)

- Live countdown to the "hour of acceptance" window
- Jumu'ah prayer rak'ah counter
- Notifications (handled by spec 026 Jumu'ah sunnah reminder)
- Ramadan Friday special content (Ramadan mode spec)

---

## References

- Athkar iOS: "Friday section — the sunan and virtues of Jumu'ah, plus Surat
  al-Kahf — gathered in one place"
- Spec 026: Jumu'ah sunnah reminder fires on Friday before Dhuhr
- Extended Athkar Categories: `docs/missing_features.md` item 7
- Existing athkar data: `apps/tilawa/assets/data/athkar.json`
