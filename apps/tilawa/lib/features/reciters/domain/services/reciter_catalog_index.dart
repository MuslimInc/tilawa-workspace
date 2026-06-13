import 'package:meta/meta.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

import '../utils/reciter_search_query_normalizer.dart';

/// Precomputed reciter catalog for O(1) letter buckets and fast name search.
///
/// Built once per reciter list snapshot; normalized names are stored in parallel
/// with [reciters] to avoid repeated normalization during search.
@immutable
final class ReciterCatalogIndex {
  const ReciterCatalogIndex._({
    required this.reciters,
    required this._normalizedNames,
    required this._byLetter,
  });

  factory ReciterCatalogIndex.from(List<ReciterEntity> reciters) {
    final normalizedNames = List<String>.filled(reciters.length, '');
    final byLetter = <String, List<ReciterEntity>>{};

    for (var i = 0; i < reciters.length; i++) {
      final ReciterEntity reciter = reciters[i];
      normalizedNames[i] = ReciterSearchQueryNormalizer.normalize(reciter.name);
      byLetter
          .putIfAbsent(reciter.letter, () => <ReciterEntity>[])
          .add(
            reciter,
          );
    }

    return ReciterCatalogIndex._(
      reciters: List<ReciterEntity>.unmodifiable(reciters),
      normalizedNames: normalizedNames,
      byLetter: byLetter,
    );
  }

  final List<ReciterEntity> reciters;
  final List<String> _normalizedNames;
  final Map<String, List<ReciterEntity>> _byLetter;

  /// O(1) bucket lookup for a letter index marker.
  List<ReciterEntity> recitersForLetter(String letter) {
    return _byLetter[letter] ?? const <ReciterEntity>[];
  }

  /// Substring search using pre-normalized names.
  List<ReciterEntity> search(String query) {
    final String normalizedQuery = ReciterSearchQueryNormalizer.normalize(
      query,
    );
    if (normalizedQuery.isEmpty) {
      return const <ReciterEntity>[];
    }

    final results = <ReciterEntity>[];
    for (var i = 0; i < reciters.length; i++) {
      final ReciterEntity reciter = reciters[i];
      if (_normalizedNames[i].contains(normalizedQuery) ||
          ReciterSearchQueryNormalizer.normalize(
            reciter.letter,
          ).contains(normalizedQuery)) {
        results.add(reciter);
      }
    }
    return results;
  }
}
