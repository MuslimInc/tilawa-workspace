# Google Play Release Plan — Quran Sessions (MeMuslim)

**App:** MeMuslim / أنا مسلم (`apps/tilawa`)  
**Feature:** Quran Sessions Free Beta  
**Sprint:** 8

---

## Release identity

| Field | Value |
|-------|-------|
| Package name | Verify in `apps/tilawa/android/app/build.gradle` (`applicationId`) |
| Track progression | Internal → Closed → Open (staged) → Production |
| Target SDK | Match project `compileSdk` / Play requirements |
| Min SDK | Per project config (support low-end matrix) |
| Countries | Egypt first (EG market); expand after Beta soak |

---

## Versioning

| Release | Version name example | Version code |
|---------|---------------------|--------------|
| Internal QA | `1.12.0-beta.1` | monotonic +1 |
| Closed Beta | `1.12.0-beta.2` | +1 |
| Staged public | `1.12.0` | +1 |

- [ ] Version code always increases vs last Play upload
- [ ] Git tag `play/quran-sessions-beta-YYYYMMDD` on release commit

---

## Release notes

### Arabic (AR) — user-facing

```
جلسات القرآن (تجريبي):
• احجز جلسات مجانية واحد-لواحد مع محفظين معتمدين
• تصفح المعلمين واختر الموعد المناسب
• انضم للجلسة عبر رابط الاجتماع
• للمحفظين: تقديم طلب، إدارة المواعيد، لوحة التحكم

ملاحظة: الجلسات مجانية في هذه المرحلة. لا يوجد دفع داخل التطبيق.
```

### English (EN) — user-facing

```
Quran Sessions (Beta):
• Book free 1-on-1 sessions with verified Quran teachers
• Browse teachers and pick a time slot
• Join your session via meeting link
• For teachers: apply, manage availability, and view your dashboard

Note: Sessions are free during this beta. No in-app payments.
```

- [ ] Both locales uploaded in Play Console
- [ ] Matches actual feature flags (no paid promises)

---

## Rollout tracks

### Track 1 — Internal testing

| Item | Detail |
|------|--------|
| Testers | 5–10 core team emails |
| Duration | 3 days minimum |
| Firebase | Production project; booking flag per rollout |
| Verify | Install, update, sign-in, book, FCM |

### Track 2 — Closed testing

| Item | Detail |
|------|--------|
| Testers | 20–40 trusted users (teachers + students) |
| Duration | 7–14 days |
| List | Play Console email list or Google Group |
| Goal | ≥20 book→join completions — [beta-testing-plan.md](./beta-testing-plan.md) |

### Track 3 — Staged rollout (production)

| Stage | % users | Advance criteria | Hold criteria |
|-------|---------|------------------|---------------|
| 1 | 5% | 48h crash-free >99%, booking success >95% | Any P0 or stop condition |
| 2 | 20% | 48h stable metrics | Error spike |
| 3 | 50% | 72h stable | Dispute backlog |
| 4 | 100% | Beta Go decision | — |

- [ ] Staged rollout enabled in Play Console
- [ ] Halt button owner knows procedure — [rollback-plan.md](./rollback-plan.md)

---

## Store listing (Beta)

### Screenshots (required)

Minimum 4 phone screenshots (AR UI preferred):

1. Sessions hub / teacher list
2. Teacher profile + book CTA
3. Booking slot picker
4. My Sessions with upcoming session + join
5. (Optional) Teacher dashboard

- [ ] 1080×1920 or Play-specified dimensions
- [ ] No misleading paid pricing in screenshots (free Beta)

### Short description (AR)

```
جلسات قرآن مجانية مع محفظين معتمدين — احجز وتابع تقدمك.
```

### Privacy

- [ ] Privacy policy URL live and mentions: account data, session scheduling, FCM, teacher application phone (format validation only in Beta)
- [ ] Data safety form updated: user data collected for sessions feature
- [ ] No payment data declared (Beta)

---

## Feature flags & Remote Config

Path: `apps/tilawa/lib/features/quran_sessions/quran_sessions_feature_flags.dart`

| Key | Internal | Closed | Staged 5% | Full |
|-----|----------|--------|-----------|------|
| `quranSessionsEnabled` | true | true | true | true |
| `quranSessionsBookingEnabled` | true | true | true | true |
| `teacherApplicationEnabled` | true | true | true | true |
| discoverability enum | per product | per product | per product | public |

- [ ] Remote Config published with defaults matching table
- [ ] Kill switch: `quranSessionsBookingEnabled=false` tested pre-launch
- [ ] Entry card hidden when `quranSessionsEnabled=false`

---

## Monitoring (Play + app)

| Signal | Tool | Action |
|--------|------|--------|
| Crash-free users | Play Console Vitals | Halt rollout if <99% |
| ANRs | Play Console | Investigate session screens |
| CF errors | Sentry / Cloud Logging | Page on-call |
| Booking funnel | Analytics `AnalyticsConstants` | Daily review |
| FCM delivery | Functions logs | Fix token pipeline |
| User reviews | Play reviews | Respond <24h during Beta |

### Sentry tags

- `feature:quran_sessions`
- `screen:booking|my_sessions|session_detail`

- [ ] Sentry release matches version name
- [ ] Source maps / symbols uploaded

---

## Rollback criteria (Play-specific)

Halt staged rollout or pull build if:

1. Crash-free rate <97% for 24h
2. P0 data leak or auth bypass
3. Accidental payment UI shown
4. Booking failure >5% (system errors)
5. Regulatory/safety escalation

**Actions:** Halt rollout → disable booking flag → optional full rollback to previous APK if crash regression — see [rollback-plan.md](./rollback-plan.md).

---

## Pre-upload checklist

- [ ] Release AAB built `--release`
- [ ] Mapped to production Firebase (`google-services.json`)
- [ ] Feature flags default safe (booking off until cohort ready)
- [ ] Experimental badge on sessions CTA (if still MVP signal)
- [ ] No debug simulate-approval in release (`kDebugMode` only)
- [ ] ProGuard keeps Firebase/Flutter essentials
- [ ] Play App Signing enrolled

---

## Post-upload checklist

- [ ] Internal track processing complete (no Play policy rejection)
- [ ] Testers received opt-in email
- [ ] First internal install successful on OPPO A98 + secondary device
- [ ] Production smoke: one book→join with closed tester account
- [ ] Release notes visible in Play tester app

---

## Google Play readiness status

| Item | Status at plan creation |
|------|-------------------------|
| AAB release build | ⬜ Pending Sprint 8 |
| Internal track | ⬜ Not uploaded |
| Closed testers list | ⬜ Recruit Sprint 7–8 |
| AR/EN release notes | ⬜ Draft above |
| Screenshots | ⬜ Capture Sprint 7 QA |
| Privacy policy update | ⬜ Review legal |
| Feature flags prod | ⬜ Booking off until rollout |
| Staged rollout | ⬜ After closed Beta |
| Monitoring | ⬜ Sentry Sprint 7 |

**Overall Play readiness:** **Not ready** — expected after Sprint 7 QA exit.
