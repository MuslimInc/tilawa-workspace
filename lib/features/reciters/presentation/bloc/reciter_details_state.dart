part of 'reciter_details_bloc.dart';

abstract class ReciterDetailsState extends Equatable {
  const ReciterDetailsState();

  @override
  List<Object?> get props => [];
}

class ReciterDetailsInitial extends ReciterDetailsState {
  const ReciterDetailsInitial();
}

class ReciterDetailsLoading extends ReciterDetailsState {
  const ReciterDetailsLoading();
}

class ReciterDetailsLoaded extends ReciterDetailsState {
  const ReciterDetailsLoaded({
    required this.surahList,
    required this.selectedMoshaf,
    this.selectedSurahId,
  });
  final List<SurahEntity> surahList;
  final Mosahf selectedMoshaf;
  final String? selectedSurahId;

  @override
  List<Object?> get props => [surahList, selectedMoshaf, selectedSurahId];

  ReciterDetailsLoaded copyWith({
    List<SurahEntity>? surahList,
    Mosahf? selectedMoshaf,
    String? selectedSurahId,
  }) {
    return ReciterDetailsLoaded(
      surahList: surahList ?? this.surahList,
      selectedMoshaf: selectedMoshaf ?? this.selectedMoshaf,
      selectedSurahId: selectedSurahId ?? this.selectedSurahId,
    );
  }
}

class ReciterDetailsError extends ReciterDetailsState {
  const ReciterDetailsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
