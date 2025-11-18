import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:muzakri/core/entities/reciter.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/reciters/data/datasources/reciters_remote_datasource.dart';
import 'package:muzakri/features/reciters/data/models/reciter_model.dart';
import 'package:muzakri/features/reciters/domain/repositories/reciters_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: RecitersRepository)
class RecitersRepositoryImpl implements RecitersRepository {
  const RecitersRepositoryImpl(this._remoteDataSource, this._prefs);

  final RecitersRemoteDataSource _remoteDataSource;
  final SharedPreferencesAsync _prefs;

  @override
  ResultFuture<List<ReciterEntity>> getReciters() async {
    try {
      final savedLang = await _prefs.getString(LanguageConfig.languageKey);
      final effectiveAppLang = savedLang ?? LanguageConfig.defaultLanguageCode;
      final effectiveApiLang = LanguageConfig.convertToApiLanguageCode(
        effectiveAppLang,
      );

      final models = await _remoteDataSource.getReciters(
        language: effectiveApiLang,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReciterEntity>> searchReciters(String query) async {
    try {
      final storedLang =
          await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;
      final apiLang = LanguageConfig.convertToApiLanguageCode(storedLang);
      final allReciters = await _remoteDataSource.getReciters(
        language: apiLang,
      );
      final filteredReciters = allReciters
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
      final storedLang =
          await _prefs.getString(LanguageConfig.languageKey) ??
          LanguageConfig.defaultLanguageCode;
      final apiLang = LanguageConfig.convertToApiLanguageCode(storedLang);
      final allReciters = await _remoteDataSource.getReciters(
        language: apiLang,
      );
      final filteredReciters = allReciters
          .where((reciter) => reciter.letter == letter)
          .map((model) => model.toEntity())
          .toList();
      return Right(filteredReciters);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
