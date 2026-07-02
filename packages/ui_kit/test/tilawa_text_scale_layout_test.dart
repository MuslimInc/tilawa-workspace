import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

TextScaler _productTextScaler() => tilawaProductTextScaler(
  const TextScaler.linear(1),
).clamp(minScaleFactor: 1, maxScaleFactor: 1.4);

Widget _scaledApp({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  Size surfaceSize = const Size(390, 800),
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    builder: (context, appChild) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: surfaceSize,
          textScaler: _productTextScaler(),
        ),
        child: appChild!,
      );
    },
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Tilawa text scale layout regressions', () {
    testWidgets('catalog title-only app bar fits in Arabic RTL', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          builder: (context, appChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(390, 800),
                textScaler: _productTextScaler(),
              ),
              child: appChild!,
            );
          },
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                appBar: TilawaCatalogAppBar.titleOnly(
                  context,
                  title: 'الإعدادات',
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('catalog title and search app bar fits at product scale', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late BuildContext hostContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          builder: (context, appChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(390, 800),
                textScaler: _productTextScaler(),
              ),
              child: appChild!,
            );
          },
          home: Builder(
            builder: (context) {
              hostContext = context;
              return Scaffold(
                appBar: TilawaCatalogAppBar(
                  preferredHeight:
                      TilawaAppBarConfig.catalogTitleAndSearchHeight(
                        context,
                        title: 'Bookmarks',
                      ),
                  title: 'Bookmarks',
                  bottomContent: const TilawaSearchField(
                    hintText: 'Search',
                  ),
                ),
                body: const SizedBox.shrink(),
              );
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      check(
        TilawaAppBarConfig.catalogTitleAndSearchHeight(
          hostContext,
          title: 'Bookmarks',
        ),
      ).isGreaterThan(TilawaAppBarConfig.catalogTitleOnlyHeight(hostContext));
    });

    testWidgets('catalog title and segment row fits at product scale', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          builder: (context, appChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(390, 800),
                textScaler: _productTextScaler(),
              ),
              child: appChild!,
            );
          },
          home: Builder(
            builder: (context) {
              final tokens = Theme.of(context).tokens;
              final double segmentBarHeight =
                  TilawaSegmentedControl.layoutHeight(context);
              return Scaffold(
                appBar: TilawaCatalogAppBar(
                  preferredHeight: TilawaCatalogAppBar.resolvePreferredHeight(
                    context,
                    title: 'القرآن',
                    automaticallyImplyLeading: false,
                    bottomContentHeight: segmentBarHeight + tokens.spaceSmall,
                  ),
                  title: 'القرآن',
                  automaticallyImplyLeading: false,
                  bottomContent: Padding(
                    padding: EdgeInsets.only(bottom: tokens.spaceSmall),
                    child: TilawaSegmentedControl<_TestTab>(
                      segments: const [
                        TilawaSegment(value: _TestTab.a, label: 'سورة'),
                        TilawaSegment(value: _TestTab.b, label: 'جزء'),
                      ],
                      selectedValue: _TestTab.a,
                      onValueChanged: (_) {},
                    ),
                  ),
                ),
                body: const SizedBox.shrink(),
              );
            },
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('catalog title-only app bar fits long Arabic title', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const String longTitle =
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(
            primaryColor: AppColors.defaultPrimary,
          ),
          builder: (context, appChild) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(390, 800),
                textScaler: _productTextScaler(),
              ),
              child: appChild!,
            );
          },
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                appBar: TilawaCatalogAppBar(
                  preferredHeight: TilawaCatalogAppBar.resolvePreferredHeight(
                    context,
                    title: longTitle,
                    leading: TilawaAppBarChrome.catalogBackButton(
                      context: context,
                    ),
                  ),
                  title: longTitle,
                  leading: TilawaAppBarChrome.catalogBackButton(
                    context: context,
                  ),
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('capability action card fits teacher dashboard copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _scaledApp(
          textDirection: TextDirection.rtl,
          child: const SizedBox(
            width: 350,
            child: TilawaCapabilityActionCard(
              title: 'لوحة تحكم المحفظ',
              subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
              leadingIcon: TilawaIcons.teacherCapability,
              badgeLabel: 'محفظ معتمد',
              onTap: _noop,
              margin: EdgeInsets.zero,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}

enum _TestTab { a, b }
