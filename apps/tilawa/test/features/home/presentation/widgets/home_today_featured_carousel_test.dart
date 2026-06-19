import 'package:dartz_plus/dartz_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_category.dart';
import 'package:tilawa/features/athkar/domain/entities/athkar_item.dart';
import 'package:tilawa/features/athkar/domain/entities/pinned_athkar_preference.dart';
import 'package:tilawa/features/athkar/domain/repositories/athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/repositories/pinned_athkar_repository.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_athkar_categories_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/get_pinned_athkar_preference_use_case.dart';
import 'package:tilawa/features/athkar/domain/usecases/save_pinned_athkar_category_ids_use_case.dart';
import 'package:tilawa/features/athkar/presentation/cubit/pinned_athkar_cubit.dart';
import 'package:tilawa/features/home/presentation/cubit/home_quran_resume_cubit.dart';
import 'package:tilawa/features/home/presentation/widgets/home_quran_resume_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_today_featured_carousel.dart';
import 'package:tilawa/features/quran_reader/domain/usecases/get_last_read_position_use_case.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('uses full-width layout when only the Quran card is visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _CarouselHarness(
        pinnedRepository: _EmptyPinnedAthkarRepository(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomeQuranResumeCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeTodayFeaturedCarousel),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('stacks multiple featured cards on compact widths', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _CarouselHarness(
        pinnedRepository: _DefaultPinnedAthkarRepository(),
        now: _morningNow,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(HomeTodayFeaturedCarousel),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('uses horizontal scroll when multiple featured cards show wide', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(900, 1200);
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _CarouselHarness(
        pinnedRepository: _DefaultPinnedAthkarRepository(),
        now: _morningNow,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeQuranResumeCard), findsOneWidget);

    final scrollFinder = find.descendant(
      of: find.byType(HomeTodayFeaturedCarousel),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollFinder, findsOneWidget);

    final RenderBox scrollBox = tester.renderObject<RenderBox>(
      scrollFinder,
    );
    expect(scrollBox.hasSize, isTrue);
    expect(
      scrollBox.size.height,
      HomeTodayFeaturedCarousel.carouselSlotHeight(
        tester.element(find.byType(HomeTodayFeaturedCarousel)),
      ),
    );
  });
}

/// Fixed morning time so contextualAthkarCategory always picks the morning card.
final _morningNow = DateTime(2024, 1, 1, 9);

class _CarouselHarness extends StatelessWidget {
  const _CarouselHarness({required this.pinnedRepository, this.now});

  final PinnedAthkarRepository pinnedRepository;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => PinnedAthkarCubit(
                GetAthkarCategoriesUseCase(_FakeAthkarRepository()),
                GetPinnedAthkarPreferenceUseCase(pinnedRepository),
                SavePinnedAthkarCategoryIdsUseCase(pinnedRepository),
              )..load(),
            ),
            BlocProvider(
              create: (_) =>
                  HomeQuranResumeCubit(_FakeGetLastReadPosition())..load(),
            ),
          ],
          child: HomeTodayFeaturedCarousel(nowOverride: now),
        ),
      ),
    );
  }
}

class _EmptyPinnedAthkarRepository implements PinnedAthkarRepository {
  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    return const Right(null);
  }
}

class _DefaultPinnedAthkarRepository implements PinnedAthkarRepository {
  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [1], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    return const Right(null);
  }
}

class _FakeGetLastReadPosition implements GetLastReadPositionUseCase {
  @override
  Future<Either<Failure, ({int? surahNumber, int? ayahNumber, int? page})>>
  call() async {
    return const Right((surahNumber: 2, ayahNumber: 43, page: 42));
  }
}

class _FakeAthkarRepository implements AthkarRepository {
  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    return const Right([
      AthkarCategory(
        id: 1,
        nameAr: 'أذكار الصباح',
        nameEn: 'Morning Athkar',
        icon: 'wb_sunny_rounded',
      ),
      AthkarCategory(
        id: 2,
        nameAr: 'أذكار المساء',
        nameEn: 'Evening Athkar',
        icon: 'nights_stay_rounded',
      ),
    ]);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return const Right([]);
  }
}
