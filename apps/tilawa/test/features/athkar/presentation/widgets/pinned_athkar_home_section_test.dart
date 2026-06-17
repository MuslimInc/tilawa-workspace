import 'dart:async';

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
import 'package:tilawa/features/athkar/presentation/widgets/pinned_athkar_home_section.dart';
import 'package:tilawa/features/home/presentation/widgets/home_featured_ritual_card.dart';
import 'package:tilawa/features/home/presentation/widgets/home_grouped_list_row.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

void main() {
  testWidgets('shows default athkar shortcuts on Home', (tester) async {
    final cubit = PinnedAthkarCubit(
      GetAthkarCategoriesUseCase(_FakeAthkarRepository()),
      GetPinnedAthkarPreferenceUseCase(_FakePinnedAthkarRepository()),
      SavePinnedAthkarCategoryIdsUseCase(_FakePinnedAthkarRepository()),
    )..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(_PinnedAthkarHarness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('Quick athkar'), findsOneWidget);
    expect(find.byType(HomeFeaturedRitualCard), findsOneWidget);
    expect(find.textContaining('Morning Athkar'), findsWidgets);
    expect(find.textContaining('Evening Athkar'), findsOneWidget);
    expect(find.byType(HomeGroupedListRow), findsOneWidget);
  });

  testWidgets('shows loading card before pinned athkar loads', (tester) async {
    final cubit = PinnedAthkarCubit(
      GetAthkarCategoriesUseCase(_SlowAthkarRepository()),
      GetPinnedAthkarPreferenceUseCase(_FakePinnedAthkarRepository()),
      SavePinnedAthkarCategoryIdsUseCase(_FakePinnedAthkarRepository()),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_PinnedAthkarHarness(cubit: cubit));
    unawaited(cubit.load());
    await tester.pump();

    expect(find.byType(TilawaLoadingIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no categories pinned', (tester) async {
    final cubit = PinnedAthkarCubit(
      GetAthkarCategoriesUseCase(_FakeAthkarRepository()),
      GetPinnedAthkarPreferenceUseCase(_EmptyPinnedAthkarRepository()),
      SavePinnedAthkarCategoryIdsUseCase(_EmptyPinnedAthkarRepository()),
    )..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(_PinnedAthkarHarness(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text('Choose your daily athkar'), findsOneWidget);
    expect(find.text('Choose athkar'), findsOneWidget);
  });
}

class _PinnedAthkarHarness extends StatelessWidget {
  const _PinnedAthkarHarness({required this.cubit});

  final PinnedAthkarCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const PinnedAthkarHomeSection(),
        ),
      ),
    );
  }
}

const _categories = [
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
];

class _FakeAthkarRepository implements AthkarRepository {
  @override
  ResultFuture<List<AthkarCategory>> getCategories() async {
    return const Right(_categories);
  }

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return const Right([]);
  }
}

class _SlowAthkarRepository implements AthkarRepository {
  static final Completer<Either<Failure, List<AthkarCategory>>> _pending =
      Completer<Either<Failure, List<AthkarCategory>>>();

  @override
  ResultFuture<List<AthkarCategory>> getCategories() => _pending.future;

  @override
  ResultFuture<List<AthkarItem>> getAthkarByCategory(int categoryId) async {
    return const Right([]);
  }
}

class _FakePinnedAthkarRepository implements PinnedAthkarRepository {
  @override
  ResultFuture<PinnedAthkarPreference> getPreference() async {
    return const Right(
      PinnedAthkarPreference(categoryIds: [1, 2], isCustomized: false),
    );
  }

  @override
  ResultVoid saveCategoryIds(List<int> categoryIds) async {
    return const Right(null);
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
