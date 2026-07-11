import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tilawa/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:tilawa/features/reciters/presentation/layout/reciter_details_fab_layout.dart';
import 'package:tilawa/shared/widgets/quran_player_chrome.dart';
import 'package:tilawa_core/entities/audio.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class MockAudioPlayerBloc extends MockBloc<AudioPlayerEvent, AudioPlayerState>
    implements AudioPlayerBloc {}

const AudioEntity _tAudio = AudioEntity(
  id: '1',
  title: 'An-Nas',
  url: 'https://example.com/114.mp3',
  duration: Duration.zero,
);

/// Mirrors [ReciterDetailsScreen] FAB + list padding on a shell child route.
class _ReciterFabLayoutProbe extends StatelessWidget {
  const _ReciterFabLayoutProbe({
    required this.onLayout,
  });

  final ValueChanged<ReciterDetailsFabLayout> onLayout;

  @override
  Widget build(BuildContext context) {
    final ReciterDetailsFabLayout layout = ReciterDetailsFabLayout.resolve(
      context,
      scrollToTopFabVisible: true,
    );
    onLayout(layout);

    return Scaffold(
      floatingActionButton: const FloatingActionButton.small(
        heroTag: 'reciter_details_scroll_top_fab_probe',
        onPressed: null,
        child: Icon(Icons.arrow_upward_rounded),
      ),
      floatingActionButtonLocation: TilawaFabLocation.placement(
        TilawaFabPlacement.end,
        bottomOffset: layout.fabBottomOffset,
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            key: const Key('reciter_list_padding_probe'),
            padding: EdgeInsets.only(bottom: layout.listBottomPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => SizedBox(
                  key: Key('surah_tile_$index'),
                  height:
                      Theme.of(context).tokens.iconSizeLarge +
                      Theme.of(context).tokens.spaceExtraLarge,
                ),
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('ReciterDetails FAB layout on screen', () {
    testWidgets(
      'FAB clears opaque system nav when mini-player footer is absent',
      (tester) async {
        const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
          bottomNavBarHeight: 0,
          isKeyboardOpen: false,
          isAudioBindingDeferred: false,
          hostAbsorbsBottomSafeArea: false,
        );

        final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
        addTearDown(notifier.dispose);
        notifier.updateShellChrome(shellChrome);

        final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();
        when(() => audioPlayerBloc.state).thenReturn(
          const AudioPlayerState(status: AudioPlayerStatus.initial),
        );
        when(
          () => audioPlayerBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

        late ReciterDetailsFabLayout layout;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
              value: notifier,
              child: BlocProvider<AudioPlayerBloc>.value(
                value: audioPlayerBloc,
                child: MaterialApp.router(
                  theme: ThemeData(
                    extensions: <ThemeExtension<dynamic>>[
                      MeMuslimDesignTokens.light(),
                      MeMuslimComponentTokens.light(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: const Color(0xFF219653),
                        ),
                      ),
                    ],
                  ),
                  routerConfig: GoRouter(
                    initialLocation: '/reciter/maher',
                    routes: <RouteBase>[
                      GoRoute(
                        path: '/reciter/:reciterId',
                        builder: (BuildContext context, GoRouterState state) {
                          return _ReciterFabLayoutProbe(
                            onLayout: (ReciterDetailsFabLayout value) {
                              layout = value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final Finder fab = find.byType(FloatingActionButton);
        final Offset fabTopLeft = tester.getTopLeft(fab);
        final double fabBottom = fabTopLeft.dy + tester.getSize(fab).height;
        expect(
          800 - fabBottom,
          greaterThanOrEqualTo(kMeMuslimMinInteractiveDimension),
        );

        expect(
          layout.listBottomPadding,
          layout.fabBottomOffset +
              kMeMuslimMinInteractiveDimension +
              MeMuslimDesignTokens.light().spaceLarge,
        );
      },
    );

    testWidgets(
      'list reserves FAB clearance when shell footer shows mini-player',
      (tester) async {
        const QuranPlayerShellChrome shellChrome = QuranPlayerShellChrome(
          bottomNavBarHeight: 0,
          isKeyboardOpen: false,
          isAudioBindingDeferred: false,
          hostAbsorbsBottomSafeArea: false,
        );

        final QuranPlayerChromeNotifier notifier = QuranPlayerChromeNotifier();
        addTearDown(notifier.dispose);
        notifier.updateShellChrome(shellChrome);

        final MockAudioPlayerBloc audioPlayerBloc = MockAudioPlayerBloc();
        when(() => audioPlayerBloc.state).thenReturn(
          const AudioPlayerState(
            status: AudioPlayerStatus.success,
            currentAudio: _tAudio,
          ),
        );
        when(
          () => audioPlayerBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

        final MeMuslimDesignTokens tokens = MeMuslimDesignTokens.light();
        final double footerHeight =
            tokens.playerCollapsedHeight +
            tokens.spaceExtraLarge +
            tokens.spaceSmall;

        late ReciterDetailsFabLayout layout;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: ChangeNotifierProvider<QuranPlayerChromeNotifier>.value(
              value: notifier,
              child: BlocProvider<AudioPlayerBloc>.value(
                value: audioPlayerBloc,
                child: MaterialApp.router(
                  theme: ThemeData(
                    extensions: <ThemeExtension<dynamic>>[
                      tokens,
                      MeMuslimComponentTokens.light(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: const Color(0xFF219653),
                        ),
                      ),
                    ],
                  ),
                  routerConfig: GoRouter(
                    initialLocation: '/reciter/maher',
                    routes: <RouteBase>[
                      ShellRoute(
                        builder:
                            (
                              BuildContext context,
                              GoRouterState state,
                              Widget child,
                            ) {
                              return TilawaAdaptiveShell(
                                destinations: const <TilawaNavDestination>[
                                  TilawaNavDestination(
                                    label: 'Home',
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home,
                                  ),
                                ],
                                selectedIndex: 0,
                                onDestinationSelected: (_) {},
                                phoneBottomNavigationBarVisible:
                                    ValueNotifier<bool>(false),
                                phoneFooterAboveNav: SizedBox(
                                  height: footerHeight,
                                  child: const ColoredBox(color: Colors.blue),
                                ),
                                bottomPlayer: const SizedBox.shrink(),
                                child: child,
                              );
                            },
                        routes: <RouteBase>[
                          GoRoute(
                            path: '/reciter/:reciterId',
                            builder:
                                (BuildContext context, GoRouterState state) {
                                  return _ReciterFabLayoutProbe(
                                    onLayout: (ReciterDetailsFabLayout value) {
                                      layout = value;
                                    },
                                  );
                                },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final double fabBottomOffset = tokens.spaceSmall + tokens.spaceLarge;
        final double fabClearance =
            fabBottomOffset +
            kMeMuslimMinInteractiveDimension +
            tokens.spaceLarge;

        expect(layout.listBottomPadding, fabClearance + tokens.spaceMedium);
        expect(
          layout.listBottomPadding,
          greaterThan(
            footerHeight,
          ),
          reason: 'FAB clearance is independent of shell footer height',
        );
      },
    );

    testWidgets(
      'FAB keeps stable size when offset location is recreated on rebuild',
      (tester) async {
        const double fabBottomOffset = 24;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: <ThemeExtension<dynamic>>[
                MeMuslimDesignTokens.light(),
              ],
            ),
            home: const _FabRebuildProbe(bottomOffset: fabBottomOffset),
          ),
        );
        await tester.pump();

        final Finder fab = find.byType(FloatingActionButton);
        final Size initialSize = tester.getSize(fab);
        expect(initialSize.width, greaterThanOrEqualTo(40));
        expect(initialSize.height, greaterThanOrEqualTo(40));

        for (var tick = 0; tick < 5; tick++) {
          await tester.tap(find.byKey(_fabRebuildProbeButtonKey));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.getSize(fab), initialSize);
        }
      },
    );
  });
}

const Key _fabRebuildProbeButtonKey = Key('fab_rebuild_probe_button');

class _FabRebuildProbe extends StatefulWidget {
  const _FabRebuildProbe({required this.bottomOffset});

  final double bottomOffset;

  @override
  State<_FabRebuildProbe> createState() => _FabRebuildProbeState();
}

class _FabRebuildProbeState extends State<_FabRebuildProbe> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const FloatingActionButton.small(
        heroTag: 'fab_size_probe',
        onPressed: null,
        child: Icon(Icons.arrow_upward_rounded),
      ),
      floatingActionButtonLocation: TilawaFabLocation.placement(
        TilawaFabPlacement.end,
        bottomOffset: widget.bottomOffset,
      ),
      body: Center(
        child: FilledButton(
          key: _fabRebuildProbeButtonKey,
          onPressed: () => setState(() => _tick++),
          child: Text('tick $_tick'),
        ),
      ),
    );
  }
}
