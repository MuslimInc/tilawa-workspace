import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Future<AppLocalizations> _loadL10n(WidgetTester tester) async {
  late AppLocalizations l10n;

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return l10n;
}

int _navIndexForTab(int tabIndex, List<AppShellNavDestination> destinations) {
  return destinations.indexWhere((d) => d.tabIndex == tabIndex);
}

void main() {
  group('AppShell profile nav selection', () {
    testWidgets('settings tab maps to profile nav index', (tester) async {
      final l10n = await _loadL10n(tester);
      final destinations = buildPhoneShellNavDestinations(l10n);

      expect(
        _navIndexForTab(kAppShellSettingsTabIndex, destinations),
        3,
      );
    });

    testWidgets('route resolver picks profile nav for settings routes', (
      tester,
    ) async {
      final l10n = await _loadL10n(tester);
      final destinations = buildPhoneShellNavDestinations(l10n);
      final int? tabIndex = AppShellRoutePolicy.tabIndexForLocation(
        '/settings',
      );

      expect(tabIndex, kAppShellSettingsTabIndex);
      expect(_navIndexForTab(tabIndex!, destinations), 3);
    });

    testWidgets('profile nav item has no pill or ring when selected', (
      tester,
    ) async {
      final l10n = await _loadL10n(tester);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                final double profileAvatarSize = Theme.of(
                  context,
                ).componentTokens.adaptiveShell.navButtonIconSize;
                final destinations = <TilawaNavDestination>[
                  const TilawaNavDestination(
                    label: 'Home',
                    icon: Icons.home_outlined,
                  ),
                  TilawaNavDestination(
                    label: l10n.bottomNavSettings,
                    icon: TilawaIcons.profile,
                    selectionUsesBackground: false,
                    iconBuilder:
                        (
                          BuildContext iconContext, {
                          required bool isSelected,
                          required Color color,
                        }) {
                          return SizedBox(
                            width: profileAvatarSize,
                            height: profileAvatarSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(child: Text('T')),
                            ),
                          );
                        },
                  ),
                ];

                return TilawaAdaptiveShell(
                  destinations: destinations,
                  selectedIndex: 1,
                  onDestinationSelected: (_) {},
                  bottomPlayer: const SizedBox.shrink(),
                  child: const ColoredBox(color: Color(0xFFEEEEEE)),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedPositionedDirectional), findsNothing);
      expect(find.byKey(const Key('nav_button_1')), findsOneWidget);

      final Finder profileRing = find.descendant(
        of: find.byKey(const Key('nav_button_1')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).border != null,
        ),
      );
      expect(profileRing, findsNothing);
      expect(find.text(l10n.bottomNavSettings), findsOneWidget);
    });

    testWidgets('profile nav item shows settings label when unselected', (
      tester,
    ) async {
      final l10n = await _loadL10n(tester);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                final double profileAvatarSize = Theme.of(
                  context,
                ).componentTokens.adaptiveShell.navButtonIconSize;
                final destinations = <TilawaNavDestination>[
                  const TilawaNavDestination(
                    label: 'Home',
                    icon: Icons.home_outlined,
                  ),
                  TilawaNavDestination(
                    label: l10n.bottomNavSettings,
                    icon: TilawaIcons.profile,
                    selectionUsesBackground: false,
                    iconBuilder:
                        (
                          BuildContext iconContext, {
                          required bool isSelected,
                          required Color color,
                        }) {
                          return SizedBox(
                            width: profileAvatarSize,
                            height: profileAvatarSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(child: Text('T')),
                            ),
                          );
                        },
                  ),
                ];

                return TilawaAdaptiveShell(
                  destinations: destinations,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bottomPlayer: const SizedBox.shrink(),
                  child: const ColoredBox(color: Color(0xFFEEEEEE)),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n.bottomNavSettings), findsOneWidget);
      expect(find.byType(AnimatedPositionedDirectional), findsNothing);
    });
  });
}
