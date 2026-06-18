import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';

void main() {
  testWidgets('phone shell nav lists six TripGlide-style items', (
    tester,
  ) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final destinations = buildPhoneShellNavDestinations(l10n);

    expect(destinations, hasLength(6));
    expect(
      destinations.map((d) => d.label).toList(),
      [
        l10n.bottomNavHome,
        l10n.bottomNavQuran,
        l10n.bottomNavReciters,
        l10n.bottomNavQibla,
        l10n.bottomNavAthkar,
        l10n.bottomNavSettings,
      ],
    );

    final tabIndices = destinations
        .map((d) => d.tabIndex)
        .whereType<int>()
        .toSet();
    expect(tabIndices, kPhoneShellNavTabIndices);
    expect(tabIndices, contains(kAppShellRecitersTabIndex));

    expect(
      destinations.singleWhere((d) => d.isPushRoute).label,
      l10n.bottomNavQuran,
    );

    expect(
      destinations.singleWhere((d) => d.usesProfileAvatar).tabIndex,
      kAppShellSettingsTabIndex,
    );

    expect(
      destinations.map((d) => d.semanticsIdentifier).toList(),
      [
        'home_tab',
        'quran_index_nav',
        'reciters_tab',
        'qibla_tab',
        'athkar_tab',
        'settings_tab',
      ],
    );
  });
}
