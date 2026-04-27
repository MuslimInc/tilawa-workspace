import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';
import '../../domain/entities/player_background_configuration.dart';

sealed class PlayerBackgroundState extends Equatable {
  const PlayerBackgroundState(this.config);
  final PlayerBackgroundConfiguration config;

  @override
  List<Object?> get props => [config];
}

class PlayerBackgroundInitial extends PlayerBackgroundState {
  const PlayerBackgroundInitial(super.config);
}

class PlayerBackgroundLoading extends PlayerBackgroundState {
  const PlayerBackgroundLoading(super.config);
}

class PlayerBackgroundSuccess extends PlayerBackgroundState {
  const PlayerBackgroundSuccess(super.config);
}

class PlayerBackgroundError extends PlayerBackgroundState {
  const PlayerBackgroundError(super.config, this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [config, failure];
}
