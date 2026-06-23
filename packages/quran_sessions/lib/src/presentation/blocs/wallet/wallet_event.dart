import 'package:equatable/equatable.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

final class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}
