import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

/// In-memory [SharedPreferencesAsync] for tests that need real read/write.
class MapBackedSharedPreferencesAsync {
  MapBackedSharedPreferencesAsync([Map<String, Object>? initial])
    : store = Map<String, Object>.from(initial ?? <String, Object>{});

  final Map<String, Object> store;

  late final SharedPreferencesAsync prefs = _create();

  SharedPreferencesAsync _create() {
    final mock = MockSharedPreferencesAsync();
    when(() => mock.setBool(any(), any())).thenAnswer((invocation) async {
      store[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as bool;
    });
    when(() => mock.getBool(any())).thenAnswer((invocation) async {
      return store[invocation.positionalArguments[0] as String] as bool?;
    });
    when(() => mock.setString(any(), any())).thenAnswer((invocation) async {
      store[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as String;
    });
    when(() => mock.getString(any())).thenAnswer((invocation) async {
      return store[invocation.positionalArguments[0] as String] as String?;
    });
    when(() => mock.remove(any())).thenAnswer((invocation) async {
      store.remove(invocation.positionalArguments[0] as String);
    });
    when(() => mock.containsKey(any())).thenAnswer((invocation) async {
      return store.containsKey(invocation.positionalArguments[0] as String);
    });
    return mock;
  }
}
