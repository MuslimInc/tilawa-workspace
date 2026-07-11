import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_sessions/l10n/quran_sessions_localizations.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../helpers/fakes/fake_teacher_application_repository.dart';
import '../../helpers/fakes/fake_teacher_profile_repository.dart';

TeacherProfile _incompleteTeacherProfile() =>
    TeacherProfileCompleteness.withComputedVisibility(
      TeacherProfile(
        id: 'teacher_1',
        userId: 'teacher_1',
        displayName: '',
        publicBio: '',
        verificationStatus: TeacherVerificationStatus.verified,
        teachingLanguages: const [],
        specializations: const [],
        averageRating: 0,
        reviewCount: 0,
        isActive: true,
        profileCompleteness: TeacherProfileCompletenessStatus.incomplete,
        isPubliclyVisible: false,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 2),
      ),
    );

TeacherApplication _approvedApplication() => TeacherApplication(
  id: 'app_1',
  userId: 'teacher_1',
  status: TeacherApplicationStatus.approved,
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 2),
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  EdgeInsets viewInsets = EdgeInsets.zero,
  SessionModePolicy sessionModePolicy = SessionModePolicy.freeBeta,
}) async {
  final profileRepo = FakeTeacherProfileRepository(
    profile: _incompleteTeacherProfile(),
  );
  final applicationRepo = FakeTeacherApplicationRepository()
    ..application = _approvedApplication();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      locale: locale,
      localizationsDelegates: const [
        QuranSessionsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: QuranSessionsLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(viewInsets: viewInsets),
        child: CompleteTeacherPublicProfileScreen(
          userId: 'teacher_1',
          getCapability: GetCurrentUserTeacherCapabilityUseCase(
            applicationRepository: applicationRepo,
            profileRepository: profileRepo,
          ),
          saveProfile: SaveTeacherPublicProfileUseCase(profileRepo),
          sessionModePolicy: sessionModePolicy,
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets(
    'hides external meeting link when session mode is videoOnly',
    (tester) async {
      await _pumpScreen(
        tester,
        sessionModePolicy: SessionModePolicy.videoOnly,
      );

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(find.text(l10n.teacherExternalMeetingUrlLabel), findsNothing);
    },
  );

  testWidgets(
    'shows exactly one external meeting link field after load',
    (tester) async {
      await _pumpScreen(tester);

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(find.text(l10n.teacherExternalMeetingUrlLabel), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TilawaTextField &&
              widget.hintText == l10n.teacherExternalMeetingUrlHint,
        ),
        findsOneWidget,
      );
      expect(
        find.text(l10n.teacherExternalMeetingUrlHelper),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'bio field uses top-aligned multiline input',
    (tester) async {
      await _pumpScreen(tester);

      final l10n = await QuranSessionsLocalizations.delegate.load(
        const Locale('en'),
      );

      expect(find.text(l10n.bioSectionTitle), findsOneWidget);

      final bioField = tester.widget<TilawaTextField>(
        find.byWidgetPredicate(
          (widget) =>
              widget is TilawaTextField && widget.hintText == l10n.bioHint,
        ),
      );

      expect(bioField.label, isNull);
      expect(bioField.minLines, 4);
      expect(bioField.maxLines, 8);
      expect(bioField.textAlignVertical, TextAlignVertical.top);
    },
  );

  testWidgets('form body has a scrollable ancestor', (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('scroll view clears sticky footer without keyboard inset', (
    tester,
  ) async {
    const keyboardInset = 300.0;
    final tokens = MeMuslimDesignTokens.light();

    await _pumpScreen(
      tester,
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final scrollPadding = scrollView.padding! as EdgeInsets;
    final footerClearance =
        TilawaFormScreenScaffold.stickyFooterScrollClearance(
          tester.element(find.byType(TilawaFormScreenScaffold)),
        );

    expect(scrollPadding.bottom, tokens.spaceLarge + footerClearance);
    expect(scrollPadding.bottom, lessThan(keyboardInset));
  });

  testWidgets('submit footer keeps token padding above keyboard', (
    tester,
  ) async {
    const keyboardInset = 300.0;
    final tokens = MeMuslimDesignTokens.light();

    await _pumpScreen(
      tester,
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );

    final l10n = await QuranSessionsLocalizations.delegate.load(
      const Locale('en'),
    );

    final Finder actionArea = find.ancestor(
      of: find.text(l10n.completeTeacherProfile),
      matching: find.byType(TilawaBottomActionArea),
    );
    final AnimatedPadding animatedPadding = tester.widget<AnimatedPadding>(
      find.descendant(
        of: actionArea,
        matching: find.byType(AnimatedPadding),
      ),
    );

    final EdgeInsets padding = animatedPadding.padding as EdgeInsets;

    expect(padding.bottom, lessThanOrEqualTo(tokens.spaceHuge));
    expect(padding.bottom, lessThan(keyboardInset));
  });
}
