import 'package:equatable/equatable.dart';

/// A bookable instant produced by [SlotGenerator]. Transient — never persisted.
///
/// [startUtc]/[endUtc] are always in UTC; the UI renders them in the viewer's
/// own zone. [slotId] is deterministic (see [GeneratedSlot.deterministicId]) so
/// the same instant always maps to the same id, making bookings idempotent and
/// "is this taken?" a single document lookup.
class GeneratedSlot extends Equatable {
  GeneratedSlot({
    required this.teacherId,
    required DateTime startUtc,
    required DateTime endUtc,
    String? slotId,
  }) : startUtc = startUtc.toUtc(),
       endUtc = endUtc.toUtc(),
       slotId = slotId ?? deterministicId(teacherId, startUtc);

  final String slotId;
  final String teacherId;
  final DateTime startUtc;
  final DateTime endUtc;

  Duration get duration => endUtc.difference(startUtc);

  /// Builds the stable id for a [teacherId] at a given start instant:
  /// `"{teacherId}_yyyyMMddTHHmmZ"` (UTC). Two students racing the same instant
  /// therefore contend for the same id — the storage layer lets one win.
  static String deterministicId(String teacherId, DateTime startUtc) {
    final u = startUtc.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}'
        'T${two(u.hour)}${two(u.minute)}Z';
    return '${teacherId}_$stamp';
  }

  /// Parses the UTC start instant encoded in a deterministic [slotId].
  static DateTime? parseStartUtc({
    required String teacherId,
    required String slotId,
  }) {
    final prefix = '${teacherId}_';
    if (!slotId.startsWith(prefix)) return null;
    final stamp = slotId.substring(prefix.length);
    final match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})Z$',
    ).firstMatch(stamp);
    if (match == null) return null;
    return DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  @override
  List<Object?> get props => [slotId, teacherId, startUtc, endUtc];
}
