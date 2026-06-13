import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quran_image/data/repositories/in_memory_navigation_visibility_repository.dart';
import 'package:quran_image/data/repositories/in_memory_page_repository.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';

import 'loaded_navigation_bloc.dart';

/// Creates a loaded [NavigationBloc] for reader navigation tests.
NavigationBloc createLoadedNavigationBloc({required int initialPage}) {
  final PageRepository pageRepository = InMemoryPageRepository();
  final PageState pageState = pageRepository.navigateToPage(initialPage);

  return LoadedNavigationBloc(
    initialState: NavigationLoaded(
      pageState: pageState,
      visibility: NavigationVisibility.initial(),
    ),
    pageRepository: pageRepository,
    visibilityRepository: InMemoryNavigationVisibilityRepository(),
    saveLastVisitedPageUseCase: SaveLastVisitedPageUseCase(
      _TestLastVisitedPageRepository(),
    ),
    getLastVisitedPageUseCase: GetLastVisitedPageUseCase(
      _TestLastVisitedPageRepository(initialPage: initialPage),
    ),
  );
}

Future<void> pumpNavigationBloc(NavigationBloc bloc) async {
  await Future<void>.delayed(Duration.zero);
}

class _TestLastVisitedPageRepository implements LastVisitedPageRepository {
  _TestLastVisitedPageRepository({this.initialPage = 1});

  final int initialPage;
  final List<int> savedPages = <int>[];

  @override
  Future<int?> getLastVisitedPage() => SynchronousFuture<int?>(initialPage);

  @override
  Future<void> saveLastVisitedPage(int pageNumber) {
    savedPages.add(pageNumber);
    return SynchronousFuture<void>(null);
  }

  @override
  Future<void> clearLastVisitedPage() => SynchronousFuture<void>(null);
}
