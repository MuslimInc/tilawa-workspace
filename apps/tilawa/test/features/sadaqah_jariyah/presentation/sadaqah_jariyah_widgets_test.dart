import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/dedication.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_config.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/entities/sadaqah_jariyah_page_data.dart';
import 'package:tilawa/features/sadaqah_jariyah/domain/enums/dedication_status.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/cubit/sadaqah_jariyah_cubit.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/cubit/sadaqah_jariyah_state.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/screens/sadaqah_jariyah_screen.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_dedication_card.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_letter_avatar.dart';
import 'package:tilawa/features/sadaqah_jariyah/presentation/widgets/sadaqah_jariyah_list.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class _MockSadaqahJariyahCubit extends MockCubit<SadaqahJariyahState>
    implements SadaqahJariyahCubit {}

void main() {
  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
      home: Scaffold(body: child),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    SadaqahJariyahState state,
  ) async {
    final _MockSadaqahJariyahCubit cubit = _MockSadaqahJariyahCubit();
    when(() => cubit.state).thenReturn(state);
    when(
      () => cubit.stream,
    ).thenAnswer((_) => Stream<SadaqahJariyahState>.value(state));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.getLightTheme(primaryColor: const Color(0xFFE05A33)),
        home: BlocProvider<SadaqahJariyahCubit>.value(
          value: cubit,
          child: const SadaqahJariyahScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('letter avatar shows first grapheme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const SadaqahJariyahLetterAvatar(name: 'Ahmed')),
    );
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('list renders photo and name without extra metadata', (
    WidgetTester tester,
  ) async {
    final List<Dedication> dedications = <Dedication>[
      const Dedication(
        id: 'founding',
        displayName: 'Ahmed Mohamed Tony',
        slug: 'ahmed-mohamed-tony',
        status: DedicationStatus.published,
        isFounding: true,
        isFeatured: false,
        sortOrder: 0,
        note: 'Should not show',
      ),
      const Dedication(
        id: 'other',
        displayName: 'Other Person',
        slug: 'other-person',
        status: DedicationStatus.published,
        isFounding: false,
        isFeatured: false,
        sortOrder: 1,
        note: 'Remembered with love',
      ),
    ];

    await tester.pumpWidget(
      wrap(
        SadaqahJariyahList(
          dedications: dedications,
          photoUrls: const <String, String?>{},
        ),
      ),
    );

    expect(find.byType(SadaqahJariyahDedicationCard), findsNWidgets(2));
    expect(find.byType(SadaqahJariyahLetterAvatar), findsOneWidget);
    expect(find.text('Founding'), findsNothing);
    expect(find.text('Should not show'), findsNothing);
    expect(find.text('Remembered with love'), findsNothing);

    final Finder founding = find.text('Ahmed Mohamed Tony');
    final Finder other = find.text('Other Person');
    expect(founding, findsOneWidget);
    expect(other, findsOneWidget);
    expect(
      tester.getTopLeft(founding).dy < tester.getTopLeft(other).dy,
      isTrue,
    );
  });

  testWidgets('uses Registered names as the sole screen title', (tester) async {
    await pumpScreen(
      tester,
      const SadaqahJariyahLoaded(
        pageData: SadaqahJariyahPageData(
          config: SadaqahJariyahConfig(),
          dedications: <Dedication>[],
        ),
        photoUrls: <String, String?>{},
      ),
    );

    expect(find.text('Registered names'), findsOneWidget);
  });

  testWidgets('remote feature switch hides names and request CTA', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const SadaqahJariyahLoaded(
        pageData: SadaqahJariyahPageData(
          config: SadaqahJariyahConfig(featureEnabled: false),
          dedications: <Dedication>[
            Dedication(
              id: 'private-name',
              displayName: 'Hidden Person',
              slug: 'private-name',
              status: DedicationStatus.published,
              isFounding: false,
              isFeatured: false,
              sortOrder: 0,
            ),
          ],
        ),
        photoUrls: <String, String?>{},
      ),
    );

    expect(
      find.text('Registered names are temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Hidden Person'), findsNothing);
    expect(find.text('Request a share'), findsNothing);
  });
}
