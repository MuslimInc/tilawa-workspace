import 'package:equatable/equatable.dart';

import 'home_athkar_compact_state.dart';

/// Which resume surface Home promotes directly under the hero.
enum HomePrimaryActionKind { quran, listening, athkar }

/// Smart primary action selection for the Home dashboard.
final class HomePrimaryActionState extends Equatable {
  const HomePrimaryActionState({
    this.kind = HomePrimaryActionKind.quran,
    this.urgentAthkarRow,
  });

  final HomePrimaryActionKind kind;
  final HomeAthkarRowState? urgentAthkarRow;

  HomePrimaryActionState copyWith({
    HomePrimaryActionKind? kind,
    HomeAthkarRowState? urgentAthkarRow,
    bool clearUrgentAthkarRow = false,
  }) {
    return HomePrimaryActionState(
      kind: kind ?? this.kind,
      urgentAthkarRow: clearUrgentAthkarRow
          ? null
          : urgentAthkarRow ?? this.urgentAthkarRow,
    );
  }

  @override
  List<Object?> get props => [kind, urgentAthkarRow];
}
