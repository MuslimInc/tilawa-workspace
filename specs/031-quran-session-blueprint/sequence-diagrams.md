# Sequence Diagrams — Quran Sessions

Cross-system actors:
- **Mobile App** — Flutter (`apps/tilawa`, `packages/quran_sessions`)
- **Cloud Function/API** — Firebase callables (`functions/src/quranSessions/`)
- **Domain Service** — lifecycle + policy layer (TS + Dart mirror)
- **Firestore** — persistence
- **Notification Service** — outbox + FCM delivery
- **Admin Panel** — Angular (`apps/tilawa_admin`)

---

## 1. Create booking (free Beta)

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App
  participant CF as Cloud Function<br/>createSessionBooking
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF: slotId, teacherId, callType, idempotencyKey
  CF->>DS: validate actor + BookingIntegrityValidator
  DS->>FS: read teacher profile, student profile, slot lock
  alt slot available + policies pass
    CF->>FS: TX write slot_lock, booking, session, event
    FS-->>CF: aggregateId, scheduled
    CF->>NS: enqueue bookingConfirmed (student, teacher)
    CF-->>MA: success + sessionId
    NS-->>MA: push (async)
    FS-->>AP: session visible in list (read)
  else slot taken / blocked
    CF-->>MA: already-exists / account_blocked
  end
```

**Idempotency:** Same key → same bookingId without duplicate docs (P0 smoke #4).

---

## 2. Cancel by teacher

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App (Teacher)
  participant CF as Cloud Function<br/>cancelSessionBooking
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF: sessionId, reason, actor=teacher
  CF->>DS: SessionLifecycleGuard cancelByTeacher
  DS->>FS: read aggregate (scheduled/confirmed)
  alt valid + reason OK
    CF->>FS: TX status→cancelledByTeacher, release lock, event
    CF->>DS: CompensationPolicy.forTeacherCancellation
    DS->>FS: create compensation record (pending)
    CF->>NS: teacherCancelled + compensationIssued
    CF-->>MA: success
    NS-->>MA: push to student
    FS-->>AP: timeline + metrics bump
  else inProgress / terminal
    CF-->>MA: invalid_transition
  end
```

---

## 3. Cancel by student

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App (Student)
  participant CF as cancelSessionBooking
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF: sessionId, reason, actor=student
  CF->>DS: CancellationPolicy.evaluate(timing)
  alt allowed
    CF->>FS: TX→cancelledByStudent, release lock, event
    opt Paid + early cancel
      CF->>FS: refund record manual_pending
    end
    CF->>NS: studentCancelled
    CF-->>MA: success + policy outcome copy
    FS-->>AP: studentCancellationCount++
  else inside blocked window
    CF-->>MA: policy_violation
  end
```

---

## 4. Reschedule (request + confirm)

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App
  participant CF1 as requestSessionReschedule
  participant CF2 as confirmSessionReschedule
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF1: aggregateId, newSlotId, reason
  CF1->>DS: ReschedulePolicy + slot check
  CF1->>FS: reschedule_request pending, status→rescheduled, event
  CF1->>NS: rescheduleRequested
  CF1-->>MA: pending requestId

  Note over MA: Counterparty accepts (or admin forces)

  MA->>CF2: requestId, accept=true
  CF2->>DS: revalidate new slot
  CF2->>FS: TX swap locks, update slot fields, status→scheduled
  CF2->>FS: event + increment rescheduleCount
  CF2->>NS: rescheduleConfirmed
  CF2-->>MA: success
  FS-->>AP: audit timeline
```

**Invariant:** Old slot released only after new slot lock succeeds.

---

## 5. Mark no-show (system job)

```mermaid
sequenceDiagram
  autonumber
  participant JOB as Scheduled Job
  participant CF as markSessionNoShow
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  JOB->>FS: query sessions startsAt+grace < now, status scheduled/confirmed
  loop each candidate
    JOB->>CF: sessionId, classification
    CF->>FS: read attendance joins
    alt no teacher join
      CF->>FS: TX→teacherNoShow, event, compensation
      CF->>NS: noShowMarked
    else no student join
      CF->>FS: TX→studentNoShow
    else neither
      CF->>FS: TX→bothNoShow
    end
    FS-->>AP: flagged session
  end
```

