import 'package:dartz/dartz.dart';
import 'package:muzakri/core/errors/failures.dart';
import 'package:muzakri/core/utils/typedefs.dart';
import 'package:muzakri/features/localization/data/datasources/localization_local_datasource.dart';
import 'package:muzakri/features/localization/domain/repositories/localization_repository.dart';

class LocalizationRepositoryImpl implements LocalizationRepository {
  const LocalizationRepositoryImpl(this._localDataSource);

  final LocalizationLocalDataSource _localDataSource;

  @override
  ResultFuture<String> getCurrentLanguage() async {
    try {
      final language = await _localDataSource.getCurrentLanguage();
      return Right(language);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultVoid setLanguage(String languageCode) async {
    try {
      await _localDataSource.setLanguage(languageCode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<String>> getSupportedLanguages() async {
    try {
      final languages = await _localDataSource.getSupportedLanguages();
      return Right(languages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
