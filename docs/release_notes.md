# Tilawa release notes

User-facing copy for Google Play **What's new**, plus a short map to git tags and
[`CHANGELOG.md`](../CHANGELOG.md). Keep Play Console text calm and short; use
the changelog for full engineering detail.

**Play Console limit:** 500 characters per language (en-US, ar).

---

## Current release

| Field | Value |
|-------|--------|
| Version | **1.0.7** (build **39**) |
| Git tag | `v1.0.7+39` (pending) |
| Date | 2026-06-02 |
| Track | Internal testing → Production |

### What's new (en-US) — copy for Play Console

```text
• Smoother green launch splash and updated app icon
• Dedicated reciters search — double-tap Reciters to find a qari quickly
• A–Z index on the reciters list for faster browsing
• Swipe between today and monthly prayer times
• More reliable sign-in, notifications, and Quran player navigation
• Security and stability fixes for a safer release
```

### ما الجديد (ar) — نص متجر Play

```text
• شاشة بدء خضراء أنعم وأيقونة تطبيق محدّثة
• بحث مخصّص للقرّاء — انقر مرتين على تبويب القرّاء للوصول السريع
• فهرس أ–ي في قائمة القرّاء لتصفح أسرع
• اسحب بين صلاة اليوم والشهر في أوقات الصلاة
• تسجيل دخول وإشعارات وتنقل مشغّل القرآن أكثر موثوقية
• إصلاحات أمان واستقرار لإصدار أكثر أماناً
```

---

## Previous current release (1.0.6+38)

| Field | Value |
|-------|--------|
| Version | **1.0.6** (build **38**) |
| Git tag | `v1.0.6+38` (pending) |
| Date | 2026-05-31 |
| Track | Internal testing → Production |

### What's new (en-US) — copy for Play Console

```text
• Delete your account from Settings when you no longer need Tilawa
• Privacy policy link on sign-in and in Settings
• Smoother launch splash and updated Tilawa branding from recent builds
• Prayer location permission recovery and stability improvements
```

### ما الجديد (ar) — نص متجر Play

```text
• احذف حسابك من الإعدادات عندما لا تحتاج تلاوة
• رابط سياسة الخصوصية في تسجيل الدخول وفي الإعدادات
• شاشة بدء أنعم وتحديث هوية تلاوة من الإصدارات الأخيرة
• تحسينات استقرار أوقات الصلاة وإذن الموقع
```

---

## Previous release (1.0.5+32)

| Field | Value |
|-------|--------|
| Version | **1.0.5** (build **32**) |
| Git tag | [`v1.0.5+32`](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.5%2B32) |
| Date | 2026-05-24 |
| Track | Production |

### What's new (en-US) — copy for Play Console

```text
• Smoother startup: splash stays until the app is ready, then tabs open without flicker
• Rate Tilawa in Settings; calm in-app review after listening, prayer, and favorites
• Refreshed coral theme with clearer catalog screens, search, and reciter favorites
• Bottom navigation uses short single-word labels for easier thumb reach
• Support purchase verification no longer shows a false failure in the background
```

### ما الجديد (ar) — نص متجر Play

```text
• بدء تشغيل أنعم: شاشة البداية تبقى حتى جاهزية التطبيق دون وميض
• قيّم تلاوة من الإعدادات؛ طلب تقييم هادئ بعد الاستماع والصلاة والمفضلة
• مظهر مرجاني محدّث مع شاشات أوضح للقرّاء والبحث والمفضلة
• شريط تنقل بأسماء مختصرة لسهولة الوصول بالإبهام
• تحقق الدعم في الخلفية لا يعرض فشلاً خاطئاً
```

---

## Previous releases

| Tag | Date | Summary |
|-----|------|---------|
| [v1.0.4+31](https://github.com/muhammadkamel/tilawa-workspace/releases/tag/v1.0.4%2B31) | 2026-05-23 | Production — Support Tilawa, player UX, App Check |
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
3. Tag: `git tag -a v1.0.5+32 -m "Release 1.0.5+32"` and `git push origin v1.0.5+32`.
4. Build: `cd apps/tilawa && shorebird release android --flutter-version=3.44.1`
   (new native changes) or `shorebird patch android --release-version 1.0.7+39`
   (Dart-only).
5. Checklist: [`google_play_release_checklist.md`](google_play_release_checklist.md)
