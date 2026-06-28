import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/share/domain/entities/share_content.dart';
import 'package:tilawa/features/share/domain/entities/share_mode.dart';
import 'package:tilawa/features/share/presentation/widgets/video_review_panel.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Finder _tilawaButton(String text, TilawaButtonVariant variant) {
  return find.byWidgetPredicate(
    (Widget w) => w is TilawaButton && w.text == text && w.variant == variant,
  );
}

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
    theme: ThemeData(extensions: [MeMuslimDesignTokens.light()]),
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
    'video mode: save uses outline TilawaButton and triggers callback',
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

      await tester.tap(_tilawaButton('Save', TilawaButtonVariant.outline));
      await tester.pump();

      expect(saveTaps, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'video mode: save is disabled and shows spinner while saving',
    (WidgetTester tester) async {
      int saveTaps = 0;

      await tester.pumpWidget(
        _buildHarness(
          content: _videoContent,
          onEdit: () {},
          onSave: () => saveTaps++,
          onShare: () {},
          isSaving: true,
        ),
      );

      final Finder saveButtonFinder = find.byKey(
        const ValueKey('video_review_save_button'),
      );
      final TilawaButton saveButton = tester.widget<TilawaButton>(
        saveButtonFinder,
      );

      expect(saveButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(saveButtonFinder);
      await tester.pump();

      expect(saveTaps, 0);
    },
  );

  testWidgets('video mode: share is the primary TilawaButton', (
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

    expect(
      _tilawaButton('Share Reel', TilawaButtonVariant.primary),
      findsOneWidget,
    );
  });

  testWidgets('screenshot mode: save is the primary TilawaButton', (
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

    final Finder saveButtonFinder = _tilawaButton(
      'Save',
      TilawaButtonVariant.primary,
    );
    expect(saveButtonFinder, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Save'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);

    await tester.tap(saveButtonFinder);
    await tester.pump();

    expect(saveTaps, 1);
  });

  testWidgets(
    'screenshot mode: share uses secondary TilawaButton, save stays primary',
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

      expect(
        _tilawaButton('Save', TilawaButtonVariant.primary),
        findsOneWidget,
      );
      expect(
        _tilawaButton('Share Screenshot', TilawaButtonVariant.secondary),
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

      final Finder saveButtonFinder = find.byKey(
        const ValueKey('video_review_save_button'),
      );
      final TilawaButton saveButton = tester.widget<TilawaButton>(
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
