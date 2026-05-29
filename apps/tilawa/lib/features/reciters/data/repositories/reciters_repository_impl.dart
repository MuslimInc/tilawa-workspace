import 'dart:async';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tilawa_core/config/language_config.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/reciters_repository.dart';
import '../../domain/services/reciter_engagement_reporter.dart';
import '../datasources/reciters_favorites_datasource.dart';
import '../datasources/reciters_local_datasource.dart';
import '../datasources/reciters_remote_datasource.dart';
import '../models/reciter_model.dart';

@LazySingleton(as: RecitersRepository)
class RecitersRepositoryImpl implements RecitersRepository {
  RecitersRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._favoritesDataSource,
    this._authRepository,
    this._prefs,
    this._engagementReporter,
  );

  final RecitersRemoteDataSource _remoteDataSource;
  final RecitersLocalDataSource _localDataSource;
  final RecitersFavoritesDataSource _favoritesDataSource;
  final AuthRepository _authRepository;
  final SharedPreferencesAsync _prefs;
  final ReciterEngagementReporter _engagementReporter;

  Future<void> _saveFavoriteIdsLocally(Iterable<String> ids) async {
    final List<String> localIds = await _localDataSource
        .getFavoriteReciterIds();
    final Set<String> localSet = localIds.toSet();

    for (final id in ids) {
      final int? parsedId = int.tryParse(id);
      if (parsedId != null && !localSet.contains(id)) {
        await _localDataSource.saveFavoriteReciterId(parsedId);
      }
    }
  }

  Future<void> _syncMissingRemoteFavorites(
    String userId,
    Iterable<String> missingIds,
  ) async {
    final List<ReciterModel> reciters = await _getRecitersData();

    for (final id in missingIds) {
      final int? reciterId = int.tryParse(id);
      if (reciterId == null) {
        continue;
      }

      final ReciterModel? reciter = reciters
          .where((r) => r.id == reciterId)
          .firstOrNull;
      if (reciter == null) {
        continue;
      }

      await _favoritesDataSource.addFavoriteReciter(
        userId: userId,
        reciterId: reciterId,
        reciterName: reciter.name,
      );
    }
  }

  Future<List<String>> _getMergedFavoriteIds(String userId) async {
    final List<String> remoteIds = await _favoritesDataSource
        .getFavoriteReciterIds(userId: userId);
    final List<String> localIds = await _localDataSource
        .getFavoriteReciterIds();

    final Set<String> mergedIds = {...remoteIds, ...localIds};
    final List<String> missingRemoteIds = mergedIds
        .where((id) => !remoteIds.contains(id))
        .toList();

    if (missingRemoteIds.isNotEmpty) {
      await _syncMissingRemoteFavorites(userId, missingRemoteIds);
    }

    await _saveFavoriteIdsLocally(mergedIds);
    return mergedIds.toList();
  }

  Future<List<ReciterModel>> _getRecitersData() async {
    final String? savedLang = await _prefs.getString(
      LanguageConfig.languageKey,
    );
    final String effectiveAppLang =
        savedLang ?? LanguageConfig.defaultLanguageCode;
    final String effectiveApiLang = LanguageConfig.convertToApiLanguageCode(
      effectiveAppLang,
    );

    try {
      // Try local assets first (Fast & Offline)
      return await _localDataSource.getReciters(language: effectiveApiLang);
    } catch (e) {
      // Fallback to remote API
      return _remoteDataSource.getReciters(language: effectiveApiLang);
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> getReciters() async {
    try {
      final List<ReciterModel> models = await _getRecitersData();
      final List<ReciterEntity> entities = models
          .map((m) => m.toReciterEntity())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> searchReciters(String query) async {
    try {
      final List<ReciterModel> allReciters = await _getRecitersData();
      final List<ReciterEntity> filteredReciters = allReciters
          .where(
            (reciter) =>
                reciter.name.toLowerCase().contains(query.toLowerCase()),
          )
          .map((model) => model.toReciterEntity())
          .toList();
      return Right(filteredReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> getRecitersByLetter(String letter) async {
    try {
      final List<ReciterModel> allReciters = await _getRecitersData();
      final List<ReciterEntity> filteredReciters = allReciters
          .where((reciter) => reciter.letter == letter)
          .map((model) => model.toReciterEntity())
          .toList();
      return Right(filteredReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ReciterEntity?> getReciterById(String id) async {
    try {
      final List<ReciterModel> allReciters = await _getRecitersData();
      final ReciterModel? match = allReciters
          .where((reciter) => reciter.id.toString() == id)
          .firstOrNull;

      if (match != null) {
        return Right(match.toReciterEntity());
      } else {
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> getFavoriteReciters() async {
    try {
      final List<String> favoriteIds = await getFavoriteReciterIds().then(
        (value) => value.fold((l) => [], (r) => r),
      );

      final List<ReciterModel> allReciters = await _getRecitersData();

      final List<ReciterEntity> favoriteReciters = allReciters
          .where((reciter) => favoriteIds.contains(reciter.id.toString()))
          .map((model) => model.toReciterEntity())
          .toList();

      return Right(favoriteReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _syncFavoriteToggleToRemote({
    required int id,
    required bool wasFavorite,
  }) async {
    final String userId = _authRepository.currentUser!.id;
    if (wasFavorite) {
      await _favoritesDataSource.removeFavoriteReciter(
        userId: userId,
        reciterId: id,
      );
      return;
    }

    final List<ReciterModel> reciters = await _getRecitersData();
    final ReciterModel? reciter = reciters
        .where((r) => r.id == id)
        .firstOrNull;
    if (reciter != null) {
      await _favoritesDataSource.addFavoriteReciter(
        userId: userId,
        reciterId: id,
        reciterName: reciter.name,
      );
    }
  }

  @override
  ResultFuture<void> toggleFavoriteReciter(int id) async {
    try {
      final List<String> currentLocalIds = await _localDataSource
          .getFavoriteReciterIds();
      final bool wasFavorite = currentLocalIds.contains(id.toString());
      if (wasFavorite) {
        await _localDataSource.removeFavoriteReciterId(id);
      } else {
        await _localDataSource.saveFavoriteReciterId(id);
      }

      if (_authRepository.currentUser != null) {
        try {
          await _syncFavoriteToggleToRemote(id: id, wasFavorite: wasFavorite);
        } catch (_) {
          // Local toggle already applied; cloud sync can retry when online.
        }
      }

      if (!wasFavorite) {
        _engagementReporter.reportFavoriteReciterAdded();
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> clearFavoriteReciters() async {
    try {
      final bool isAuth = _authRepository.currentUser != null;

      if (isAuth) {
        await _favoritesDataSource.clearFavoriteReciters(
          userId: _authRepository.currentUser!.id,
        );
      }

      await _localDataSource.clearFavoriteReciterIds();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<String>> getFavoriteReciterIds() async {
    try {
      final isAuth = _authRepository.currentUser != null;
      if (isAuth) {
        final String userId = _authRepository.currentUser!.id;
        try {
          final List<String> ids = await _getMergedFavoriteIds(userId);
          return Right(ids);
        } catch (_) {
          final List<String> localIds = await _localDataSource
              .getFavoriteReciterIds();
          return Right(localIds);
        }
      }

      final List<String> ids = await _localDataSource.getFavoriteReciterIds();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
