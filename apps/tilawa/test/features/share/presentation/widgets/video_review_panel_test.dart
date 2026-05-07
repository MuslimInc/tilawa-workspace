import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/presentation/widgets/video_review_panel.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Widget _buildHarness({
  required ShareContent content,
  required VoidCallback onEdit,
  required VoidCallback onSave,
  required VoidCallback onShare,
  bool isSaving = false,
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
      ),
    ),
  );
}

void main() {
  testWidgets('save button triggers callback when not saving', (
    WidgetTester tester,
  ) async {
    int saveTaps = 0;

    await tester.pumpWidget(
      _buildHarness(
        content: const ShareContent.video(
          filePath: '/tmp/video.mp4',
          surahName: 'Al-Fatihah',
          fromAyah: 1,
          toAyah: 7,
          reciterName: 'Test Reciter',
        ),
        onEdit: () {},
        onSave: () => saveTaps++,
        onShare: () {},
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pump();

    expect(saveTaps, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('save button is disabled and shows spinner while saving', (
    WidgetTester tester,
  ) async {
    int saveTaps = 0;

    await tester.pumpWidget(
      _buildHarness(
        content: const ShareContent.screenshot(
          filePath: '/tmp/image.png',
          surahName: 'Al-Baqarah',
          pageNumber: 2,
        ),
        onEdit: () {},
        onSave: () => saveTaps++,
        onShare: () {},
        isSaving: true,
      ),
    );

    final Finder saveButtonFinder = find.widgetWithText(OutlinedButton, 'Save');
    final OutlinedButton saveButton = tester.widget<OutlinedButton>(
      saveButtonFinder,
    );

    expect(saveButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(saveTaps, 0);
  });
}
