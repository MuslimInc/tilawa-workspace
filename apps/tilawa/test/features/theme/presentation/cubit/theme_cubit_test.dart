import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/theme/domain/entities/app_theme_preset.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/features/theme/presentation/cubit/theme_cubit.dart';

import '../../../../helpers/hydrated_bloc_test_helper.dart';

void main() {
  late ThemeCubit cubit;

  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  setUp(() {
    cubit = ThemeCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  group('fresh/default state', () {
    test('starts with expected defaults', () {
      expect(cubit.state.mode, ThemeMode.light);
      expect(cubit.state.primaryColor, PrimaryColorPreset.defaultPreset.value);
      expect(cubit.state.primaryColorSource, PrimaryColorSource.preset);
      expect(cubit.state.primaryPresetId, PrimaryColorPreset.defaultPreset.id);
    });
  });

  group('preset selection', () {
    for (final preset in PrimaryColorPreset.values) {
      test(
        'setPrimaryPreset(${preset.id}) updates state and json schema',
        () async {
          await cubit.setPrimaryPreset(preset);

          expect(cubit.state.primaryColor, preset.value);
          expect(cubit.state.primaryColorSource, PrimaryColorSource.preset);
          expect(cubit.state.primaryPresetId, preset.id);

          final json = cubit.toJson(cubit.state);
          expect(json, isNotNull);
          expect(json!['primaryColor'], preset.value.toARGB32());
          expect(json['primaryColorSource'], 'preset');
          expect(json['primaryPresetId'], preset.id);
        },
      );
    }
  });

  group('custom color selection', () {
    test(
      'setPrimaryColor marks state as custom and preserves ARGB in json',
      () async {
        const customColor = Color(0xFF12A4F6);

        await cubit.setPrimaryColor(customColor);

        expect(cubit.state.primaryColor, customColor);
        expect(cubit.state.primaryColorSource, PrimaryColorSource.custom);
        expect(cubit.state.primaryPresetId, isNull);

        final json = cubit.toJson(cubit.state);
        expect(json, isNotNull);
        expect(json!['primaryColor'], customColor.toARGB32());
        expect(json['primaryColorSource'], 'custom');
        expect(json['primaryPresetId'], isNull);
      },
    );
  });

  group('new schema restore', () {
    test(
      'preset source with valid preset id restores canonical preset color',
      () {
        final restored = cubit.fromJson({
          'mode': 'light',
          'primaryColor': const Color(0xFF000000).toARGB32(),
          'primaryColorSource': 'preset',
          'primaryPresetId': PrimaryColorPreset.brown.id,
          'useSystemTheme': false,
          'preset': AppThemePreset.defaultMode.name,
        });

        expect(restored, isNotNull);
        expect(restored!.primaryColorSource, PrimaryColorSource.preset);
        expect(restored.primaryPresetId, PrimaryColorPreset.brown.id);
        expect(restored.primaryColor, PrimaryColorPreset.brown.value);
      },
    );

    test(
      'preset source with invalid preset id falls back to default preset',
      () {
        final restored = cubit.fromJson({
          'mode': 'light',
          'primaryColor': const Color(0xFF123456).toARGB32(),
          'primaryColorSource': 'preset',
          'primaryPresetId': 'not-a-preset',
          'useSystemTheme': false,
          'preset': AppThemePreset.defaultMode.name,
        });

        expect(restored, isNotNull);
        expect(restored!.primaryColorSource, PrimaryColorSource.preset);
        expect(restored.primaryPresetId, PrimaryColorPreset.defaultPreset.id);
        expect(restored.primaryColor, PrimaryColorPreset.defaultPreset.value);
      },
    );

    test('custom source restores exact stored primary color', () {
      const customColor = Color(0xFF224466);

      final restored = cubit.fromJson({
        'mode': 'dark',
        'primaryColor': customColor.toARGB32(),
        'primaryColorSource': 'custom',
        'primaryPresetId': null,
        'useSystemTheme': true,
        'preset': AppThemePreset.trueBlack.name,
      });

      expect(restored, isNotNull);
      expect(restored!.primaryColor, customColor);
      expect(restored.primaryColorSource, PrimaryColorSource.custom);
      expect(restored.primaryPresetId, isNull);
    });
  });

  group('legacy schema migration', () {
    for (final preset in PrimaryColorPreset.values) {
      test(
        'legacy payload matching ${preset.id} migrates to preset source',
        () {
          final restored = cubit.fromJson({
            'mode': 'light',
            'primaryColor': preset.value.toARGB32(),
            'useSystemTheme': false,
            'preset': AppThemePreset.defaultMode.name,
          });

          expect(restored, isNotNull);
          expect(restored!.primaryColor, preset.value);
          expect(restored.primaryColorSource, PrimaryColorSource.preset);
          expect(restored.primaryPresetId, preset.id);
        },
      );
    }

    test('legacy payload with custom color migrates to custom source', () {
      const customColor = Color(0xFF0F9D58);

      final restored = cubit.fromJson({
        'mode': 'light',
        'primaryColor': customColor.toARGB32(),
        'useSystemTheme': false,
        'preset': AppThemePreset.defaultMode.name,
      });

      expect(restored, isNotNull);
      expect(restored!.primaryColor, customColor);
      expect(restored.primaryColorSource, PrimaryColorSource.custom);
      expect(restored.primaryPresetId, isNull);
    });

    test(
      'legacy payload missing source and missing color falls back safely',
      () {
        final restored = cubit.fromJson({
          'mode': 'light',
          'preset': AppThemePreset.defaultMode.name,
        });

        expect(restored, isNotNull);
        expect(restored!.primaryColor, PrimaryColorPreset.defaultPreset.value);
        expect(restored.primaryColorSource, PrimaryColorSource.preset);
        expect(restored.primaryPresetId, PrimaryColorPreset.defaultPreset.id);
      },
    );
  });

  group('corrupt payload safety', () {
    test('malformed payload does not throw and falls back to defaults', () {
      final restored = cubit.fromJson({
        'mode': 42,
        'primaryColor': 'bad-color',
        'primaryColorSource': {'not': 'a-string'},
      });

      expect(restored, isNotNull);
      expect(restored!.mode, ThemeMode.light);
      expect(restored.primaryColor, PrimaryColorPreset.defaultPreset.value);
      expect(restored.primaryColorSource, PrimaryColorSource.preset);
      expect(restored.primaryPresetId, PrimaryColorPreset.defaultPreset.id);
    });

    test('unsupported source value with missing color falls back safely', () {
      final restored = cubit.fromJson({
        'mode': 'dark',
        'primaryColorSource': 'unsupported',
      });

      expect(restored, isNotNull);
      expect(restored!.primaryColor, PrimaryColorPreset.defaultPreset.value);
      expect(restored.primaryColorSource, PrimaryColorSource.preset);
      expect(restored.primaryPresetId, PrimaryColorPreset.defaultPreset.id);
    });
  });

  group('mode, preset and useSystemTheme fields', () {
    test('mode serialization/restoration works', () {
      final darkState = cubit.state.copyWith(mode: ThemeMode.dark);
      final json = cubit.toJson(darkState);
      final restored = cubit.fromJson(json!);

      expect(json['mode'], 'dark');
      expect(restored, isNotNull);
      expect(restored!.mode, ThemeMode.dark);
    });

    for (final appPreset in AppThemePreset.values) {
      test('app preset ${appPreset.name} serialization/restoration works', () {
        final state = cubit.state.copyWith(preset: appPreset);
        final json = cubit.toJson(state);
        final restored = cubit.fromJson(json!);

        expect(json['preset'], appPreset.name);
        expect(restored, isNotNull);
        expect(restored!.preset, appPreset);
      });
    }

    test('useSystemTheme is preserved through serialization/restoration', () {
      final state = cubit.state.copyWith(useSystemTheme: true);
      final json = cubit.toJson(state);
      final restored = cubit.fromJson(json!);

      expect(json['useSystemTheme'], isTrue);
      expect(restored, isNotNull);
      expect(restored!.useSystemTheme, isTrue);
    });
  });
}
