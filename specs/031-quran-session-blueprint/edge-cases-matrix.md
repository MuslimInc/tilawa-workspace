# Edge Cases Matrix — Quran Sessions

**Columns:** Expected result · User message · Backend state · Admin visibility · Compensation/refund · Tests required

**Tags:** `[B]` Beta · `[P]` Paid · `[A]` Admin-only path

---

## Booking & eligibility

| # | Edge case | Expected result | User message (AR key intent) | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|------------------------------|---------------|-------|--------------|-------|
| E01 | Double-tap book same slot | Single booking | "تم تأكيد الحجز" once | One aggregate scheduled | 1 row | — | Idempotency integration |
| E02 | Two students race same slot | Second fails | "الموعد لم يعد متاحًا" | First scheduled; second no write | — | — | Slot lock integration |
| E03 | Book while profile incomplete | Blocked | "أكمل ملفك الشخصي" | No write | — | — | Eligibility unit |
| E04 | Book with suspended student account | Blocked | "حسابك موقوف" | No write | User flagged | — | CF account_blocked |
| E05 | Book suspended teacher | Blocked | "المعلم غير متاح" | No write | — | — | Eligibility + CF |
| E06 | Gender policy violation | Blocked | Policy-specific | No write | — | — | ValidateBookingEligibility |
| E07 | Child student without guardian `[P]` | Blocked | "موافقة ولي الأمر مطلوبة" | No write | — | — | Eligibility unit |
| E08 | Book inside min notice (<1h default) | Blocked | "يجب الحجز قبل ساعة" | No write | — | — | BookingPolicy |
| E09 | Book beyond max horizon (30d) | Blocked | "التاريخ بعيد جدًا" | No write | — | — | Slot generator |
| E10 | Book teacher vacation day | Blocked | "المعلم في إجازة" | No write | — | — | Override validator |
| E11 | Paid teacher, payment disabled `[B]` | Blocked | "الدفع غير متاح حاليًا" | No write | — | — | payment_provider_unavailable |
| E12 | pendingPayment TTL expires | Expired | "انتهت صلاحية الحجز" | expired + slot released | Expired row | — | expirePendingReservations |
| E13 | Book free when teacher pricingType paid `[B]` | Allowed if market price=0 override OR block | Product decision: Beta force free teachers only | scheduled | — | — | Config test |

---

## Cancellation

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E20 | Student early cancel (>24h) | Allowed | Policy summary: full credit | cancelledByStudent | Event | Credit `[P]` refund | CancellationPolicy |
| E21 | Student late cancel (<24h) | Allowed, no refund | "لن يتم استرداد الرسوم" | cancelledByStudent | Event | None | Policy unit |
| E22 | Student cancel inside 1h block | Blocked | "لا يمكن الإلغاء الآن" | unchanged | — | — | Policy + CF |
| E23 | Teacher cancel with reason | Allowed | Confirmation | cancelledByTeacher | Event + metric | Auto student credit | Cancel teacher integration |
| E24 | Teacher cancel inProgress | Blocked | "تواصل مع الدعم" | unchanged | — | — | Lifecycle guard |
| E25 | Admin cancel with compensation choice | Allowed | — (admin) | cancelledByAdmin | Full audit | Per choice | Admin CF test |
| E26 | Cancel already terminal session | Rejected | "الجلسة منتهية" | unchanged | — | — | Guard unit |
| E27 | Cancel pendingPayment before capture | Allowed | "تم إلغاء الحجز" | cancelledByStudent or expired | — | Void payment `[P]` | CF |
| E28 | Non-participant attempts cancel | Permission denied | Generic error | unchanged | Security log | — | P0 smoke #1 |

---

## Reschedule

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E30 | Request reschedule max exceeded | Blocked | "تجاوزت عدد التغييرات" | unchanged | — | — | ReschedulePolicy |
| E31 | New slot taken before confirm | Confirm fails | "الموعد الجديد غير متاح" | rescheduled or revert scheduled | — | — | CF atomic |
| E32 | Counterparty rejects reschedule | Stays original slot | "تم رفض طلب التغيير" | scheduled (original) | Event | — | Reschedule flow |
| E33 | Reschedule request expires | Auto revert | "انتهى طلب التغيير" | scheduled | Event | — | TTL job |
| E34 | Admin force reschedule | Allowed | Notify both | scheduled new slot | Audit | — | Admin CF |
| E35 | Reschedule during inProgress | Blocked | — | unchanged | — | — | Guard |

---

