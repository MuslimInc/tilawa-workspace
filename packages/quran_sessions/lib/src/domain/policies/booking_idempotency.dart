import 'dart:math';

/// Client idempotency key for booking creation (Q-BK-04).
abstract final class BookingIdempotency {
  static final Random _random = Random.secure();

  /// One key per submit tap; server dedupes within 24h.
  static String generateClientKey() {
    final millis = DateTime.now().toUtc().millisecondsSinceEpoch;
    final nonce = _random.nextInt(0xFFFFFF);
    return 'bk-$millis-$nonce';
  }
}
