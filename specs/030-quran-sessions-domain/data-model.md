# Data Model: Quran Sessions Business Domain

> Infrastructure detail for Firestore. Domain entities in
> `packages/quran_sessions` remain backend-agnostic per ADR-002.

---

## Collection map

| Collection | Purpose | Write path |
|------------|---------|------------|
| `quran_bookings/{id}` | Commercial reservation | CF only |
| `quran_sessions/{id}` | Operational session | CF only |
| `quran_session_events/{id}` | Append-only audit log | CF only |
| `quran_session_compensations/{id}` | Compensation execution records | CF only |
| `quran_session_notifications/{id}` | Notification outbox | CF + delivery workers |
| `quran_reschedule_requests/{id}` | Pending reschedule flows | CF only |
| `quran_slot_locks/{lockId}` | Atomic slot exclusivity | CF only |
| `quran_teacher_metrics/{teacherId}` | Denormalized teacher stats | CF only |
| `quran_student_metrics/{studentId}` | Denormalized student stats | CF only |
| `quran_admin_actions/{id}` | Admin moderation log (cross-feature) | CF only |

Existing collections unchanged: `users`, `quran_teacher_profiles`,
`quran_teacher_applications`, `availability_config`, `availability_overrides`,
`quran_session_market_configs`, `quran_session_platform_config`.

### Migration compatibility status

- Domain fallback mapping shipped in package layer:
  `QuranBooking.effectiveLifecycleStatus` and
  `QuranSession.effectiveLifecycleStatus`.
- Read priority remains: `lifecycleStatus` first, legacy `status` fallback.
- `status` writes remain temporary until Phase M3 cutover.

---

## `quran_bookings/{bookingId}`

Document ID: auto-generated or deterministic `{studentId}_{slotId}` (CF decides).

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `bookingId` | string | yes | Same as doc ID |
| `aggregateId` | string | yes | Links booking + session |
| `studentId` | string | yes | |
| `teacherId` | string | yes | |
| `slotId` | string | yes | `{teacherId}_yyyyMMddTHHmmZ` |
| `startsAt` | timestamp | yes | UTC |
| `endsAt` | timestamp | yes | UTC |
| `timezone` | string | yes | IANA, from teacher schedule |
| `callType` | string | yes | `externalMeeting`, `voiceCall`, `videoCall` |
| `pricingType` | string | yes | `free`, `fixedPerSession`, `subscription` |
| `lifecycleStatus` | string | yes | `SessionLifecycleStatus` snake_case in Firestore |
| `status` | string | legacy | Deprecated after M3; keep for migration |
| `amountPaidUsd` | number | no | |
| `paymentReference` | string | no | Opaque |
| `paymentStatus` | string | no | `none`, `pending`, `captured`, `refunded`, `failed` |
| `sessionId` | string | no | Set when session doc created |
| `studentNote` | string | no | Max length enforced |
| `rescheduleCount` | int | yes | Default 0 |
| `countryCode` | string | no | Denormalized for admin filter |
| `cityId` | string | no | Denormalized for admin filter |
| `createdAt` | timestamp | yes | |
| `updatedAt` | timestamp | yes | |
| `cancelledAt` | timestamp | no | |
| `cancellationReason` | string | no | |
| `cancelledByActorId` | string | no | |
| `cancelledByRole` | string | no | `student`, `teacher`, `admin`, `system` |
| `version` | int | yes | Optimistic concurrency |

### Indexes

- `studentId` ASC, `createdAt` DESC (existing)
- `teacherId` ASC, `startsAt` DESC
- `lifecycleStatus` ASC, `startsAt` DESC (admin)
- `countryCode` ASC, `cityId` ASC, `startsAt` DESC (admin)

---

## `quran_sessions/{sessionId}`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `sessionId` | string | yes | Doc ID |
| `bookingId` | string | yes | |
| `aggregateId` | string | yes | |
| `studentId` | string | yes | |
| `teacherId` | string | yes | |
| `startsAt` | timestamp | yes | |
| `endsAt` | timestamp | yes | |
| `callType` | string | yes | |
| `lifecycleStatus` | string | yes | Mirrors booking after sync |
| `status` | string | legacy | Deprecated |
| `meetingLink` | string | no | |
| `callRoomId` | string | no | |
| `notes` | string | no | Participant notes |
| `attendance` | map | no | See below |
| `createdAt` | timestamp | yes | |
| `updatedAt` | timestamp | yes | |
| `completedAt` | timestamp | no | |
| `version` | int | yes | |

### `attendance` map

| Field | Type | Notes |
|-------|------|-------|
| `teacherJoinedAt` | timestamp | |
| `studentJoinedAt` | timestamp | |
| `sessionStartedAt` | timestamp | |
| `sessionEndedAt` | timestamp | |
| `classification` | string | NoShowClassification |
| `evidenceJson` | string | Provider logs / admin input |

### Indexes

- `studentId` ASC, `startsAt` DESC (existing)
- `teacherId` ASC, `startsAt` DESC (existing)
- `lifecycleStatus` ASC, `startsAt` DESC

---

## `quran_session_events/{eventId}`

Append-only audit log.

| Field | Type | Required |
|-------|------|----------|
| `eventId` | string | yes |
| `aggregateId` | string | yes |
| `bookingId` | string | no |
| `sessionId` | string | no |
| `actorId` | string | yes |
| `actorRole` | string | yes |
| `action` | string | yes |
| `previousStatus` | string | no |
| `newStatus` | string | yes |
| `reason` | string | no |
| `timestamp` | timestamp | yes |
| `source` | string | yes |
| `metadata` | map | no |

### Indexes

