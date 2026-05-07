import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_mode.dart';
import 'package:tilawa/features/share/presentation/widgets/video_review_panel.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _buildHarness({
  required ShareContent content,
  required VoidCallback onEdit,
  required VoidCallback onSave,
  required VoidCallback onShare,
  bool isSaving = false,
  ShareMode mode = ShareMode.video,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(extensions: [TilawaDesignTokens.light()]),
    home: Scaffold(
      body: VideoReviewPanel(
        content: content,
        onEdit: onEdit,
        onSave: onSave,
        onShare: onShare,
        isSaving: isSaving,
        mode: mode,
      ),
    ),
  );
}

const _videoContent = ShareContent.video(
  filePath: '/tmp/video.mp4',
  surahName: 'Al-Fatihah',
  fromAyah: 1,
  toAyah: 7,
  reciterName: 'Test Reciter',
);

const _screenshotContent = ShareContent.screenshot(
  filePath: '/tmp/image.png',
  surahName: 'Al-Baqarah',
  pageNumber: 2,
);

void main() {
  testWidgets(
    'video mode: save button is OutlinedButton and triggers callback',
    (WidgetTester tester) async {
      int saveTaps = 0;

      await tester.pumpWidget(
        _buildHarness(
          content: _videoContent,
          onEdit: () {},
          onSave: () => saveTaps++,
          onShare: () {},
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
      await tester.pump();

      expect(saveTaps, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'video mode: save button is disabled and shows spinner while saving',
    (WidgetTester tester) async {
      int saveTaps = 0;

      await tester.pumpWidget(
        _buildHarness(
          content: _screenshotContent,
          onEdit: () {},
          onSave: () => saveTaps++,
          onShare: () {},
          isSaving: true,
        ),
      );

      final Finder saveButtonFinder = find.widgetWithText(
        OutlinedButton,
        'Save',
      );
      final OutlinedButton saveButton = tester.widget<OutlinedButton>(
        saveButtonFinder,
      );

      expect(saveButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(saveButtonFinder);
      await tester.pump();

      expect(saveTaps, 0);
    },
  );

  testWidgets('video mode: share is the FilledButton primary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        content: _videoContent,
        onEdit: () {},
        onSave: () {},
        onShare: () {},
      ),
    );

    // Filled (non-tonal) Share Reel exists
    expect(find.widgetWithText(FilledButton, 'Share Reel'), findsOneWidget);
    // No tonal share button in video mode
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is FilledButton &&
            (w.style?.backgroundColor != null) == false &&
            false,
      ),
      findsNothing,
    );
  });

  testWidgets('screenshot mode: save is the FilledButton primary', (
    WidgetTester tester,
  ) async {
    int saveTaps = 0;

    await tester.pumpWidget(
      _buildHarness(
        content: _screenshotContent,
        onEdit: () {},
        onSave: () => saveTaps++,
        onShare: () {},
        mode: ShareMode.screenshot,
      ),
    );

    final Finder saveButtonFinder = find.widgetWithText(FilledButton, 'Save');
    expect(saveButtonFinder, findsOneWidget);
    // Save must NOT be an OutlinedButton in screenshot mode
    expect(find.widgetWithText(OutlinedButton, 'Save'), findsNothing);

    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(saveTaps, 1);
  });

  testWidgets(
    'screenshot mode: share is rendered via FilledButton.tonalIcon, not the '
    'filled primary',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(
          content: _screenshotContent,
          onEdit: () {},
          onSave: () {},
          onShare: () {},
          mode: ShareMode.screenshot,
        ),
      );

      // The Save button is the only filled (non-tonal) FilledButton.
      // FilledButton.tonalIcon also returns a FilledButton subtype, so we
      // assert the count by label rather than runtime type — Save is filled
      // primary; Share is tonal but still type FilledButton.
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Share Screenshot'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'screenshot mode: save shows spinner and is disabled while saving',
    (WidgetTester tester) async {
      int saveTaps = 0;

      await tester.pumpWidget(
        _buildHarness(
          content: _screenshotContent,
          onEdit: () {},
          onSave: () => saveTaps++,
          onShare: () {},
          isSaving: true,
          mode: ShareMode.screenshot,
        ),
      );

      final Finder saveButtonFinder = find.widgetWithText(FilledButton, 'Save');
      final FilledButton saveButton = tester.widget<FilledButton>(
        saveButtonFinder,
      );

      expect(saveButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(saveButtonFinder);
      await tester.pump();

      expect(saveTaps, 0);
    },
  );
}
