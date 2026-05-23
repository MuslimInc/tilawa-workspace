import 'package:equatable/equatable.dart';

/// Events for [SplashBloc].
sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

/// Starts readiness checks and route resolution.
final class SplashStarted extends SplashEvent {
  const SplashStarted();
}
