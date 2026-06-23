# Rollback Plan — Quran Sessions

**Target recovery time:** <15 minutes to stop new harm; <1 hour full feature degrade  
**Sprint 7 drill required:** US-072

---

## Rollback layers (fastest first)

| Order | Layer | Speed | Effect |
|-------|-------|-------|--------|
| 1 | Feature flag: `quranSessionsBookingEnabled=false` | ~1–5 min | Block new bookings; UI may still browse |
| 2 | Feature flag: `quranSessionsEnabled=false` | ~1–5 min | Hide entry card; no new sessions navigation |
| 3 | Remote Config kill switch | ~5 min | Same as 1–2 without app release |
| 4 | Disable teacher application flag | ~5 min | Stop new teacher supply |
| 5 | Play staged rollout **halt** | immediate | Stop new installs/updates reaching users |
| 6 | CF traffic disable (extreme) | ~15 min | Remove function or IAM deny — breaks all mutations |
| 7 | Firestore rules rollback | ~10 min | Revert rules git tag — **high risk** |
| 8 | CF version rollback | ~15–30 min | Redeploy previous functions tag |
| 9 | Full APK rollback (Play) | hours–days | Promote previous release; users must update |

**Default incident response:** Execute layers 1 → 2 → 5. Escalate to 7–8 only on rules/CF regression.

---

## Layer 1–4: Feature flags (mobile)

**File:** `apps/tilawa/lib/features/quran_sessions/quran_sessions_feature_flags.dart`  
**Remote Config keys (if wired):** same names

### Disable new bookings only

```
quranSessionsBookingEnabled = false
```

**User experience:**
- Browse teachers may still work (product choice)
- Book CTA shows "الحجز غير متاح حالياً" or equivalent
- In-flight booking attempts fail gracefully

**Verify:**
- [ ] Attempt book → blocked message, no CF call or CF returns disabled
- [ ] Existing My Sessions still loads

### Hide entire feature

```
quranSessionsEnabled = false
```

**User experience:**
- `HomeSessionsEntryCard` hidden
- Deep links to `/sessions/*` redirect or show unavailable

### Disable teacher applications

```
teacherApplicationEnabled = false
```

**When:** Spam applications or approval queue overwhelmed

---

## Layer 5: Google Play halt

1. Play Console → Release → Production/Open testing → **Halt rollout**
2. Do not delete release — allows resume
3. Notify closed testers if incident communication needed

**Keep bookings readable:** Existing users on old build retain app; flags via Remote Config still apply.

---

## Layer 6–8: Backend rollback

### CF rollback

```sh
git checkout <previous-release-tag> -- functions/
cd functions && npm run build
firebase deploy --only functions:<affected-callables>
```

**Prefer partial rollback** of broken callable only (e.g. `createSessionBooking`) vs full deploy.

**Previous tag:** Record in [release-checklist.md](./release-checklist.md) each deploy.

### Rules rollback

```sh
git checkout <previous-rules-tag> -- firestore.rules
firebase deploy --only firestore:rules
```

**Warning:** May re-open security holes fixed in current rules — ops + eng joint decision only.

### Admin emergency actions

If mobile/admin broken but CF healthy:
- Ops uses `functions/scripts/` MVO scripts or Firebase console read-only
- Admin can still call CF via Postman with admin token for critical cancel/dispute

Path: `functions/scripts/` (list pending applications, etc.)

---

## Data preservation during rollback

| Data | Behavior |
|------|----------|
| Existing `quran_sessions` docs | **Readable** — do not delete |
| Existing `quran_bookings` | **Readable** |
| `meetingLink` on confirmed sessions | **Must remain visible** — users need join |
| In-progress reschedule requests | Complete or admin-cancel manually |
| Open disputes/reports | Admin queue still processed |
| manual_pending ledger | Retained for finance |

**Do NOT:** mass-delete collections on rollback.

---

## Rollback scenarios

### Scenario A — Booking CF broken (500 errors)

1. `quranSessionsBookingEnabled=false` immediately
2. Sentry investigate `createSessionBooking`
3. Hotfix or redeploy previous CF tag
4. Staging verify → re-enable flag 5% cohort

### Scenario B — Wrong user sees another's sessions (P0)

1. `quranSessionsEnabled=false` immediately
2. Halt Play rollout
3. Eng identify UID scoping bug
4. Rules audit — no client write bypass
5. Postmortem before re-enable

### Scenario C — FCM spam / duplicate reminders

1. Disable `sessionReminders` scheduled job in CF console
2. Fix `notificationOutboxService` idempotency
3. Redeploy fix; re-enable job

### Scenario D — Accidental paid charge (should not happen Beta)

1. **All flags off** + halt Play
2. Finance + PSP void charges
3. Verify `DisabledPaymentProvider` in prod build

### Scenario E — Admin panel writes corrupt data

1. Disable admin deploy / revert admin build
2. Use CF-only mutations
3. Backfill from audit if available

---

## Rollback drill script (Sprint 7)

**Environment:** Staging  
**Duration:** 30 min

| Step | Action | Expected | Time |
|------|--------|----------|------|
| 1 | Note active bookings count | Baseline | 2m |
| 2 | Set `quranSessionsBookingEnabled=false` | New book blocked | 3m |
| 3 | Student attempts book | Error message | 2m |
| 4 | Open My Sessions on existing user | Sessions visible + link | 2m |
| 5 | Set `quranSessionsEnabled=false` | Entry hidden | 3m |
| 6 | Restore `quranSessionsEnabled=true` | Entry back | 2m |
| 7 | Restore `quranSessionsBookingEnabled=true` | Book works | 5m |
| 8 | Document timestamps + owners | Drill log | 5m |

- [ ] Drill log stored in team wiki / issue
- [ ] On-call knows Remote Config console path

---

## Communication

| Audience | Channel | Template |
|----------|---------|----------|
| Closed testers | Email/WhatsApp | "نعطل الحجز مؤقتاً للصيانة. جلساتك الحالية ما زالت في «جلساتي»." |
| Teachers | Direct message | Same + admin contact |
| Internal | Slack/issue | P0 incident thread |

---

## Recovery (re-enable)

1. Root cause fixed and verified on staging
2. Smoke subset pass (book, cancel, join link)
3. Re-enable flags: booking first, then discoverability expand
4. Resume Play rollout from halted %
5. 24h heightened monitoring

---

## Contacts (fill at Sprint 0)

| Role | Contact |
|------|---------|
| Flag owner (Remote Config) | |
| CF deploy owner | |
| Play Console owner | |
| Ops / disputes | |
| On-call eng | |