## No-show & attendance

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E40 | Teacher never joins (grace 15m) | teacherNoShow | "المعلم لم يحضر" | teacherNoShow | Flagged | Auto credit | markNoShow job |
| E41 | Student never joins | studentNoShow | "لم تحضر للجلسة" | studentNoShow | Metric++ | Policy: no refund | markNoShow |
| E42 | Neither joins | bothNoShow | Neutral message both | bothNoShow | Review | Case-by-case | System
| E43 | Teacher late join (<5m) | `[Future]` lateJoin sub-state | — | may stay scheduled→inProgress | — | — | Attendance policy |
| E44 | Teacher marks no-show before grace | Blocked | "انتظر حتى انتهاء المهلة" | unchanged | — | — | Policy CF |
| E45 | False no-show dispute | openDispute | — | disputed | Queue | Manual | Dispute integration |
| E46 | Session completes after brief join | completed | Review prompt | completed | — | — | completeSession |

---

## Disputes, reports, remediation

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E50 | Open dispute from active scheduled | Blocked | "لا يمكن بعد انتهاء الجلسة" | unchanged | — | — | Guard |
| E51 | Open dispute from completed | Allowed | "تم استلام الشكوى" | disputed | Queue | — | openDispute |
| E52 | Duplicate dispute same session | Idempotent or reject | — | one disputed | — | — | CF |
| E53 | Report safety during session | Allowed | "تم إرسال البلاغ" | report doc | High priority | — | reportSessionConcern |
| E54 | Resolve favor_student | Compensation + optional refund | "تم الحكم لصالحك" | compensated/refunded | Closed | Yes | Integration #7 |
| E55 | Compensation gateway fails | Retry queue | "جاري المعالجة" | terminal + comp failed | Retry UI | Pending | Gateway fake |
| E56 | Duplicate refund idempotency | Same refund doc | — | refunded once | Ledger | Once | P0 smoke #6 |

---

## Teacher lifecycle & availability

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E60 | Teacher suspended mid-booking flow | Block at confirm | "المعلم غير متاح" | no write | — | — | CF |
| E61 | Teacher sets vacation over booked days | Block save OR warn | "لديك حجوزات في هذه الفترة" | — | Alert | Admin reschedule | Override validator |
| E62 | Approved but incomplete profile | Not in list | — | isPubliclyVisible=false | — | — | Capability test |
| E63 | Reapply within 30d cooldown | Blocked | "يمكنك التقديم بعد …" | — | — | — | Submit application |
| E64 | Revoked teacher opens dashboard | Blocked | "تم إلغاء حساب المعلم" | — | — | — | Capability |
| E65 | Teacher cancel rate > threshold `[P]` | Auto suspend bookings | Email to teacher | acceptBookings=false | Dashboard | — | Metrics job |

---

## Payment & ledger `[P]`

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E70 | Payment capture fails | expired | "فشل الدفع" | expired | — | — | payment test |
| E71 | Partial refund | Ledger partial | — | refunded partial | Ledger | Partial | Financial service |
| E72 | Refund after compensated | Allowed with guard | — | refunded | Audit both | Reconcile | Policy |
| E73 | Subscription session debit | Package -1 credit | — | scheduled | — | — | `[Future]` |

---

## System & security

| # | Edge case | Expected result | User message | Backend state | Admin | Compensation | Tests |
|---|-----------|-----------------|--------------|---------------|-------|--------------|-------|
| E80 | Blocked user self-unblock via client | Denied by rules | — | unchanged | — | — | Rules test P0 #2 |
| E81 | Client direct write booking doc | Denied | — | unchanged | — | — | Firestore rules |
| E82 | lifecycleStatus vs legacy status drift | Read prefers lifecycle | — | dual-read | Backfill | — | Mapper test |
| E83 | Booking flag off, UI shows book | Hide/disable CTA | "الحجز قريبًا" | — | — | — | Feature flag widget test |
| E84 | Offline book attempt | Queue or fail clearly | "تحقق من الاتصال" | — | — | — | UX |
| E85 | Timezone DST shift on slot | Slot at UTC stable | Display local correct | UTC stored | — | — | Slot generator |

---

## Test coverage mapping

| Suite | Edge IDs |
|-------|----------|
| `session_lifecycle_guard_test.dart` | E26, E35, E50 |
| `bookingEligibility.test.ts` | E03–E06, E10 |
| `createSessionBooking.integration.test.ts` | E01–E02, E04 |
| `cancelSession` integration | E20–E28 |
| `resolveSessionDispute.integration.test.ts` | E54–E56 |
| `usersModeration.rules.test.ts` | E80–E81 |
| `paymentAndIdempotency.test.ts` | E56, E70 |

Full matrix: [test-matrix.md](./test-matrix.md).
