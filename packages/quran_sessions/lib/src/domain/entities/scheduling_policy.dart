import 'package:equatable/equatable.dart';

/// Bounds that shape which generated slots are actually bookable.
///
/// Separated from the weekly rules because these are operational guard-rails
/// (how soon, how far ahead, and how much breathing room between sessions)
/// rather than "when do you teach".
class SchedulingPolicy extends Equatable {
  const SchedulingPolicy({
    this.minNoticeMinutes = 120,
    this.maxHorizonDays = 30,
    this.bufferBeforeMinutes = 0,
    this.bufferAfterMinutes = 0,
  }) : assert(minNoticeMinutes >= 0),
       assert(maxHorizonDays > 0),
       assert(bufferBeforeMinutes >= 0),
       assert(bufferAfterMinutes >= 0);

  /// A booking cannot start sooner than this many minutes from now.
  final int minNoticeMinutes;

  /// Slots are not generated further than this many days into the future.
  final int maxHorizonDays;

  /// Reserved time before each session (e.g. preparation/wudu). Not surfaced
  /// in the v1 editor but honoured by generation when set.
  final int bufferBeforeMinutes;

  /// Reserved time after each session.
  final int bufferAfterMinutes;

  /// Sensible defaults: 2h minimum notice, 30-day horizon, no buffers.
  static const standard = SchedulingPolicy();

  SchedulingPolicy copyWith({
    int? minNoticeMinutes,
    int? maxHorizonDays,
    int? bufferBeforeMinutes,
    int? bufferAfterMinutes,
  }) => SchedulingPolicy(
    minNoticeMinutes: minNoticeMinutes ?? this.minNoticeMinutes,
    maxHorizonDays: maxHorizonDays ?? this.maxHorizonDays,
    bufferBeforeMinutes: bufferBeforeMinutes ?? this.bufferBeforeMinutes,
    bufferAfterMinutes: bufferAfterMinutes ?? this.bufferAfterMinutes,
  );

  @override
  List<Object?> get props => [
    minNoticeMinutes,
    maxHorizonDays,
    bufferBeforeMinutes,
    bufferAfterMinutes,
  ];
}
