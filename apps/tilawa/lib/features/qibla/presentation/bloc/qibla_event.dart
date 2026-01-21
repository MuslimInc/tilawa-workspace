part of 'qibla_bloc.dart';

abstract class QiblaEvent extends Equatable {
  const QiblaEvent();

  @override
  List<Object?> get props => [];
}

class CheckLocationService extends QiblaEvent {
  const CheckLocationService();
}

class RequestLocationPermission extends QiblaEvent {
  const RequestLocationPermission();
}

class StartQiblaStream extends QiblaEvent {
  const StartQiblaStream();
}

class StopQiblaStream extends QiblaEvent {
  const StopQiblaStream();
}

class UpdateQiblaDirection extends QiblaEvent {
  const UpdateQiblaDirection(this.direction);
  final QiblaDirectionEntity direction;

  @override
  List<Object?> get props => [direction];
}

class QiblaErrorOccurred extends QiblaEvent {
  const QiblaErrorOccurred(this.errorMessage);
  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
