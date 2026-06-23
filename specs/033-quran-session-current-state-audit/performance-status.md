# Performance Status — Quran Sessions

**Audit:** 2026-06-23  
**Method:** Query/index review + code patterns (no profiling run)

**Legend:** ✅ OK for Beta | 🟡 Watch | 🔴 Fix before scale

---

## Client (Flutter)

| Area | Pattern | Status | Notes |
|------|---------|--------|-------|
| Teacher list pagination | `TeacherListBloc` load-more | ✅ | `ListView` builder pattern |
| Availability slots | 14-day generation server/client | 🟡 | Per-teacher slot count bounded |
| Booking submit | Idempotency key in gateway | ✅ | Prevents double-tap duplicate **if** same key |
| Image/avatar | Initials placeholder | ✅ | No network avatars yet |
| BLoC sequential transformers | Cancel/join events | ✅ | Race reduction on cancel |
| Join handler empty | No URL launch cost | N/A | Feature missing, not perf |

**US-066 (slow 3G):** Not measured this audit. **Should fix before Free Beta** — manual device matrix row in `032/qa-test-plan.md`.

| Target | Status |
|--------|--------|
| Teacher list TTI <5s on budget phone | ⏸️ Unverified |
| Skeleton while loading | 🟡 Partial on some screens |

---

## Firestore reads

| Query | Source | Index | Status |
|-------|--------|-------|--------|
| Student sessions by `studentId` + time | `FirestoreSessionDataSource` | Composite in `firestore.indexes.json` | ✅ |
| Teacher sessions by `teacherId` | Same | ✅ | |
| Public teachers list | `isPubliclyVisible` filter | ✅ | |
| Teacher availability collection group | Rules allow read | 🟡 | Monitor read volume |
| Session audit timeline | Per booking | ✅ | Small N per session |
| Market config | Single doc per country | ✅ | Cached in repo |

**Staff Backend Engineer:** No N+1 hotspot found in repository impls at audit time.

---

## Cloud Functions

| Path | Concern | Status |
|------|---------|--------|
| `createSessionBooking` | Transaction + lock + idempotency | ✅ Single transaction |
| `sessionReminders` | Hourly scan all upcoming sessions | 🟡 | OK for Beta volume; watch at scale |
| `deliverSessionNotification` | Per outbox doc trigger | ✅ |
| `expirePendingReservations` | 5-min scan pending_payment | ✅ No-op heavy for free Beta |

---

## Caching

| Layer | Implementation | Status |
|-------|----------------|--------|
| Market config | Fetched per profile completion | 🟡 | Could cache in memory — **Can improve after Beta** |
| Session policy | Repository fetch per eligibility | 🟡 | Acceptable for Beta |
| Teacher list | No persistent cache | 🟡 | Pull-to-refresh would help UX |

---

## Performance verdict

| Classification | Items |
|----------------|-------|
| **Good enough for Beta** | Pagination, bounded slot window, indexed queries, CF transactions |
| **Should fix before Free Beta** | Manual slow-network smoke on OPPO-class device (US-066) |
| **Postpone to Production** | Firebase Performance traces, list image caching, reminder job sharding |
| **Postpone to Paid Sessions** | Payment latency budgets |

**Overall:** ✅ **No performance blockers** for closed Beta at expected volume (<500 DAU).
