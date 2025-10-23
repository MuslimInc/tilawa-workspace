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
  final List<SurahEntity> surahList;
  final Mosahf selectedMoshaf;
  final String? selectedSurahId;

  const ReciterDetailsLoaded({
    required this.surahList,
    required this.selectedMoshaf,
    this.selectedSurahId,
  });

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
  final String message;

  const ReciterDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
