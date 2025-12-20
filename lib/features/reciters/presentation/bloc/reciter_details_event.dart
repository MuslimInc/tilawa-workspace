part of 'reciter_details_bloc.dart';

abstract class ReciterDetailsEvent extends Equatable {
  const ReciterDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSurahList extends ReciterDetailsEvent {
  const LoadSurahList({required this.reciter, required this.moshaf});
  final ReciterEntity reciter;
  final MoshafEntity moshaf;

  @override
  List<Object?> get props => [reciter, moshaf];
}

class SelectMoshaf extends ReciterDetailsEvent {
  const SelectMoshaf(this.moshaf);
  final MoshafEntity moshaf;

  @override
  List<Object?> get props => [moshaf];
}

class SelectSurah extends ReciterDetailsEvent {
  const SelectSurah(this.surahId);
  final String surahId;

  @override
  List<Object?> get props => [surahId];
}

class RefreshSurahDownloadStatus extends ReciterDetailsEvent {
  const RefreshSurahDownloadStatus({
    required this.surahId,
    required this.reciterName,
  });
  final String surahId;
  final String reciterName;

  @override
  List<Object?> get props => [surahId, reciterName];
}

class DownloadAllSurahs extends ReciterDetailsEvent {
  const DownloadAllSurahs({required this.reciter, required this.surahs});
  final ReciterEntity reciter;
  final List<SurahEntity> surahs;

  @override
  List<Object?> get props => [reciter, surahs];
}
