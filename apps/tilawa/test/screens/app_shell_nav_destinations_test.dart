import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa/screens/app_shell_nav_destinations.dart';

void main() {
  testWidgets('phone shell nav lists five items without reciters tab', (
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

    expect(destinations, hasLength(5));
    expect(
      destinations.map((d) => d.label).toList(),
      [
        l10n.bottomNavHome,
        l10n.bottomNavPrayer,
        l10n.bottomNavQuran,
        l10n.bottomNavAthkar,
        l10n.bottomNavSettings,
      ],
    );

    final tabIndices = destinations
        .map((d) => d.tabIndex)
        .whereType<int>()
        .toSet();
    expect(tabIndices, kPhoneShellNavTabIndices);
    expect(tabIndices, isNot(contains(kAppShellRecitersTabIndex)));

    expect(
      destinations.singleWhere((d) => d.isPushRoute).label,
      l10n.bottomNavQuran,
    );

    expect(
      destinations.map((d) => d.semanticsIdentifier).toList(),
      [
        'home_tab',
        'prayer_times_tab',
        'quran_last_read_nav',
        'athkar_tab',
        'settings_tab',
      ],
    );
  });
}
