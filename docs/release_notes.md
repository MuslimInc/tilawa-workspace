# Tilawa release notes

User-facing copy for Google Play **What's new**, plus a short map to git tags and
[`CHANGELOG.md`](../CHANGELOG.md). Keep Play Console text calm and short; use
the changelog for full engineering detail.

**Play Console limit:** 500 characters per language (en-US, ar).

---

## Current release

| Field | Value |
|-------|--------|
| Version | **1.0.4** (build **31**) |
| Git tag | [`v1.0.4+31`](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.4%2B31) |
| Date | 2026-05-23 |
| Track | Production |

### What's new (en-US) — copy for Play Console

```text
• Support Tilawa: optional one-time contributions through Google Play to help keep the app calm and ad-free
• Smoother Quran player with elapsed/remaining time and a cleaner collapse to the mini player
• More reliable Google sign-in on Android
• Clearer Athkar session layout and tap feedback
• Prayer tools, reading, and listening stay free — support is always optional
```

### ما الجديد (ar) — نص متجر Play

```text
• ادعم تلاوة: مساهمات اختيارية لمرة واحدة عبر Google Play لمساعدتنا على استمرار التطبيق هادئاً وخالياً من الإعلانات
• مشغل قرآن أوضح مع وقت منقضٍ/متبقٍ وانتقال أنعم إلى الشريط المصغّر
• تسجيل دخول Google أوثق على Android
• تحسين تفاصيل الأذكار والتفاعل عند اللمس
• أدوات العبادة والقراءة والاستماع تبقى مجانية — الدعم اختياري دائماً
```

### Post-release fixes (in repo at `v1.0.4+31`, patch via Shorebird if not in store binary)

These landed in PR #56 after the first production upload. They are on `master` and
tag `v1.0.4+31`; ship with a **Shorebird patch** at release version `1.0.4+31` or
the next Play build.

- **Support:** Purchases no longer show a false failure when verification runs in
  the background and on the support screen at the same time.
- **In-app review:** Review prompts stay blocked on Athkar while you are still on
  the Athkar tab after closing a details screen.
- **Support UI:** Minor footer layout cleanup.

---

## Previous releases

| Tag | Date | Summary |
|-----|------|---------|
| [v1.0.4+30](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.4%2B30) | 2026-05-22 | Closed testing — Support Tilawa billing + App Check groundwork |
| [v1.0.3+28](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.3%2B28) | 2026-05-20 | Settings UX, ui_kit feedback, default Arabic for new installs |
| [v1.0.2+27](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.2%2B27) | 2026-05-15 | Compact bottom nav, prayer list contrast, sheet handles |

Older entries: see [`CHANGELOG.md`](../CHANGELOG.md).

---

## Unreleased

_Dart-only fixes queued for Shorebird patch or the next `pubspec` bump — move here
from the post-release section when shipped._

---

## How to publish

1. Update **What's new** in Play Console from the en-US / ar blocks above (trim to
   500 characters if needed).
2. Record the same version in [`CHANGELOG.md`](../CHANGELOG.md).
3. Tag: `git tag -a v1.0.4+NN -m "Release 1.0.4+NN"` and `git push origin v1.0.4+NN`.
4. Build: `cd apps/tilawa && shorebird release android --flutter-version=3.44.0`
   (new native changes) or `shorebird patch android --release-version 1.0.4+31`
   (Dart-only).
5. Checklist: [`google_play_release_checklist.md`](google_play_release_checklist.md)
