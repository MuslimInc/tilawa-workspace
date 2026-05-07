import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/presentation/utils/video_reel_composer_presets.dart';
import 'package:tilawa/features/share/presentation/widgets/composer_controls.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  Widget buildSubject({
    String? rangeIssue,
    String? errorMessage,
    bool isBusy = false,
  }) {
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
          isBusy: isBusy,
          isGeneratingVideo: false,
          isError: false,
          rangeIsValid: rangeIssue == null,
          reciterName: 'Test Reciter',
          isLoadingReciters: false,
          canSelectReciter: true,
          arabicSurahName: 'الفاتحة',
          rangeIssue: rangeIssue,
          errorMessage: errorMessage,
          onReciterTap: () {},
          onDurationChanged: (_) {},
          onFromChanged: (_) {},
          onToChanged: (_) {},
          onPrimaryAction: () {},
          onCancel: () {},
        ),
      ),
    );
  }

  testWidgets('renders range issue text when rangeIssue is set and not busy', (
    tester,
  ) async {
    const reason = 'First ayah must be before or equal to the last.';
    await tester.pumpWidget(buildSubject(rangeIssue: reason));
    await tester.pump();

    expect(find.text(reason), findsOneWidget);
  });

  testWidgets('disables the primary action when range is invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(rangeIssue: 'Selected range is outside this surah.'),
    );
    await tester.pump();

    final FilledButton primary = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(primary.onPressed, isNull);
  });

  testWidgets('hides range issue while busy', (tester) async {
    const reason = 'Maximum 30 verses per clip.';
    await tester.pumpWidget(buildSubject(rangeIssue: reason, isBusy: true));
    await tester.pump();

    expect(find.text(reason), findsNothing);
  });

  testWidgets(
    'errorMessage takes precedence over rangeIssue when both are set',
    (tester) async {
      const reason = 'Selected range is outside this surah.';
      const error = 'Network unreachable';
      await tester.pumpWidget(
        buildSubject(rangeIssue: reason, errorMessage: error),
      );
      await tester.pump();

      expect(find.text(error), findsOneWidget);
      expect(find.text(reason), findsNothing);
    },
  );
}
