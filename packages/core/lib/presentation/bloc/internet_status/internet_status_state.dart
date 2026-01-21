import 'package:equatable/equatable.dart';

enum InternetStatus { connected, disconnected }

class InternetStatusState extends Equatable {
  const InternetStatusState._({required this.status});

  const InternetStatusState.connected()
    : this._(status: InternetStatus.connected);
  const InternetStatusState.disconnected()
    : this._(status: InternetStatus.disconnected);
  final InternetStatus status;

  @override
  List<Object?> get props => [status];
}
