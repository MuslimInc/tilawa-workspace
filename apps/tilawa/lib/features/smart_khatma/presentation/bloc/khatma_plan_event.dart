import 'package:equatable/equatable.dart';

import '../../domain/entities/khatma_plan.dart';

sealed class KhatmaPlanEvent extends Equatable {
  const KhatmaPlanEvent();

  @override
  List<Object?> get props => const [];
}

final class KhatmaPlanStarted extends KhatmaPlanEvent {
  const KhatmaPlanStarted();
}

final class KhatmaPlanPreviewRequested extends KhatmaPlanEvent {
  const KhatmaPlanPreviewRequested({
    required this.durationDays,
    required this.startPage,
    required this.targetPage,
  });

  final int durationDays;
  final int startPage;
  final int targetPage;

  @override
  List<Object?> get props => [durationDays, startPage, targetPage];
}

final class KhatmaPlanCreationConfirmed extends KhatmaPlanEvent {
  const KhatmaPlanCreationConfirmed(this.plan);

  final KhatmaPlan plan;

  @override
  List<Object?> get props => [plan];
}

final class KhatmaProgressConfirmed extends KhatmaPlanEvent {
  const KhatmaProgressConfirmed(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

final class KhatmaPlanExtendSelected extends KhatmaPlanEvent {
  const KhatmaPlanExtendSelected();
}

final class KhatmaPlanResetRequested extends KhatmaPlanEvent {
  const KhatmaPlanResetRequested();
}

final class KhatmaPlanEditPreviewRequested extends KhatmaPlanEvent {
  const KhatmaPlanEditPreviewRequested({
    required this.plan,
    required this.durationDays,
  });

  final KhatmaPlan plan;
  final int durationDays;

  @override
  List<Object?> get props => [plan, durationDays];
}

final class KhatmaPlanEditConfirmed extends KhatmaPlanEvent {
  const KhatmaPlanEditConfirmed({
    required this.plan,
    required this.durationDays,
  });

  final KhatmaPlan plan;
  final int durationDays;

  @override
  List<Object?> get props => [plan, durationDays];
}
