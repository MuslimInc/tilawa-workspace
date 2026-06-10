import 'dart:convert';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/interfaces/app_info_service.dart';

import '../../domain/entities/changelog_catalog.dart';
import '../../domain/entities/changelog_release.dart';
import '../../domain/repositories/changelog_repository.dart';
import '../datasources/changelog_asset_data_source.dart';
import '../models/changelog_catalog_dto.dart';

@LazySingleton(as: ChangelogRepository)
class ChangelogRepositoryImpl implements ChangelogRepository {
  ChangelogRepositoryImpl(
    this._assetDataSource,
    this._appInfoService,
  );

  final ChangelogAssetDataSource _assetDataSource;
  final AppInfoService _appInfoService;

  ChangelogCatalog? _cachedCatalog;

  Future<Either<Failure, ChangelogCatalog>> _loadCatalog() async {
    if (_cachedCatalog != null) {
      return Right(_cachedCatalog!);
    }

    try {
      final String raw = await _assetDataSource.loadRawCatalog();
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      final ChangelogCatalog catalog = ChangelogCatalogDto.fromJson(
        json,
      ).toEntity();
      if (catalog.releases.isEmpty) {
        return const Left(CacheFailure('Changelog catalog is empty'));
      }
      _cachedCatalog = catalog;
      return Right(catalog);
    } on FormatException catch (e) {
      return Left(CacheFailure('Invalid changelog JSON: $e'));
    } catch (e) {
      return Left(CacheFailure('Failed to load changelog: $e'));
    }
  }

  @override
  Future<Either<Failure, ChangelogRelease>> getReleaseForCurrentApp() async {
    final Either<Failure, ChangelogCatalog> catalogResult = await _loadCatalog();
    Failure? catalogFailure;
    ChangelogCatalog? catalog;
    catalogResult.fold(
      (Failure failure) => catalogFailure = failure,
      (ChangelogCatalog value) => catalog = value,
    );
    if (catalogFailure != null || catalog == null) {
      return Left(catalogFailure ?? const CacheFailure('Missing catalog'));
    }

    try {
      final ChangelogCatalog resolvedCatalog = catalog!;
      final appInfo = await _appInfoService.getAppInfo();
      final int buildNumber = int.tryParse(appInfo.buildNumber) ?? 0;
      final String releaseId = ChangelogRelease.composeId(
        version: appInfo.version,
        buildNumber: buildNumber,
      );
      final ChangelogRelease? release = resolvedCatalog.findById(releaseId);
      if (release == null) {
        return Left(
          CacheFailure('No changelog entry for release $releaseId'),
        );
      }
      return Right(release);
    } catch (e) {
      return Left(CacheFailure('Failed to resolve current release: $e'));
    }
  }
}
