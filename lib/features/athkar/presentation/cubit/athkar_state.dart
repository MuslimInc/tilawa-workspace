import 'package:equatable/equatable.dart';

import '../../domain/entities/athkar_category.dart';
import '../../domain/entities/athkar_item.dart';

abstract class AthkarState extends Equatable {
  const AthkarState();

  @override
  List<Object?> get props => [];
}

class AthkarInitial extends AthkarState {}

class AthkarLoading extends AthkarState {}

class AthkarCategoriesLoaded extends AthkarState {

  const AthkarCategoriesLoaded(this.categories);
  final List<AthkarCategory> categories;

  @override
  List<Object?> get props => [categories];
}

class AthkarItemsLoaded extends AthkarState {

  const AthkarItemsLoaded({required this.items, required this.currentCounts});
  final List<AthkarItem> items;
  final Map<int, int> currentCounts;

  @override
  List<Object?> get props => [items, currentCounts];
}

class AthkarError extends AthkarState {

  const AthkarError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
