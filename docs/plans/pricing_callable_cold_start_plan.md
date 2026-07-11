# Pricing-Callable Cold Start — Elimination Plan (Spec)

Status: **proposed.** Client-side mitigation (non-blocking discovery list) has
shipped on `042-quran-learning-packages`; this spec covers the remaining
**server-side** work that removes the cold start itself at the lowest ongoing
cost, while keeping pricing authority on the server. No code from this spec is
implemented yet.

Owner: TBD · Reviewers: backend + cost owner · Target branch:
`042-quran-learning-packages` (or a dedicated `perf/pricing-warmup`).

---

## 1. Context

Opening the student discovery list (`/sessions`) showed one dominant cost in
the live trace:

```
firestore_getTeachers                 236ms
functions_getBookingPricingQuotes    7269ms   ← Cloud Functions cold start
firestore_getSchedule                 209ms
firestore_getOverrides            294 / 315ms
firestore_getTeacherProfileById   295 / 354ms
```

Every trace except the pricing callable is sub-second. The 7.3s is a **Cloud
Functions v2 (Cloud Run) cold start**, not handler logic — proven earlier on the
booking path: same function, same session, 2202ms cold → 362ms warm
(`getBookingPricingQuote` phased timing logs). The batch handler
`getBookingPricingQuotes` is already efficient when warm: one shared-context
read + a single `db.getAll(...)` for all teachers (see
`functions/src/quranSessions/getBookingPricingQuotes.ts`).

### 1.1 What already shipped (client mitigation, this branch)

These reduce *perceived* latency but do **not** remove the cold start:

- **Non-blocking discovery list.** `ResolveTeacherListUseCase` split into
  `fetchTeachers()` (fast) + `resolveQuotes()` (pricing + bookability filter).
  `TeacherListBloc` now emits `[Loading, Success(isResolving), Success]` — teacher
  rows render immediately; price chip + availability patch in when the quote
  resolves. `QuranSessionPriceChip` already renders nothing on a null quote
  (never fakes "Free"), so no misleading state during resolve.
- **Parallelized student sessions load.** `GetStudentSessionsUseCase` ran
  upcoming + past as sequential awaits (~1.4s); now concurrent via record
  `.wait` (~0.8s).

### 1.2 Rejected approach — denormalize bookability onto the teacher doc

Precomputing a `bookable`/`price` field onto `quran_teacher_profiles/{id}` via a
trigger, so the list filters locally without a function call, was considered and
**rejected**. Two blockers, confirmed against
`functions/src/quranSessions/bookingEligibilityService.ts`:

1. **Bookability is student-contextual, not teacher-static.** The quote depends
   on the viewer's market, currency, gender, age, and market whitelist. Durable
   block reasons split into global/market-level (`marketDisabled`,
   `bookingDisabledByAdmin`, `pricingConfigMissing`), teacher×market
   (`paymentProviderUnavailable`), and teacher×student (gender/age). A single
   value on the teacher doc cannot represent "bookable for *this* student."
2. **Trust model.** The codebase enforces that *client checks are advisory only;
   Flutter must never infer paid/free from market data.* Moving the decision
   client-side to skip the call would weaken an authoritative safety/pricing
   boundary.

Conclusion: keep pricing authority on the server; fix the cold start on the
server.

---

## 2. Problem statement

The first invocation of `getBookingPricingQuote` / `getBookingPricingQuotes`
after the function scales to zero pays a multi-second container spin-up. The
warm-instance floor intended to prevent this
(`sessionPricingQuoteHttpsOptions.minInstances`, wired to
`QURAN_SESSIONS_MIN_INSTANCES` in `sessionCallableOptions.ts`) **did not take
effect** on the 2026-07-11 deploy:

```
$ gcloud functions describe getBookingPricingQuotes --gen2 \
    --region us-central1 --project quran-playera-app \
    --format="value(serviceConfig.minInstanceCount)"
                    # ← blank == 0, warm floor not applied
```

Reading `process.env.QURAN_SESSIONS_MIN_INSTANCES` at module-load time is not a
reliable way to set a deploy-time option; Firebase resolves option values from
**params**, not arbitrary env reads, during config discovery.

---

## 3. Goals & non-goals

**Goals**

- G1 — First discovery-list / booking quote returns in **< 1s** at the
  50th–95th percentile during active hours (no multi-second cold start).
- G2 — **Lowest sustainable cost**: no 24/7 reserved capacity if active-hours
  warming achieves G1.
- G3 — Pricing/bookability authority stays **entirely server-side** (no client
  inference, no trust-model change).
