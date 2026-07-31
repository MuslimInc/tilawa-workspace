import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/presentation/widgets/molecules/page_slider.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('PageSlider uses minPage as slider lower bound', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
        home: Scaffold(
          body: PageSlider(
            currentPage: 12,
            committedPage: 12,
            minPage: 10,
            totalPages: 20,
            onChanged: (_) {},
            screenWidth: 390,
          ),
        ),
      ),
    );

    final Slider slider = tester.widget(find.byType(Slider));
    expect(slider.min, 10);
    expect(slider.max, 20);
    expect(slider.value, 12);
  });
}
