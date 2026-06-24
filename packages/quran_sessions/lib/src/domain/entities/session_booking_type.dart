/// How many participants a booking accommodates.
///
/// Free Beta implements [individual] only. [group] is reserved for a future
/// release — backend rejects group bookings until then.
enum SessionBookingType {
  individual,
  group,
}
