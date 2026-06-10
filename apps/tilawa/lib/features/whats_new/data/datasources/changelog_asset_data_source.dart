import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

abstract interface class ChangelogAssetDataSource {
  Future<String> loadRawCatalog();
}

@LazySingleton(as: ChangelogAssetDataSource)
class ChangelogAssetDataSourceImpl implements ChangelogAssetDataSource {
  static const String assetPath = 'assets/changelog/changelog.json';

  @override
  Future<String> loadRawCatalog() {
    return rootBundle.loadString(assetPath);
  }
}
