import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/history/presentation/widgets/history_search_bar.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('centers the RTL search text without vertical content padding', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: TilawaCatalogAppBar(
              title: 'سجل الاستماع',
              bottomContentHeight: TilawaAppBarConfig.catalogSearchRowHeight(
                context,
              ),
              bottomContent: HistorySearchBar(
                controller: controller,
                onChanged: (_) {},
                onClear: () {},
              ),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final fieldFinder = find.byType(TextField);
    final fieldRect = tester.getRect(fieldFinder);
    final fieldContext = tester.element(fieldFinder);
    final expectedHeight = Theme.of(
      fieldContext,
    ).componentTokens.searchField.height;
    final hintRect = tester.getRect(find.text('البحث في السجل...'));

    expect(
      (fieldRect.height - expectedHeight).abs(),
      lessThanOrEqualTo(
        Theme.of(fieldContext).tokens.borderWidthThin * 2,
      ),
    );
    expect(
      (fieldRect.center.dy - hintRect.center.dy).abs(),
      lessThanOrEqualTo(1),
    );
    expect(tester.takeException(), isNull);
  });
}
