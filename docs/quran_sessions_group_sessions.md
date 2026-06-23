# Quran group sessions — conceptual model (not implemented)

Free Beta ships **individual 1:1** bookings only. This document reserves the
data shape so group work does not require a booking rewrite.

## Booking

| Field | Individual (now) | Group (future) |
|-------|------------------|----------------|
| `bookingType` | `individual` | `group` |
| `capacity` | `2` (teacher + one student) | `N` (teacher + many students) |
| `participants` | `[teacher, student]` | `[teacher, student…]` with roles |

Backend already rejects `bookingType !== individual` in Free Beta.

## Session

| Field | Purpose |
|-------|---------|
| `sessionMode` / `callType` | `voice` \| `video` \| `externalMeeting` |
| `callProvider` | `external` \| `mock` \| `agora` \| `webrtc` |
| `providerSessionId` | Server-issued room/channel id |
| `joinToken` | Server-issued; never client-generated |
| `participants` | Array of `{ userId, role }` |

## Call join

`JoinSessionUseCase` + `SessionCallProvider` already accept
`SessionParticipantRole`. Group join reuses the same gateway; provider
implementations add multi-participant UI when RTC ships.

## Teacher dashboard

Upcoming list stays per-session document. Group sessions surface one card with
capacity badge; student list loads from `participants` (future).

## Out of scope (Free Beta)

- Paid group pricing, wallets, payouts
- Agora/WebRTC multi-party channels
- Waitlists and partial fills
