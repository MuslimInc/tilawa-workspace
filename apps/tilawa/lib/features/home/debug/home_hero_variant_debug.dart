import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug-only A/B switch for comparing home hero layouts.
enum HomeHeroDesignVariant {
  /// Cream gradient hero with wavy bottom clip (legacy debug).
  a,

  /// Compact gold featured-card hero with flat sheet handoff (default).
  b,
}

/// Persists the selected hero variant for side-by-side UX comparison.
abstract final class HomeHeroVariantDebug {
  const HomeHeroVariantDebug._();

  static const String preferenceKey = 'debug_home_hero_variant';

  static final ValueNotifier<HomeHeroDesignVariant> variant =
      ValueNotifier<HomeHeroDesignVariant>(HomeHeroDesignVariant.b);

  static bool _loaded = false;

  @visibleForTesting
  static void resetForTests() {
    _loaded = false;
    variant.value = HomeHeroDesignVariant.b;
  }

  static Future<void> ensureLoaded(SharedPreferencesAsync prefs) async {
    if (_loaded) {
      return;
    }
    final String? raw = await prefs.getString(preferenceKey);
    if (raw == HomeHeroDesignVariant.a.name) {
      variant.value = HomeHeroDesignVariant.a;
    }
    _loaded = true;
  }

  static Future<void> cycle(SharedPreferencesAsync prefs) async {
    final HomeHeroDesignVariant next =
        variant.value == HomeHeroDesignVariant.a
        ? HomeHeroDesignVariant.b
        : HomeHeroDesignVariant.a;
    variant.value = next;
    await prefs.setString(preferenceKey, next.name);
  }

  static String labelFor(HomeHeroDesignVariant value) {
    return switch (value) {
      HomeHeroDesignVariant.a => 'Variant A — cream gradient + wave (legacy)',
      HomeHeroDesignVariant.b => 'Variant B — compact gold card (default)',
    };
  }
}
