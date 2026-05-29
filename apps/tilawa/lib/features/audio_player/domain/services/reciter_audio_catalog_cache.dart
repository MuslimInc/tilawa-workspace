import 'dart:developer' show log;

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../entities/reciter_audio_catalog.dart';
import 'reciter_audio_catalog_builder.dart';

/// Loads and caches [ReciterAudioCatalog] for playback (5-minute TTL).
@lazySingleton
class ReciterAudioCatalogCache {
  ReciterAudioCatalogCache(
    this._recitersRepository,
    this._catalogBuilder,
  );

  RecitersRepository _recitersRepository;
  final ReciterAudioCatalogBuilder _catalogBuilder;

  /// Current reciter repository (for raw entity reads outside the catalog).
  RecitersRepository get recitersRepository => _recitersRepository;

  ReciterAudioCatalog? _cachedCatalog;
  DateTime? _lastCacheTime;
  bool _isLoading = false;

  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Latest catalog after a successful load (O(1) read when warm).
  ReciterAudioCatalog? get catalog => _cachedCatalog;

  /// Swaps repository (tests) and clears cached data.
  void bindRepository(RecitersRepository repository) {
    _recitersRepository = repository;
    invalidate();
  }

  void invalidate() {
    _cachedCatalog = null;
    _lastCacheTime = null;
  }

  /// Loads or returns the cached catalog. O(1) when TTL is valid.
  Future<ReciterAudioCatalog?> loadCatalog() async {
    if (_isCacheValid) {
      return _cachedCatalog;
    }

    if (_isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return _cachedCatalog;
    }

    _isLoading = true;
    try {
      final Either<Failure, List<ReciterEntity>> recitersData =
          await _recitersRepository.getReciters();

      return recitersData.fold(
        (Failure failure) {
          log('Error fetching reciters: ${failure.message}');
          return null;
        },
        (List<ReciterEntity> reciters) {
          final ReciterAudioCatalog built = _catalogBuilder.build(reciters);
          _cachedCatalog = built;
          _lastCacheTime = DateTime.now();
          return built;
        },
      );
    } finally {
      _isLoading = false;
    }
  }

  /// O(1) when [loadCatalog] has already succeeded within the TTL.
  Future<List<AudioEntity>?> loadTracks() async {
    return (await loadCatalog())?.tracks;
  }

  /// O(1) when [loadCatalog] has already succeeded within the TTL.
  Future<List<ReciterEntity>?> loadReciters() async {
    return (await loadCatalog())?.reciters;
  }

  /// O(1) reciter lookup when the catalog is warm.
  Future<ReciterEntity?> reciterNamed(String name) async {
    return (await loadCatalog())?.reciterNamed(name);
  }

  bool get _isCacheValid =>
      _cachedCatalog != null &&
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
}
