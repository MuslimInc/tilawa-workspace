part of 'reciter_details_bloc.dart';

abstract class ReciterDetailsEvent extends Equatable {
  const ReciterDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSurahList extends ReciterDetailsEvent {
  final Reciter reciter;
  final Mosahf moshaf;

  const LoadSurahList({required this.reciter, required this.moshaf});

  @override
  List<Object?> get props => [reciter, moshaf];
}

class SelectMoshaf extends ReciterDetailsEvent {
  final Mosahf moshaf;

  const SelectMoshaf(this.moshaf);

  @override
  List<Object?> get props => [moshaf];
}

class SelectSurah extends ReciterDetailsEvent {
  final String surahId;

  const SelectSurah(this.surahId);

  @override
  List<Object?> get props => [surahId];
}

class RefreshSurahDownloadStatus extends ReciterDetailsEvent {
  final String surahId;
  final String reciterName;

  const RefreshSurahDownloadStatus({
    required this.surahId,
    required this.reciterName,
  });

  @override
  List<Object?> get props => [surahId, reciterName];
}
