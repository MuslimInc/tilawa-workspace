import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/component_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/foundation/tilawa_type_scale.dart';

@immutable
class _ProbeThemeExtension extends ThemeExtension<_ProbeThemeExtension> {
  const _ProbeThemeExtension({required this.marker});

  final String marker;

  @override
  _ProbeThemeExtension copyWith({String? marker}) {
    return _ProbeThemeExtension(marker: marker ?? this.marker);
  }

  @override
  _ProbeThemeExtension lerp(
    covariant ThemeExtension<_ProbeThemeExtension>? other,
    double t,
  ) {
    if (other is! _ProbeThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

void main() {
  group('AppTheme', () {
    test(
      'Flutter test env builds light theme without bundled font family',
      () {
        final ThemeData theme = AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        );

        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.titleMedium, isNotNull);
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          isNot(contains('IBMPlexSansArabic')),
        );
        final double? baseTitleSize = Typography.material2021(
          platform: defaultTargetPlatform,
        ).black.titleLarge?.fontSize;
        if (baseTitleSize != null) {
          expect(
            theme.textTheme.titleLarge?.fontSize,
            closeTo(baseTitleSize * kTilawaGlobalTextScaleFactor, 0.01),
          );
        }
      },
    );

    test('merges caller extensions after design token extensions', () {
      const probe = _ProbeThemeExtension(marker: 'probe');
      final ThemeData theme = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
        extensions: [probe],
      );

      expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
      expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);
      expect(theme.extension<_ProbeThemeExtension>()?.marker, 'probe');
    });

    test('dark theme registers design and component token extensions', () {
      final ThemeData theme = AppTheme.getDarkTheme(
        primaryColor: AppColors.defaultPrimary,
        isDefaultPreset: true,
      );

      expect(theme.extension<MeMuslimDesignTokens>(), isNotNull);
      expect(theme.extension<MeMuslimComponentTokens>(), isNotNull);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });
}
