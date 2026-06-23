import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/atoms/tilawa_button.dart';
import '../../lib/src/atoms/tilawa_sheet_handle.dart';
import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/design_tokens.dart';
import '../../lib/src/foundation/tilawa_bottom_sheet_actions.dart';
import '../../lib/src/foundation/tilawa_bottom_sheet_scaffold.dart';
import '../../lib/src/foundation/tilawa_bottom_sheet_title_row.dart';
import '../../lib/src/foundation/tilawa_icons.dart';

void main() {
  const footerKey = Key('footer');

  Future<EdgeInsets> pumpFooterPadding(
    WidgetTester tester, {
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            viewPadding: viewPadding,
            viewInsets: viewInsets,
          ),
          child: const TilawaBottomSheetScaffold(
            footer: KeyedSubtree(
              key: footerKey,
              child: Text('Footer'),
            ),
            children: [Text('Body')],
          ),
        ),
      ),
    );

    final footerPadding = tester.widget<Padding>(
      find.byWidgetPredicate(
        (widget) => widget is Padding && widget.child?.key == footerKey,
      ),
    );
    return footerPadding.padding as EdgeInsets;
  }

  testWidgets('lays out handle, optional topBar, between, and children', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Scaffold(
          body: TilawaBottomSheetScaffold(
            topBar: const Text('Title'),
            betweenTopBarAndBody: const <Widget>[Divider(height: 1)],
            children: const <Widget>[Text('Content')],
          ),
        ),
      ),
    );

    expect(find.byType(TilawaSheetHandle), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('footer stays visible while list scrolls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: TilawaBottomSheetScaffold(
              topBar: const TilawaBottomSheetTitleRow(title: 'Settings'),
              footer: TilawaBottomSheetActions(
                primaryLabel: 'Save',
                onPrimary: () {},
                secondaryLabel: 'Cancel',
                onSecondary: () {},
              ),
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: 40,
                    itemBuilder: (context, index) => ListTile(
                      title: Text('Row $index'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Row 0'), findsOneWidget);

    await tester.drag(find.text('Row 0'), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Row 0'), findsNothing);
  });

  testWidgets('title row close button pops navigator route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TilawaButton(
                text: 'Open',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: TilawaBottomSheetScaffold(
                          topBar: const TilawaBottomSheetTitleRow(
                            title: 'Sheet',
                            trailingClose: true,
                          ),
                          children: const [Text('Body')],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('Close')),
      const Size.square(kTilawaMinInteractiveDimension),
    );

    await tester.tap(find.byIcon(TilawaIcons.dismiss));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('modalShape uses scaffold top radius from tokens', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final shape = TilawaBottomSheetScaffold.modalShape(ctx);
    expect(shape, isA<RoundedRectangleBorder>());
    final r = Theme.of(ctx).componentTokens.bottomSheetScaffold.topRadius;
    expect(r, 28.0);
  });

  testWidgets('confirm-style layout does not overflow at max height', (
    tester,
  ) async {
    const sheetHeight = 400.0;
    const longMessage =
        'This permanently deletes your Tilawa account and synced profile '
        'data. Purchases verified with Google Play may be kept in anonymized '
        'records for fraud prevention. This cannot be undone.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: sheetHeight),
                  child: TilawaBottomSheetScaffold(
                    topBar: const TilawaBottomSheetTitleRow(
                      title: 'Delete account',
                    ),
                    footer: TilawaBottomSheetActions(
                      primaryLabel: 'Delete account',
                      onPrimary: () {},
                      secondaryLabel: 'Cancel',
                      onSecondary: () {},
                      primaryVariant: TilawaButtonVariant.danger,
                    ),
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                                TilawaBottomSheetScaffold.resolvedBodyPadding(
                                  context,
                                ),
                            child: const Text(longMessage),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('footer uses top border instead of layout divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Scaffold(
          body: TilawaBottomSheetScaffold(
            footer: TilawaBottomSheetActions(
              primaryLabel: 'Save',
              onPrimary: () {},
            ),
            children: const [Text('Body')],
          ),
        ),
      ),
    );

    expect(find.byType(Divider), findsNothing);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('footer keeps comfortable bottom spacing with zero safe area', (
    tester,
  ) async {
    final padding = await pumpFooterPadding(tester);
    final tokens = Theme.of(tester.element(find.byKey(footerKey))).tokens;

    expect(padding.bottom, tokens.spaceHuge);
  });

  testWidgets('footer adds a buffer above the system bottom safe area', (
    tester,
  ) async {
    const systemBottomSafeArea = 34.0;

    final padding = await pumpFooterPadding(
      tester,
      viewPadding: const EdgeInsets.only(bottom: systemBottomSafeArea),
    );
    final tokens = Theme.of(tester.element(find.byKey(footerKey))).tokens;

    expect(padding.bottom, systemBottomSafeArea + tokens.spaceExtraLarge);
  });

  testWidgets('footer clears the keyboard with the token footer buffer', (
    tester,
  ) async {
    const keyboardInset = 300.0;

    final padding = await pumpFooterPadding(
      tester,
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );
    final context = tester.element(find.byKey(footerKey));
    final footerPadding =
        Theme.of(
          context,
        ).componentTokens.bottomSheetScaffold.footerPadding.resolve(
          Directionality.of(context),
        );

    expect(padding.bottom, keyboardInset + footerPadding.bottom);
  });

  testWidgets('resolvedBodyPadding matches token defaults', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
        ),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      TilawaBottomSheetScaffold.resolvedBodyPadding(ctx),
      const EdgeInsets.fromLTRB(16, 12, 16, 24),
    );
  });
}
