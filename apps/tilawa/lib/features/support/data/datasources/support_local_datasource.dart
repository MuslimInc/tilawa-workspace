import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SupportLocalDataSource {
  Future<void> saveLastSupport({
    required String productId,
    required DateTime at,
  });

  Future<DateTime?> getLastSupportAt();

  Future<String?> getLastSupportProductId();
}

@LazySingleton(as: SupportLocalDataSource)
class SupportLocalDataSourceImpl implements SupportLocalDataSource {
  SupportLocalDataSourceImpl(this._prefs);

  static const String _keyProductId = 'support_last_product_id';
  static const String _keyAtMillis = 'support_last_at_millis';

  final SharedPreferencesAsync _prefs;

  @override
  Future<void> saveLastSupport({
    required String productId,
    required DateTime at,
  }) async {
    await _prefs.setString(_keyProductId, productId);
    await _prefs.setInt(_keyAtMillis, at.millisecondsSinceEpoch);
  }

  @override
  Future<DateTime?> getLastSupportAt() async {
    final int? millis = await _prefs.getInt(_keyAtMillis);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<String?> getLastSupportProductId() async {
    return _prefs.getString(_keyProductId);
  }
}
