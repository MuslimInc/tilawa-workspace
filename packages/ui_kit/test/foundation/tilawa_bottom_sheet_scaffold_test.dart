import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/foundation/app_colors.dart';
import '../../lib/src/foundation/app_theme.dart';
import '../../lib/src/foundation/component_tokens/component_tokens_theme.dart';
import '../../lib/src/foundation/tilawa_bottom_sheet_scaffold.dart';
import '../../lib/src/atoms/tilawa_sheet_handle.dart';

void main() {
  testWidgets('lays out handle, optional topBar, between, and children', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
          useGoogleFontsOverride: false,
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

  testWidgets('modalShape uses scaffold top radius from tokens', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
          useGoogleFontsOverride: false,
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

  testWidgets('resolvedBodyPadding matches token defaults', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(
          primaryColor: AppColors.defaultPrimary,
          useGoogleFontsOverride: false,
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