- G4 — Warm path adds **no** measurable request cost to real user calls and no
  new auth surface.

**Non-goals**

- Reducing warm handler latency (already ~360ms; acceptable).
- Warming the other ~9 session callables (mutations are user-initiated after the
  screen is interactive; not on the pre-action latency path).
- Changing pricing math, bookability rules, or the discovery query.

---

## 4. Options considered

| # | Option | Removes cold start | Ongoing cost | Effort | Keeps server authority |
|---|--------|--------------------|--------------|--------|------------------------|
| A | `minInstances` always-on (via `defineInt`) | Yes, 24/7 | Highest — 2 idle instances billed 24/7, incl. overnight | Low | Yes |
| B | **Scheduled warmer, active hours** (recommended) | Yes, during active hours | Low — warm only while students are active; scale-to-zero overnight | Medium | Yes |
| C | Reduce cold-start *duration* (lazy imports, min memory) | Partially — shrinks the penalty, doesn't remove it | None | Medium | Yes |
| D | Denormalize bookability to teacher doc | N/A (removes the call) | Low | High | **No** — see §1.2 |

**Recommendation: Option B**, with Option A's `defineInt` fix kept available as a
one-line escalation lever (set the param > 0) if active-hours warming proves
insufficient. Option C is a complementary follow-up, not a substitute.

---

## 5. Recommended design — scheduled warmer (Option B)

A single scheduled function pings both pricing callables every few minutes
during local active hours. The pings keep the Cloud Run service warm without
reserving an instance, so the service still scales to zero overnight.

### 5.1 Warmup short-circuit in the pricing callables

Both callables gain a top-of-handler guard that returns before any auth, reads,
or pricing work, so a warm ping costs ~nothing and produces no error logs.

`functions/src/quranSessions/getBookingPricingQuote.ts` and
`getBookingPricingQuotes.ts`, first lines of the handler:

```ts
// Warm ping from the scheduled warmer: spin the container without doing work.
// Gated by a shared secret so it cannot be used to bypass auth for real data.
if (isWarmupRequest(request.data, warmupSecret())) {
  return WARMUP_OK; // e.g. { warmed: true } / { quotes: {} }
}
```

`sessionCallableOptions.ts` (new helpers + param):

```ts
import { defineString, defineInt } from "firebase-functions/params";

// Robust replacement for the process.env read — resolved at deploy time.
const MIN_INSTANCES = defineInt("QURAN_SESSIONS_MIN_INSTANCES", { default: 0 });
const WARMUP_SECRET = defineString("QURAN_SESSIONS_WARMUP_SECRET", { default: "" });

export function warmupSecret(): string { return WARMUP_SECRET.value(); }

export function isWarmupRequest(data: unknown, secret: string): boolean {
  return secret.length > 0
    && typeof data === "object" && data !== null
    && (data as Record<string, unknown>).__warmup === secret;
}

export const sessionPricingQuoteHttpsOptions = {
  ...sessionCallableHttpsOptions,
  minInstances: MIN_INSTANCES, // param, not process.env — this is the deploy fix
};
```

Notes:
- The secret gate means the short-circuit can never be abused to skip
  `requireAuthenticatedUid` for real pricing data — a caller without the secret
  falls straight through to the normal authenticated path.
- App Check is currently opt-in and **off** (`QURAN_SESSIONS_ENFORCE_APP_CHECK`
  default false). If it is later enabled, the warmer either needs an App Check
  exemption for the warmup payload or must switch to the OIDC-ping variant
  (§5.4). Tracked in Open Questions.

### 5.2 The scheduled warmer

New file `functions/src/quranSessions/warmPricingCallables.ts`:

```ts
import { onSchedule } from "firebase-functions/v2/scheduler";

// Active hours only (server TZ). Every 5 min, 06:00–23:59 → scale-to-zero
// overnight. Cron beats "every 5 minutes" so we control the hour window.
export const warmPricingCallables = onSchedule(
  { schedule: "*/5 6-23 * * *", timeZone: "Africa/Cairo" },
  async () => {
    await Promise.allSettled([
      pingCallable("getBookingPricingQuote"),
      pingCallable("getBookingPricingQuotes"),
    ]);
  },
);
```

`pingCallable` POSTs the callable protocol body `{ data: { __warmup: SECRET } }`
to the function's Cloud Run URL (constructed from project + region + name). It
does not need Firebase Auth because the handler short-circuits before
`requireAuthenticatedUid`. `Promise.allSettled` so one failing ping never fails
the tick.

Cadence rationale: Cloud Run keeps an idle instance alive for a bounded window
after the last request; a 5-minute ping stays inside that window, so one warm
instance persists continuously through active hours.

