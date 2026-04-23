import 'package:equatable/equatable.dart';

/// Represents a single match in a Quran search.
class SearchEntry extends Equatable {
  const SearchEntry({required this.surahNumber, required this.verseNumber});

  final int surahNumber;
  final int verseNumber;

  @override
  List<Object?> get props => [surahNumber, verseNumber];
}

/// Represents the full result set of a Quran search.
class SearchResult extends Equatable {
  const SearchResult({required this.occurrences, required this.entries});

  final int occurrences;
  final List<SearchEntry> entries;

  @override
  List<Object?> get props => [occurrences, entries];
}
