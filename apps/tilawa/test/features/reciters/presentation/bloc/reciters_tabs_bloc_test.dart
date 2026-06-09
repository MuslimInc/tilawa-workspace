import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_tabs_bloc.dart';

void main() {
  group('RecitersTabsBloc', () {
    blocTest<RecitersTabsBloc, RecitersTabsState>(
      'starts on the provided initial tab',
      build: () => RecitersTabsBloc(initialTab: RecitersHomeTab.favorites),
      verify: (bloc) {
        expect(bloc.state.selectedTab, RecitersHomeTab.favorites);
        expect(bloc.state.selectedIndex, RecitersHomeTab.favorites.index);
      },
    );

    blocTest<RecitersTabsBloc, RecitersTabsState>(
      'emits selected tab when it changes',
      build: RecitersTabsBloc.new,
      act: (bloc) =>
          bloc.add(const RecitersTabSelected(RecitersHomeTab.downloads)),
      expect: () => const [
        RecitersTabsState(selectedTab: RecitersHomeTab.downloads),
      ],
    );

    blocTest<RecitersTabsBloc, RecitersTabsState>(
      'does not emit when selecting the current tab',
      build: RecitersTabsBloc.new,
      act: (bloc) => bloc.add(const RecitersTabSelected(RecitersHomeTab.all)),
      expect: () => const <RecitersTabsState>[],
    );
  });
}
