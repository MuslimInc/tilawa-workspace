part of 'reciters_bloc.dart';

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
  final List<entity.ReciterEntity> reciters;
  final List<entity.ReciterEntity> filteredReciters;
  final String searchQuery;
  final String? selectedLetter;

  @override
  List<Object?> get props => [
    reciters,
    filteredReciters,
    searchQuery,
    selectedLetter,
  ];

  RecitersLoaded copyWith({
    List<entity.ReciterEntity>? reciters,
    List<entity.ReciterEntity>? filteredReciters,
    String? searchQuery,
    String? selectedLetter,
    bool clearSelectedLetter = false,
  }) {
    return RecitersLoaded(
      reciters: reciters ?? this.reciters,
      filteredReciters: filteredReciters ?? this.filteredReciters,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLetter: clearSelectedLetter
          ? null
          : (selectedLetter ?? this.selectedLetter),
    );
  }
}

class RecitersError extends RecitersState {
  const RecitersError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
