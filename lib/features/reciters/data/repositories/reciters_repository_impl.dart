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
}
