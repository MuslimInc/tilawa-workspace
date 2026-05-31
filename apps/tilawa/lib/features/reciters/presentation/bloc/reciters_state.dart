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
    this.selectedLetter,
    this.showFavoritesOnly = false,
    this.favoriteIds = const <int>{},
  });
  final List<entity.ReciterEntity> reciters;
  final List<entity.ReciterEntity> filteredReciters;
  final String? selectedLetter;
  final bool showFavoritesOnly;
  final Set<int> favoriteIds;

  @override
  List<Object?> get props => [
    reciters,
    filteredReciters,
    selectedLetter,
    showFavoritesOnly,
    favoriteIds,
  ];

  RecitersLoaded copyWith({
    List<entity.ReciterEntity>? reciters,
    List<entity.ReciterEntity>? filteredReciters,
    String? selectedLetter,
    bool? showFavoritesOnly,
    Set<int>? favoriteIds,
    bool clearSelectedLetter = false,
  }) {
    return RecitersLoaded(
      reciters: reciters ?? this.reciters,
      filteredReciters: filteredReciters ?? this.filteredReciters,
      selectedLetter: clearSelectedLetter
          ? null
          : (selectedLetter ?? this.selectedLetter),
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

class RecitersError extends RecitersState {
  const RecitersError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
