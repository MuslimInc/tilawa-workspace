import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/src/foundation/app_colors.dart';
import 'package:tilawa_ui_kit/src/foundation/app_theme.dart';
import 'package:tilawa_ui_kit/src/foundation/design_tokens.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_app_bar_config.dart';
import 'package:tilawa_ui_kit/src/molecules/tilawa_catalog_app_bar.dart';

ThemeData _lightTheme() => AppTheme.getLightTheme(
  primaryColor: AppColors.defaultPrimary,
);

void main() {
  group('TilawaAppBarChrome.toolbarControlBackground', () {
    test('vellum enabled uses surface', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.vellum,
          enabled: true,
        ),
        scheme.surface,
      );
    });

    test('parchment enabled uses surfaceContainerHigh', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.parchment,
          enabled: true,
        ),
        scheme.surfaceContainerHigh,
      );
    });

    test('disabled returns transparent', () {
      final scheme = _lightTheme().colorScheme;
      expect(
        TilawaAppBarChrome.toolbarControlBackground(
          scheme,
          TilawaAppBarSurface.vellum,
          enabled: false,
        ),
        Colors.transparent,
      );
    });
  });

  group('TilawaAppBarConfig defaults', () {
    test('elevation shadow is off; hairline is on', () {
      expect(TilawaAppBarConfig.showElevationShadow, isFalse);
      expect(TilawaAppBarConfig.showBottomHairline, isTrue);
      expect(TilawaAppBarConfig.elevation, 1);
    });

    test('catalog screens default to parchment and left title', () {
      expect(TilawaAppBarConfig.surface, TilawaAppBarSurface.parchment);
      expect(TilawaAppBarConfig.centerTitle, isFalse);
    });
  });

  group('TilawaAppBarChrome elevation shadow', () {
    test('enabled uses scheme.shadow at opacityShadow', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      expect(
        TilawaAppBarChrome.elevationShadowColor(scheme, tokens),
        scheme.shadow.withValues(alpha: tokens.opacityShadow),
      );
    });

    test('bottom hairline uses softened outlineVariant', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      final RoundedRectangleBorder shape =
          TilawaAppBarChrome.bottomHairline(
                scheme,
                tokens,
              )
              as RoundedRectangleBorder;
      expect(
        shape.side.color,
        scheme.outlineVariant.withValues(alpha: tokens.opacitySubtle * 2.5),
      );
      expect(shape.side.width, tokens.borderWidthThin);
    });

    test('disabled returns transparent shadow and zero elevation', () {
      final theme = _lightTheme();
      final scheme = theme.colorScheme;
      final tokens = theme.extension<TilawaDesignTokens>()!;
      expect(
        TilawaAppBarChrome.elevationShadowColor(
          scheme,
          tokens,
          enabled: false,
        ),
        Colors.transparent,
      );
      expect(TilawaAppBarChrome.elevation(enabled: false), 0);
      expect(TilawaAppBarChrome.scrolledUnderElevation(enabled: false), 0);
    });
  });

  group('TilawaAppBarChrome.resolveCatalogRowLeading', () {
    testWidgets('returns back control on a pushed route', (
      WidgetTester tester,
    ) async {
      late BuildContext pushedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: _lightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          pushedContext = context;
                          return const Scaffold(body: Text('child'));
                        },
                      ),
                    );
                  },
                  child: const Text('push'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      final Widget? leading = TilawaAppBarChrome.resolveCatalogRowLeading(
        pushedContext,
        automaticallyImplyLeading: true,
      );

      expect(leading, isNotNull);
    });
  });

  group('TilawaCatalogAppBar constructor default automaticallyImplyLeading', () {
    // These tests document the expected contract: when a TilawaCatalogAppBar
    // is placed on a screen pushed onto the navigator stack, it must show a
    // back button without callers having to opt in.  The failing tests below
    // prove the current default (false) violates that contract.

    testWidgets(
      'shows back button on a pushed route when using default constructor',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: _lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (innerContext) {
                            return Scaffold(
                              appBar: TilawaCatalogAppBar(
                                preferredHeight:
                                    TilawaAppBarConfig.catalogTitleOnlyHeight(
                                      innerContext,
                                    ),
                                title: 'Detail',
                                // No automaticallyImplyLeading passed —
                                // relies on the default.
                              ),
                              body: const SizedBox.shrink(),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('push'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();

        // Expect the back button — currently FAILS because the default is false.
        expect(find.byType(BackButtonIcon), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'hides back button when automaticallyImplyLeading is explicitly false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: _lightTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (innerContext) {
                            return Scaffold(
                              appBar: TilawaCatalogAppBar(
                                preferredHeight:
                                    TilawaAppBarConfig.catalogTitleOnlyHeight(
                                      innerContext,
                                    ),
                                title: 'Detail',
                                automaticallyImplyLeading: false,
                              ),
                              body: const SizedBox.shrink(),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('push'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();

        expect(find.byType(BackButtonIcon), findsNothing);
      },
    );

    testWidgets(
      'shows back button on root screen does not imply leading',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: _lightTheme(),
            home: Builder(
              builder: (context) {
                return Scaffold(
                  appBar: TilawaCatalogAppBar(
                    preferredHeight:
                        TilawaAppBarConfig.catalogTitleOnlyHeight(context),
                    title: 'Home',
                    // default automaticallyImplyLeading — root route, no back
                  ),
                  body: const SizedBox.shrink(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Root route: no back button even with automaticallyImplyLeading: true.
        expect(find.byType(BackButtonIcon), findsNothing);
      },
    );

    testWidgets(
      'default and titleOnly factory behave identically on a pushed route',
      (WidgetTester tester) async {
        // titleOnly already defaults to automaticallyImplyLeading: true.
        // After the fix, the main constructor must match its behaviour.
        for (final useFactory in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: _lightTheme(),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (innerContext) {
                              final PreferredSizeWidget appBar = useFactory
                                  ? TilawaCatalogAppBar.titleOnly(
                                      innerContext,
                                      title: 'Detail',
                                    )
                                  : TilawaCatalogAppBar(
                                      preferredHeight:
                                          TilawaAppBarConfig
                                              .catalogTitleOnlyHeight(
                                                innerContext,
                                              ),
                                      title: 'Detail',
                                    );
                              return Scaffold(
                                appBar: appBar,
                                body: const SizedBox.shrink(),
                              );
                            },
                          ),
                        );
                      },
                      child: const Text('push'),
                    );
                  },
                ),
              ),
            ),
          );

          await tester.tap(find.text('push'));
          await tester.pumpAndSettle();

          expect(
            find.byType(BackButtonIcon),
            findsAtLeastNWidgets(1),
            reason: useFactory
                ? 'titleOnly factory should show back button'
                : 'main constructor should show back button (same as factory)',
          );

          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  });

  group('TilawaCatalogAppBar.titleOnly defaults', () {
    testWidgets('shows back control on a pushed route by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: _lightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return Scaffold(
                            appBar: TilawaCatalogAppBar.titleOnly(
                              context,
                              title: 'Title',
                            ),
                            body: const SizedBox.shrink(),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('push'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(find.byType(BackButtonIcon), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Shell-tab safety contract
  //
  // INVARIANT: TilawaCatalogAppBar must never render a back button when it is
  // the app bar of a *root* route — i.e. the initial page of a Navigator.
  //
  // WHY THIS IS SAFE with automaticallyImplyLeading: true
  // -------------------------------------------------------
  // resolveLeading() (tilawa_app_bar_config.dart) only adds the back control
  // when ModalRoute.impliesAppBarDismissal is true.  Flutter sets that flag
  // only when the route can be popped (canPop) AND it is not the first route
  // in its navigator.  Root routes therefore always get impliesAppBarDismissal
  // == false, so automaticallyImplyLeading: true has no effect on them.
  //
  // SCREENS COVERED BY THIS CONTRACT
  // ----------------------------------
  // Every bottom-navigation shell tab is a root route of its inner navigator:
  //   - RecitersScreen   (TilawaCatalogAppBar.titleOnly, centerTitle: true)
  //   - HomeScreen       (custom sliver, not TilawaCatalogAppBar)
  //   - AthkarScreen     (TilawaCatalogAppBar)
  //   - SettingsScreen   (TilawaCatalogAppBar — explicitly passes false, safe)
  //
  // IF A TEST IN THIS GROUP FAILS it means either:
  //   (a) resolveLeading() changed its ModalRoute.impliesAppBarDismissal check,
  //   (b) automaticallyImplyLeading default was set back to true in a way that
  //       also affects the root-route path, or
  //   (c) the harness accidentally wrapped the tab in a pushed route.
  // Do not work around a failure here by tweaking the harness — fix the source.
  // ---------------------------------------------------------------------------
  group('TilawaCatalogAppBar shell-tab safety (root route, no back button)', () {
    // Minimal harness: a Navigator whose sole initial route hosts the app bar.
    // This reproduces the shell-tab scenario without any app-level route imports.
    Widget buildShellTabHost({
      required PreferredSizeWidget Function(BuildContext) appBarBuilder,
    }) {
      return MaterialApp(
        theme: _lightTheme(),
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => Scaffold(
              appBar: appBarBuilder(context),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'titleOnly does not show a back button when it is the root route',
      (WidgetTester tester) async {
        // CONTRACT: root route → impliesAppBarDismissal == false → no back button,
        // even though automaticallyImplyLeading defaults to true.
        await tester.pumpWidget(
          buildShellTabHost(
            appBarBuilder: (context) => TilawaCatalogAppBar.titleOnly(
              context,
              title: 'Tab title',
              centerTitle: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(BackButtonIcon),
          findsNothing,
          reason:
              'Root route: ModalRoute.impliesAppBarDismissal == false. '
              'Back button must never appear on a shell tab.',
        );
      },
    );

    testWidgets(
      'titleOnly shows a back button only when ModalRoute implies dismissal',
      (WidgetTester tester) async {
        // CONTRACT: back button is gated on ModalRoute.impliesAppBarDismissal,
        // not on automaticallyImplyLeading alone.
        // Phase 1 — root route (no back button).
        await tester.pumpWidget(
          MaterialApp(
            theme: _lightTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                appBar: TilawaCatalogAppBar.titleOnly(context, title: 'Tab'),
                body: Builder(
                  builder: (innerContext) => ElevatedButton(
                    onPressed: () => Navigator.of(innerContext).push(
                      MaterialPageRoute<void>(
                        builder: (pushedContext) => Scaffold(
                          appBar: TilawaCatalogAppBar.titleOnly(
                            pushedContext,
                            title: 'Detail',
                          ),
                          body: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    child: const Text('push'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(BackButtonIcon),
          findsNothing,
          reason:
              'Phase 1 — root route: impliesAppBarDismissal == false. '
              'No back button.',
        );

        // Phase 2 — pushed route (back button must appear).
        await tester.tap(find.text('push'));
        await tester.pumpAndSettle();
        expect(
          find.byType(BackButtonIcon),
          findsAtLeastNWidgets(1),
          reason:
              'Phase 2 — pushed route: impliesAppBarDismissal == true. '
              'Back button must appear.',
        );
      },
    );

    testWidgets(
      'RecitersScreen-shaped usage does not show a back button on a root tab',
      (WidgetTester tester) async {
        // CONTRACT: the exact TilawaCatalogAppBar.titleOnly configuration used
        // by RecitersScreen must not render a back button when hosted at the
        // root of a navigator (shell tab).  If this test fails, RecitersScreen
        // will show a spurious back button on the Reciters tab.
        await tester.pumpWidget(
          buildShellTabHost(
            appBarBuilder: (context) => TilawaCatalogAppBar.titleOnly(
              context,
              title: 'Reciters',
              centerTitle: true,
              showBottomHairline: false,
              showElevationShadow: false,
              // automaticallyImplyLeading omitted — relies on default (true).
              // Root route → impliesAppBarDismissal == false → no back button.
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(BackButtonIcon),
          findsNothing,
          reason:
              'RecitersScreen is a root shell tab. '
              'automaticallyImplyLeading: true must not add a back button '
              'because ModalRoute.impliesAppBarDismissal is false on root routes.',
        );
      },
    );
  });

  group('TilawaAppBarScope', () {
    testWidgets('leading and action fills respect separate toggles', (
      WidgetTester tester,
    ) async {
      late Color leadingFill;
      late Color actionFill;

      await tester.pumpWidget(
        MaterialApp(
          theme: _lightTheme(),
          home: TilawaAppBarScope(
            surface: TilawaAppBarSurface.vellum,
            showLeadingControlBackground: true,
            showActionControlBackground: false,
            child: Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                final scope = TilawaAppBarScope.maybeOf(context)!;
                leadingFill = scope.leadingControlFillColor(scheme);
                actionFill = scope.actionControlFillColor(scheme);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final scheme = _lightTheme().colorScheme;
      expect(leadingFill, scheme.surface);
      expect(actionFill, Colors.transparent);
    });
  });
}
