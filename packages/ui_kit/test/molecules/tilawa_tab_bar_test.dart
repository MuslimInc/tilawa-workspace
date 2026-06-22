import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  group('TilawaTabBar', () {
    testWidgets('underline variant uses themed TabBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const _Harness(
            variant: TilawaTabBarVariant.underline,
            firstLabel: 'This week',
            secondLabel: 'Next week',
          ),
        ),
      );

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final tokens = AppTheme.getLightTheme(
        primaryColor: AppColors.defaultPrimary,
      ).tokens;

      expect(find.text('This week'), findsOneWidget);
      expect(
        tabBar.splashBorderRadius,
        BorderRadius.circular(
          tokens.resolveRadius(family: TilawaRadiusFamily.section),
        ),
      );
      expect(tabBar.overlayColor, isNotNull);
    });

    testWidgets('pill variant wraps TabBar in rounded track', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
          home: const _Harness(
            variant: TilawaTabBarVariant.pill,
            firstLabel: 'All',
            secondLabel: 'Favorites',
          ),
        ),
      );

      expect(find.byType(DecoratedBox), findsWidgets);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });
}

class _Harness extends StatefulWidget {
  const _Harness({
    required this.variant,
    required this.firstLabel,
    required this.secondLabel,
  });

  final TilawaTabBarVariant variant;
  final String firstLabel;
  final String secondLabel;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TilawaTabBar(
        controller: _controller,
        variant: widget.variant,
        tabs: [
          Tab(text: widget.firstLabel),
          Tab(text: widget.secondLabel),
        ],
      ),
    );
  }
}
