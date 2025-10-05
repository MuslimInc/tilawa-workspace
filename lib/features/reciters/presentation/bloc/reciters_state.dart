import 'package:equatable/equatable.dart';
import 'package:muzakri/core/entities/reciter.dart';

abstract class RecitersState extends Equatable {
  const RecitersState();

  @override
  List<Object?> get props => [];
}

class RecitersInitial extends RecitersState {
  const RecitersInitial();
}

class RecitersLoading extends RecitersState {
  const RecitersLoading();
}

class RecitersLoaded extends RecitersState {
  const RecitersLoaded({
    required this.reciters,
    required this.filteredReciters,
    this.searchQuery = '',
    this.selectedLetter,
  });

  final List<ReciterEntity> reciters;
  final List<ReciterEntity> filteredReciters;
  final String searchQuery;
  final String? selectedLetter;

  RecitersLoaded copyWith({
    List<ReciterEntity>? reciters,
    List<ReciterEntity>? filteredReciters,
    String? searchQuery,
    String? selectedLetter,
  }) {
    return RecitersLoaded(
      reciters: reciters ?? this.reciters,
      filteredReciters: filteredReciters ?? this.filteredReciters,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLetter: selectedLetter ?? this.selectedLetter,
    );
  }

  @override
  List<Object?> get props => [
    reciters,
    filteredReciters,
    searchQuery,
    selectedLetter,
  ];
}

class RecitersError extends RecitersState {
  const RecitersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
