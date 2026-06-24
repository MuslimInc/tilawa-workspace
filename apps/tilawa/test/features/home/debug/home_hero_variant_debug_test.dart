import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/features/home/debug/home_hero_variant_debug.dart';

class _InMemoryPrefs implements SharedPreferencesAsync {
  final Map<String, Object?> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<bool> setString(String key, String value) {
    _data[key] = value;
    return Future<bool>.value(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HomeHeroVariantDebug.resetForTests();
  });

  test('defaults to compact variant B', () {
    expect(HomeHeroVariantDebug.variant.value, HomeHeroDesignVariant.b);
    expect(
      HomeHeroVariantDebug.labelFor(HomeHeroDesignVariant.b),
      contains('compact gold card'),
    );
  });

  test('cycle toggles variant and persists preference', () async {
    final SharedPreferencesAsync prefs = _InMemoryPrefs();

    await HomeHeroVariantDebug.cycle(prefs);
    expect(HomeHeroVariantDebug.variant.value, HomeHeroDesignVariant.a);
    expect(await prefs.getString(HomeHeroVariantDebug.preferenceKey), 'a');

    await HomeHeroVariantDebug.cycle(prefs);
    expect(HomeHeroVariantDebug.variant.value, HomeHeroDesignVariant.b);
    expect(await prefs.getString(HomeHeroVariantDebug.preferenceKey), 'b');
  });

  test('ensureLoaded restores persisted variant A', () async {
    final SharedPreferencesAsync prefs = _InMemoryPrefs();
    await prefs.setString(HomeHeroVariantDebug.preferenceKey, 'a');

    await HomeHeroVariantDebug.ensureLoaded(prefs);

    expect(HomeHeroVariantDebug.variant.value, HomeHeroDesignVariant.a);
  });
}
