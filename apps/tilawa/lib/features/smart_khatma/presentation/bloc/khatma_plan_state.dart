import 'package:equatable/equatable.dart';

import '../../domain/entities/khatma_plan.dart';

sealed class KhatmaPlanState extends Equatable {
  const KhatmaPlanState();

  @override
  List<Object?> get props => const [];
}

final class KhatmaPlanInitial extends KhatmaPlanState {
  const KhatmaPlanInitial();
}

final class KhatmaPlanLoading extends KhatmaPlanState {
  const KhatmaPlanLoading();
}

final class KhatmaPlanLoaded extends KhatmaPlanState {
  const KhatmaPlanLoaded({required this.plan, required this.todayTarget});

  final KhatmaPlan? plan;
  final KhatmaTodayTarget? todayTarget;

  @override
  List<Object?> get props => [plan, todayTarget];
}

final class KhatmaPlanFailure extends KhatmaPlanState {
  const KhatmaPlanFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