- `aggregateId` ASC, `timestamp` ASC
- `actorId` ASC, `timestamp` DESC

---

## `quran_session_compensations/{compensationId}`

| Field | Type | Required |
|-------|------|----------|
| `compensationId` | string | yes |
| `aggregateId` | string | yes |
| `bookingId` | string | yes |
| `type` | string | yes |
| `status` | string | yes | `pending`, `completed`, `failed`, `cancelled` |
| `policyRuleId` | string | yes |
| `parameters` | map | no |
| `amountUsd` | number | no |
| `paymentReference` | string | no |
| `issuedByActorId` | string | yes |
| `issuedByRole` | string | yes |
| `failureReason` | string | no |
| `retryCount` | int | yes |
| `createdAt` | timestamp | yes |
| `completedAt` | timestamp | no |

---

## `quran_session_notifications/{notificationId}`

Outbox pattern for multi-channel delivery.

| Field | Type | Required |
|-------|------|----------|
| `notificationId` | string | yes |
| `aggregateId` | string | yes |
| `recipientUserId` | string | yes |
| `type` | string | yes |
| `payload` | map | yes |
| `channels` | array | yes | `push`, `email`, … |
| `deliveryStatus` | map | yes | Per-channel status |
| `scheduledFor` | timestamp | no |
| `createdAt` | timestamp | yes |
| `sentAt` | timestamp | no |

---

## `quran_reschedule_requests/{requestId}`

| Field | Type | Required |
|-------|------|----------|
| `requestId` | string | yes |
| `aggregateId` | string | yes |
| `requestedByUserId` | string | yes |
| `requestedByRole` | string | yes |
| `reason` | string | yes |
| `oldSlotId` | string | yes |
| `newSlotId` | string | yes |
| `status` | string | yes | `pending`, `accepted`, `rejected`, `expired` |
| `respondedByUserId` | string | no |
| `createdAt` | timestamp | yes |
| `expiresAt` | timestamp | yes |

---

## `quran_slot_locks/{lockId}`

Lock ID: `{teacherId}_{startsAtEpochMs}`.

| Field | Type | Required |
|-------|------|----------|
| `lockId` | string | yes |
| `teacherId` | string | yes |
| `slotId` | string | yes |
| `aggregateId` | string | yes |
| `lockType` | string | yes | `soft`, `hard` |
| `lockedAt` | timestamp | yes |
| `expiresAt` | timestamp | yes |

TTL: Firestore TTL policy on `expiresAt` for automatic cleanup.

---

## `quran_teacher_metrics/{teacherId}`

Denormalized; updated by CF on terminal transitions.

| Field | Type | Notes |
|-------|------|-------|
| `teacherId` | string | Doc ID |
| `confirmedSessionCount` | int | |
| `completedSessionCount` | int | |
| `teacherCancellationCount` | int | Rolling + total |
| `teacherNoShowCount` | int | |
| `cancellationRate90d` | number | Computed |
| `lastCancellationAt` | timestamp | |
| `updatedAt` | timestamp | |

---

## `quran_student_metrics/{studentId}`

| Field | Type | Notes |
|-------|------|-------|
| `studentId` | string | Doc ID |
| `bookedSessionCount` | int | |
| `studentCancellationCount` | int | |
| `studentNoShowCount` | int | |
| `lastNoShowAt` | timestamp | |
| `updatedAt` | timestamp | |

---

## Platform config extensions

### `quran_session_platform_config/global`

Add nested maps:

```json
{
  "cancellationPolicy": {
    "earlyCancellationHours": 24,
    "lateRefundFraction": 0.0,
    "earlyRefundFraction": 1.0,
    "studentLateCountsAsUsed": true
  },
  "compensationPolicy": {
    "teacherCancel": ["restoreSessionCredit"],
    "teacherNoShow": ["restoreSessionCredit", "issueWalletCredit"],
    "defaultAdminChoices": ["restoreSessionCredit", "processPaymentRefund", "createManualReviewCase"]
  },
  "reschedulePolicy": {
    "maxReschedules": 1,
    "minHoursBeforeSession": 24
  },
  "noShowPolicy": {
    "gracePeriodMinutes": 15,
    "autoMarkBothNoShowAfterMinutes": 30
  },
  "bookingPolicy": {
    "minNoticeMinutes": 60,
    "maxHorizonDays": 30,
    "pendingPaymentTtlMinutes": 15
  },
  "reminderPolicy": {
    "hoursBefore": [24, 1]
  }
}
```

Per-market overrides on `quran_session_market_configs/{country}` optional.

---

## Legacy status migration map

| booking.status | session.status | → lifecycleStatus |
|----------------|----------------|-------------------|
| pending | — | pendingPayment |
| confirmed | scheduled | scheduled |
| confirmed | in_progress | inProgress |
| confirmed | completed | completed |
| confirmed | cancelled_by_student | cancelledByStudent |
| confirmed | cancelled_by_teacher | cancelledByTeacher |
| confirmed | no_show | teacherNoShow * |
| cancelled | * | cancelledByStudent * |
| refunded | * | refunded |
| rejected | — | expired |

\* Requires manual review script for ambiguous legacy rows.

---

## Security rules (target)

All new collections: **read** scoped to participants + admin; **write: false**
(client). Cloud Functions use Admin SDK.

`quran_session_events`: admin + participants read; append CF-only.

Admin panel reads via Firebase Admin SDK in CF or authenticated admin reads
with `isAdmin()` rule.

---

## ADR candidate

After approval, add **ADR-004: Quran Session Lifecycle & Server-Authoritative
Writes** documenting aggregate model, CF-only mutations, and migration phases.