### 5.3 Config / secrets

| Param | Where | Value |
|-------|-------|-------|
| `QURAN_SESSIONS_MIN_INSTANCES` | `functions/.env.quran-playera-app` | `0` (warmer covers it; set `1` only to escalate to always-on) |
| `QURAN_SESSIONS_WARMUP_SECRET` | Secret Manager / deploy env | random 32+ char string; shared by callables + warmer (same process, same param) |

### 5.4 Fallback variant (no handler change)

If we prefer zero callable changes: Cloud Scheduler → Cloud Run URL with an OIDC
token (SA holding `run.invoker`). The onCall wrapper rejects the non-callable
request **after** the container starts, so the instance still warms. Cost is the
same; the downside is one 4xx log line per ping per function. The §5.1 approach
is preferred because it is silent and self-documenting.

---

## 6. Cost analysis

- **Option A (always-on):** 2 functions × 1 reserved instance × 24h/day. Idle
  Cloud Run billing runs even at 03:00 with zero students.
- **Option B (this plan):** no reserved instance. Cost ≈ warm-instance time
  during active hours only (real traffic + pings), scaling to zero overnight.
  Invocation cost of the pings themselves is negligible (~2 functions × ~216
  invocations/day, sub-second, short-circuited).

Exact figures depend on Cloud Run billing mode (request-based vs instance-based)
and memory; **measure** post-rollout in Cloud Run metrics rather than assume.
Expected: B is materially cheaper than A whenever traffic is concentrated in
local daytime, which matches a prayer/Qur'an audience.

---

## 7. Testing & verification

- **Unit** (`functions/`): `isWarmupRequest` — true only with the exact secret;
  false for empty secret, wrong/missing `__warmup`, non-object data. Guard order:
  a warmup request returns before `requireAuthenticatedUid` (assert auth is not
  invoked).
- **Handler parity:** a non-warmup request is byte-for-byte unchanged (existing
  `getBookingPricingQuote(s)` tests must stay green).
- **Post-deploy checks:**
  - `gcloud functions describe getBookingPricingQuotes --gen2 --region
    us-central1 --format="value(serviceConfig.minInstanceCount)"` → still `0`
    under Option B (confirms we are not paying for always-on).
  - Cloud Scheduler shows `warmPricingCallables` succeeding on cadence.
  - Live trace: open `/sessions` cold (after overnight) during active hours →
    `functions_getBookingPricingQuotes` < 1s.
  - Overnight trace (outside the window) may cold-start — expected and accepted.

---

## 8. Rollout

1. Land callable short-circuit + `defineInt`/`defineString` params (behind the
   default `WARMUP_SECRET=""`, which disables the short-circuit — safe no-op).
2. Set `QURAN_SESSIONS_WARMUP_SECRET` in the deploy env / Secret Manager.
3. Deploy functions:
   `firebase deploy --only functions:getBookingPricingQuote,functions:getBookingPricingQuotes,functions:warmPricingCallables --project quran-playera-app`
4. Verify Scheduler + a cold-then-warm trace (§7).
5. Tune the hour window / cadence to observed traffic; only if p95 still misses
   G1, escalate by setting `QURAN_SESSIONS_MIN_INSTANCES=1` and redeploying.

Rollback: delete the `warmPricingCallables` schedule (or set
`WARMUP_SECRET=""`); callables revert to plain cold-start behavior with no other
change.

---

## 9. Open questions

1. **App Check + warmup.** When `QURAN_SESSIONS_ENFORCE_APP_CHECK` flips on, does
   the callable-protocol ping still reach the short-circuit, or must we move to
   the OIDC variant (§5.4)? Decide before enabling enforcement.
2. **Active-hours window.** Single `Africa/Cairo` window for the pilot, or
   multiple windows once markets span time zones? Start single; revisit at
   multi-market.
3. **Cadence vs Cloud Run keep-alive.** Confirm the current keep-alive window on
   our memory/CPU config; widen from 5 min only if instances die between pings.
4. **Escalation trigger.** What p95 over what window justifies flipping to
   always-on (Option A)? Define the threshold with the cost owner.

---

## 10. Appendix — related work

- `docs/plans/teacher_dashboard_read_model_plan.md` — same "one read, O(1)
  upkeep" philosophy for the teacher dashboard.
- `functions/src/quranSessions/sessionCallableOptions.ts` — current (broken)
  `process.env` min-instances read this spec replaces with a param.
- Booking-screen cold-start findings and the non-blocking booking flow that this
  discovery-list work mirrors.
