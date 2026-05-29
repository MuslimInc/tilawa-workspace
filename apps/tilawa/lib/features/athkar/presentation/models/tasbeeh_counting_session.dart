import 'package:equatable/equatable.dart';

import '../../domain/entities/tasbeeh_dhikr.dart';

/// Active tap-to-count experience. Ephemeral sessions never use target feedback.
sealed class TasbeehCountingSession extends Equatable {
  const TasbeehCountingSession();
}

final class TasbeehEphemeralCountingSession extends TasbeehCountingSession {
  const TasbeehEphemeralCountingSession({required this.count});

  final int count;

  @override
  List<Object?> get props => [count];
}

final class TasbeehSavedDhikrCountingSession extends TasbeehCountingSession {
  const TasbeehSavedDhikrCountingSession({
    required this.dhikr,
    required this.targetFeedbackPulse,
  });

  final TasbeehDhikr dhikr;
  final int targetFeedbackPulse;

  double get progress => dhikr.targetCount <= 0
      ? 0
      : (dhikr.count / dhikr.targetCount).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [dhikr, targetFeedbackPulse];
}
