part of 'qibla_bloc.dart';

enum QiblaStatus {
  initial,
  loading,
  permissionDenied,
  serviceDisabled,
  success,
  error,
}

class QiblaState extends Equatable {
  const QiblaState({
    this.status = QiblaStatus.initial,
    this.direction,
    this.errorMessage,
  });

  final QiblaStatus status;
  final QiblaDirectionEntity? direction;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, direction, errorMessage];

  QiblaState copyWith({
    QiblaStatus? status,
    QiblaDirectionEntity? direction,
    String? errorMessage,
  }) {
    return QiblaState(
      status: status ?? this.status,
      direction: direction ?? this.direction,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
