import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/pinned_athkar_constants.dart';

abstract interface class PinnedAthkarLocalDataSource {
  Future<List<int>?> readCategoryIds();

  Future<void> writeCategoryIds(List<int> categoryIds);
}

@LazySingleton(as: PinnedAthkarLocalDataSource)
class PinnedAthkarLocalDataSourceImpl implements PinnedAthkarLocalDataSource {
  PinnedAthkarLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<int>?> readCategoryIds() async {
    final List<String>? raw = await _prefs.getStringList(
      PinnedAthkarConstants.preferenceKey,
    );
    return raw?.map(int.tryParse).whereType<int>().toList();
  }

  @override
  Future<void> writeCategoryIds(List<int> categoryIds) {
    return _prefs.setStringList(
      PinnedAthkarConstants.preferenceKey,
      categoryIds.map((id) => id.toString()).toList(growable: false),
    );
  }
}
