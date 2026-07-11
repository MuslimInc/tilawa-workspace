import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran index header goldens', () {
    testWidgets('light rtl constrained', (tester) async {
      const Size size = Size(393, 220);
      await _pumpHeaderGolden(tester, size: size, isDark: false);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/quran_index_header_rtl_light.png'),
      );
    });

    testWidgets('dark rtl constrained', (tester) async {
      const Size size = Size(393, 220);
      await _pumpHeaderGolden(tester, size: size, isDark: true);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/quran_index_header_rtl_dark.png'),
      );
    });
  });
}

Future<void> _pumpHeaderGolden(
  WidgetTester tester, {
  required Size size,
  required bool isDark,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      darkTheme: AppTheme.getDarkTheme(primaryColor: AppColors.defaultPrimary),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const _QuranHeaderPreview(),
    ),
  );

  await tester.pumpAndSettle();
}

class _QuranHeaderPreview extends StatelessWidget {
  const _QuranHeaderPreview();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MeMuslimDesignTokens tokens = theme.tokens;
    final TilawaSettingsGroupTokens groupTokens =
        theme.componentTokens.settingsGroup;
    final double segmentBarHeight = TilawaSegmentedControl.layoutHeight(
      context,
    );

    return Scaffold(
      appBar: TilawaCatalogAppBar(
        title: context.l10n.quranHubTitle,
        bottomContentHeight: segmentBarHeight + tokens.spaceSmall,
        bottomContent: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            groupTokens.groupHorizontalPadding,
            0,
            groupTokens.groupHorizontalPadding,
            tokens.spaceSmall,
          ),
          child: TilawaSegmentedControl<String>(
            selectedValue: 'surah',
            onValueChanged: (_) {},
            segments: const [
              TilawaSegment(value: 'surah', label: 'سورة'),
              TilawaSegment(value: 'juz', label: 'جزء'),
              TilawaSegment(value: 'page', label: 'صفحة'),
            ],
          ),
        ),
      ),
      body: const SizedBox.expand(),
    );
  }
}
