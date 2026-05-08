import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/video_reel_composer_presets.dart';
import 'package:tilawa/features/share/presentation/widgets/composer_controls.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Widget buildSubject({required bool isError, VoidCallback? onPrimaryAction}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
      home: Scaffold(
        body: ComposerControls(
          durationPreset: ShareDurationPreset.auto,
          fromAyah: 1,
          toAyah: 7,
          minAyah: 1,
          maxAyah: 7,
          isBusy: false,
          isGeneratingVideo: false,
          isError: isError,
          rangeIsValid: true,
          reciterName: 'Test Reciter',
          isLoadingReciters: false,
          canSelectReciter: true,
          arabicSurahName: 'الفاتحة',
          onReciterTap: () {},
          onDurationChanged: (_) {},
          onFromChanged: (_) {},
          onToChanged: (_) {},
          onPrimaryAction: onPrimaryAction ?? () {},
          onCancel: () {},
        ),
      ),
    );
  }

  testWidgets('shows Retry label on the primary button when isError is true', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(isError: true));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    expect(
      find.widgetWithIcon(FilledButton, Icons.refresh_rounded),
      findsOneWidget,
    );
    expect(
      find.widgetWithIcon(FilledButton, Icons.movie_creation_rounded),
      findsNothing,
    );
  });

  testWidgets(
    'shows Generate Reel label on the primary button when not in error',
    (tester) async {
      await tester.pumpWidget(buildSubject(isError: false));
      await tester.pump();

      expect(
        find.widgetWithIcon(FilledButton, Icons.movie_creation_rounded),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
    },
  );

  testWidgets('tapping Retry invokes the same primary-action callback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      buildSubject(isError: true, onPrimaryAction: () => taps++),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pump();

    expect(taps, 1);
  });
}
