import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fixtures.dart';
import 'teacher_list_test_bloc.dart';

void main() {
  group('TeacherListScreen', () {
    testWidgets('renders compact teacher cards with filter chips', (
      tester,
    ) async {
      final teachers = [
        makeTeacher(id: 't1', avatarUrl: ''),
        makeTeacher(id: 't2', avatarUrl: ''),
        makeTeacher(id: 't3', avatarUrl: ''),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<TeacherListBloc>(
            create: (_) => TeacherListTestBloc(
              TeacherListSuccess(
                teachers: teachers,
                hasMore: false,
              ),
            ),
            child: TeacherListScreen(
              featureConfig: const QuranSessionsFeatureConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherCard), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('uses a short AppBar title and long header title in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<TeacherListBloc>(
            create: (_) => TeacherListTestBloc(
              TeacherListSuccess(
                teachers: [makeTeacher(id: 't1', avatarUrl: '')],
                hasMore: false,
              ),
            ),
            child: TeacherListScreen(
              featureConfig: const QuranSessionsFeatureConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBarTitle = find.descendant(
        of: find.byType(TilawaAppBar),
        matching: find.text('Tutors'),
      );
      expect(appBarTitle, findsOneWidget);
      expect(find.text('Learn Quran with your teacher'), findsOneWidget);
    });

    testWidgets('uses a short AppBar title and long header title in Arabic', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          locale: const Locale('ar'),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<TeacherListBloc>(
              create: (_) => TeacherListTestBloc(
                TeacherListSuccess(
                  teachers: [makeTeacher(id: 't1', avatarUrl: '')],
                  hasMore: false,
                ),
              ),
              child: TeacherListScreen(
                featureConfig: const QuranSessionsFeatureConfig(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBarTitle = find.descendant(
        of: find.byType(TilawaAppBar),
        matching: find.text('المحفظون'),
      );
      expect(appBarTitle, findsOneWidget);
      expect(find.text('تعلّم القرآن مع محفظك'), findsOneWidget);
    });

    testWidgets('renders 360x800 Arabic list with availability labels', (
      tester,
    ) async {
      final anchor = DateTime(2026, 6, 15, 10);
      final teachers = [
        makeTeacher(
          id: 't1',
          displayName: 'الشيخ محمد كامل الطويل',
          avatarUrl: '',
        ),
        makeTeacher(id: 't2', displayName: 'المحفظ عبد الرحمن', avatarUrl: ''),
        makeTeacher(id: 't3', displayName: 'Sheikh Ahmed', avatarUrl: ''),
      ];

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          locale: const Locale('ar'),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<TeacherListBloc>(
              create: (_) => TeacherListTestBloc(
                TeacherListSuccess(
                  teachers: teachers,
                  hasMore: false,
                  availabilitySummaries: {
                    't1':
                        TeacherAvailabilitySummaryPresenter(
                          now: () => anchor,
                        ).fromSlots(
                          teacherId: 't1',
                          slots: [
                            makeSlot(
                              teacherId: 't1',
                              startsAt: anchor.add(const Duration(hours: 2)),
                            ),
                          ],
                        ),
                    't2': const TeacherAvailabilitySummary(
                      teacherId: 't2',
                      status: TeacherAvailabilityStatus.noSlots,
                    ),
                    't3': const TeacherAvailabilitySummary(
                      teacherId: 't3',
                      status: TeacherAvailabilityStatus.unavailable,
                    ),
                  },
                ),
              ),
              child: TeacherListScreen(
                featureConfig: const QuranSessionsFeatureConfig(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherCard), findsNWidgets(3));
      // "متاح اليوم" is also a filter chip label, so scope to the card body to
      // assert the availability hint specifically.
      expect(
        find.descendant(
          of: find.byType(TeacherCard),
          matching: find.text('متاح اليوم'),
        ),
        findsOneWidget,
      );
      expect(find.text('لا توجد مواعيد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty teachers state shows illustrated empty view', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<TeacherListBloc>(
            create: (_) => TeacherListTestBloc(const TeacherListEmpty()),
            child: TeacherListScreen(
              featureConfig: const QuranSessionsFeatureConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuranSessionsStudentEmptyState), findsOneWidget);
    });

    testWidgets('invokes onTeacherListViewed once when the screen opens', (
      tester,
    ) async {
      var viewedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<TeacherListBloc>(
            create: (_) => TeacherListTestBloc(
              TeacherListSuccess(
                teachers: [makeTeacher(id: 't1', avatarUrl: '')],
                hasMore: false,
              ),
            ),
            child: TeacherListScreen(
              featureConfig: const QuranSessionsFeatureConfig(),
              analytics: QuranSessionsAnalyticsCallbacks(
                onTeacherListViewed: () => viewedCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(viewedCount, 1);
    });

    testWidgets('search field filters teachers by display name', (
      tester,
    ) async {
      final teachers = [
        makeTeacher(id: 't1', displayName: 'Sheikh Ahmed', avatarUrl: ''),
        makeTeacher(id: 't2', displayName: 'Ustad Fatima', avatarUrl: ''),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          localizationsDelegates:
              QuranSessionsLocalizations.localizationsDelegates,
          supportedLocales: QuranSessionsLocalizations.supportedLocales,
          home: BlocProvider<TeacherListBloc>(
            create: (_) => TeacherListTestBloc(
              TeacherListSuccess(
                teachers: teachers,
                hasMore: false,
              ),
            ),
            child: TeacherListScreen(
              featureConfig: const QuranSessionsFeatureConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeacherCard), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'Fatima');
      await tester.pumpAndSettle();

      expect(find.byType(TeacherCard), findsOneWidget);
      expect(find.text('Ustad Fatima'), findsOneWidget);
    });
  });
}
