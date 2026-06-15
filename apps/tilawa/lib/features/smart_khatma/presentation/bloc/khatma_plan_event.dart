import 'package:equatable/equatable.dart';

sealed class KhatmaPlanEvent extends Equatable {
  const KhatmaPlanEvent();

  @override
  List<Object?> get props => const [];
}

final class KhatmaPlanStarted extends KhatmaPlanEvent {
  const KhatmaPlanStarted();
}

final class KhatmaPlanQuickStartRequested extends KhatmaPlanEvent {
  const KhatmaPlanQuickStartRequested(this.durationDays);

  final int durationDays;

  @override
  List<Object?> get props => [durationDays];
}

final class KhatmaPlanCatchUpSelected extends KhatmaPlanEvent {
  const KhatmaPlanCatchUpSelected();
}

final class KhatmaPlanExtendSelected extends KhatmaPlanEvent {
  const KhatmaPlanExtendSelected();
}

final class KhatmaPlanResetRequested extends KhatmaPlanEvent {
  const KhatmaPlanResetRequested();
}