---

## 6. Open dispute

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App
  participant CF as openSessionDispute
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF: sessionId, reason, evidence
  CF->>DS: guard openDispute from terminal
  CF->>FS: TX status→disputed, event, admin case metadata
  CF->>NS: manual review alert (admin channel)
  CF-->>MA: caseId
  AP->>FS: read dispute queue (filter disputed)
```

**Gap:** Mobile dispute UI not implemented; CF exists.

---

## 7. Resolve dispute (admin)

```mermaid
sequenceDiagram
  autonumber
  participant AP as Admin Panel
  participant CF as resolveSessionDispute
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant MA as Mobile App

  AP->>CF: sessionId, resolution, compensationChoice
  CF->>DS: validate admin claim
  alt favor_student / with_compensation
    CF->>FS: compensation ledger manual_pending
    CF->>FS: event issueCompensation
  else favor_teacher / dismiss
    CF->>FS: event only + note
  end
  CF->>NS: resolution summary to both users
  CF-->>AP: success
  NS-->>MA: push
```

---

## 8. Issue compensation

```mermaid
sequenceDiagram
  autonumber
  participant AP as Admin Panel
  participant CF as issueSessionCompensation
  participant DS as CompensationPolicy
  participant FS as Firestore
  participant GW as Compensation Gateway
  participant NS as Notification Service
  participant MA as Mobile App

  AP->>CF: sessionId, type, parameters
  CF->>DS: validate from disputed/cancelledByTeacher/teacherNoShow
  CF->>FS: create compensation pending
  CF->>GW: execute (credit / wallet)
  alt success
    GW-->>CF: completed
    CF->>FS: status completed, status→compensated
    CF->>NS: compensationIssued
  else failure
    CF->>FS: status failed, retryCount++
  end
  NS-->>MA: push
```

**Beta:** Gateway executes session credit only; no PSP.

---

## 9. Issue refund / manual pending

```mermaid
sequenceDiagram
  autonumber
  participant AP as Admin Panel
  participant CF as approveSessionRefund
  participant DS as Domain Service
  participant FS as Firestore
  participant PSP as Payment Provider
  participant NS as Notification Service
  participant MA as Mobile App

  AP->>CF: sessionId, amount, idempotencyKey
  CF->>FS: check duplicate refund doc
  alt Paid + PSP configured
    CF->>PSP: refund API
    PSP-->>CF: reference
    CF->>FS: refund completed, status→refunded
  else Beta / PSP unavailable
    CF->>FS: refund manual_pending ledger
  end
  CF->>FS: audit event
  CF->>NS: refundIssued
  NS-->>MA: push
```

**Idempotency:** P0 smoke #6 — duplicate key → one ledger doc.

---

## 10. Report safety concern

```mermaid
sequenceDiagram
  autonumber
  participant MA as Mobile App
  participant CF as reportSessionConcern
  participant DS as Domain Service
  participant FS as Firestore
  participant NS as Notification Service
  participant AP as Admin Panel

  MA->>CF: sessionId, category, narrative
  CF->>DS: validate participant or witness policy
  CF->>FS: create report doc + admin action + event
  CF->>NS: alert moderators (high priority)
  CF-->>MA: reportId + confirmation copy
  AP->>FS: read reports queue
  AP->>CF: resolveSessionReport (separate flow)
  CF->>FS: resolution + optional suspend user
  NS-->>MA: outcome notification
```

**Gap:** Report UI missing on mobile; admin reports queue UI partial.

---

## Sequence index

| # | Flow | Primary CF | Beta |
|---|------|------------|------|
| 1 | Create booking | createSessionBooking | ✅ free |
| 2 | Teacher cancel | cancelSessionBooking | ✅ |
| 3 | Student cancel | cancelSessionBooking | ✅ |
| 4 | Reschedule | request + confirm | ✅ |
| 5 | No-show | markSessionNoShow | ✅ |
| 6 | Open dispute | openSessionDispute | UI gap |
| 7 | Resolve dispute | resolveSessionDispute | ✅ |
| 8 | Compensation | issueSessionCompensation | ✅ credit |
| 9 | Refund | approveSessionRefund | manual |
| 10 | Safety report | reportSessionConcern | UI gap |
