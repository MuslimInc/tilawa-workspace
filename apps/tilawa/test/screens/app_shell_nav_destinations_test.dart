import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('phone shell nav lists four Tilawa shell items', (
    tester,
  ) async {
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

    final destinations = buildPhoneShellNavDestinations(l10n);

    expect(destinations, hasLength(4));
    expect(
      destinations.map((d) => d.label).toList(),
      [
        l10n.bottomNavHome,
        l10n.bottomNavQuran,
        l10n.bottomNavReciters,
        l10n.bottomNavSettings,
      ],
    );

    final tabIndices = destinations
        .map((d) => d.tabIndex)
        .whereType<int>()
        .toSet();
    expect(tabIndices, kPhoneShellNavTabIndices);
    expect(tabIndices, contains(kAppShellRecitersTabIndex));
    final recitersDestination = destinations.singleWhere(
      (d) => d.tabIndex == kAppShellRecitersTabIndex,
    );
    expect(recitersDestination.icon, TilawaIcons.reciter);
    expect(recitersDestination.iconBuilder, isNotNull);
    final quranDestination = destinations.singleWhere((d) => d.isPushRoute);
    expect(quranDestination.iconBuilder, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Row(
            children: [
              quranDestination.iconBuilder!(
                context,
                color: Theme.of(context).colorScheme.primary,
              ),
              recitersDestination.iconBuilder!(
                context,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(SvgPicture), findsNWidgets(2));

    expect(quranDestination.label, l10n.bottomNavQuran);

    expect(
      destinations
          .singleWhere((d) => d.tabIndex == kAppShellSettingsTabIndex)
          .icon,
      TilawaIcons.settings,
    );
    expect(
      destinations.where((d) => d.usesProfileAvatar),
      isEmpty,
    );

    expect(
      destinations.map((d) => d.semanticsIdentifier).toList(),
      [
        'home_tab',
        'quran_index_nav',
        'reciters_tab',
        'settings_tab',
      ],
    );
  });
}
