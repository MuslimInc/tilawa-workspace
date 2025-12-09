import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/language_config.dart';
import '../../../../core/entities/reciter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/repositories/reciters_repository.dart';
import '../datasources/reciters_remote_datasource.dart';
import '../models/reciter_model.dart';

@LazySingleton(as: RecitersRepository)
class RecitersRepositoryImpl implements RecitersRepository {
  const RecitersRepositoryImpl(this._remoteDataSource, this._prefs);

  final RecitersRemoteDataSource _remoteDataSource;
  final SharedPreferencesAsync _prefs;

  @override
  ResultFuture<List<ReciterEntity>> getReciters() async {
    try {
      final String? savedLang = await _prefs.getString(
        LanguageConfig.languageKey,
      );
      final String effectiveAppLang =
          savedLang ?? LanguageConfig.defaultLanguageCode;
      final String effectiveApiLang = LanguageConfig.convertToApiLanguageCode(
        effectiveAppLang,
      );

      final List<ReciterModel> models = await _remoteDataSource.getReciters(
        language: effectiveApiLang,
      );
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
      final String storedLang =
          await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;
      final String apiLang = LanguageConfig.convertToApiLanguageCode(
        storedLang,
      );
      final List<ReciterModel> allReciters = await _remoteDataSource
          .getReciters(language: apiLang);
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
      final String storedLang =
          await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;
      final String apiLang = LanguageConfig.convertToApiLanguageCode(
        storedLang,
      );
      final List<ReciterModel> allReciters = await _remoteDataSource
          .getReciters(language: apiLang);
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
