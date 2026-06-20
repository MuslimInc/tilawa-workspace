/// How a session is priced.
///
/// [free]        — no charge; used for trial or charity sessions.
/// [fixedPerSession] — flat fee per booking.
/// [subscription]    — covered under a recurring plan (future phase).
enum SessionPricingType {
  free,
  fixedPerSession,
  subscription,
}
