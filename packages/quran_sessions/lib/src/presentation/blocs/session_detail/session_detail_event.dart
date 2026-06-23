import 'package:equatable/equatable.dart';

sealed class SessionDetailEvent extends Equatable {
  const SessionDetailEvent();

  @override
  List<Object?> get props => [];
}

final class SessionDetailLoadRequested extends SessionDetailEvent {
  const SessionDetailLoadRequested({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => [bookingId];
}

/// User taps join on session detail.
final class SessionDetailJoinRequested extends SessionDetailEvent {
  const SessionDetailJoinRequested();
}
