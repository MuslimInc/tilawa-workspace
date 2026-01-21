import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';

import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import '../../domain/repositories/localization_repository.dart';
import '../datasources/localization_local_datasource.dart';

@LazySingleton(as: LocalizationRepository)
class LocalizationRepositoryImpl implements LocalizationRepository {
  const LocalizationRepositoryImpl(this._localDataSource);

  final LocalizationLocalDataSource _localDataSource;

  @override
  ResultFuture<String> getCurrentLanguage() async {
    try {
      final String language = await _localDataSource.getCurrentLanguage();
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
      final List<String> languages = await _localDataSource
          .getSupportedLanguages();
      return Right(languages);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
