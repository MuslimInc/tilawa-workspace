import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:tilawa/features/downloads/presentation/widgets/reciter_downloads_section.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockDownloadsBloc extends Mock implements DownloadsBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDownloadsBloc mockDownloadsBloc;

  const testReciterName = 'Test Reciter';

  setUpAll(() {
    registerFallbackValue(const DeleteDownloadEvent(downloadId: 'fallback'));
    registerFallbackValue(
      const DeleteReciterDownloads(reciterName: testReciterName),
    );
  });

  setUp(() {
    mockDownloadsBloc = _MockDownloadsBloc();
    when(() => mockDownloadsBloc.state).thenReturn(const DownloadsState());
    when(
      () => mockDownloadsBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockDownloadsBloc.close()).thenAnswer((_) async {});
    when(() => mockDownloadsBloc.add(any())).thenReturn(null);
  });

  Future<void> pumpSection(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: PrimaryColorPreset.defaultPreset.value,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DownloadsBloc>.value(
          value: mockDownloadsBloc,
          child: Scaffold(
            body: ReciterDownloadsSection(
              reciterName: testReciterName,
              downloadsByNarrative: const {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'delete all confirmation dispatches DeleteReciterDownloads from dialog',
    (tester) async {
      await pumpSection(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete All'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(TilawaButton, 'Delete All').last,
      );
      await tester.pumpAndSettle();

      final captured = verify(
        () => mockDownloadsBloc.add(captureAny()),
      ).captured;
      expect(
        captured.last,
        const DeleteReciterDownloads(reciterName: testReciterName),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
