# Session mode / provider change — Free Beta policy

**Status:** Decision (pre-implementation)  
**Scope:** Individual Quran Sessions, experimental production  
**Related:** [individual-booking-provider-report.md](./individual-booking-provider-report.md), [provider-candidate-evaluation.md](./provider-candidate-evaluation.md)

---

## Executive decision (Free Beta)

**Lock `sessionMode` and `callProvider` at booking time.**

| Action | Free Beta |
|--------|-----------|
| Student/teacher change mode or provider after book | **Not allowed** (no in-app request flow) |
| Admin support override | **Allowed** (audited CF only) |
| Bilateral request → approve (your preference) | **Post-beta** (reuse reschedule pattern) |

**Rationale:** Reschedule request/confirm CF exists but is not fully E2E in app ([spec 031](../031-quran-session-blueprint/README.md)). Adding a second bilateral workflow for mode/provider duplicates complexity, risks silent metadata drift, and Agora/WebRTC are not live. Locking keeps join behavior predictable for beta validation.

---

## Answers to product questions

### 1. Who may change channel/provider?

| Actor | Free Beta | Post-beta (target) |
|-------|-----------|-------------------|
| Student | No | May **request** change; teacher must approve |
| Teacher | No | May **request** change; student must approve |
| Admin | Yes (support override only) | Yes (override + audit) |
| Both freely | No | Never |

Matches your preference: no free changes; bilateral confirmation later; admin for support.

### 2. Changeable after booking?

**Free Beta:** No (except admin override).  
**Post-beta:** Yes, via `SessionModeChangeRequest` workflow (see domain model below).

### 3. Time limits

| Window | Free Beta | Post-beta (recommended) |
|--------|-----------|----------------------|
| After session start | Never | Never |
| &lt; 1 h before start | N/A (no changes) | Block new requests |
| &lt; 24 h before start | N/A | Block unless admin |
| Before 24 h | N/A | Allow request (align with `DefaultReschedulePolicy`) |

Reuse existing **24 h** rule from `DefaultReschedulePolicy` for any post-beta mode change — same trust bar as reschedule.

### 4. If one party disagrees

**Free Beta:** N/A — no request flow.  
**Post-beta:** Request stays `pending` until `approved` / `rejected` / `expired`. Session keeps **original** mode/provider until approved. No partial apply.

### 5. Teacher: external → in-app video

**Free Beta:** Not allowed without admin.  
**Post-beta:**

- Teacher requests → student confirms (your preference).
- Student gets push + in-app pending action.
- Student may reject → request `rejected`, session unchanged.
- **Not** a full reschedule (time unchanged) unless slot/provider change requires new `providerSessionId` / token — then treat as mode change only, not datetime change.

If moving to Agora/WebRTC when live: backend mints new `joinToken` / `providerSessionId` on approve only.

### 6. Student: video → audio

**Free Beta:** Not allowed.  
**Post-beta:** Student requests → **teacher approves** (session delivery is teacher-led). Admin not required unless dispute.

### 7. Admin force-change

**Yes** for support (wrong link, broken Meet, safety). Requirements:

- Callable: `adminOverrideSessionCallSettings` (or extend existing admin session actions)
- Writes `session.callProvider`, `session.callType`, `meetingLink` / provider metadata
- Audit: `quran_session_events` with `action: admin_override_call_settings`
- Notification outbox to **both** student and teacher
- Never silent

---

## Free Beta: what happens today

At `createSessionBooking`:

- `callType` + `callProvider` resolved server-side (`callProviderResolver`)
- `meetingLink` copied from teacher profile (external) or mock metadata (voice/video)
- Immutable for participants via Firestore rules (client cannot patch provider fields)

**If wrong mode booked:** cancel + rebook (existing cancel flow) or **admin support override**.

---

## Post-beta domain model (design only — do not implement in Free Beta)

```text
SessionModeChangeRequest
  id
  bookingId
  sessionId
  requestedBy: student | teacher
  requestedByUserId
  oldSessionMode / newSessionMode
  oldProviderType / newProviderType
  status: pending | approved | rejected | expired | cancelled
  reason (optional)
  respondedBy / respondedAt
  createdAt
  expiresAt (e.g. 48 h pending)
```

**Flow:**

1. Requester calls `requestSessionModeChange` CF → creates pending doc + audit + notify counterparty.
2. Counterparty calls `respondSessionModeChange` (approve/reject) → on approve, transaction updates session + regenerates provider metadata via `callProviderResolver` (server-side only).
3. `SessionCallProvider` gateway unchanged — join reads updated session doc.

**No provider logic in UI** — use cases + CF only.

---

## Notifications (post-beta)

| Event | Recipients |
|-------|------------|
| Request created | Counterparty (approve/reject) |
| Approved | Both |
| Rejected | Requester |
| Expired | Requester |
| Admin override | Both |

Use existing `enqueueSessionNotification` / FCM patterns; resolve teacher `userId` from profile doc id (same fix as booking notifications).

---

## Backend validation (when implemented)

- Caller is participant (student `userId` or `ownsTeacherProfile(teacherId)`)
- Session lifecycle allows change (`scheduled` / `confirmed`, not `inProgress` / terminal)
- Time policy (≥ 24 h before start)
- `newProviderType` allowed in `quran_session_platform_config.global.enabledCallProviders`
- External → requires teacher `externalMeetingUrl` at approve time
- Agora/WebRTC → server issues token; client never sends token
- Idempotency on approve
- Reject downgrades nothing

**Free Beta:** only admin override path needs validation + audit.

---

## UI (post-beta)

| Surface | Requirement |
|---------|-------------|
| Session detail | “Request different call type” → reason + picker (only enabled modes) |
| Pending banner | Counterparty: Approve / Reject |
| History | Timeline shows mode change requests (uses fixed events query) |
| Admin | Support panel: override with reason (admin app) |

**Free Beta UI:** None. Optional copy on session detail: “Call type was set at booking. Contact support to change.”

---

## Postponed (explicit)

- `SessionModeChangeRequest` collection + CFs
- Student/teacher approve/reject UI
- Agora/WebRTC mode switches (providers not live)
- Auto-expire pending requests (cron)
- Mode change bundled with reschedule (keep separate — different concerns)

---

## Implementation checklist (Free Beta only)

- [ ] Document lock in session detail (informational string, ARB)
- [ ] Firestore rules: `callProvider`, `callType`, `meetingLink` on `quran_sessions` — CF/admin write only (verify)
- [ ] Admin override CF + audit + dual notification (if not already present)
- [ ] QA: attempt client patch of provider fields → denied

---

## Go / No-Go

| Item | Verdict |
|------|---------|
| Lock after booking for Free Beta | **Go** |
| Bilateral change workflow in Free Beta | **No-Go** (post-beta) |
| Admin audited override | **Go** (minimal, if support needed) |
