import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:quran_image/presentation/bloc/navigation/navigation_state.dart';
import 'package:tilawa/features/quran_reader/presentation/navigation/quran_image_reader_index_navigation.dart';

import '../../helpers/test_navigation_bloc_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranImageReader index provider wiring', () {
    testWidgets(
      'parent screen context cannot read NavigationBloc above BlocProvider',
      (WidgetTester tester) async {
        BuildContext? parentContext;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, _) {
                parentContext = context;
                return BlocProvider<NavigationBloc>(
                  create: (_) => createLoadedNavigationBloc(initialPage: 1),
                  child: const Placeholder(),
                );
              },
            ),
          ),
        );

        expect(parentContext, isNotNull);
        expect(
          () => parentContext!.read<NavigationBloc>(),
          throwsA(isA<ProviderNotFoundException>()),
        );
      },
    );

    testWidgets(
      'child below BlocProvider can read the reader NavigationBloc',
      (WidgetTester tester) async {
        NavigationBloc? childBloc;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<NavigationBloc>(
              create: (_) => createLoadedNavigationBloc(initialPage: 137),
              child: Builder(
                builder: (context) {
                  childBloc = context.read<NavigationBloc>();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        expect(childBloc, isNotNull);
        expect(
          (childBloc!.state as NavigationLoaded).pageState.currentPage,
          137,
        );
      },
    );

    testWidgets(
      'screen-level handler skips dispatch when sheet returns null',
      (WidgetTester tester) async {
        final NavigationBloc navigationBloc = createLoadedNavigationBloc(
          initialPage: 137,
        );
        addTearDown(navigationBloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: ElevatedButton(
              onPressed: () {
                const int? selectedSurah = null;
                if (!QuranImageReaderIndexNavigation.shouldDispatchSelection(
                  isMounted: true,
                  selectedSurah: selectedSurah,
                )) {
                  return;
                }
                QuranImageReaderIndexNavigation.dispatchSelection(
                  navigationBloc,
                  selectedSurah!,
                );
              },
              child: const Text('Dismiss index'),
            ),
          ),
        );

        await tester.tap(find.text('Dismiss index'));
        await tester.pump();

        expect(
          (navigationBloc.state as NavigationLoaded).pageState.currentPage,
          137,
        );
      },
    );
  });
}
