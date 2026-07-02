import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

const String _kCapabilityCardTitle = 'Teacher dashboard';
const String _kCapabilityCardSubtitle =
    'Manage your schedule and sessions from here.';
const String _kCapabilityCardBadge = 'Verified teacher';

Widget _capabilityCardFixture({VoidCallback? onTap}) {
  return TilawaCapabilityActionCard(
    title: _kCapabilityCardTitle,
    subtitle: _kCapabilityCardSubtitle,
    leadingIcon: TilawaIcons.teacherCapability,
    badgeLabel: _kCapabilityCardBadge,
    onTap: onTap ?? () {},
    margin: EdgeInsets.zero,
  );
}

Widget _capabilityCardSkeletonFixture() {
  return const TilawaCapabilityActionCardSkeleton(
    margin: EdgeInsets.zero,
    animate: false,
    mirrorTitle: _kCapabilityCardTitle,
    mirrorSubtitle: _kCapabilityCardSubtitle,
    mirrorBadgeLabel: _kCapabilityCardBadge,
  );
}

Widget _wrap({
  required Widget child,
  required Brightness brightness,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    darkTheme: AppTheme.getDarkTheme(primaryColor: AppColors.defaultPrimary),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, appChild) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: textScaler == null
            ? mediaQuery
            : mediaQuery.copyWith(textScaler: textScaler),
        child: appChild!,
      );
    },
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TilawaCapabilityActionCard', () {
    testWidgets('renders title, subtitle, badge, and chevron', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: TilawaCapabilityActionCard(
            title: 'لوحة تحكم المحفظ',
            subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
            leadingIcon: TilawaIcons.teacherCapability,
            badgeLabel: 'محفظ معتمد',
            onTap: () {},
          ),
        ),
      );

      check(find.text('لوحة تحكم المحفظ').evaluate().length).equals(1);
      check(
        find.text('يمكنك إدارة مواعيدك وجلساتك من هنا').evaluate().length,
      ).equals(1);
      check(find.text('محفظ معتمد').evaluate().length).equals(1);
      check(
        find.byType(TilawaVerifiedTeacherBadge).evaluate().length,
      ).equals(1);
      check(
        find.byIcon(TilawaIcons.chevronRightSmall).evaluate().length,
      ).equals(1);
    });

    testWidgets('meets minimum tap target height', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: TilawaCapabilityActionCard(
            title: 'Teacher dashboard',
            subtitle: 'Manage sessions',
            leadingIcon: TilawaIcons.teacherCapability,
            onTap: () {},
          ),
        ),
      );

      final Size cardSize = tester.getSize(
        find.byType(TilawaCapabilityActionCard),
      );
      check(cardSize.height >= kMeMuslimMinInteractiveDimension).isTrue();
    });

    testWidgets('Arabic copy does not clip in RTL layout', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          textDirection: TextDirection.rtl,
          child: const SizedBox(
            width: 320,
            child: TilawaCapabilityActionCard(
              title: 'لوحة تحكم المحفظ',
              subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
              leadingIcon: TilawaIcons.teacherCapability,
              badgeLabel: 'محفظ معتمد',
              onTap: _noop,
            ),
          ),
        ),
      );

      final titleSize = tester.getSize(find.text('لوحة تحكم المحفظ'));
      final subtitleSize = tester.getSize(
        find.text('يمكنك إدارة مواعيدك وجلساتك من هنا'),
      );

      check(titleSize.height).isGreaterThan(0);
      check(subtitleSize.height).isGreaterThan(0);
    });

    testWidgets(
      'Arabic teacher dashboard copy fits at product text scale in RTL',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            textDirection: TextDirection.rtl,
            textScaler:
                tilawaProductTextScaler(
                  const TextScaler.linear(1),
                ).clamp(
                  minScaleFactor: 1,
                  maxScaleFactor: kTilawaGlobalTextScaleFactor,
                ),
            child: const SizedBox(
              width: 350,
              child: TilawaCapabilityActionCard(
                title: 'لوحة تحكم المحفظ',
                subtitle: 'يمكنك إدارة مواعيدك وجلساتك من هنا',
                leadingIcon: TilawaIcons.teacherCapability,
                badgeLabel: 'محفظ معتمد',
                onTap: _noop,
                margin: EdgeInsets.zero,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('dark theme keeps readable title and subtitle colors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.dark,
          child: TilawaCapabilityActionCard(
            title: 'Teacher dashboard',
            subtitle: 'Manage sessions',
            leadingIcon: TilawaIcons.teacherCapability,
            onTap: () {},
          ),
        ),
      );

      final titleStyle = tester
          .widget<Text>(find.text('Teacher dashboard'))
          .style;
      final subtitleStyle = tester
          .widget<Text>(find.text('Manage sessions'))
          .style;

      check(titleStyle?.color).isNotNull();
      check(subtitleStyle?.color).isNotNull();
      check(titleStyle!.color != subtitleStyle!.color).isTrue();
    });
    testWidgets(
      'complete teacher profile copy fits without vertical overflow at settings width',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const String title = 'Complete teacher profile';
        const String subtitle =
            'Add the public details students see before opening your dashboard.';

        await tester.pumpWidget(
          _wrap(
            brightness: Brightness.light,
            child: const SizedBox(
              width: 350,
              child: TilawaCapabilityActionCard(
                title: title,
                subtitle: subtitle,
                leadingIcon: TilawaIcons.teacherCapability,
                badgeLabel: 'Verified teacher',
                onTap: _noop,
                margin: EdgeInsets.zero,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('matches skeleton height for canonical badge layout', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: SizedBox(
            width: 360,
            child: KeyedSubtree(
              key: _kCardProbeKey,
              child: _capabilityCardFixture(),
            ),
          ),
        ),
      );
      final double cardHeight = tester
          .getSize(find.byKey(_kCardProbeKey))
          .height;

      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: SizedBox(
            width: 360,
            child: KeyedSubtree(
              key: _kSkeletonProbeKey,
              child: _capabilityCardSkeletonFixture(),
            ),
          ),
        ),
      );
      final double skeletonHeight = tester
          .getSize(find.byKey(_kSkeletonProbeKey))
          .height;

      check(cardHeight).equals(skeletonHeight);
    });
  });

  group('TilawaCapabilityActionCardSkeleton', () {
    testWidgets('renders placeholder bones and loading semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: const TilawaCapabilityActionCardSkeleton(),
        ),
      );

      check(
        find.byType(TilawaCapabilityActionCardSkeleton).evaluate().length,
      ).equals(1);
      check(find.byType(InkWell).evaluate().isEmpty).isTrue();
      check(find.bySemanticsLabel('Loading').evaluate().length).equals(1);
    });

    testWidgets('meets minimum tap target height', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: const TilawaCapabilityActionCardSkeleton(),
        ),
      );

      final Size cardSize = tester.getSize(
        find.byType(TilawaCapabilityActionCardSkeleton),
      );
      check(cardSize.height >= kMeMuslimMinInteractiveDimension).isTrue();
    });

    testWidgets('hides badge bone when showBadge is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: const TilawaCapabilityActionCardSkeleton(showBadge: true),
        ),
      );
      final int withBadge = find.byType(RepaintBoundary).evaluate().length;

      await tester.pumpWidget(
        _wrap(
          brightness: Brightness.light,
          child: const TilawaCapabilityActionCardSkeleton(showBadge: false),
        ),
      );
      final int withoutBadge = find.byType(RepaintBoundary).evaluate().length;

      check(withoutBadge).isLessThan(withBadge);
    });
  });
}

void _noop() {}

const Key _kCardProbeKey = Key('capability_card_probe');
const Key _kSkeletonProbeKey = Key('capability_card_skeleton_probe');
