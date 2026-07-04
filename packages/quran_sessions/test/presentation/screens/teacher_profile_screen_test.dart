import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/availability_test_helpers.dart';
import '../../helpers/fakes/fake_session_repository.dart';
import '../../helpers/fakes/fake_teacher_repository.dart';
import '../../helpers/fixtures.dart';

class _TeacherProfileTestBloc extends TeacherProfileBloc {
  _TeacherProfileTestBloc(TeacherProfileSuccess seed)
    : super(
        getProfile: GetTeacherProfileUseCase(FakeTeacherRepository()),
        getAvailability: buildGetTeacherAvailabilityUseCase(
          scheduleRepository: FakeScheduleRepository(),
          sessionRepository: FakeSessionRepository(),
        ),
      ) {
    emit(seed);
  }

  @override
  void add(TeacherProfileEvent event) {}
}

Future<void> _pumpProfile(
  WidgetTester tester,
  TeacherProfileSuccess seed, {
  double textScaleFactor = 1.0,
  QuranSessionsAnalyticsCallbacks analytics =
      const QuranSessionsAnalyticsCallbacks(),
  SessionModePolicy sessionModePolicy = SessionModePolicy.freeBeta,
}) async {
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
      localizationsDelegates: const [
        ...QuranSessionsLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: QuranSessionsThemeScope(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: BlocProvider<TeacherProfileBloc>.value(
              value: _TeacherProfileTestBloc(seed),
              child: TeacherProfileScreen(
                teacherId: seed.teacher.id,
                analytics: analytics,
                sessionModePolicy: sessionModePolicy,
                onBookTapped: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('invokes onTeacherProfileViewed with the teacher id on open', (
    tester,
  ) async {
    String? viewedTeacherId;

    await _pumpProfile(
      tester,
      TeacherProfileSuccess(
        teacher: makeTeacher(id: 't42', avatarUrl: ''),
        availability: const [],
        reviews: const [],
      ),
      analytics: QuranSessionsAnalyticsCallbacks(
        onTeacherProfileViewed: (id) => viewedTeacherId = id,
      ),
    );

    expect(viewedTeacherId, 't42');
  });

  testWidgets('no-slot profile is safe on 360x800 at text scale 1.4', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      TeacherProfileSuccess(
        teacher: makeTeacher(
          displayName: 'الشيخ محمد بن عبد الله كامل الهاشمي الطويل',
          avatarUrl: '',
        ).copyWithReviews(totalReviews: 0),
        availability: const [],
        reviews: const [],
      ),
      textScaleFactor: 1.4,
    );

    expect(find.text('جديد'), findsOneWidget);
    expect(find.text('لا توجد مواعيد متاحة'), findsOneWidget);
    expect(find.text('لم تُنشر أي مواعيد بعد.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('available-slot profile keeps booking CTA active', (
    tester,
  ) async {
    final slot = makeSlot(
      startsAt: DateTime.now().add(const Duration(days: 1)),
    );
    var selectedTeacherId = '';
    String? selectedSlotId;

    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final seed = TeacherProfileSuccess(
      teacher: makeTeacher(avatarUrl: ''),
      availability: [slot],
      reviews: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        locale: const Locale('ar'),
        localizationsDelegates:
            QuranSessionsLocalizations.localizationsDelegates,
        supportedLocales: QuranSessionsLocalizations.supportedLocales,
        home: QuranSessionsThemeScope(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<TeacherProfileBloc>.value(
              value: _TeacherProfileTestBloc(seed),
              child: TeacherProfileScreen(
                teacherId: seed.teacher.id,
                onBookTapped: (teacherId, slotId) {
                  selectedTeacherId = teacherId;
                  selectedSlotId = slotId;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('احجز جلسة'));
    await tester.pump();

    expect(selectedTeacherId, seed.teacher.id);
    expect(selectedSlotId, isNull);
  });

  testWidgets('hides report tutor action for launch rollout', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      TeacherProfileSuccess(
        teacher: makeTeacher(avatarUrl: ''),
        availability: const [],
        reviews: const [],
      ),
    );

    expect(find.byIcon(Icons.flag_outlined), findsNothing);
    expect(find.byTooltip('الإبلاغ عن المحفظ'), findsNothing);
  });

  testWidgets('expands credentials section when teacher has credentials', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      TeacherProfileSuccess(
        teacher: makeTeacher(
          avatarUrl: '',
          credentials: const [
            TeacherCredential(
              title: 'Ijazah in Hafs',
              issuer: 'Test institute',
              isVerified: true,
            ),
          ],
        ),
        availability: const [],
        reviews: const [],
      ),
    );

    expect(find.text('الشهادات والإجازات'), findsOneWidget);
    expect(find.text('Ijazah in Hafs'), findsNothing);

    await tester.tap(find.text('شهادة واحدة'));
    await tester.pumpAndSettle();

    expect(find.text('Ijazah in Hafs'), findsOneWidget);
    expect(find.text('موثّقة من تلاوة'), findsOneWidget);
  });

  testWidgets('hides external sessions chip when session mode is videoOnly', (
    tester,
  ) async {
    final l10n = await QuranSessionsLocalizations.delegate.load(
      const Locale('ar'),
    );

    await _pumpProfile(
      tester,
      TeacherProfileSuccess(
        teacher: makeTeacher(id: 't_ext', avatarUrl: ''),
        availability: const [],
        reviews: const [],
      ),
      sessionModePolicy: SessionModePolicy.videoOnly,
    );

    expect(find.text(l10n.teacherOffersExternalSessions), findsNothing);
  });
}

extension on QuranTeacher {
  QuranTeacher copyWithReviews({required int totalReviews}) {
    return QuranTeacher(
      id: id,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      gender: gender,
      verificationStatus: verificationStatus,
      supportedCallTypes: supportedCallTypes,
      pricingType: pricingType,
      price: price,
      specializations: specializations,
      languages: languages,
      averageRating: averageRating,
      totalReviews: totalReviews,
      totalSessionsCompleted: totalSessionsCompleted,
      credentials: credentials,
    );
  }
}
