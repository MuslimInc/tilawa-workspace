import 'package:equatable/equatable.dart';

import '../../../../core/entities/reciter_entity.dart';

sealed class ReciterDetailsLoaderState extends Equatable {
  const ReciterDetailsLoaderState();

  @override
  List<Object?> get props => [];
}

final class ReciterDetailsLoaderInitial extends ReciterDetailsLoaderState {
  const ReciterDetailsLoaderInitial();
}

final class ReciterDetailsLoaderLoading extends ReciterDetailsLoaderState {
  const ReciterDetailsLoaderLoading();
}

final class ReciterDetailsLoaderSuccess extends ReciterDetailsLoaderState {
  const ReciterDetailsLoaderSuccess(this.reciter);
  final ReciterEntity reciter;

  @override
  List<Object?> get props => [reciter];
}

final class ReciterDetailsLoaderFailure extends ReciterDetailsLoaderState {
  const ReciterDetailsLoaderFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
