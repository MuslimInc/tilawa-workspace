import 'package:equatable/equatable.dart';

/// How long a single bookable session lasts. Governs every generated slot
/// regardless of the day it falls on.
///
/// Four presets (15/30/45/60) cover the common cases; any positive minute count
/// is allowed via the default constructor for a custom duration.
class SlotDuration extends Equatable {
  const SlotDuration(this.minutes) : assert(minutes > 0, 'minutes must be > 0');

  final int minutes;

  static const fifteen = SlotDuration(15);
  static const thirty = SlotDuration(30);
  static const fortyFive = SlotDuration(45);
  static const sixty = SlotDuration(60);

  /// The presets offered as quick choices in the editor, in display order.
  static const presets = <SlotDuration>[fifteen, thirty, fortyFive, sixty];

  /// True when [minutes] matches one of the [presets].
  bool get isPreset => presets.contains(this);

  Duration get asDuration => Duration(minutes: minutes);

  @override
  List<Object?> get props => [minutes];

  @override
  String toString() => '${minutes}m';
}
