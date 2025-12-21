import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/language_config.dart';
import '../../../../core/entities/reciter_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/repositories/reciters_repository.dart';
import '../datasources/reciters_local_datasource.dart';
import '../datasources/reciters_remote_datasource.dart';
import '../models/reciter_model.dart';

@LazySingleton(as: RecitersRepository)
class RecitersRepositoryImpl implements RecitersRepository {
  const RecitersRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._prefs,
  );

  final RecitersRemoteDataSource _remoteDataSource;
  final RecitersLocalDataSource _localDataSource;
  final SharedPreferencesAsync _prefs;

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
          .map((m) => m.toEntity())
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
          .map((model) => model.toEntity())
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
          .map((model) => model.toEntity())
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
        return Right(match.toEntity());
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
      final List<String> favoriteIds = await _localDataSource
          .getFavoriteReciterIds();
      final List<ReciterModel> allReciters = await _getRecitersData();

      final List<ReciterEntity> favoriteReciters = allReciters
          .where((reciter) => favoriteIds.contains(reciter.id.toString()))
          .map((model) => model.toEntity())
          .toList();

      return Right(favoriteReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> toggleFavoriteReciter(int id) async {
    try {
      final List<String> currentIds = await _localDataSource
          .getFavoriteReciterIds();
      if (currentIds.contains(id.toString())) {
        await _localDataSource.removeFavoriteReciterId(id);
      } else {
        await _localDataSource.saveFavoriteReciterId(id);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<String>> getFavoriteReciterIds() async {
    try {
      final List<String> ids = await _localDataSource.getFavoriteReciterIds();
      return Right(ids);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
