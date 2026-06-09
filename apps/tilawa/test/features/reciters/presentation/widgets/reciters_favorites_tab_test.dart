import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/cubit/favorites_cubit.dart';
import 'package:tilawa/features/reciters/presentation/widgets/reciters_favorites_tab.dart';
import 'package:tilawa/features/theme/domain/primary_color_preset.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../../../support/reciters_screen_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerRecitersScreenTestFallbacks);

  Finder favoritesScrollView() {
    return find.descendant(
      of: find.byType(RecitersFavoritesTab),
      matching: find.byType(CustomScrollView),
    );
  }

  Widget buildNestedFavoritesTab({
    required FavoritesCubit favoritesCubit,
    required ScrollController scrollController,
    required Widget body,
  }) {
    return MaterialApp(
      theme: AppTheme.getLightTheme(
        primaryColor: PrimaryColorPreset.defaultPreset.value,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<FavoritesCubit>.value(
        value: favoritesCubit,
        child: body,
      ),
    );
  }

  Widget nestedFavoritesBody(ScrollController scrollController) {
    return Builder(
      builder: (BuildContext context) {
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ),
            ];
          },
          body: RecitersFavoritesTab(
            pageStorageKey: const PageStorageKey<String>('favorites_test'),
            scrollController: scrollController,
          ),
        );
      },
    );
  }

  group('RecitersFavoritesTab', () {
    late FavoritesCubit favoritesCubit;
    late ScrollController scrollController;

    setUp(() {
      favoritesCubit = seededFavoritesCubit();
      scrollController = ScrollController();
    });

    tearDown(() async {
      scrollController.dispose();
      if (!favoritesCubit.isClosed) {
        await favoritesCubit.close();
      }
    });

    testWidgets('uses PrimaryScrollController inside NestedScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildNestedFavoritesTab(
          favoritesCubit: favoritesCubit,
          scrollController: scrollController,
          body: nestedFavoritesBody(scrollController),
        ),
      );
      await tester.pumpAndSettle();

      final CustomScrollView scrollView = tester.widget(favoritesScrollView());
      expect(scrollView.controller, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state omits browse-reciters action', (tester) async {
      await favoritesCubit.close();
      favoritesCubit = seededFavoritesCubit(
        favoriteIds: const {},
        favorites: const [],
      );

      await tester.pumpWidget(
        buildNestedFavoritesTab(
          favoritesCubit: favoritesCubit,
          scrollController: scrollController,
          body: nestedFavoritesBody(scrollController),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No favorites'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TilawaIllustratedState),
          matching: find.byType(TilawaButton),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
